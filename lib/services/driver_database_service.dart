import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service — all driver data writes go through here.
/// Use [DriverDatabaseService.instance] everywhere in the app instead of
/// calling Supabase.instance.client directly from UI files.
class DriverDatabaseService {
  DriverDatabaseService._();
  static final DriverDatabaseService instance = DriverDatabaseService._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── 1. Activity Logger ────────────────────────────────────────────────────

  /// Inserts one row into driver_activity_logs.
  /// Fire-and-forget safe — never throws.
  Future<void> logDriverAction({
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _db.from('driver_activity_logs').insert({
        'driver_id': uid,
        'action_type': action,
        'metadata': details ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('[DriverLogger] ✓ $action');
    } catch (e) {
      debugPrint('[DriverLogger] ✗ $action — $e');
    }
  }

  // ── 2. Profile Sync ───────────────────────────────────────────────────────

  /// Upserts the driver's profile fields and bumps last_active.
  Future<void> updateProfile({
    String? fullName,
    String? vehicleDetails,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final payload = <String, dynamic>{
        'driver_id': uid,
        'last_active': DateTime.now().toUtc().toIso8601String(),
      };
      if (fullName != null) payload['full_name'] = fullName;
      if (vehicleDetails != null) payload['vehicle_details'] = vehicleDetails;

      await _db.from('drivers_profile').upsert(payload, onConflict: 'driver_id');
      await logDriverAction(action: 'PROFILE_UPDATED', details: payload);
    } catch (e) {
      debugPrint('[DriverDatabaseService] updateProfile error: $e');
    }
  }

  // ── 3. Online Status ──────────────────────────────────────────────────────

  /// Toggles duty status in drivers_profile and writes an activity log.
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _db.from('drivers_profile').upsert({
        'driver_id': uid,
        'is_online': isOnline,
        'last_active': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'driver_id');

      await logDriverAction(
        action: 'DUTY_STATUS_CHANGED',
        details: {'is_online': isOnline},
      );
    } catch (e) {
      debugPrint('[DriverDatabaseService] updateOnlineStatus error: $e');
    }
  }

  // ── 4. Live Location ──────────────────────────────────────────────────────

  /// UPSERTs the driver's GPS coordinates into driver_locations.
  /// Does NOT write an activity log — too frequent to log every fix.
  Future<void> updateLiveLocation(
    double lat,
    double lng, {
    double heading = 0.0,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _db.from('driver_locations').upsert({
        'driver_id': uid,
        'latitude': lat,
        'longitude': lng,
        'heading': heading,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'driver_id');
    } catch (e) {
      debugPrint('[DriverDatabaseService] updateLiveLocation error: $e');
    }
  }
}
