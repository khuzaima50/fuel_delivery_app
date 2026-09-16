import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a single circular service area zone fetched from the database.
class ServiceArea {
  final String id;
  final String name;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final bool isActive;

  const ServiceArea({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.isActive,
  });

  factory ServiceArea.fromMap(Map<String, dynamic> map) {
    return ServiceArea(
      id: map['id'] as String,
      name: map['name'] as String,
      centerLat: (map['center_lat'] as num).toDouble(),
      centerLng: (map['center_lng'] as num).toDouble(),
      radiusKm: (map['radius_km'] as num).toDouble(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

/// Service responsible for fetching and caching active global service areas.
///
/// Usage:
///   final areas = await ServiceAreaService.fetchActiveAreas();
///   final inArea = ServiceAreaService.isOrderInServiceAreas(areas, orderLat, orderLng);
class ServiceAreaService {
  /// Fetches all active service areas from Supabase.
  static Future<List<ServiceArea>> fetchActiveAreas() async {
    try {
      final data = await Supabase.instance.client
          .from('service_areas')
          .select()
          .eq('is_active', true)
          .order('created_at');

      final areas = (data as List<dynamic>)
          .map((e) => ServiceArea.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('[ServiceAreaService] Fetched ${areas.length} active service area(s).');
      return areas;
    } catch (e) {
      debugPrint('[ServiceAreaService] Failed to fetch service areas: $e');
      return [];
    }
  }

  /// Checks whether a given order coordinate falls within active service area or 50 km maximum radius from driver.
  static bool isOrderInServiceAreas({
    required List<ServiceArea> areas,
    required double? driverLat,
    required double? driverLng,
    required double? orderLat,
    required double? orderLng,
    String? orderId,
    double maxDistanceKm = 50.0,
  }) {
    if (driverLat == null || driverLng == null) {
      return false;
    }
    if (orderLat != null && orderLng != null && orderLat != 0.0 && orderLng != 0.0) {
      final dist = haversineKm(driverLat, driverLng, orderLat, orderLng);
      return dist <= maxDistanceKm;
    }
    return false;
  }

  /// Resolves latitude and longitude for an order from its data fields or by geocoding its address.
  static Future<Map<String, double>?> resolveOrderCoordinates(
      Map<String, dynamic> order, {String? apiKey}) async {
    final latRaw = order['customer_lat'] ??
        order['delivery_lat'] ??
        order['latitude'] ??
        order['delivery_latitude'] ??
        order['lat'];
    final lngRaw = order['customer_lng'] ??
        order['delivery_lng'] ??
        order['longitude'] ??
        order['delivery_longitude'] ??
        order['lng'];

    double? lat = double.tryParse(latRaw?.toString() ?? '');
    double? lng = double.tryParse(lngRaw?.toString() ?? '');

    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      return {'lat': lat, 'lng': lng};
    }

    // Geocode address fallback
    final address = order['delivery_address']?.toString() ?? '';
    final key = apiKey ?? dotenv.env['MAPS_API_KEY'] ?? '';
    if (address.isNotEmpty && key.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}&key=$key',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results.first['geometry']['location'];
            lat = (loc['lat'] as num).toDouble();
            lng = (loc['lng'] as num).toDouble();
            order['delivery_lat'] = lat;
            order['delivery_lng'] = lng;
            return {'lat': lat, 'lng': lng};
          }
        }
      } catch (e) {
        debugPrint('[ServiceAreaService] Geocode error: $e');
      }
    }
    return null;
  }

  /// Haversine formula — returns distance in kilometres between two coordinates.
  static double haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
