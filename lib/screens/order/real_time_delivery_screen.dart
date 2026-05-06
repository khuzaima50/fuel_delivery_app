import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';
import 'safety_checklist_starting_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RealTimeDeliveryScreen — Full production navigation screen.
//
// Key behaviours mandated by spec:
//  • GPS via getPositionStream (NEVER getCurrentPosition + timer)
//  • Polyline fetched ONCE; only re-fetched when driver deviates > 100 m
//  • Marker animates smoothly using LatLng lerp over 500 ms
//  • Camera follows driver with tilt:45, zoom:16, bearing:heading
//  • Supabase UPSERT to driver_locations + drivers (throttled 3 s)
// ─────────────────────────────────────────────────────────────────────────────
class RealTimeDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const RealTimeDeliveryScreen({super.key, this.order});

  @override
  State<RealTimeDeliveryScreen> createState() => _RealTimeDeliveryScreenState();
}

class _RealTimeDeliveryScreenState extends State<RealTimeDeliveryScreen>
    with TickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = []; // stored in memory after first fetch

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();
  StreamSubscription<ServiceStatus>? _serviceStatusSub;

  // ── Smooth marker animation ───────────────────────────────────────────────
  AnimationController? _markerAnimController;
  Animation<double>? _markerAnim;
  LatLng? _prevMarkerPos; // interpolation start
  LatLng? _currentMarkerPos; // interpolation end (latest GPS fix)

  // ── State flags ───────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;
  bool _isArrived = false;

  // ── Stats ──────────────────────────────────────────────────────────────────
  double _distanceMiles = 0.0;
  int _estimatedMinutes = 0;
  String _etaTime = '--:--';

  // ── Customer profile ───────────────────────────────────────────────────────
  String _customerName = 'Customer';
  String? _customerAvatarUrl;
  double _customerRating = 5.0;

  // ── Destination (mutable — resolved async) ───────────────────────────────
  double? _destLat;
  double? _destLng;
  String _destAddress = 'Customer Location';
  String? _customerPhone;
  bool _isResolvingDestination = false;
  bool _destinationMissing = false;

  // -- Directions API (direct HTTP call -- no third-party package) ----------
  final String _apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
  late final PolylinePoints _polylinePoints;

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints(apiKey: _apiKey);

    // Marker animation controller
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fetchCustomerData();
    _startLocationStream();
    _resolveDestination(); // async — resolves lat/lng from order
    _checkInitialStatus();
    _fetchRouteEarly();   // fetch route immediately without waiting for stream
  }

  /// Immediately grabs a GPS fix and draws the route —
  /// fallback for cases where the stream hasn't emitted yet.
  Future<void> _fetchRouteEarly() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      // Store driver marker right away
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentMarkerPos = latLng;
      _updateDriverMarker(latLng, pos.heading);
      // Fetch route if destination is already resolved
      if (_destLat != null && _destLng != null && !_routeFetched) {
        _fetchRoute(pos);
      }
    } catch (e) {
      debugPrint('[RealTimeDelivery] Early GPS fix failed: $e');
    }
  }

  void _checkInitialStatus() {
  }

  @override
  void dispose() {
    _gpsTracker.dispose();
    _serviceStatusSub?.cancel();
    _markerAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  // ── Resolve destination — tries every known column name, re-fetches from
  //    Supabase if needed, falls back to Geocoding API. ──────────────────────
  Future<void> _resolveDestination() async {
    if (_isResolvingDestination) return;
    if (mounted) setState(() => _isResolvingDestination = true);

    final order = widget.order;
    final orderId = order?['id']?.toString();
    debugPrint('[Order Fetch] Resolving destination for order: $orderId');

    // ── Step 1: Try every column name variant present in the passed map ───
    final allLatKeys = [
      'customer_lat', 'delivery_lat', 'latitude', 'delivery_latitude',
      'lat', 'dest_lat', 'dropoff_lat',
    ];
    final allLngKeys = [
      'customer_lng', 'delivery_lng', 'longitude', 'delivery_longitude',
      'lng', 'dest_lng', 'dropoff_lng',
    ];

    double? lat;
    double? lng;

    if (order != null) {
      for (final k in allLatKeys) {
        final v = _parseDouble(order[k]);
        if (v != null && v != 0.0) { lat = v; break; }
      }
      for (final k in allLngKeys) {
        final v = _parseDouble(order[k]);
        if (v != null && v != 0.0) { lng = v; break; }
      }
    }

    final address = order?['delivery_address']?.toString() ??
        order?['address']?.toString() ?? '';
    _customerPhone = order?['customer_phone']?.toString();

    // ── Step 2: Re-fetch full order row from Supabase (realtime payloads
    //    may have incomplete records) ─────────────────────────────────────
    if ((lat == null || lng == null) && orderId != null) {
      debugPrint('[Order Fetch] Lat/lng missing in passed map — re-fetching order $orderId from Supabase');
      try {
        final fresh = await Supabase.instance.client
            .from('orders')
            .select('*, profiles:user_id(phone_number)')
            .eq('id', orderId)
            .maybeSingle();
        if (fresh != null) {
          debugPrint('[Order Fetch] Fresh order columns: ${fresh.keys.toList()}');
          for (final k in allLatKeys) {
            final v = _parseDouble(fresh[k]);
            if (v != null && v != 0.0) { lat = v; break; }
          }
          for (final k in allLngKeys) {
            final v = _parseDouble(fresh[k]);
            if (v != null && v != 0.0) { lng = v; break; }
          }
          // Also grab address / phone if not yet set
          final freshAddress = fresh['delivery_address']?.toString() ??
              fresh['address']?.toString() ?? address;

          // Enhanced phone resolution: orders.customer_phone -> profiles.phone_number
          String? freshPhone = fresh['customer_phone']?.toString();
          if (freshPhone == null || freshPhone.isEmpty) {
            final profiles = fresh['profiles'];
            if (profiles is Map) {
              freshPhone = profiles['phone_number']?.toString();
            }
          }

          if (mounted) {
            setState(() {
              _destAddress = freshAddress.isNotEmpty ? freshAddress : 'Customer Location';
              _customerPhone = freshPhone ?? _customerPhone;
            });
          }
        }
      } catch (e) {
        debugPrint('[Order Fetch] Supabase re-fetch error: $e');
      }
    } else if (address.isNotEmpty) {
      if (mounted) setState(() => _destAddress = address);
    }

    // ── Step 2b: Always fetch phone number from profiles unconditionally ──
    //    Runs even when lat/lng are already present, ensuring the call button
    //    always has a valid number regardless of how this screen was opened.
    final userId = order?['user_id']?.toString();
    if ((_customerPhone == null || _customerPhone!.isEmpty) && userId != null) {
      debugPrint('[Order Fetch] Fetching phone from profiles for user $userId');
      try {
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('phone_number')
            .eq('id', userId)
            .maybeSingle();
        final fetchedPhone = profileData?['phone_number']?.toString();
        if (fetchedPhone != null && fetchedPhone.isNotEmpty) {
          if (mounted) setState(() => _customerPhone = fetchedPhone);
          debugPrint('[Order Fetch] Phone resolved from profiles: $fetchedPhone');
        }
      } catch (e) {
        debugPrint('[Order Fetch] Profile phone fetch error: $e');
      }
    }

    // ── Step 3: Geocode address → lat/lng if still missing ────────────────
    if ((lat == null || lng == null) && _destAddress.isNotEmpty && _apiKey.isNotEmpty) {
      debugPrint('[Destination ERROR] No lat/lng in DB — attempting Geocoding for: "$_destAddress"');
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(_destAddress)}&key=$_apiKey',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results.first['geometry']['location'];
            lat = (loc['lat'] as num).toDouble();
            lng = (loc['lng'] as num).toDouble();
            debugPrint('[Destination Loaded] Geocoded: $lat, $lng');

            // Cache back into DB so future fetches have it
            if (orderId != null) {
              _cacheCoordinatesInDb(orderId, lat, lng);
            }
          }
        }
      } catch (e) {
        debugPrint('[Destination ERROR] Geocoding failed: $e');
      }
    }

    // ── Step 4: Final result ──────────────────────────────────────────────
    if (lat != null && lng != null) {
      debugPrint('[Destination Loaded] lat=$lat, lng=$lng address=$_destAddress');
      if (mounted) {
        setState(() {
          _destLat = lat;
          _destLng = lng;
          _isResolvingDestination = false;
          _destinationMissing = false;
        });
      }
      // Trigger first route once destination is known & we have GPS
      if (_currentMarkerPos != null) {
        final fakePos = await Geolocator.getLastKnownPosition();
        if (fakePos != null && !_routeFetched) _fetchRoute(fakePos);
      }
    } else {
      debugPrint('[Destination ERROR] Missing lat/lng — cannot draw route');
      if (mounted) {
        setState(() {
          _isResolvingDestination = false;
          _destinationMissing = true;
        });
      }
    }
  }

  /// Cache geocoded coordinates back into the orders table so future fetches
  /// don't need to geocode again.
  Future<void> _cacheCoordinatesInDb(String orderId, double lat, double lng) async {
    try {
      // Try the most common column name — this is a best-effort write
      await Supabase.instance.client.from('orders').update({
        'delivery_lat': lat,
        'delivery_lng': lng,
      }).eq('id', orderId);
      debugPrint('[Order Fetch] Cached geocoded coords to orders.$orderId');
    } catch (e) {
      debugPrint('[Order Fetch] Cache write failed (column may not exist): $e');
    }
  }

  // ── Customer profile fetch ────────────────────────────────────────────────
  Future<void> _fetchCustomerData() async {
    try {
      final userId = widget.order?['user_id']?.toString();
      if (userId == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile != null && mounted) {
        setState(() {
          _customerName = profile['full_name'] ?? profile['username'] ?? 'Customer';
          _customerAvatarUrl = profile['avatar_url'];
          _customerRating = (profile['rating'] as num?)?.toDouble() ?? 5.0;
          _customerPhone = profile['phone_number'] ?? _customerPhone;
        });
      }
    } catch (e) {
      debugPrint('[RealTimeDelivery] customer profile fetch error: $e');
    }
  }

  // ── Start GPS stream ──────────────────────────────────────────────────────
  Future<void> _startLocationStream() async {
    // 1. Listen for service status changes (auto-recovery)
    _serviceStatusSub ??= Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled) {
        debugPrint('[Location] GPS service enabled — re-starting tracker');
        if (mounted) setState(() => _gpsDisabled = false);
        _startLocationStream();
      }
    });

    final ok = await _gpsTracker.start(
      dbThrottleSeconds: 3,
      onPosition: _onNewPosition,
    );

    if (!ok && mounted) {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _gpsDisabled = !svcEnabled;
        _locationPermissionDenied = svcEnabled; // service is on but perm denied
      });
    }
  }

  // ── Handle every new GPS position ─────────────────────────────────────────
  void _onNewPosition(Position pos) {
    if (!mounted) return;

    final newLatLng = LatLng(pos.latitude, pos.longitude);

    // --- Smooth marker animation -------------------------------------------
    final from = _currentMarkerPos ?? newLatLng;
    _prevMarkerPos = from;
    _currentMarkerPos = newLatLng;

    _markerAnimController?.reset();
    _markerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _markerAnimController!, curve: Curves.easeInOut),
    )..addListener(() {
        if (!mounted) return;
        final t = _markerAnim!.value;
        final interp = _lerpLatLng(_prevMarkerPos!, _currentMarkerPos!, t);
        _updateDriverMarker(interp, pos.heading);
      });
    _markerAnimController?.forward();

    // --- Stats ---------------------------------------------------------------
    if (_destLat != null && _destLng != null) {
      _updateStats(pos);
    }

    // --- Camera follow -------------------------------------------------------
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: newLatLng,
        zoom: 16,
        tilt: 45,
        bearing: pos.heading,
      )),
    );

    // --- Arrival check -------------------------------------------------------
    final dLatCheck = _destLat;
    final dLngCheck = _destLng;
    if (dLatCheck != null && dLngCheck != null) {
      final dist = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLatCheck, dLngCheck,
      );
      if (mounted) setState(() => _isArrived = dist < 80);
    }

    // --- Smart polyline refresh (ONLY if deviated > 100 m from route) --------
    if (_routeFetched && _routePoints.isNotEmpty) {
      final nearestDist = _distanceToPolyline(newLatLng, _routePoints);
      if (nearestDist > 100) {
        debugPrint('[Route Fetch] Driver deviated ${nearestDist.toStringAsFixed(0)} m — re-fetching route');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute &&
        _destLat != null && _destLng != null) {
      // First-time fetch
      _fetchRoute(pos);
    }
  }

  // ── LatLng linear interpolation (smooth marker movement) ─────────────────
  LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      lerpDouble(a.latitude, b.latitude, t)!,
      lerpDouble(a.longitude, b.longitude, t)!,
    );
  }

  // ── Nearest distance (meters) from point to any polyline segment ──────────
  double _distanceToPolyline(LatLng point, List<LatLng> poly) {
    if (poly.isEmpty) return double.infinity;
    double minDist = double.infinity;
    for (final pt in poly) {
      final d = Geolocator.distanceBetween(
          point.latitude, point.longitude, pt.latitude, pt.longitude);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  // ── Update driver marker on map ───────────────────────────────────────────
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

  // ── Stats (distance + ETA) ────────────────────────────────────────────────
  void _updateStats(Position pos) {
    final dLat = _destLat;
    final dLng = _destLng;
    if (dLat == null || dLng == null) return;
    final distM = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLat, dLng);
    final miles = distM / 1609.34;
    final mins = math.max(1, (miles / 18.64 * 60.0).ceil()); // 30 km/h is approx 18.64 mph
    final arrival = DateTime.now().add(Duration(minutes: mins));
    final h = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final m = arrival.minute.toString().padLeft(2, '0');
    final ampm = arrival.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _distanceMiles = miles;
        _estimatedMinutes = mins;
        _etaTime = '$h:$m $ampm';
      });
    }
  }

  // -- Fetch Google Directions API route ------------------------------------
  Future<void> _fetchRoute(Position driverPos) async {
    final dLat = _destLat;
    final dLng = _destLng;

    if (dLat == null || dLng == null) {
      debugPrint('[Route ERROR] Destination missing -- cannot fetch route');
      return;
    }
    if (_isLoadingRoute) return;

    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        // ignore: deprecated_member_use
        request: PolylineRequest(
          origin: PointLatLng(driverPos.latitude, driverPos.longitude),
          destination: PointLatLng(dLat, dLng),
          mode: TravelMode.driving,
        ),
      );

      if (!mounted) return;

      if (result.points.isNotEmpty) {
        _routePoints
          ..clear()
          ..addAll(result.points.map((p) => LatLng(p.latitude, p.longitude)));

        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(dLat, dLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _destAddress),
          zIndexInt: 1,
        ));

        debugPrint('[Polyline Drawn] ${_routePoints.length} points rendered on map');

        setState(() {
          _routeFetched = true;
          _isLoadingRoute = false;
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF4285F4),
              points: List<LatLng>.from(_routePoints),
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
        });
      } else {
        debugPrint('[Route ERROR] No points returned: ${result.errorMessage}');
        if (mounted) setState(() => _isLoadingRoute = false);
      }
    } catch (e) {
      debugPrint('[Route ERROR] Exception: $e');
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // ── Map created ───────────────────────────────────────────────────────────
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // If we already have a driver position, zoom to it; otherwise show dest
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


  // ── Call customer ─────────────────────────────────────────────────────────
  Future<void> _callCustomer() async {
    final phone = _customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer. Please check permissions.')),
        );
      }
    }
  }

  // ── Arrived button handler ────────────────────────────────────────────────
  Future<void> _onArrived() async {
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      // 1. Update status in DB to 'arrived'
      try {
        await Supabase.instance.client.from('orders').update({
          'status': 'DRIVER_ARRIVED',
          'arrived_at': now,
        }).eq('id', orderId);
      } catch (e) {
        debugPrint('[RealTimeDelivery] arrived_at update failed, falling back to status only: $e');
        await Supabase.instance.client.from('orders').update({
          'status': 'DRIVER_ARRIVED',
        }).eq('id', orderId);
      }

      // 2. Update local state
      widget.order?['status'] = 'DRIVER_ARRIVED';
      widget.order?['arrived_at'] = now;

      // 3. Notify Customer
      final userId = widget.order?['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        NotificationService.notifyUserDriverArrived(userId, orderId);
      }

      // Mark arrival state and navigate
      if (mounted) {
        setState(() => _isArrived = true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SafetyChecklistStartingScreen(order: widget.order),
          ),
        );
      }

    } catch (e) {
      debugPrint('[RealTimeDelivery] arrived update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update arrival: $e')),
        );
        // Fallback navigation for testing purposes so driver is not stuck
        setState(() => _isArrived = true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SafetyChecklistStartingScreen(order: widget.order),
          ),
        );
      }
    }
  }

  // Realtime listener moved to SafetyComplianceScreen

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── Permission / GPS error screens ─────────────────────────────────────
    if (_gpsDisabled) {
      return _errorScreen(
        'GPS is disabled',
        'Please turn on Location Services in your device settings.',
        Icons.location_disabled_rounded,
        actionLabel: 'Open GPS Settings',
        onAction: () async {
          await Geolocator.openLocationSettings();
        },
      );
    }
    if (_locationPermissionDenied) {
      return _errorScreen(
        'Location Permission Denied',
        'FuelDirect needs location access to navigate. Tap below to open Settings.',
        Icons.lock_rounded,
        actionLabel: 'Open Settings',
        onAction: () async {
          await Geolocator.openAppSettings();
        },
      );
    }

    final dLatV = _destLat;
    final dLngV = _destLng;
    final LatLng initialTarget = (dLatV != null && dLngV != null)
        ? LatLng(dLatV, dLngV)
        : _currentMarkerPos ??
            const LatLng(24.8607, 67.0011); // Karachi fallback

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              // style: null → renders the default Google Maps look (roads, POIs,
              // labels and landmarks exactly as the native Google Maps app shows them)
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

          // ── Route loading indicator ──────────────────────────────────────
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

          // ── Destination resolving banner ─────────────────────────────────
          if (_isResolvingDestination)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFFF4D00).withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text('Locating delivery address…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // ── Destination missing overlay ──────────────────────────────────
          if (_destinationMissing && !_isResolvingDestination)
            Positioned(
              bottom: 240,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded,
                        color: Color(0xFFFF4D00), size: 36),
                    const SizedBox(height: 10),
                    const Text('Delivery location not available',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 6),
                    Text(
                        _destAddress.isNotEmpty
                            ? 'Address: $_destAddress'
                            : 'No address on record for this order.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888))),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resolveDestination,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top controls ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(Icons.arrow_back_ios_new,
                          () => Navigator.of(context).pop(),
                          size: 18),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Destination card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8DD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFFF4D00), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivering to',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                _destAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom UI ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Stats row ───────────────────────────────────────────
                  Row(
                    children: [
                      _statBox('ETA', _etaTime),
                      const SizedBox(width: 10),
                      _statBox('TIME', '$_estimatedMinutes min'),
                      const SizedBox(width: 10),
                      _statBox(
                          'DIST',
                          _distanceMiles > 0
                              ? '${_distanceMiles.toStringAsFixed(1)} miles'
                              : '--'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Driver/Customer info card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(
                            _customerAvatarUrl != null && _customerAvatarUrl!.isNotEmpty
                                ? _customerAvatarUrl!
                                : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=100&auto=format',
                          ),
                          backgroundColor: const Color(0xFFEEEEEE),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_customerName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1F1F))),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFB800), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _customerRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFB800)),
                                ),
                                const SizedBox(width: 8),
                                const Text('Customer',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w500)),
                              ]),
                            ],
                          ),
                        ),
                        // Chat
                        GestureDetector(
                          onTap: () {
                            final order = widget.order;
                            final userId = order?['user_id']?.toString();
                            if (userId != null && order != null) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (c) => ChatScreen(
                                  orderId: order['id'].toString(),
                                  customerId: userId,
                                  customerName: order['customer_name']
                                          ?.toString() ??
                                      'Customer',
                                ),
                              ));
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle),
                            child: const Icon(Icons.chat_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Call
                        GestureDetector(
                          onTap: _callCustomer,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                                color: Color(0xFFFF4D00),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.phone_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Action Button / Waiting State ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                            onPressed: _onArrived,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isArrived
                                  ? Colors.green.shade600
                                  : const Color(0xFFFF4D00),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isArrived
                                      ? Icons.check_circle_rounded
                                      : Icons.location_on_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isArrived
                                      ? 'Arrived! Confirm Arrival'
                                      : 'Arrived at Customer',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ],
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

  // ── Reusable widgets ──────────────────────────────────────────────────────


  Widget _circleBtn(IconData icon, VoidCallback onTap, {double size = 20}) {
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
                color: Colors.black.withValues(alpha: 0.10), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1F1F1F), size: size),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D00),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Full-screen error widget ──────────────────────────────────────────────
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
                        color: Color(0xFFFF4D00), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
