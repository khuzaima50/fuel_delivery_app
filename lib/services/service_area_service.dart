import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  static const double _fallbackRadiusKm = 25.0;

  /// Fetches all active service areas from Supabase.
  /// Returns an empty list on error (triggering fallback behavior).
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
      debugPrint('[ServiceAreaService] Failed to fetch service areas (fallback active): $e');
      return [];
    }
  }

  /// Checks whether a given order coordinate falls within any active service area.
  ///
  /// Fallback: if [areas] is empty, checks whether the order is within
  /// [_fallbackRadiusKm] of the driver's current position.
  ///
  /// - [driverLat] / [driverLng]: driver's current GPS position (used only as fallback)
  /// - [orderLat] / [orderLng]: the delivery destination coordinates
  static bool isOrderInServiceAreas({
    required List<ServiceArea> areas,
    required double? driverLat,
    required double? driverLng,
    required double? orderLat,
    required double? orderLng,
    String? orderId,
  }) {
    final oidLog = orderId != null ? 'Order $orderId' : 'Order';

    // If order coordinates are missing, show by default
    if (orderLat == null || orderLng == null || orderLat == 0.0 || orderLng == 0.0) {
      debugPrint('[ServiceAreaService] $oidLog: No valid coords — showing by default.');
      return true;
    }

    // ── No service areas configured: fallback to driver proximity ──────────
    if (areas.isEmpty) {
      if (driverLat == null || driverLng == null) {
        debugPrint('[ServiceAreaService] $oidLog: No service areas & no driver position — showing by default.');
        return true;
      }
      final dist = _haversineKm(driverLat, driverLng, orderLat, orderLng);
      final inRange = dist <= _fallbackRadiusKm;
      if (!inRange) {
        debugPrint('[ServiceAreaService] MATCH FAILURE $oidLog: dist=${dist.toStringAsFixed(2)}km > limit=${_fallbackRadiusKm}km (Fallback radius)');
      } else {
        debugPrint('[ServiceAreaService] MATCH SUCCESS $oidLog: dist=${dist.toStringAsFixed(2)}km <= limit=${_fallbackRadiusKm}km (Fallback radius)');
      }
      return inRange;
    }

    // ── Check against each active service area ─────────────────────────────
    for (final area in areas) {
      final dist = _haversineKm(area.centerLat, area.centerLng, orderLat, orderLng);
      if (dist <= area.radiusKm) {
        debugPrint(
          '[ServiceAreaService] MATCH SUCCESS $oidLog inside "${area.name}" '
          '(dist=${dist.toStringAsFixed(2)}km <= limit=${area.radiusKm}km)',
        );
        return true;
      }
    }

    debugPrint('[ServiceAreaService] MATCH FAILURE $oidLog: outside all ${areas.length} service area(s) -> HIDE');
    return false;
  }

  /// Haversine formula — returns distance in kilometres between two coordinates.
  static double _haversineKm(
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
