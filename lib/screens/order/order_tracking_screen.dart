import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/location_service.dart';
import 'safety_checklist_starting_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderTrackingScreen — Pre-delivery live tracking view.
//
// Supports BOTH:
//  1. Driver Mode: Streams local hardware GPS to Supabase driver_locations
//  2. Customer Mode: Subscribes via Supabase Realtime + 3s poll to driver_locations
//     to dynamically track the driver's real-time position, bearing, and route.
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
    with WidgetsBindingObserver {
  // ── Map style (Silver / InDrive look) ─────────────────────────────────────


  // ── Map & markers ──────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  int _currentPolylineIndex = 0;

  // ── GPS stream (Driver mode) ──────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();

  // ── Remote tracking (Customer mode) ───────────────────────────────────────
  RealtimeChannel? _driverLocationChannel;
  RealtimeChannel? _orderAssignmentChannel;
  Timer? _remotePollTimer;
  LatLng? _lastRemoteDriverPos;
  DateTime? _lastDriverUpdatedAt;

  // ── Smooth animation & Navigation Arrow ───────────────────────────────────
  LatLng? _currentMarkerPos;
  double _currentBearing = 0.0;
  Position? _lastGpsFix;
  BitmapDescriptor? _driverArrowIcon;
  bool _isCameraFollowing = true;
  StreamSubscription<CompassEvent>? _compassSub;
  int _lastCompassMs = 0;
  double _lastCompassHeading = -999;

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
    WidgetsBinding.instance.addObserver(this);
    _polylinePoints = PolylinePoints(apiKey: _apiKey);


    // Load navigation-style vehicle arrow icon
    NavigationMarkerHelper.getDriverArrowIcon().then((icon) {
      if (mounted) {
        setState(() {
          _driverArrowIcon = icon;
          if (_currentMarkerPos != null) {
            _updateDriverMarker(_currentMarkerPos!, _currentBearing);
          }
        });
      }
    });

    _initTrackingMode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final driverId = widget.order?['driver_id']?.toString();
      final isDriver = currentUserId != null && driverId != null && currentUserId == driverId;
      if (isDriver && !_gpsTracker.isActive) {
        debugPrint('[OrderTracking] App resumed -> restarting GPS stream');
        _gpsTracker.restart(
          dbThrottleSeconds: 3,
          onPosition: _onNewPosition,
        );
      }
    }
  }

  void _initTrackingMode() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final driverId = widget.order?['driver_id']?.toString();
    final isDriver = currentUserId != null && driverId != null && currentUserId == driverId;

    if (isDriver) {
      debugPrint('[OrderTracking] Current user IS driver -> starting local hardware GPS stream');
      // Fast driver location retrieval
      Geolocator.getLastKnownPosition().then((pos) {
        if (pos != null && mounted && _currentMarkerPos == null) {
          setState(() {
            final latLng = LatLng(pos.latitude, pos.longitude);
            _currentMarkerPos = latLng;
            _currentBearing = pos.heading >= 0.0 ? pos.heading : 0.0;
            _updateDriverMarker(latLng, _currentBearing);
          });
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
          }
        }
      });
      _startLocationStream();
      _initCompass();
    } else {
      debugPrint('[OrderTracking] Current user IS CUSTOMER -> tracking driver: $driverId');
      _initRemoteDriverTracking(driverId);
    }
  }

  void _initRemoteDriverTracking(String? driverId) {
    _driverLocationChannel?.unsubscribe();
    _remotePollTimer?.cancel();

    if (driverId == null || driverId.isEmpty) {
      debugPrint('[OrderTracking] No driverId assigned yet -> waiting for driver assignment');
      if (mounted) {
        setState(() {
          _arrivalTime = 'Assigning driver...';
        });
      }
      _subscribeToOrderAssignment();
      return;
    }

    // 1. Immediate initial location fetch from Supabase
    _fetchRemoteDriverLocation(driverId);

    // 2. Realtime WebSocket subscription to driver_locations table
    _driverLocationChannel = Supabase.instance.client
        .channel('public_driver_loc_$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record['latitude'] != null && record['longitude'] != null) {
              final lat = (record['latitude'] as num).toDouble();
              final lng = (record['longitude'] as num).toDouble();
              final heading = (record['heading'] as num?)?.toDouble() ?? 0.0;
              final updatedAt = record['updated_at']?.toString();
              _onDriverLocationUpdateFromRemote(lat, lng, heading, updatedAt);
            }
          },

        )
        .subscribe();

    // 3. Fallback polling timer (every 3 seconds) for 100% update reliability
    _remotePollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchRemoteDriverLocation(driverId);
    });
  }

  void _subscribeToOrderAssignment() {
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;
    _orderAssignmentChannel?.unsubscribe();
    _orderAssignmentChannel = Supabase.instance.client
        .channel('order_assign_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            final assignedId = payload.newRecord['driver_id']?.toString();
            if (assignedId != null && assignedId.isNotEmpty) {
              widget.order?['driver_id'] = assignedId;
              _initRemoteDriverTracking(assignedId);
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchRemoteDriverLocation(String driverId) async {
    try {
      final loc = await Supabase.instance.client
          .from('driver_locations')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      double? lat;
      double? lng;
      double heading = 0.0;

      String? updatedAt;
      if (loc != null && loc['latitude'] != null && loc['longitude'] != null) {
        lat = (loc['latitude'] as num).toDouble();
        lng = (loc['longitude'] as num).toDouble();
        heading = (loc['heading'] as num?)?.toDouble() ?? 0.0;
        updatedAt = loc['updated_at']?.toString();
      } else {
        final d = await Supabase.instance.client
            .from('drivers')
            .select()
            .eq('id', driverId)
            .maybeSingle();
        if (d != null && d['current_lat'] != null && d['current_lng'] != null) {
          lat = (d['current_lat'] as num).toDouble();
          lng = (d['current_lng'] as num).toDouble();
          updatedAt = d['last_updated_at']?.toString();
        }
      }

      if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
        _onDriverLocationUpdateFromRemote(lat, lng, heading, updatedAt);
      }
    } catch (e) {
      debugPrint('[RemoteDriverLoc Fetch ERROR] $e');
    }
  }

  void _onDriverLocationUpdateFromRemote(
    double lat,
    double lng,
    double heading,
    String? updatedAtIso,
  ) {
    if (!mounted) return;

    if (updatedAtIso != null && updatedAtIso.isNotEmpty) {
      final incomingTime = DateTime.tryParse(updatedAtIso);
      if (incomingTime != null) {
        if (_lastDriverUpdatedAt != null &&
            incomingTime.isBefore(_lastDriverUpdatedAt!)) {
          debugPrint(
            '[REALTIME DISCARDED] Out-of-order payload: timestamp=$updatedAtIso is older than current $_lastDriverUpdatedAt',
          );
          return;
        }
        _lastDriverUpdatedAt = incomingTime;
      }
    }

    debugPrint(
      'REALTIME: '
      'latitude=${lat.toStringAsFixed(6)} '
      'longitude=${lng.toStringAsFixed(6)} '
      'updated_at=${updatedAtIso ?? "none"}',
    );

    final newLatLng = LatLng(lat, lng);

    double targetBearing = heading;
    final lastLatLng = _lastRemoteDriverPos;
    if (lastLatLng != null) {
      final distMoved = Geolocator.distanceBetween(
        lastLatLng.latitude, lastLatLng.longitude, lat, lng,
      );
      if (distMoved >= 1.0) {
        targetBearing = LocationService.calculateBearing(
          lastLatLng.latitude, lastLatLng.longitude, lat, lng,
        );
      }
    }
    _lastRemoteDriverPos = newLatLng;

    _currentMarkerPos = newLatLng;
    _currentBearing = targetBearing;
    _updateDriverMarker(newLatLng, targetBearing);
    if (_isCameraFollowing && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLatLng,
            zoom: 16.5,
            tilt: 45,
            bearing: targetBearing,
          ),
        ),
      );
    }
    if (_routeFetched && _routePoints.isNotEmpty) {
      _updatePolylineTrimmed(newLatLng);
    }

    if (!_routeFetched && !_isLoadingRoute && widget.deliveryLat != null && widget.deliveryLng != null) {
      final mockPos = Position(
        longitude: lng,
        latitude: lat,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: heading,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _fetchRoute(mockPos);
    } else if (widget.deliveryLat != null && widget.deliveryLng != null) {
      _calculateDistanceAndTimeFromCoords(lat, lng);
    }
  }

  void _calculateDistanceAndTimeFromCoords(double driverLat, double driverLng) {
    if (widget.deliveryLat == null || widget.deliveryLng == null) return;
    final distM = Geolocator.distanceBetween(
      driverLat, driverLng, widget.deliveryLat!, widget.deliveryLng!,
    );
    final miles = distM / 1609.34;
    final mins = math.max(1, (miles / 18.64 * 60.0).ceil());
    final arrival = DateTime.now().add(Duration(minutes: mins));
    final formatted = DateFormat('h:mm a').format(arrival);
    if (mounted) {
      setState(() {
        _estimatedMinutes = mins;
        _arrivalTime = formatted;
      });
    }
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading == null || heading.isNaN) return;

      // Normalize heading to standard [0, 360)
      final normalizedHeading = (heading % 360.0 + 360.0) % 360.0;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastCompassMs < 50) return; // ~20 fps for responsive rotation
      _lastCompassMs = nowMs;

      if (_lastCompassHeading < 0) {
        _lastCompassHeading = normalizedHeading;
      }

      // Angular difference (shortest path)
      double diff = (normalizedHeading - _lastCompassHeading) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;

      // Ignore micro noise (< 0.8 degrees)
      if (diff.abs() < 0.8) return;

      // Smooth EMA filter (alpha = 0.25) so phone rotation smoothly turns the beam
      final smoothedHeading = (_lastCompassHeading + diff * 0.25 + 360.0) % 360.0;
      _lastCompassHeading = smoothedHeading;

      // When standing still or moving slowly (< 1.8 m/s), rotating phone rotates the blue beam in real time!
      final speed = _lastGpsFix?.speed ?? 0.0;
      if (speed < 1.8) {
        _currentBearing = smoothedHeading;
        final pos = _currentMarkerPos;
        if (pos != null) {
          _updateDriverMarker(pos, smoothedHeading);
        }
      }
    });
  }



  void _recenterCamera() {
    setState(() => _isCameraFollowing = true);
    final pos = _currentMarkerPos;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos,
            zoom: 16.5,
            tilt: 45,
            bearing: _currentBearing,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsTracker.dispose();
    _compassSub?.cancel();
    _driverLocationChannel?.unsubscribe();
    _orderAssignmentChannel?.unsubscribe();
    _remotePollTimer?.cancel();
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

  void _onNewPosition(Position pos) {
    if (!mounted) return;
    // Reject invalid / zero coordinates
    if (pos.latitude == 0.0 && pos.longitude == 0.0) return;

    // Reject low accuracy fixes (> 30m)
    if (pos.accuracy > 30.0 && _currentMarkerPos != null) {
      debugPrint('[GPS Filter OT] Low accuracy fix (${pos.accuracy.toStringAsFixed(1)}m) — ignoring');
      return;
    }

    final newLatLng = LatLng(pos.latitude, pos.longitude);
    final currentPos = _currentMarkerPos ?? newLatLng;
    final rawSpeed = pos.speed >= 0.0 ? pos.speed : 0.0;

    final distanceMoved = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      newLatLng.latitude,
      newLatLng.longitude,
    );

    // Driver Movement Detection:
    // Move marker if distance >= 1.2m (walking / driving) OR speed >= 0.3 m/s (~1.0 km/h)
    final isDriverMoving = (distanceMoved >= 1.2) || (rawSpeed >= 0.3);
    final targetPos = isDriverMoving ? newLatLng : currentPos;

    // 1. Calculate or extract accurate bearing
    double targetBearing = _currentBearing;
    if (isDriverMoving) {
      if (rawSpeed >= 0.5 && pos.heading >= 0.0 && pos.heading <= 360.0) {
        targetBearing = pos.heading;
      } else if (distanceMoved >= 1.0) {
        targetBearing = LocationService.calculateBearing(
          currentPos.latitude,
          currentPos.longitude,
          newLatLng.latitude,
          newLatLng.longitude,
        );
      }
    }

    _lastGpsFix = pos;
    _currentMarkerPos = targetPos;
    _currentBearing = targetBearing;

    debugPrint('[LiveTracking OT] Fix: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)} | acc: ${pos.accuracy.toStringAsFixed(1)}m | spd: ${pos.speed.toStringAsFixed(1)}m/s | bearing: ${targetBearing.toStringAsFixed(1)}°');

    // 2. Real-time driver marker update
    _updateDriverMarker(targetPos, targetBearing);

    // 3. Smooth hardware-accelerated camera follow (Google Maps style)
    if (_isCameraFollowing && _mapController != null && isDriverMoving) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetPos,
            zoom: 17.0,
            tilt: 45,
            bearing: targetBearing,
          ),
        ),
      );
    }

    // 4. Dynamic polyline trimming behind driver
    if (_routeFetched && _routePoints.isNotEmpty) {
      _updatePolylineTrimmed(newLatLng);
    }

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

    // Smart polyline: fetch once, re-fetch only if deviated > 70 m
    if (_routeFetched && _routePoints.isNotEmpty) {
      final dev = _distanceToPolyline(newLatLng, _routePoints);
      if (dev > 70) {
        debugPrint('[Route Fetch] OrderTracking: deviation ${dev.toStringAsFixed(0)} m — re-fetching');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute &&
        widget.deliveryLat != null && widget.deliveryLng != null) {
      _fetchRoute(pos);
    }
  }

  /// Trims route polyline behind driver so polyline erases as driver moves forward (Google Maps style)
  void _updatePolylineTrimmed(LatLng driverPos) {
    if (!mounted || _routePoints.isEmpty) return;

    final closestIdx = LocationService.findClosestPolylineIndex(
      driverPos,
      _routePoints,
      _currentPolylineIndex,
    );

    if (closestIdx > _currentPolylineIndex) {
      _currentPolylineIndex = closestIdx;
    }

    final List<LatLng> activePoints = [driverPos];
    if (_currentPolylineIndex + 1 < _routePoints.length) {
      activePoints.addAll(_routePoints.sublist(_currentPolylineIndex + 1));
    } else if (_routePoints.isNotEmpty) {
      activePoints.add(_routePoints.last);
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF4285F4),
          points: activePoints,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    });
  }



  double _distanceToPolyline(LatLng point, List<LatLng> poly) {
    if (poly.isEmpty) return double.infinity;
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

    final updated = Set<Marker>.of(_markers.where((m) => m.markerId.value != 'driver'));
    updated.add(Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      icon: _driverArrowIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      anchor: const Offset(0.5, 0.58),
      rotation: heading,
      flat: true,
      zIndexInt: 2,
      infoWindow: const InfoWindow(title: 'Your Location'),
    ));

    setState(() {
      _markers = updated;
    });
  }

  void _ensureDestinationMarker() {
    final hasDestMarker =
        _markers.any((m) => m.markerId.value == 'delivery');
    if (!hasDestMarker &&
        widget.deliveryLat != null &&
        widget.deliveryLng != null) {
      if (mounted) {
        final updated = Set<Marker>.of(_markers.where((m) => m.markerId.value != 'delivery'));
        updated.add(Marker(
          markerId: const MarkerId('delivery'),
          position:
              LatLng(widget.deliveryLat!, widget.deliveryLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
              title: widget.deliveryAddress ?? 'Delivery Point'),
          zIndexInt: 1,
        ));
        setState(() {
          _markers = updated;
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
    final miles = distM / 1609.34;
    final mins = math.max(1, (miles / 18.64 * 60.0).ceil());
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
        _currentPolylineIndex = 0;

        debugPrint('[Polyline Drawn] OrderTracking: ${_routePoints.length} points');

        setState(() {
          _routeFetched = true;
          _isLoadingRoute = false;
        });

        final dPos = _currentMarkerPos ?? LatLng(driverPos.latitude, driverPos.longitude);
        _updatePolylineTrimmed(dPos);
      } else {

        debugPrint('[Route Fetch] OrderTracking: No points returned — Error: ${result.errorMessage ?? "no details"}');
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
            : const LatLng(37.7749, -122.4194));

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                if (_isCameraFollowing) {
                  setState(() => _isCameraFollowing = false);
                }
              },
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: initialPos,
                  zoom: 16,
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

          // ── Recenter Button (shows when user manually panned map) ─────────
          if (!_isCameraFollowing)
            Positioned(
              right: 20,
              bottom: 270,
              child: FloatingActionButton.extended(
                heroTag: 'recenter_order_tracking',
                onPressed: _recenterCamera,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF4D00),
                elevation: 4,
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text(
                  'Re-center',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFFF4D00),
                  ),
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
                child: Text(AppLocalizations.of(context)!.orderTrackingGoBack,
                    style: const TextStyle(
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
