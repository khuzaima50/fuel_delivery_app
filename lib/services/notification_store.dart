import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_common.dart';
import 'notification_service.dart';

// ── AppNotification model ────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

// ── NotificationStore ────────────────────────────────────────────────────────
/// Singleton ChangeNotifier that:
///   • Subscribes to the Supabase `notifications` table in real-time.
///   • Merges DB rows with locally cached notifications (from FCM foreground).
///   • Keeps the home-screen app badge in sync with unreadCount.
class NotificationStore extends ChangeNotifier {
  NotificationStore._internal() {
    _loadLastClearedAt();
    // Listen to in-app (foreground) notifications from NotificationService
    _localSub = NotificationService().onLocalNotification.listen((data) {
      _addLocal(
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
        type: data['type'] is NotificationType
            ? data['type'] as NotificationType
            : NotificationType.order,
      );
    });
  }

  static final NotificationStore instance = NotificationStore._internal();

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  StreamSubscription<Map<String, dynamic>>? _localSub;

  final List<AppNotification> _items = [];
  DateTime? _lastClearedAt;

  // ── Public API ─────────────────────────────────────────────────────────────

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;

  /// Call after driver logs in.
  void syncWithSupabase(String driverId) {
    _subscription?.cancel();
    _subscription = NotificationService.getNotificationStream(driverId)
        .listen((data) async {
      final dbItems = <AppNotification>[];

      for (final doc in data) {
        final ts = DateTime.tryParse(doc['created_at']?.toString() ?? '');
        if (ts == null) continue;
        if (_lastClearedAt != null && ts.isBefore(_lastClearedAt!)) continue;

        dbItems.add(AppNotification(
          id: doc['id'].toString(),
          title: doc['title']?.toString() ?? '',
          body: (doc['body'] ?? doc['message'] ?? '').toString(),
          timestamp: ts,
          type: _parseType(doc['type']?.toString()),
          isRead: doc['is_read'] == true,
        ));
      }

      final localItems = await _loadPersistedLocal();
      final filteredLocal = localItems.where((n) {
        if (_lastClearedAt != null && n.timestamp.isBefore(_lastClearedAt!)) {
          return false;
        }
        // Deduplicate — remove local item if an identical DB item already exists
        return !dbItems.any((db) => db.title == n.title && db.body == n.body);
      }).toList();

      _items
        ..clear()
        ..addAll(dbItems)
        ..addAll(filteredLocal)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _updateBadge();
      notifyListeners();
    });
  }

  Future<void> markAllRead() async {
    // Mark in DB
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true}).eq('user_id', user.id);
      } catch (e) {
        debugPrint('[NotifStore] markAllRead DB error: $e');
      }
    }

    // Mark local cache
    final local = await _loadPersistedLocal();
    for (final n in local) {
      n.isRead = true;
    }
    await _savePersistedLocal(local);

    for (final n in _items) {
      n.isRead = true;
    }
    _updateBadge();
    notifyListeners();
  }

  Future<void> clear() async {
    _lastClearedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'driver_last_cleared_notifications', _lastClearedAt!.toIso8601String());
    await prefs.remove('driver_local_notifications');

    _items.clear();
    _updateBadge();
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _addLocal({
    required String title,
    required String body,
    NotificationType type = NotificationType.order,
  }) async {
    final n = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    final local = await _loadPersistedLocal();
    local.add(n);
    await _savePersistedLocal(local);

    _items.add(n);
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _updateBadge();
    notifyListeners();
  }

  void _updateBadge() {
    // Badges are handled automatically by Android notification channels on Android 8+
  }

  Future<void> _loadLastClearedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getString('driver_last_cleared_notifications');
      if (ts != null) _lastClearedAt = DateTime.parse(ts);
    } catch (_) {}
  }

  Future<List<AppNotification>> _loadPersistedLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('driver_local_notifications');
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => AppNotification(
                id: item['id']?.toString() ?? '',
                title: item['title']?.toString() ?? '',
                body: item['body']?.toString() ?? '',
                timestamp: DateTime.parse(item['timestamp'].toString()),
                type: _parseType(item['type']?.toString()),
                isRead: item['isRead'] == true,
              ))
          .toList();
    } catch (e) {
      debugPrint('[NotifStore] _loadPersistedLocal error: $e');
      return [];
    }
  }

  Future<void> _savePersistedLocal(List<AppNotification> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapList = list
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'body': n.body,
                'timestamp': n.timestamp.toIso8601String(),
                'type': n.type.name,
                'isRead': n.isRead,
              })
          .toList();
      await prefs.setString(
          'driver_local_notifications', jsonEncode(mapList));
    } catch (e) {
      debugPrint('[NotifStore] _savePersistedLocal error: $e');
    }
  }

  NotificationType _parseType(String? raw) {
    switch (raw) {
      case 'promo':
        return NotificationType.promo;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.order;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _localSub?.cancel();
    super.dispose();
  }
}
