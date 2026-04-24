import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../services/location_service.dart';
import 'safety_checklist_starting_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderTrackingScreen — Pre-delivery live tracking view.
//
// Migration from timer-based polling to proper GPS stream.
// Applies same smart-polyline-refresh (deviate > 100 m) architecture.
// ─────────────────────────────────────────────────────────────────────────────
class OrderTrackingScreen extends StatefulWidget {
  final double? deliveryLat;
  final double? deliveryLng;
  final String? deliveryAddress;
  final String? fuelInfo;
  final Map<String, dynamic>? order;

  const OrderTrackingScreen({
    super.key,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryAddress,
    this.fuelInfo,
    this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  // ── Map style (Silver / InDrive look) ─────────────────────────────────────


  // ── Map & markers ──────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();

  // ── Smooth animation ──────────────────────────────────────────────────────
  AnimationController? _markerAnimController;
  Animation<double>? _markerAnim;
  LatLng? _prevMarkerPos;
  LatLng? _currentMarkerPos;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;

  // ── Stats ──────────────────────────────────────────────────────────────────
  String _arrivalTime = 'Calculating...';
  int _estimatedMinutes = 0;

  final String _apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
  late final PolylinePoints _polylinePoints;

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints(apiKey: _apiKey);

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startLocationStream();
  }

  @override
  void dispose() {
    _gpsTracker.dispose();
    _markerAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Start GPS stream (replaces old timer + getCurrentPosition) ────────────
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
        _arrivalTime = svcEnabled ? 'Permission denied' : 'Location disabled';
      });
    }
  }

  // ── Handle new GPS fix ────────────────────────────────────────────────────
  void _onNewPosition(Position pos) {
    if (!mounted) return;

    final newLatLng = LatLng(pos.latitude, pos.longitude);

    // Smooth marker animation
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

    // Stats / destination marker
    if (widget.deliveryLat != null && widget.deliveryLng != null) {
      _calculateDistanceAndTime(pos);
      _ensureDestinationMarker();
    } else {
      if (mounted) {
        setState(() {
          _estimatedMinutes = 0;
          _arrivalTime = 'No destination set';
        });
      }
    }

    // Camera follow
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: newLatLng,
        zoom: 16,
        tilt: 45,
        bearing: pos.heading,
      )),
    );

    // Smart polyline: fetch once, re-fetch only if deviated > 100 m
    if (_routeFetched && _routePoints.isNotEmpty) {
      final dev = _distanceToPolyline(newLatLng, _routePoints);
      if (dev > 100) {
        debugPrint('[Route Fetch] OrderTracking: deviation ${dev.toStringAsFixed(0)} m — re-fetching');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute &&
        widget.deliveryLat != null && widget.deliveryLng != null) {
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

  void _ensureDestinationMarker() {
    final hasDestMarker =
        _markers.any((m) => m.markerId.value == 'delivery');
    if (!hasDestMarker &&
        widget.deliveryLat != null &&
        widget.deliveryLng != null) {
      if (mounted) {
        setState(() {
          _markers.add(Marker(
            markerId: const MarkerId('delivery'),
            position:
                LatLng(widget.deliveryLat!, widget.deliveryLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
                title: widget.deliveryAddress ?? 'Delivery Point'),
            zIndexInt: 1,
          ));
        });
      }
    }
  }

  void _calculateDistanceAndTime(Position driverPos) {
    final distM = Geolocator.distanceBetween(
      driverPos.latitude,
      driverPos.longitude,
      widget.deliveryLat!,
      widget.deliveryLng!,
    );
    final km = distM / 1000.0;
    final mins = math.max(1, (km / 30.0 * 60.0).ceil());
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: mins));
    final formatted = DateFormat('h:mm a').format(arrival);
    if (mounted) {
      setState(() {
        _estimatedMinutes = mins;
        _arrivalTime = formatted;
      });
    }
  }

  Future<void> _fetchRoute(Position driverPos) async {
    if (widget.deliveryLat == null || widget.deliveryLng == null) return;
    if (_isLoadingRoute) return;
    if (mounted) setState(() => _isLoadingRoute = true);

    debugPrint('[Route Fetch] OrderTracking: '
        '${driverPos.latitude.toStringAsFixed(5)},${driverPos.longitude.toStringAsFixed(5)}'
        ' → ${widget.deliveryLat},${widget.deliveryLng}');

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        // ignore: deprecated_member_use
        request: PolylineRequest(
          origin: PointLatLng(driverPos.latitude, driverPos.longitude),
          destination:
              PointLatLng(widget.deliveryLat!, widget.deliveryLng!),
          mode: TravelMode.driving,
        ),
      );

      if (!mounted) return;

      if (result.points.isNotEmpty) {
        _routePoints
          ..clear()
          ..addAll(
              result.points.map((p) => LatLng(p.latitude, p.longitude)));

        debugPrint('[Polyline Drawn] OrderTracking: ${_routePoints.length} points');

        setState(() {
          _routeFetched = true;
          _isLoadingRoute = false;
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF4285F4),
              points: _routePoints,
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
        });
      } else {
        debugPrint('[Route Fetch] OrderTracking: No points returned');
        if (mounted) setState(() => _isLoadingRoute = false);
      }
    } catch (e) {
      debugPrint('[Route Fetch] OrderTracking ERROR: $e');
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentMarkerPos != null &&
        widget.deliveryLat != null &&
        widget.deliveryLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentMarkerPos!.latitude, widget.deliveryLat!),
          math.min(_currentMarkerPos!.longitude, widget.deliveryLng!),
        ),
        northeast: LatLng(
          math.max(_currentMarkerPos!.latitude, widget.deliveryLat!),
          math.max(_currentMarkerPos!.longitude, widget.deliveryLng!),
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gpsDisabled) {
      return _errorScreen(
          'GPS Disabled', 'Please enable location services.', Icons.location_disabled_rounded);
    }
    if (_locationPermissionDenied) {
      return _errorScreen(
        'Location Permission Denied',
        'Please allow location access in Settings.',
        Icons.lock_rounded,
        actionLabel: 'Open Settings',
        onAction: () async => Geolocator.openAppSettings(),
      );
    }

    final initialPos = _currentMarkerPos ??
        (widget.deliveryLat != null && widget.deliveryLng != null
            ? LatLng(widget.deliveryLat!, widget.deliveryLng!)
            : const LatLng(24.8607, 67.0011));

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 14,
              ),
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              markers: Set<Marker>.of(_markers),
              polylines: Set<Polyline>.of(_polylines),
            ),
          ),

          // Route loading bar
          if (_isLoadingRoute)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: Color(0xFFFF6600),
                backgroundColor: Colors.transparent,
              ),
            ),

          // Back button
          Positioned(
            top: 60,
            left: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Bottom tracking card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Arrival:',
                        style: TextStyle(
                            color: Color(0xFF666666), fontSize: 14),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6600),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE TRACKING',
                            style: TextStyle(
                              color: Color(0xFFFF6600),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$_estimatedMinutes',
                            style: const TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'MIN',
                            style: TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Arriving at $_arrivalTime',
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.fuelInfo ?? '95 Octane • 12 Gallons',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 14),
                  ),
                  if (widget.deliveryAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.deliveryAddress!,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),


                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SafetyChecklistStartingScreen(
                                          order: widget.order),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 22),
                            label: const Text(
                              'Arrived',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6600),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F3F3),
                            foregroundColor: const Color(0xFF333333),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.home_outlined, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
              Icon(icon, size: 72, color: const Color(0xFFFF6600)),
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
                      backgroundColor: const Color(0xFFFF6600),
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
                        color: Color(0xFFFF6600),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
