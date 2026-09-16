import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LocationResult — simple value object returned from one-shot lookups
// ─────────────────────────────────────────────────────────────────────────────
class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  bool get isValid => latitude != 0.0 && longitude != 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// NavigationMarkerHelper — Generates a crisp navigation-style arrow marker puck
// ─────────────────────────────────────────────────────────────────────────────
class NavigationMarkerHelper {
  static BitmapDescriptor? _cachedArrowIcon;

  /// Generates a Google Maps–style blue navigation puck with directional beam.
  /// The puck is a blue circle with white border, and a lighter blue cone/beam
  /// extending upward (north) to indicate heading direction.
  static Future<BitmapDescriptor> getDriverArrowIcon({double size = 140}) async {
    if (_cachedArrowIcon != null) {
      return _cachedArrowIcon!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size / 2, size * 0.58);  // puck center slightly below middle to leave room for beam
    final puckRadius = size * 0.16;

    // 1. Directional beam / cone (pointing north / upward)
    final beamPath = Path();
    final beamLength = size * 0.42;
    final beamHalfWidth = size * 0.22;
    beamPath.moveTo(center.dx, center.dy);  // Start at puck center
    beamPath.lineTo(center.dx - beamHalfWidth, center.dy - beamLength);  // Left edge
    beamPath.quadraticBezierTo(
      center.dx, center.dy - beamLength - size * 0.06,  // Rounded tip
      center.dx + beamHalfWidth, center.dy - beamLength,  // Right edge
    );
    beamPath.close();

    // Beam gradient: solid near puck, fading outward
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy),
        Offset(center.dx, center.dy - beamLength),
        [
          const Color(0x664285F4),  // semi-transparent blue near puck
          const Color(0x104285F4),  // almost transparent at tip
        ],
      );
    canvas.drawPath(beamPath, beamPaint);

    // 2. Soft outer glow / shadow around puck
    final glowPaint = Paint()
      ..color = const Color(0x334285F4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, puckRadius + 6, glowPaint);

    // 3. White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, puckRadius + 3, borderPaint);

    // 4. Main blue puck body (Google Maps blue)
    final bodyPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, puckRadius, bodyPaint);

    // 5. Small white inner dot (center highlight)
    final innerDot = Paint()
      ..color = const Color(0xBBFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, puckRadius * 0.30, innerDot);

    // Convert to image -> bytes -> BitmapDescriptor
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    _cachedArrowIcon = BitmapDescriptor.bytes(uint8List);
    return _cachedArrowIcon!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DriverLocationStream — real-time continuous GPS streaming service.
//
// Usage:
//   final tracker = DriverLocationStream();
//   await tracker.start(onPosition: (pos) { ... });
//   // ... later ...
//   tracker.dispose();
// ─────────────────────────────────────────────────────────────────────────────
class DriverLocationStream {
  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;
  DateTime? _lastDbWrite;
  DateTime? _lastFixReceivedTime;
  bool _isStarting = false;

  /// Whether the GPS position stream is currently active and listening.
  bool get isActive => _positionSub != null || _fallbackTimer != null;

  /// Start streaming GPS. Calls [onPosition] on every update, throttles
  /// Supabase writes to at most once per [dbThrottleSeconds].
  Future<bool> start({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 2,
  }) async {
    if (_isStarting) {
      debugPrint('[Location Start] start() already in progress — skipping');
      return isActive;
    }
    if (_positionSub != null) {
      debugPrint('[Location Start] Stream already active — skipping restart');
      return true;
    }
    _isStarting = true;

    try {
      return await _doStart(onPosition: onPosition, dbThrottleSeconds: dbThrottleSeconds);
    } finally {
      _isStarting = false;
    }
  }

