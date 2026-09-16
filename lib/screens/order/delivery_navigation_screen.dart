import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'fuel_pickup_screen.dart';

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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  int _currentPolylineIndex = 0;

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();

  // ── 60 FPS Smooth marker lerp & Turn-by-Turn camera animation ─────────────
  late AnimationController _markerAnimController;
  LatLng? _animStartPos;
  LatLng? _animTargetPos;
  double _animStartBearing = 0.0;
  double _animTargetBearing = 0.0;
  LatLng? _currentAnimatedPos;
  double _currentAnimatedBearing = 0.0;
  int _lastFixTimeMs = 0;

  // ── Navigation Arrow & Compass ────────────────────────────────────────────
  LatLng? _currentMarkerPos;
  double _currentBearing = 0.0;
  Position? _lastGpsFix;
  BitmapDescriptor? _driverArrowIcon;
  bool _isCameraFollowing = true;
  StreamSubscription<CompassEvent>? _compassSub;
  int _lastCompassMs = 0;
  double _lastCompassHeading = -999;
  int _gpsFixCount = 0;
  double _currentAccuracy = 0.0;

  // ── State ───────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;
  bool _isReleasing = false; // guard for Release Order button

  // ── Order status realtime subscription ─────────────────────────────────
  RealtimeChannel? _orderStatusChannel;

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

  bool _isResolvingDestination = false;

  @override
  void initState() {
    super.initState();

    // 60 FPS marker lerp controller
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _markerAnimController.addListener(_onMarkerAnimTick);

    _destinationLabel = widget.order?['delivery_address']?.toString() ?? 'Customer Location';

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

    // Fast driver location from cache — centers map on driver immediately
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null && mounted && _currentMarkerPos == null) {
        setState(() {
          final latLng = LatLng(pos.latitude, pos.longitude);
          _currentMarkerPos = latLng;
          _currentBearing = pos.heading >= 0.0 ? pos.heading : 0.0;
          _updateDriverMarker(latLng, _currentBearing);
        });
        if (_mapController != null) {
          if (_destLat != null && _destLng != null) {
            final bounds = LatLngBounds(
              southwest: LatLng(
                math.min(pos.latitude, _destLat!),
                math.min(pos.longitude, _destLng!),
              ),
              northeast: LatLng(
                math.max(pos.latitude, _destLat!),
                math.max(pos.longitude, _destLng!),
              ),
            );
            _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
          } else {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
          }
        }
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _resolveDestination();
    _startLocationStream();
    _initCompass();
    _subscribeToOrderStatus(); // listen for cancellation
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[DeliveryNavigation] App resumed -> checking GPS stream status');
      if (!_gpsTracker.isActive) {
        _gpsTracker.restart(
          dbThrottleSeconds: 2,
          onPosition: _onNewPosition,
        );
      }
    }
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (!mounted) return;
      final heading = event.heading ?? event.headingForCameraMode;
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
        _currentAnimatedBearing = smoothedHeading;
        _animStartBearing = smoothedHeading;
        _animTargetBearing = smoothedHeading;

        final pos = _currentAnimatedPos ?? _currentMarkerPos;
        if (pos != null) {
          _updateDriverMarker(pos, smoothedHeading);
          if (_isCameraFollowing && _mapController != null) {
            _mapController?.moveCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: pos,
                  zoom: 17.5,
                  tilt: 35.0,
                  bearing: smoothedHeading,
                ),
              ),
            );
          }
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

  Future<void> _resolveDestination() async {
    if (_isResolvingDestination) return;
    if (mounted) setState(() => _isResolvingDestination = true);

    final order = widget.order;
    double? lat = _parseDouble(order?['customer_lat']) ??
        _parseDouble(order?['delivery_lat']) ??
        _parseDouble(order?['latitude']) ??
        _parseDouble(order?['delivery_latitude']) ??
        _parseDouble(order?['lat']);
    double? lng = _parseDouble(order?['customer_lng']) ??
        _parseDouble(order?['delivery_lng']) ??
        _parseDouble(order?['longitude']) ??
        _parseDouble(order?['delivery_longitude']) ??
        _parseDouble(order?['lng']);
        
    if (lat == 0.0 && lng == 0.0) {
      lat = null;
      lng = null;
    }

    if ((lat == null || lng == null) && _destinationLabel.isNotEmpty && _apiKey.isNotEmpty) {
      debugPrint('[DeliveryNav] No lat/lng in DB — attempting Geocoding for: "$_destinationLabel"');
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(_destinationLabel)}&key=$_apiKey',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results.first['geometry']['location'];
            lat = (loc['lat'] as num).toDouble();
            lng = (loc['lng'] as num).toDouble();
            debugPrint('[DeliveryNav] Geocoded: $lat, $lng');
          }
        }
      } catch (e) {
        debugPrint('[DeliveryNav] Geocoding failed: $e');
      }
    }

    if (lat != null && lng != null) {
      if (mounted) {
        setState(() {
          _destLat = lat;
          _destLng = lng;
          _isResolvingDestination = false;
          // Propagate resolved coords to order map so child screens have them
          widget.order?['delivery_lat'] = lat;
          widget.order?['delivery_lng'] = lng;
        });
      }
      // Animate camera to fit driver + destination if map is ready
      if (_mapController != null) {
        if (_currentMarkerPos != null) {
          final bounds = LatLngBounds(
            southwest: LatLng(
              math.min(_currentMarkerPos!.latitude, lat),
              math.min(_currentMarkerPos!.longitude, lng),
            ),
            northeast: LatLng(
              math.max(_currentMarkerPos!.latitude, lat),
              math.max(_currentMarkerPos!.longitude, lng),
            ),
          );
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
        } else {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14));
        }
      }
      _fetchRouteEarly();
    } else {
      if (mounted) {
        setState(() => _isResolvingDestination = false);
      }
    }
  }

  /// Fetch route using an already-available position — NO getCurrentPosition().
  void _fetchRouteEarly() {
    if (_routeFetched || _isLoadingRoute) return;
    if (_destLat == null || _destLng == null) return;

    final gpsFix = _lastGpsFix;
    if (gpsFix != null) {
      debugPrint('[DeliveryNav] Fetching route from stream GPS fix');
      _fetchRoute(gpsFix);
    } else {
      // Fall back to getLastKnownPosition (safe — does NOT interfere with stream)
      Geolocator.getLastKnownPosition().then((pos) {
        if (pos != null && mounted && !_routeFetched) {
          final latLng = LatLng(pos.latitude, pos.longitude);
          _currentMarkerPos ??= latLng;
          _updateDriverMarker(latLng, pos.heading >= 0.0 ? pos.heading : 0.0);
          debugPrint('[DeliveryNav] Fetching route from last known position');
          _fetchRoute(pos);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markerAnimController.stop();
    _markerAnimController.dispose();
    _gpsTracker.dispose();
    _compassSub?.cancel();
    _mapController?.dispose();
    _orderStatusChannel?.unsubscribe();
    super.dispose();
  }

  // ── Subscribe to order status (cancellation detection) ────────────────────
  void _subscribeToOrderStatus() {
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;

    try {
      _orderStatusChannel?.unsubscribe();
      _orderStatusChannel = Supabase.instance.client
          .channel('dnav_order_status_$orderId')
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
              final newStatus = payload.newRecord['status']?.toString().toLowerCase() ?? '';
              debugPrint('[DeliveryNav] Order status update: $newStatus');
              if (!mounted) return;

              if (newStatus == 'cancelled') {
                _gpsTracker.dispose();
                _orderStatusChannel?.unsubscribe();
                _showCancellationDialog();
              }
            },
          )
          .subscribe((status, error) {
            debugPrint('[DeliveryNav] Order channel: $status');
          });
    } catch (e) {
      debugPrint('[DeliveryNav] Realtime subscribe error: $e');
    }
  }

  void _showCancellationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Order Cancelled', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'This order has been cancelled by the customer. You will be returned to the orders list.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil(
                (route) => route.settings.name == '/assigned-orders' || route.isFirst,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  // ── Start GPS stream ──────────────────────────────────────────────────────
  Future<void> _startLocationStream() async {
    // Seed immediate initial position fix so GPS badge turns green instantly
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null && mounted && _gpsFixCount == 0) {
        _onNewPosition(pos);
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
        _locationPermissionDenied = svcEnabled;
      });
    }
  }

  // ── 60 FPS Animation Ticker ────────────────────────────────────────────────
  // Fires on every frame tick (~60 times per second) to update vehicle marker,
  // dynamically melt/trim the polyline behind the bumper, and smoothly track camera.
  void _onMarkerAnimTick() {
    if (!mounted) return;
    final startPos = _animStartPos;
    final targetPos = _animTargetPos;
    if (startPos == null || targetPos == null) return;

    final t = _markerAnimController.value;

    // 1. Fluid position lerp
    final currentPos = LocationService.interpolateLatLng(startPos, targetPos, t);

    // 2. Shortest-path rotational bearing lerp
    final currentBearing = LocationService.interpolateAngle(
      _animStartBearing,
      _animTargetBearing,
      t,
    );

    _currentAnimatedPos = currentPos;
    _currentAnimatedBearing = currentBearing;

    // 3. 60 FPS Vehicle marker update
    _updateDriverMarker(currentPos, currentBearing);

    // 4. Dynamic Polyline Rolling & Trimming (Uber / Careem / Foodpanda style)
    if (_routeFetched && _routePoints.isNotEmpty) {
      _updatePolylineTrimmed(currentPos);
    }

    // 5. Turn-by-Turn 60 FPS Camera Follow
    if (_isCameraFollowing && _mapController != null) {
      _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPos,
            zoom: 17.5,
            tilt: 35.0,
            bearing: currentBearing,
          ),
        ),
      );
    }
  }

  void _onNewPosition(Position pos) {
    if (!mounted) return;
    if (pos.latitude == 0.0 && pos.longitude == 0.0) return;

    // Filter out grossly inaccurate GPS fixes (> 30m)
    if (pos.accuracy > 30.0 && _currentMarkerPos != null) {
      debugPrint('[GPS Filter] Low accuracy fix (${pos.accuracy.toStringAsFixed(1)}m) — ignoring');
      return;
    }

    final newLatLng = LatLng(pos.latitude, pos.longitude);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    int animDurationMs = 1000;
    if (_lastFixTimeMs > 0) {
      animDurationMs = (nowMs - _lastFixTimeMs).clamp(500, 2000);
    }
    _lastFixTimeMs = nowMs;

    final currentPos = _currentAnimatedPos ?? _currentMarkerPos ?? newLatLng;
    final currentBearing = _currentAnimatedBearing != 0.0 ? _currentAnimatedBearing : _currentBearing;

    final distanceMoved = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      newLatLng.latitude,
      newLatLng.longitude,
    );

    final rawSpeed = pos.speed >= 0.0 ? pos.speed : 0.0;

    // Driver Movement Detection:
    // Move marker if distance >= 1.2m (walking / driving) OR speed >= 0.3 m/s (~1.0 km/h)
    final isDriverMoving = (distanceMoved >= 1.2) || (rawSpeed >= 0.3);
    final targetPos = isDriverMoving ? newLatLng : currentPos;

    // Heading calculation & shortest rotation path
    double targetBearing = currentBearing;
    if (isDriverMoving) {
      if (pos.heading >= 0.0 && pos.heading <= 360.0 && rawSpeed >= 0.5) {
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

    _animStartPos = currentPos;
    _animTargetPos = targetPos;
    _animStartBearing = currentBearing;
    _animTargetBearing = targetBearing;

    _markerAnimController.duration = Duration(milliseconds: animDurationMs);
    _markerAnimController.forward(from: 0.0);

    setState(() {
      _lastGpsFix = pos;
      _currentMarkerPos = targetPos;
      _currentBearing = targetBearing;
      _gpsFixCount++;
      _currentAccuracy = pos.accuracy;
    });

    // Stats
    if (_destLat != null && _destLng != null) _updateStats(pos);

    // Smart polyline refresh (if driver deviates > 70 m off route)
    if (_routeFetched && _routePoints.isNotEmpty) {
      final dev = _distanceToPolyline(newLatLng, _routePoints);
      if (dev > 70) {
        debugPrint('[Route Fetch] Deviation ${dev.toStringAsFixed(0)} m — re-fetching route');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute && _destLat != null && _destLng != null) {
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
      flat: false,
      zIndexInt: 2,
      infoWindow: const InfoWindow(title: 'Your Location'),
    ));

    setState(() {
      _markers = updated;
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
        debugPrint('[Route API Response] HTTP error ${response.statusCode} — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';
      debugPrint('[Route API Response] status=$status');

      if (status != 'OK') {
        debugPrint('[Route ERROR] API status=$status — ${data['error_message'] ?? 'no details'} — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route ERROR] No routes returned — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
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
        debugPrint('[Polyline ERROR] Empty polyline string — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);
      debugPrint('[Polyline Points] count = ${decodedPoints.length}');

      if (decodedPoints.length < 2) {
        debugPrint('[Polyline ERROR] Too few points: ${decodedPoints.length} — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      _routePoints
        ..clear()
        ..addAll(decodedPoints);
      _currentPolylineIndex = 0;

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
      });

      final dPos = _currentMarkerPos ?? LatLng(driverPos.latitude, driverPos.longitude);
      _updatePolylineTrimmed(dPos);


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
      debugPrint('[Route ERROR] Exception: $e — trying OSRM fallback');
      if (mounted) {
        await _fetchRouteOSRM(driverPos, dLat, dLng);
      }
    }
  }

  Future<void> _fetchRouteOSRM(Position driverPos, double dLat, double dLng) async {
    try {
      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving'
        '/${driverPos.longitude},${driverPos.latitude};$dLng,$dLat'
        '?overview=full&geometries=polyline',
      );
      debugPrint('[Route OSRM Fallback] Fetching OSRM: $osrmUri');
      final response = await http.get(osrmUri).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode != 200) {
        debugPrint('[Route OSRM Fallback] HTTP error ${response.statusCode}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route OSRM Fallback] No routes returned');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final route = routes[0] as Map<String, dynamic>;
      final encodedPolyline = (route['geometry'] as String?) ?? '';
      if (encodedPolyline.isEmpty) {
        debugPrint('[Route OSRM Fallback] Empty polyline string');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);
      debugPrint('[Route OSRM Fallback] Polyline Points count = ${decodedPoints.length}');

      if (decodedPoints.length < 2) {
        debugPrint('[Route OSRM Fallback] Too few points: ${decodedPoints.length}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final double apiDistanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final int apiDurationSecs = (route['duration'] as num?)?.toInt() ?? 0;

      debugPrint('[Route OSRM Fallback Stats] duration=${apiDurationSecs}s distance=${apiDistanceMeters}m');

      _routePoints
        ..clear()
        ..addAll(decodedPoints);
      _currentPolylineIndex = 0;

      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dLat, dLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destinationLabel),
        zIndexInt: 1,
      ));

      setState(() {
        _routeFetched = true;
        _isLoadingRoute = false;
      });

      final dPos = _currentMarkerPos ?? LatLng(driverPos.latitude, driverPos.longitude);
      _updatePolylineTrimmed(dPos);


      if (apiDistanceMeters > 0) {
        _applyStats(
          distanceMeters: apiDistanceMeters,
          durationSecs: apiDurationSecs,
        );
      } else {
        _updateStats(driverPos);
      }
    } catch (osrmError) {
      debugPrint('[Route OSRM Fallback ERROR] Exception: $osrmError');
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
    } else if (_currentMarkerPos != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentMarkerPos!, 16));
    } else if (dLatV != null && dLngV != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(dLatV, dLngV), 14));
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_gpsDisabled) {
      return _errorScreen(
        l10n.navGpsDisabled,
        l10n.navGpsDisabledDesc,
        Icons.location_disabled_rounded,
      );
    }
    if (_locationPermissionDenied) {
      return _errorScreen(
        l10n.navPermissionDenied,
        l10n.navPermissionDeniedDesc,
        Icons.lock_rounded,
        actionLabel: l10n.navOpenSettings,
        onAction: () async => Geolocator.openAppSettings(),
      );
    }

    final dLatV = _destLat;
    final dLngV = _destLng;
    final double? fallbackLat = double.tryParse(widget.order?['delivery_lat']?.toString() ?? '');
    final double? fallbackLng = double.tryParse(widget.order?['delivery_lng']?.toString() ?? '');
    final LatLng initialTarget = _currentMarkerPos ??
        ((dLatV != null && dLngV != null)
            ? LatLng(dLatV, dLngV)
            : (fallbackLat != null && fallbackLng != null
                ? LatLng(fallbackLat, fallbackLng)
                : const LatLng(37.7749, -122.4194)));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                if (_isCameraFollowing) {
                  setState(() => _isCameraFollowing = false);
                }
              },
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition:
                    CameraPosition(target: initialTarget, zoom: 16),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                markers: Set<Marker>.of(_markers),
                polylines: Set<Polyline>.of(_polylines),
                onMapCreated: _onMapCreated,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _gpsFixCount > 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _gpsFixCount > 0 ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _gpsFixCount > 0
                                  ? 'GPS: $_gpsFixCount fixes (${_currentAccuracy.toStringAsFixed(0)}m)'
                                  : 'GPS: WAITING FIX',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Recenter Button (shows when user manually panned map) ─────────
          if (!_isCameraFollowing)
            Positioned(
              right: 20,
              bottom: 270,
              child: FloatingActionButton.extended(
                heroTag: 'recenter_delivery_nav',
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
                        child: Text(
                          l10n.chatCustomer.toUpperCase(),
                          style: const TextStyle(
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
                        _isCalculating ? l10n.navCalculating : _etaTime,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'TIME',
                        _isCalculating
                            ? l10n.navCalculating
                            : l10n.navMinutes('$_estimatedMinutes'),
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'DIST',
                        _isCalculating
                            ? l10n.navCalculating
                            : (_distanceMiles > 0
                                ? l10n.navMiles(_distanceMiles.toStringAsFixed(1))
                                : l10n.common_na),
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
                                  l10n.navCustomerNotes,
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
                                      : l10n.navNoInstructions,
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
                        if (orderId == null) {
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FuelPickupScreen(order: widget.order),
                            ),
                          );
                          return;
                        }

                        try {
                          final now = DateTime.now().toUtc().toIso8601String();
                          // Only update arrived_at — do NOT set status here because
                          // 'ARRIVED_AT_SOURCE' is not a valid order_status enum value.
                          // Status will be set to IN_PROGRESS by FuelPickupScreen.
                          try {
                            await Supabase.instance.client.from('orders').update({
                              'arrived_at': now,
                            }).eq('id', orderId);
                          } catch (e) {
                            debugPrint('[DeliveryNavigation] arrived_at update failed (column may not exist): $e');
                          }

                          widget.order?['arrived_at'] = now;

                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FuelPickupScreen(order: widget.order),
                            ),
                          );
                        } catch (e) {
                          debugPrint('[DeliveryNavigation] Error: $e');
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FuelPickupScreen(order: widget.order),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            l10n.navArrivedAtSource,
                            style: const TextStyle(
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
                        _isReleasing ? l10n.navReleasing : l10n.navReleaseOrder,
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
    final l10n = AppLocalizations.of(context)!;
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;

    // ── Confirmation dialog ────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFCC0000), size: 22),
            const SizedBox(width: 10),
            Text(
              l10n.navReleasePromptTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1C2733),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.navReleasePromptDesc,
          style: const TextStyle(
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
                    child: Text(
                      l10n.common_cancel,
                      style: const TextStyle(
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
                    child: Text(
                      l10n.navRelease,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.navReleaseSuccess),
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
          content: Text(AppLocalizations.of(context)!.navReleaseFailed(e.toString())),
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
                child: Text(AppLocalizations.of(context)!.common_goBack,
                    style: const TextStyle(
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
