import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = []; // stored in memory after first fetch
  int _currentPolylineIndex = 0;

  // ── GPS stream ────────────────────────────────────────────────────────────
  final DriverLocationStream _gpsTracker = DriverLocationStream();
  StreamSubscription<ServiceStatus>? _serviceStatusSub;

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

  // ── State flags ───────────────────────────────────────────────────────────
  bool _locationPermissionDenied = false;
  bool _gpsDisabled = false;
  bool _isLoadingRoute = false;
  bool _routeFetched = false;
  bool _isArrived = false;

  // ── Order status realtime subscription ───────────────────────────────────
  RealtimeChannel? _orderStatusChannel;

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
  @override
  void initState() {
    super.initState();

    // 60 FPS marker lerp controller
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _markerAnimController.addListener(_onMarkerAnimTick);

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

    // Fast driver location retrieval (cached fix)
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
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
          }
        }
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _fetchCustomerData();
    _startLocationStream();
    _initCompass();
    _resolveDestination(); // async — resolves lat/lng from order
    _checkInitialStatus();
    // NOTE: _fetchRouteEarly() REMOVED — it called getCurrentPosition() which
    // kills the active getPositionStream() on Android. The route is now fetched
    // on the first stream event via _onNewPosition, or after destination resolves.
    _subscribeToOrderStatus(); // listen for cancellation / status changes
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[RealTimeDelivery] App resumed -> checking GPS stream status');
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

      // Only update compass beam when stationary / moving slowly (< 1.8 m/s)
      final speed = _lastGpsFix?.speed ?? 0.0;
      if (speed < 1.8) {
        _currentBearing = smoothedHeading;
        _currentAnimatedBearing = smoothedHeading;
        _animStartBearing = smoothedHeading;
        _animTargetBearing = smoothedHeading;

        final pos = _currentAnimatedPos ?? _currentMarkerPos;
        if (pos != null) {
          _updateDriverMarker(pos, smoothedHeading);
        }
      }
    });
  }





  /// Fetch route using an already-available position — NO getCurrentPosition().
  /// Called from _onNewPosition (first stream event) or after destination resolves.
  void _fetchRouteFromAvailablePosition() {
    if (_routeFetched || _isLoadingRoute) return;
    if (_destLat == null || _destLng == null) return;

    // Use last GPS fix from the stream, or fall back to cached marker position
    final gpsFix = _lastGpsFix;
    final markerPos = _currentMarkerPos;

    if (gpsFix != null) {
      debugPrint('[Route] Fetching route from stream GPS fix');
      _fetchRoute(gpsFix);
    } else if (markerPos != null) {
      // Construct a minimal Position from the cached marker position
      debugPrint('[Route] Fetching route from cached marker position');
      Geolocator.getLastKnownPosition().then((pos) {
        if (pos != null && mounted && !_routeFetched) {
          _fetchRoute(pos);
        }
      });
    }
  }

  void _checkInitialStatus() {
  }

  // ── Subscribe to order status changes (cancellation detection) ──────────
  void _subscribeToOrderStatus() {
    final orderId = widget.order?['id']?.toString();
    if (orderId == null) return;

    try {
      _orderStatusChannel?.unsubscribe();
      _orderStatusChannel = Supabase.instance.client
          .channel('rtd_order_status_$orderId')
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
              debugPrint('[RealTimeDelivery] Order status update received: $newStatus');
              if (!mounted) return;

              if (newStatus == 'cancelled') {
                // Stop GPS tracking immediately
                _gpsTracker.dispose();
                _orderStatusChannel?.unsubscribe();
                _showCancellationDialog();
              }
            },
          )
          .subscribe((status, error) {
            debugPrint('[RealTimeDelivery] Order channel: $status');
          });
    } catch (e) {
      debugPrint('[RealTimeDelivery] Realtime subscribe error: $e');
    }
  }

  /// Shows a non-dismissible dialog when order is cancelled by customer.
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
              Navigator.of(ctx).pop(); // Close dialog
              // Pop back to assigned orders
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markerAnimController.stop();
    _markerAnimController.dispose();
    _gpsTracker.dispose();
    _compassSub?.cancel();
    _serviceStatusSub?.cancel();
    _orderStatusChannel?.unsubscribe();
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
            .select('*, profiles(phone_number)')
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
          // Propagate resolved coordinates to the order map object
          if (widget.order != null) {
            widget.order!['delivery_lat'] = lat;
            widget.order!['delivery_lng'] = lng;
          }
          _isResolvingDestination = false;
          _destinationMissing = false;
        });
      }
      
      // Move camera if map is already created
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

      // Trigger route fetch now that destination is known.
      // Use already-available position — NEVER call getCurrentPosition() here
      // as it kills the active getPositionStream() on Android.
      if (!_routeFetched && !_isLoadingRoute) {
        _fetchRouteFromAvailablePosition();
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
        debugPrint('[Location] GPS service enabled');
        if (mounted) setState(() => _gpsDisabled = false);
        if (!_gpsTracker.isActive) {
          _startLocationStream();
        }
      }
    });

    // Seed immediate initial position fix so GPS badge turns green instantly
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null && mounted && _gpsFixCount == 0) {
        _onNewPosition(pos);
      }
    });

    final ok = await _gpsTracker.start(
      dbThrottleSeconds: 2,
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
    if (!_isArrived && _isCameraFollowing && _mapController != null) {
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

  void _recenterCamera() {
    setState(() => _isCameraFollowing = true);
    final pos = _currentAnimatedPos ?? _currentMarkerPos;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos,
            zoom: 17.5,
            tilt: 35.0,
            bearing: _currentAnimatedBearing != 0.0 ? _currentAnimatedBearing : _currentBearing,
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

    // Stats & Arrival Check
    if (_destLat != null && _destLng != null) {
      _updateStats(pos);
      final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, _destLat!, _destLng!);
      if (mounted) setState(() => _isArrived = dist < 80);
    }

    // Smart polyline refresh (if driver deviated > 70 m off route)
    if (_routeFetched && _routePoints.isNotEmpty) {
      final nearestDist = _distanceToPolyline(newLatLng, _routePoints);
      if (nearestDist > 70) {
        debugPrint('[Route Fetch] Driver deviated ${nearestDist.toStringAsFixed(0)} m — re-fetching route');
        _fetchRoute(pos);
      }
    } else if (!_routeFetched && !_isLoadingRoute && _destLat != null && _destLng != null) {
      debugPrint('[Route] First stream event — triggering route fetch');
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

  // ── Stats (distance + ETA) ────────────────────────────────────────────────
  void _updateStats(Position pos) {
    final dLat = _destLat;
    final dLng = _destLng;
    if (dLat == null || dLng == null) return;
    final distM = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, dLat, dLng);
    _applyStats(distanceMeters: distM, durationSecs: null);
  }

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

      if (status != 'OK') {
        final errMsg = data['error_message'] as String? ?? 'no details';
        debugPrint('[Route ERROR] API status=$status — $errMsg — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route ERROR] No routes returned — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final legs = routes[0]['legs'] as List?;
      int? apiDurationSecs;
      double? apiDistanceMeters;
      if (legs != null && legs.isNotEmpty) {
        final leg = legs[0] as Map<String, dynamic>?;
        apiDurationSecs = (leg?['duration_in_traffic']?['value'] as int?) ??
            (leg?['duration']?['value'] as int?);
        apiDistanceMeters = ((leg?['distance']?['value']) as num?)?.toDouble();
      }

      final encodedPolyline =
          (routes[0]['overview_polyline']['points'] as String?) ?? '';

      if (encodedPolyline.isEmpty) {
        debugPrint('[Polyline ERROR] Empty polyline string — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);

      if (decodedPoints.isNotEmpty) {
        _routePoints
          ..clear()
          ..addAll(decodedPoints);
        _currentPolylineIndex = 0;

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
        });

        final dPos = _currentMarkerPos ?? LatLng(driverPos.latitude, driverPos.longitude);
        _updatePolylineTrimmed(dPos);

        if (apiDistanceMeters != null && apiDistanceMeters > 0) {
          _applyStats(
            distanceMeters: apiDistanceMeters,
            durationSecs: apiDurationSecs,
          );
        } else {
          _updateStats(driverPos);
        }
      } else {
        debugPrint('[Route ERROR] No points decoded — trying OSRM fallback');
        await _fetchRouteOSRM(driverPos, dLat, dLng);
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
      debugPrint('[Route OSRM Fallback RealTime] Fetching OSRM: $osrmUri');
      final response = await http.get(osrmUri).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode != 200) {
        debugPrint('[Route OSRM Fallback RealTime] HTTP error ${response.statusCode}');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('[Route OSRM Fallback RealTime] No routes returned');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final route = routes[0] as Map<String, dynamic>;
      final encodedPolyline = (route['geometry'] as String?) ?? '';
      if (encodedPolyline.isEmpty) {
        debugPrint('[Route OSRM Fallback RealTime] Empty polyline string');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final decodedPoints = _decodePolyline(encodedPolyline);
      debugPrint('[Route OSRM Fallback RealTime] Polyline Points count = ${decodedPoints.length}');

      if (decodedPoints.isEmpty) {
        debugPrint('[Route OSRM Fallback RealTime] No points decoded');
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      final double apiDistanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final int apiDurationSecs = (route['duration'] as num?)?.toInt() ?? 0;

      debugPrint('[Route OSRM Fallback RealTime Stats] duration=${apiDurationSecs}s distance=${apiDistanceMeters}m');

      _routePoints
        ..clear()
        ..addAll(decodedPoints);
      _currentPolylineIndex = 0;

      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dLat, dLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destAddress),
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
      debugPrint('[Route OSRM Fallback RealTime ERROR] Exception: $osrmError');
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
    } else if (dLatV != null && dLngV != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(dLatV, dLngV), 14));
    } else if (_currentMarkerPos != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentMarkerPos!, 16));
    }
  }


  // ── Call customer ─────────────────────────────────────────────────────────
  Future<void> _callCustomer() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rtdNoPhone)),
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
          SnackBar(content: Text(l10n.rtdCallError)),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.rtdArrivalFailed(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    // ── Permission / GPS error screens ─────────────────────────────────────
    if (_gpsDisabled) {
      return _errorScreen(
        l10n.rtdGpsDisabled,
        l10n.rtdGpsDisabledDesc,
        Icons.location_disabled_rounded,
        actionLabel: l10n.rtdOpenGps,
        onAction: () async {
          await Geolocator.openLocationSettings();
        },
      );
    }
    if (_locationPermissionDenied) {
      return _errorScreen(
        l10n.rtdPermDenied,
        l10n.rtdPermDeniedDesc,
        Icons.lock_rounded,
        actionLabel: l10n.rtdOpenSettings,
        onAction: () async {
          await Geolocator.openAppSettings();
        },
      );
    }

    final double? fallbackLat = double.tryParse(widget.order?['delivery_lat']?.toString() ?? '');
    final double? fallbackLng = double.tryParse(widget.order?['delivery_lng']?.toString() ?? '');
    final LatLng initialTarget = _currentMarkerPos ??
        ((fallbackLat != null && fallbackLng != null)
            ? LatLng(fallbackLat, fallbackLng)
            : const LatLng(37.7749, -122.4194));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                if (_isCameraFollowing) {
                  setState(() => _isCameraFollowing = false);
                }
              },
              child: GoogleMap(
                mapType: MapType.normal,
                // style: null → renders the default Google Maps look (roads, POIs,
                // labels and landmarks exactly as the native Google Maps app shows them)
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.rtdLocating,
                        style: const TextStyle(
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
                    Text(l10n.rtdDestMissing,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 6),
                    Text(
                        _destAddress.isNotEmpty
                            ? l10n.rtdAddressLabel(_destAddress)
                            : l10n.rtdNoAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888))),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resolveDestination,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.rtdRetry),
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
                              Text(l10n.rtdDeliveringTo,
                                  style: const TextStyle(
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

          // ── Recenter Button (shows when user manually panned map) ─────────
          if (!_isCameraFollowing)
            Positioned(
              right: 20,
              bottom: 300,
              child: FloatingActionButton.extended(
                heroTag: 'recenter_realtime_nav',
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
                      _statBox(l10n.rtdEtaLabel, _etaTime),
                      const SizedBox(width: 10),
                      _statBox(l10n.rtdTimeLabel, l10n.rtdMin(_estimatedMinutes.toString())),
                      const SizedBox(width: 10),
                      _statBox(
                          l10n.rtdDistLabel,
                          _distanceMiles > 0
                              ? l10n.rtdMiles(_distanceMiles.toStringAsFixed(1))
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
                          backgroundColor: const Color(0xFFEEEEEE),
                          child: (_customerAvatarUrl != null && _customerAvatarUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    _customerAvatarUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      color: Color(0xFF888888),
                                      size: 24,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFF888888),
                                  size: 24,
                                ),
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
                                Text(l10n.rtdCustomer,
                                    style: const TextStyle(
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
                                      ? l10n.rtdArrivedConfirm
                                      : l10n.rtdArrivedAt,
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
    final l10n = AppLocalizations.of(context)!;
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
                child: Text(l10n.rtdGoBack,
                    style: const TextStyle(
                        color: Color(0xFFFF4D00), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
