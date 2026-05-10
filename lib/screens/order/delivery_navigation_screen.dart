import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../services/location_service.dart';
import 'safety_checklist_starting_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeliveryNavigationScreen — Driver navigation TO customer location.
//
// Identical architecture to RealTimeDeliveryScreen:
//  • GPS via getPositionStream (NEVER getCurrentPosition + timer)
//  • Polyline fetched ONCE; only re-fetched on > 100 m deviation
//  • Smooth LatLng lerp marker animation (500 ms)
//  • Camera tilt:45, zoom:16, bearing:heading
//  • Supabase UPSERT driver_locations + drivers (throttled 3 s)
//
// Difference: "Arrived" button → FuelPickupScreen (instead of SafetyChecklist).
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryNavigationScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const DeliveryNavigationScreen({super.key, this.order});

  @override
  State<DeliveryNavigationScreen> createState() =>
      _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen>
    with TickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();

  // ── Smooth marker animation ───────────────────────────────────────────────
  AnimationController? _markerAnimController;
  Animation<double>? _markerAnim;
  LatLng? _prevMarkerPos;
  LatLng? _currentMarkerPos;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;
  bool _isReleasing = false; // guard for Release Order button

  // ── Stats ──────────────────────────────────────────────────────────────────
  double _distanceMiles = 0.0;
  int _estimatedMinutes = 0;
  String _etaTime = '--:--';
  bool _isCalculating = true; // true until first route fetch completes

  // ── Destination (mutable — resolved async) ───────────────────────────────
  double? _destLat;
  double? _destLng;
  String _destinationLabel = 'Customer Location';

  // ── Directions API (direct HTTP call — no third-party package) ──────────
  final String _apiKey = dotenv.env['MAPS_API_KEY'] ?? '';



  @override
  void initState() {
    super.initState();

    final order = widget.order;
    double? lat = _parseDouble(order?['customer_lat']) ??
        _parseDouble(order?['delivery_lat']);
    double? lng = _parseDouble(order?['customer_lng']) ??
        _parseDouble(order?['delivery_lng']);
    if (lat == 0.0 && lng == 0.0) {
      lat = null;
      lng = null;
    }
    _destLat = lat;
    _destLng = lng;
    _destinationLabel =
        order?['delivery_address']?.toString() ?? 'Customer Location';

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startLocationStream();
    _fetchRouteEarly();
  }

  Future<void> _fetchRouteEarly() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentMarkerPos = latLng;
      _updateDriverMarker(latLng, pos.heading);
      if (_destLat != null && _destLng != null && !_routeFetched) {
        _fetchRoute(pos);
      }
    } catch (e) {
      debugPrint('[DeliveryNav] Early GPS fix failed: $e');
    }
  }

  @override
  void dispose() {
    _gpsTracker.dispose();
    _markerAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  // ── Start GPS stream ──────────────────────────────────────────────────────
  Future<void> _startLocationStream() async {
    final ok = await _gpsTracker.start(
      dbThrottleSeconds: 3,
      onPosition: _onNewPosition,
    );

    if (!ok && mounted) {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _gpsDisabled = !svcEnabled;
        _locationPermissionDenied = svcEnabled;
      });
    }
  }

  // ── Handle each new GPS fix ───────────────────────────────────────────────
  void _onNewPosition(Position pos) {
    if (!mounted) return;

    final newLatLng = LatLng(pos.latitude, pos.longitude);

    // Smooth marker interpolation
    final from = _currentMarkerPos ?? newLatLng;
    _prevMarkerPos = from;
    _currentMarkerPos = newLatLng;

    _markerAnimController?.reset();
    _markerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _markerAnimController!, curve: Curves.easeInOut),
    )..addListener(() {
        if (!mounted) return;
        final interp = _lerpLatLng(
            _prevMarkerPos!, _currentMarkerPos!, _markerAnim!.value);
        _updateDriverMarker(interp, pos.heading);
      });
    _markerAnimController?.forward();

    // Stats
    if (_destLat != null && _destLng != null) _updateStats(pos);

    // Camera follow
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: newLatLng,
        zoom: 16,
        tilt: 45,
        bearing: pos.heading,
      )),
    );

    // Smart polyline refresh
    if (_routeFetched && _routePoints.isNotEmpty) {
      final dev = _distanceToPolyline(newLatLng, _routePoints);
      if (dev > 100) {
        debugPrint('[Route Fetch] Deviation ${dev.toStringAsFixed(0)} m — re-fetching');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute &&
        _destLat != null && _destLng != null) {
      _fetchRoute(pos);
    }
  }

  LatLng _lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
        lerpDouble(a.latitude, b.latitude, t)!,
        lerpDouble(a.longitude, b.longitude, t)!,
      );

  double _distanceToPolyline(LatLng point, List<LatLng> poly) {
    double min = double.infinity;
    for (final pt in poly) {
      final d = Geolocator.distanceBetween(
          point.latitude, point.longitude, pt.latitude, pt.longitude);
      if (d < min) min = d;
    }
    return min;
  }

  void _updateDriverMarker(LatLng pos, double heading) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        rotation: heading,
        flat: true,
        zIndexInt: 2,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    });
  }

  void _updateStats(Position pos) {
    final dLat = _destLat;
    final dLng = _destLng;
    if (dLat == null || dLng == null) return;
    final distM = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLat, dLng);
    _applyStats(distanceMeters: distM, durationSecs: null);
  }

  /// Core stats applier — called both from API response and from live GPS.
  /// [durationSecs] comes from the Directions API (preferred).
  /// If null, duration is estimated from speed (30 km/h average).
  void _applyStats({required double distanceMeters, int? durationSecs}) {
    final miles = distanceMeters / 1609.34;
    final int mins = durationSecs != null
        ? math.max(1, (durationSecs / 60).ceil())
        : math.max(1, (miles / 18.64 * 60.0).ceil()); // 30 km/h fallback
    final arrival = DateTime.now().add(Duration(minutes: mins));
    final h = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final m = arrival.minute.toString().padLeft(2, '0');
    final ampm = arrival.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _isCalculating = false;
        _distanceMiles = miles;
        _estimatedMinutes = mins;
        _etaTime = '$h:$m $ampm';
      });
    }
  }

  // ── Google Directions API: decode encoded polyline string ─────────────────
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _fetchRoute(Position driverPos) async {
    final dLat = _destLat;
    final dLng = _destLng;

    if (dLat == null || dLng == null) {
      debugPrint('[Route ERROR] Destination missing — cannot fetch route');
      return;
    }
    if (_isLoadingRoute) return;

    debugPrint('[Route Input] driver: ${driverPos.latitude},${driverPos.longitude}');
    debugPrint('[Route Input] destination: $dLat,$dLng');

    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${driverPos.latitude},${driverPos.longitude}'
        '&destination=$dLat,$dLng'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode != 200) {
        debugPrint('[Route API Response] HTTP error ${response.statusCode}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';
      debugPrint('[Route API Response] status=$status');

      if (status != 'OK') {
        debugPrint('[Route ERROR] API status=$status — ${data['error_message'] ?? 'no details'}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route ERROR] No routes returned');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      // ── Extract duration + distance from legs ─────────────────────────
      final legs = routes[0]['legs'] as List?;
      int? apiDurationSecs;
      double? apiDistanceMeters;
      if (legs != null && legs.isNotEmpty) {
        // Prefer duration_in_traffic if present (real-time traffic)
        final leg = legs[0] as Map<String, dynamic>?;
        apiDurationSecs = (leg?['duration_in_traffic']?['value'] as int?) ??
            (leg?['duration']?['value'] as int?);
        apiDistanceMeters =
            ((leg?['distance']?['value']) as num?)?.toDouble();
        debugPrint(
            '[Route Stats] duration=${apiDurationSecs}s  distance=${apiDistanceMeters}m');
      }

      final encodedPolyline =
          (routes[0]['overview_polyline']['points'] as String?) ?? '';
      debugPrint('[Polyline Raw] ${encodedPolyline.length > 80 ? '${encodedPolyline.substring(0, 80)}…' : encodedPolyline}');

      if (encodedPolyline.isEmpty) {
        debugPrint('[Polyline ERROR] Empty polyline string');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);
      debugPrint('[Polyline Points] count = ${decodedPoints.length}');

      if (decodedPoints.length < 2) {
        debugPrint('[Polyline ERROR] Too few points: ${decodedPoints.length}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      _routePoints
        ..clear()
        ..addAll(decodedPoints);

      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dLat, dLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destinationLabel),
        zIndexInt: 1,
      ));

      debugPrint('[Polyline Drawn] ${decodedPoints.length} points rendered on map ✓');

      setState(() {
        _routeFetched = true;
        _isLoadingRoute = false;
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF4285F4),
            points: List<LatLng>.from(decodedPoints),
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ));
      });

      // ── Update stats IMMEDIATELY from API data ─────────────────────────
      if (apiDistanceMeters != null && apiDistanceMeters > 0) {
        _applyStats(
          distanceMeters: apiDistanceMeters,
          durationSecs: apiDurationSecs,
        );
      } else {
        // Fallback: haversine from driver position
        _updateStats(driverPos);
      }

    } catch (e) {
      debugPrint('[Route ERROR] Exception: $e');
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final dLatV = _destLat;
    final dLngV = _destLng;
    if (_currentMarkerPos != null && dLatV != null && dLngV != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentMarkerPos!.latitude, dLatV),
          math.min(_currentMarkerPos!.longitude, dLngV),
        ),
        northeast: LatLng(
          math.max(_currentMarkerPos!.latitude, dLatV),
          math.max(_currentMarkerPos!.longitude, dLngV),
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_gpsDisabled) {
      return _errorScreen(
        'GPS is Disabled',
        'Please turn on Location Services in your device settings.',
        Icons.location_disabled_rounded,
      );
    }
    if (_locationPermissionDenied) {
      return _errorScreen(
        'Location Permission Denied',
        'FuelDirect needs location access to navigate.',
        Icons.lock_rounded,
        actionLabel: 'Open Settings',
        onAction: () async => Geolocator.openAppSettings(),
      );
    }

    final dLatV = _destLat;
    final dLngV = _destLng;
    final LatLng initialTarget = (dLatV != null && dLngV != null)
        ? LatLng(dLatV, dLngV)
        : _currentMarkerPos ?? const LatLng(24.8607, 67.0011);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition:
                  CameraPosition(target: initialTarget, zoom: 14),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              markers: Set<Marker>.of(_markers),
              polylines: Set<Polyline>.of(_polylines),
              onMapCreated: _onMapCreated,
            ),
          ),

          // Route loading bar
          if (_isLoadingRoute)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: Color(0xFFFF4D00),
                backgroundColor: Colors.transparent,
              ),
            ),

          // ── Top controls ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(
                        Icons.arrow_back_ios_new,
                        Colors.black,
                        () => Navigator.of(context).pop(),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _destinationLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F1F1F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8DD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CUSTOMER',
                          style: TextStyle(
                            color: Color(0xFFFF4D00),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBox(
                        'ETA',
                        _isCalculating ? 'Calc...' : _etaTime,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'TIME',
                        _isCalculating
                            ? 'Calc...'
                            : '$_estimatedMinutes min',
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'DIST',
                        _isCalculating
                            ? 'Calc...'
                            : (_distanceMiles > 0
                                ? '${_distanceMiles.toStringAsFixed(1)} mi'
                                : 'N/A'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Customer Notes ──────────────────────────────────────
                  Builder(builder: (context) {
                    final notes = (
                      widget.order?['drop_off_instructions'] ??
                      widget.order?['delivery_instructions'] ??
                      widget.order?['customer_notes'] ??
                      widget.order?['special_instructions'] ??
                      widget.order?['notes']
                    )?.toString().trim() ?? '';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: notes.isNotEmpty
                            ? const Color(0xFFFFF9F5)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notes.isNotEmpty
                              ? const Color(0xFFFFE8DD)
                              : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            notes.isNotEmpty
                                ? Icons.sticky_note_2_rounded
                                : Icons.sticky_note_2_outlined,
                            color: notes.isNotEmpty
                                ? const Color(0xFFFF4D00)
                                : const Color(0xFFCCCCCC),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CUSTOMER NOTES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: notes.isNotEmpty
                                        ? const Color(0xFFFF4D00)
                                        : const Color(0xFFCCCCCC),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notes.isNotEmpty
                                      ? notes
                                      : 'No special instructions provided.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: notes.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontStyle: notes.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                    color: notes.isNotEmpty
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFAAAAAA),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final orderId = widget.order?['id']?.toString();
                        if (orderId == null) return;

                        try {
                          final now = DateTime.now().toUtc().toIso8601String();
                          try {
                            await Supabase.instance.client.from('orders').update({
                              'status': 'DRIVER_ARRIVED',
                              'arrived_at': now,
                            }).eq('id', orderId);
                          } catch (e) {
                            debugPrint('[DeliveryNavigation] arrived_at update failed: $e');
                            await Supabase.instance.client.from('orders').update({
                              'status': 'DRIVER_ARRIVED',
                            }).eq('id', orderId);
                          }

                          widget.order?['status'] = 'DRIVER_ARRIVED';
                          widget.order?['arrived_at'] = now;

                          if (!context.mounted) return;
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  SafetyChecklistStartingScreen(order: widget.order),
                            ),
                          );
                          
                        } catch (e) {
                          debugPrint('[DeliveryNavigation] Error: $e');
                          if (!context.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e')),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  SafetyChecklistStartingScreen(order: widget.order),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Arrived at Customer',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Release Order button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _isReleasing ? null : _releaseOrder,
                      icon: _isReleasing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFCC0000),
                              ),
                            )
                          : const Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Color(0xFFCC0000),
                            ),
                      label: Text(
                        _isReleasing ? 'Releasing…' : 'Release Order',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFFCC0000),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFCC0000), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Release Order ────────────────────────────────────────────────
  Future<void> _releaseOrder() async {
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;

    // ── Confirmation dialog ────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFCC0000), size: 22),
            SizedBox(width: 10),
            Text(
              'Release Order?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1C2733),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to release this order?\n\nIt will be returned to the available pool and reassigned to another driver.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF888888)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCC0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Release',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Supabase update ───────────────────────────────────────
    setState(() => _isReleasing = true);
    try {
      await Supabase.instance.client.from('orders').update({
        'status': 'available',
        'driver_id': null,
        'driver_name': null,
        'driver_photo': null,
        'driver_vehicle': null,
        'driver_phone': null,
        'driver_latitude': null,
        'driver_longitude': null,
        'assigned_at': null,
      }).eq('id', orderId);

      debugPrint('[ReleaseOrder] Order $orderId released back to pool');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Order released. It will be reassigned.'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
        ),
      );

      // Pop back to the orders list
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('[ReleaseOrder] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to release order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isReleasing = false);
    }
  }

  Widget _circleBtn(IconData icon, Color iconColor, VoidCallback onTap,
      {double size = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8DD).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorScreen(
    String title,
    String subtitle,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: const Color(0xFFFF4D00)),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F))),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF888888), height: 1.5)),
              const SizedBox(height: 32),
              if (actionLabel != null && onAction != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back',
                    style: TextStyle(
                        color: Color(0xFFFF4D00),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
