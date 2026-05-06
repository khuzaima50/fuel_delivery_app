import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
// DriverLocationStream — real-time GPS streaming service.
//
// Usage:
//   final tracker = DriverLocationStream();
//   await tracker.start(onPosition: (pos) { ... });
//   // ... later ...
//   tracker.dispose();
// ─────────────────────────────────────────────────────────────────────────────
class DriverLocationStream {
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastDbWrite;

  /// Start streaming GPS. Calls [onPosition] on every update, throttles
  /// Supabase writes to at most once per [dbThrottleSeconds].
  ///
  /// Returns [false] if permission/service unavailable (caller should show UI).
  Future<bool> start({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 3,
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

    debugPrint('[Location Start] GPS stream beginning (bestForNavigation, distanceFilter: 10m)');

    // ── 3. Open position stream ─────────────────────────────────────────────
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // emit every fix regardless of movement
      intervalDuration: const Duration(seconds: 2),
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position pos) {
        debugPrint('[Location Update] ${pos.latitude.toStringAsFixed(6)}, '
            '${pos.longitude.toStringAsFixed(6)} '
            '| heading: ${pos.heading.toStringAsFixed(1)}°');

        // Emit to UI immediately
        onPosition(pos);

        // Throttled Supabase write
        final now = DateTime.now();
        if (_lastDbWrite == null ||
            now.difference(_lastDbWrite!).inSeconds >= dbThrottleSeconds) {
          _lastDbWrite = now;
          _writeToSupabase(pos);
        }
      },
      onError: (Object e) {
        debugPrint('[Location Update] stream error: $e');
      },
    );

    return true;
  }

  /// Cancel the stream and free resources.
  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    debugPrint('[Location Start] GPS stream disposed');
  }

  // ── Private: write to both driver_locations (UPSERT) and drivers (UPDATE) ──
  static Future<void> _writeToSupabase(Position pos) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now().toUtc().toIso8601String();

      // 1. UPSERT dedicated driver_locations table
      await Supabase.instance.client.from('driver_locations').upsert({
        'driver_id': user.id,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'heading': pos.heading,
        'updated_at': now,
      }, onConflict: 'driver_id');

      // 2. Keep drivers table current_lat/lng in sync (backward compat)
      await Supabase.instance.client.from('drivers').upsert({
        'id': user.id,
        'current_lat': pos.latitude,
        'current_lng': pos.longitude,
        'last_updated_at': now,
      }, onConflict: 'id');

      debugPrint('[Supabase Write] ${pos.latitude.toStringAsFixed(6)}, '
          '${pos.longitude.toStringAsFixed(6)}');
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
}