  /// Force-restart the stream with a new callback (e.g. after app resume).
  Future<bool> restart({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 2,
  }) async {
    if (_isStarting) {
      debugPrint('[Location Restart] start() or restart() already in progress — skipping');
      return isActive;
    }
    _isStarting = true;

    try {
      await _disposeInternal();
      return await _doStart(onPosition: onPosition, dbThrottleSeconds: dbThrottleSeconds);
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _disposeInternal() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    if (_positionSub != null) {
      debugPrint('LOCATION_UNSUBSCRIBE');
      await _positionSub?.cancel();
      _positionSub = null;
    }
  }

  /// Cancel the stream and free resources.
  Future<void> dispose() async {
    _isStarting = true;
    try {
      await _disposeInternal();
      debugPrint('[Location Start] GPS stream disposed');
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _doStart({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 2,
  }) async {
    // ── 1. Check GPS service ────────────────────────────────────────────────
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[Permission] GPS service disabled');
      return false;
    }

    // ── 2. Check / request permission ──────────────────────────────────────
    LocationPermission perm = await Geolocator.checkPermission();
    debugPrint('[Permission] current: $perm');

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      debugPrint('[Permission] after request: $perm');
      if (perm == LocationPermission.denied) return false;
    }

    if (perm == LocationPermission.deniedForever) {
      debugPrint('[Permission] deniedForever — open settings');
      return false;
    }

    debugPrint('[Location Start] GPS stream beginning (bestForNavigation, distanceFilter: 0m)');

    // ── 3. Open platform-specific position stream ───────────────────────────
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    await _disposeInternal();

    debugPrint('LOCATION_STREAM_CREATED');

    void handlePos(Position pos) {
      if (pos.latitude == 0.0 && pos.longitude == 0.0) return;
      _lastFixReceivedTime = DateTime.now();

      try {
        onPosition(pos);
      } catch (e) {
        debugPrint('LOCATION_CALLBACK_ERROR error=$e');
      }

      final now = DateTime.now();
      if (_lastDbWrite == null ||
          now.difference(_lastDbWrite!).inSeconds >= dbThrottleSeconds) {
        _lastDbWrite = now;
        _writeToSupabase(pos);
      }
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      handlePos,
      onError: (Object e) {
        debugPrint('LOCATION_STREAM_ERROR error=$e');
      },
      onDone: () {
        debugPrint('LOCATION_STREAM_DONE');
      },
      cancelOnError: false,
    );

    // Bulletproof 1-second fallback poll: if stream is quiet for > 1.2s, poll position
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final lastTime = _lastFixReceivedTime;
      if (lastTime == null || DateTime.now().difference(lastTime).inMilliseconds > 1200) {
        try {
          final freshPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 2),
            ),
          );
          handlePos(freshPos);
        } catch (_) {}
      }
    });

    return true;
  }

  // ── Private: write to both driver_locations (UPSERT) and drivers (UPDATE) ──
  static Future<void> _writeToSupabase(Position pos) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = pos.timestamp.toUtc().toIso8601String();

      // 1. UPSERT dedicated driver_locations table
      try {
        await Supabase.instance.client.from('driver_locations').upsert({
          'driver_id': user.id,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'heading': pos.heading,
          'speed': pos.speed,
          'accuracy': pos.accuracy,
          'updated_at': now,
        }, onConflict: 'driver_id');
      } catch (e) {
        debugPrint('[Supabase Write driver_locations] $e');
      }

      // 2. Keep drivers table in sync if columns exist
      try {
        await Supabase.instance.client.from('drivers').update({
          'current_lat': pos.latitude,
          'current_lng': pos.longitude,
          'last_updated_at': now,
        }).eq('id', user.id);
      } catch (_) {
        // Safe to ignore if column is absent
      }

      debugPrint(
        'SUPABASE: '
        'latitude=${pos.latitude.toStringAsFixed(6)} '
        'longitude=${pos.longitude.toStringAsFixed(6)} '
        'updated_at=$now',
      );
    } catch (e) {
      debugPrint('[Supabase Write] ERROR: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LocationService — static helpers (unchanged API for rest of app)
// ─────────────────────────────────────────────────────────────────────────────
class LocationService {
  static final String _mapsApiKey = dotenv.env['MAPS_API_KEY'] ?? '';

  /// One-shot permission check + position fetch (used by non-nav screens).
  static Future<LocationResult?> getCurrentLocation({
    BuildContext? context,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && context.mounted) {
        _showSnackBar(context, 'Location services are disabled. Please enable GPS.');
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context != null && context.mounted) {
          _showSnackBar(context, 'Location permission denied.');
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null && context.mounted) {
        _showSnackBar(
          context,
          'Location permission permanently denied. Please enable in Settings.',
        );
        await Geolocator.openAppSettings();
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String? address;
      if (_mapsApiKey.isNotEmpty) {
        address = await _reverseGeocode(position.latitude, position.longitude);
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('[LocationService] Error getting location: $e');
      if (context != null && context.mounted) {
        _showSnackBar(context, 'Could not get your location. Please try again.');
      }
      return null;
    }
  }

  static Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$_mapsApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results.first['formatted_address']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode failed: $e');
    }
    return null;
  }

  static String buildNavigationUrl(double destLat, double destLng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng';
  }

  static String buildLocationUrl(double lat, double lng, {String? label}) {
    final q = label != null ? Uri.encodeComponent(label) : '$lat,$lng';
    return 'https://www.google.com/maps/search/?api=1&query=$q&query_place_id=';
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Legacy compatibility — kept for screens that haven't been migrated.
  static Future<void> updateDriverLocationInDb(double lat, double lng) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now().toUtc().toIso8601String();

      await Supabase.instance.client.from('driver_locations').upsert({
        'driver_id': user.id,
        'latitude': lat,
        'longitude': lng,
        'updated_at': now,
      }, onConflict: 'driver_id');

      await Supabase.instance.client.from('drivers').upsert({
        'id': user.id,
        'current_lat': lat,
        'current_lng': lng,
        'last_updated_at': now,
      }, onConflict: 'id');

      debugPrint('[Supabase Write] legacy: $lat, $lng');
    } catch (e) {
      debugPrint('[Supabase Write] legacy ERROR: $e');
    }
  }

  static double getDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calculates the forward azimuth / bearing in degrees (0..360) from
  /// start coordinate to end coordinate using spherical trigonometry.
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final startLatRad = _degreesToRadians(startLat);
    final startLngRad = _degreesToRadians(startLng);
    final endLatRad = _degreesToRadians(endLat);
    final endLngRad = _degreesToRadians(endLng);

    final dLng = endLngRad - startLngRad;

    final y = math.sin(dLng) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = _radiansToDegrees(bearing);
    return (bearing + 360.0) % 360.0;
  }

  /// Interpolates linearly between [start] and [end] LatLng positions.
  static LatLng interpolateLatLng(LatLng start, LatLng end, double t) {
    final lat = ui.lerpDouble(start.latitude, end.latitude, t) ?? start.latitude;
    final lng = ui.lerpDouble(start.longitude, end.longitude, t) ?? start.longitude;
    return LatLng(lat, lng);
  }

  /// Interpolates between [start] and [end] angles (in degrees, 0..360)
  /// using the shortest rotational path to prevent full 360-degree spins.
  static double interpolateAngle(double start, double end, double t) {
    double diff = (end - start) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return (start + diff * t + 360.0) % 360.0;
  }

  /// Finds the index in [routePoints] closest to [driverPos], starting search around [currentIndex].
  static int findClosestPolylineIndex(
    LatLng driverPos,
    List<LatLng> routePoints,
    int currentIndex,
  ) {
    if (routePoints.isEmpty) return 0;
    int bestIdx = math.max(0, math.min(currentIndex, routePoints.length - 1));
    double minDistance = double.infinity;

    final searchStart = math.max(0, currentIndex - 2);
    final searchEnd = math.min(routePoints.length, searchStart + 50);

    for (int i = searchStart; i < searchEnd; i++) {
      final dist = Geolocator.distanceBetween(
        driverPos.latitude,
        driverPos.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Calculates the road segment heading ahead of the driver on the route polyline.
  static double getPolylineAheadBearing(
    LatLng driverPos,
    List<LatLng> routePoints,
    int currentIndex,
  ) {
    if (routePoints.isEmpty) return 0.0;
    final closestIdx = findClosestPolylineIndex(driverPos, routePoints, currentIndex);
    if (closestIdx + 1 < routePoints.length) {
      final nextPt = routePoints[closestIdx + 1];
      return calculateBearing(
        driverPos.latitude,
        driverPos.longitude,
        nextPt.latitude,
        nextPt.longitude,
      );
    } else if (closestIdx > 0) {
      final prevPt = routePoints[closestIdx - 1];
      return calculateBearing(
        prevPt.latitude,
        prevPt.longitude,
        driverPos.latitude,
        driverPos.longitude,
      );
    }
    return 0.0;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
  static double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;
}


