import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_globals.dart';
import 'notification_common.dart';
import '../screens/order/delivery_complete_screen.dart';
import '../screens/chat/chat_screen.dart';

/// Handles all push + in-app notification logic for the FuelDirect driver app.
///
/// Architecture:
///   Flutter → Supabase Edge Function (send-notification)
///             → Google OAuth2 (service account JWT)
///             → FCM HTTP v1 API
///             → Target device
class NotificationService {
  // ── Singleton (instance methods used by NotificationStore) ──────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Emits foreground FCM notifications so NotificationStore can cache them.
  final _onLocalNotification =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onLocalNotification =>
      _onLocalNotification.stream;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialization ──────────────────────────────────────────────────────

  static Future<void> initialize() async {
    // 1. Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[Notif] Permission status: ${settings.authorizationStatus}');

    // 2. Create high-priority Android notification channels
    const channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Fuel delivery order status and chat notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const immediateChannel = AndroidNotificationChannel(
      'immediate_notifications',
      'App Notifications',
      description: 'Real-time feedback for driver actions and chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);
    await androidImplementation?.createNotificationChannel(immediateChannel);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[Notif] User granted permission');
    } else {
      debugPrint('[Notif] User declined or has not accepted permission');
    }

    // 3. Init flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localPlugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 4. Save FCM token and listen for refreshes
    await syncToken();
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[Notif] FCM token refreshed — updating DB');
      syncToken();
    });

    // 5. Foreground messages → show in-app SnackBar + local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. App in background → user tapped notification banner
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. App was terminated → user tapped notification to open
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[Notif] App opened from terminated via notification');
      _handleNotificationTap(initial);
    }

    // 8. Start realtime listener if user is already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      startRealtimeMessageListener(currentUser.id);
    }

    debugPrint('[Notif] NotificationService initialized ✓');
  }

  // ── FCM Token ───────────────────────────────────────────────────────────

  /// Saves (or refreshes) the FCM token into both `drivers` and `profiles` tables.
  static Future<void> syncToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[Notif] syncToken: no authenticated user — skipping');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Notif] syncToken: FCM token is NULL — check Firebase setup / permissions');
        return;
      }

      debugPrint('[Notif] FCM token obtained: ${token.substring(0, 20)}...');

      // Update drivers table
      try {
        final res = await Supabase.instance.client
            .from('drivers')
            .update({'fcm_token': token})
            .eq('id', user.id)
            .select('id');

        if (res.isEmpty) {
          await Supabase.instance.client.from('drivers').upsert(
            {'id': user.id, 'fcm_token': token},
            onConflict: 'id',
          );
        }
      } catch (e) {
        debugPrint('[Notif] Error updating drivers.fcm_token: $e');
      }

      // Also update profiles table for complete consistency
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      } catch (e) {
        debugPrint('[Notif] Error updating profiles.fcm_token: $e');
      }

      debugPrint('[Notif] FCM token saved to drivers and profiles tables ✓');
    } catch (e) {
      debugPrint('[Notif] Token update error (non-fatal): $e');
    }
  }

  /// Alias for syncToken to maintain compatibility if needed (deprecated)
  static Future<void> updateFcmToken() => syncToken();

  // ── Core Send via Edge Function ─────────────────────────────────────────

  /// Sends a push notification via the Supabase Edge Function.
  /// Returns true if the notification was sent, false if skipped/failed.
  static Future<bool> _sendNotification({
    required String targetType,
    required String targetId,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      debugPrint('[Notif] ▶ Calling Edge Function: "$title" → $targetType/$targetId');

      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'target_type': targetType,
          'target_id': targetId,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      final responseData = response.data;
      debugPrint('[Notif] ◀ Edge Function response: $responseData');

      if (responseData is Map) {
        if (responseData['success'] == true) {
          if (responseData['skipped'] == true) {
            debugPrint('[Notif] ⚠ Skipped — no FCM token for $targetType $targetId');
            return false;
          }
          debugPrint('[Notif] ✓ Notification sent successfully');
          return true;
        } else if (responseData['error'] != null) {
          debugPrint('[Notif] ✗ Edge function returned error: ${responseData['error']}');
          return false;
        }
      }
      return true;
    } catch (e) {
      // Non-fatal: log but don't crash the app
      debugPrint('[Notif] ✗ Edge function exception (non-fatal): $e');
      return false;
    }
  }

  // ── Driver Notification Bell ────────────────────────────────────────────

  /// Persists a notification row for the current driver
  /// (shown in the in-app Notifications screen / bell).
  static Future<void> saveDriverNotification({
    required String title,
    required String message,
    required String type,
    String? orderId,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[Notif] saveDriverNotification: no authenticated user — skipping');
        return;
      }

      // Provides ALL columns to satisfy any possible DB constraint
      final row = <String, dynamic>{
        'driver_id': user.id,
        'user_id': null, // Explicit null satisfies recipient_check
        'order_id': orderId, // Can be null
        'title': title,
        'message': message,
        'body': message, // Backwards compatibility for older schema
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      debugPrint('[Notif] Attempting DB save: $title');
      await Supabase.instance.client.from('notifications').insert(row);
      debugPrint('[Notif] Driver notification saved to DB ✓');
    } on PostgrestException catch (e) {
      debugPrint('[Notif] DIAGNOSTIC ERROR: ${e.message}');
      debugPrint('[Notif]   Details: ${e.details}');
      debugPrint('[Notif]   Hint: ${e.hint}');
    } catch (e) {
      debugPrint('[Notif] saveDriverNotification unexpected error: $e');
    }
  }

  // ── Convenience Event Methods ───────────────────────────────────────────

  /// Driver accepts an order → notify the customer user.
  static void notifyUserOrderAccepted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Order Accepted → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Driver Accepted 🚗',
      body: 'A driver has accepted your order and is on the way!',
      data: {'type': 'order_update', 'order_id': orderId, 'status': 'accepted'},
    ));
    unawaited(saveDriverNotification(
      title: 'Order Accepted',
      message: 'You accepted order #${orderId.substring(0, 4).toUpperCase()}',
      type: 'order',
      orderId: orderId,
    ));
  }

  /// Driver starts delivery → notify the customer user.
  static void notifyUserDeliveryStarted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Delivery Started → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Delivery Started 🚛',
      body: 'Your driver is on the way with your fuel!',
      data: {'type': 'order_update', 'order_id': orderId, 'status': 'in_progress'},
    ));
  }

  /// Driver arrives → notify the customer user.
  static void notifyUserDriverArrived(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Driver Arrived → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Driver Arrived 📍',
      body: 'Your driver has arrived at your location.',
      data: {'type': 'order_update', 'order_id': orderId, 'status': 'driver_arrived'},
    ));
  }

  /// Driver finished fueling → notify the customer to confirm receipt.
  static void notifyUserAwaitingConfirmation(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Awaiting Confirmation → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Action Required: Confirm Delivery ⛽',
      body: 'Your fuel delivery is ready! Please open the app to confirm receipt and complete the order.',
      data: {'type': 'awaiting_confirmation', 'order_id': orderId},
    ));
  }


  /// Driver triggers emergency → notify the customer user.
  static void notifyUserEmergency(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Emergency Triggered → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Emergency Action Required 🚨',
      body: 'Your driver has triggered an emergency alert for your order.',
      data: {'type': 'order_update', 'order_id': orderId},
    ));
  }


  /// Order completed → notify the customer user.
  static void notifyUserOrderCompleted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Order Completed → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Order Completed ✅',
      body: 'Your fuel delivery has been completed. Thank you!',
      data: {'type': 'order_update', 'order_id': orderId, 'status': 'completed'},
    ));
    unawaited(saveDriverNotification(
      title: 'Delivery Completed',
      message:
          'Order #${orderId.substring(0, 4).toUpperCase()} completed successfully',
      type: 'order',
      orderId: orderId,
    ));
  }

  /// New chat message → notify the receiver.
  static void notifyChatMessage({
    required String receiverId,
    required String receiverType,
    required String messageText,
    required String orderId,
  }) {
    debugPrint('[Notif] EVENT: Chat Message → notifying $receiverType $receiverId');
    final preview =
        messageText.length > 60 ? '${messageText.substring(0, 60)}…' : messageText;
    unawaited(_sendNotification(
      targetType: receiverType,
      targetId: receiverId,
      title: 'New Message 💬',
      body: preview,
      data: {
        'type': 'chat',
        'order_id': orderId,
        'receiver_id': receiverId,
      },
    ));
  }

  static final Set<String> _processedMessageIds = {};
  static StreamSubscription? _chatSubscription;

  /// Real-time stream of driver notifications from the `notifications` table.
  static Stream<List<Map<String, dynamic>>> getNotificationStream(
      String driverId) {
    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
  }

  /// Listens in realtime to incoming chat messages for this driver.
  /// If the driver is not currently looking at the chat screen for this order,
  /// an immediate local notification and a floating in-app banner with 'Reply'
  /// action are displayed.
  static void startRealtimeMessageListener(String driverId) {
    _chatSubscription?.cancel();
    debugPrint('[Notif] Starting realtime chat message listener for driver $driverId');

    _chatSubscription = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .listen((messages) async {
      if (messages.isEmpty) return;

      for (final latest in messages) {
        final msgId = latest['id']?.toString() ?? '';
        if (msgId.isEmpty || _processedMessageIds.contains(msgId)) continue;
        _processedMessageIds.add(msgId);
        if (_processedMessageIds.length > 200) {
          _processedMessageIds.remove(_processedMessageIds.first);
        }

        final senderId = latest['sender_id']?.toString() ?? '';
        // Skip messages sent by the driver himself
        if (senderId == driverId) continue;

        final orderId = latest['order_id']?.toString() ?? '';
        final messageText = latest['message']?.toString() ?? '';
        final receiverId = latest['receiver_id']?.toString();

        // Ignore messages created more than 60 seconds ago
        final createdAtStr = latest['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null &&
              DateTime.now().toUtc().difference(createdAt).inSeconds > 60) {
            continue;
          }
        }

        // If driver is currently inside the active ChatScreen for this order, skip alert
        if (ChatScreen.activeChatOrderId == orderId) {
          continue;
        }

        // If receiver_id is explicitly set for someone else, skip
        if (receiverId != null &&
            receiverId.isNotEmpty &&
            receiverId != driverId) {
          continue;
        }

        // If receiver_id is null, verify order belongs to driver
        if (receiverId == null || receiverId.isEmpty) {
          try {
            final order = await Supabase.instance.client
                .from('orders')
                .select('driver_id')
                .eq('id', orderId)
                .maybeSingle();
            if (order != null && order['driver_id'] != driverId) {
              continue;
            }
          } catch (_) {}
        }

        // Look up sender name from profiles
        String senderName = 'Customer';
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('full_name')
              .eq('id', senderId)
              .maybeSingle();
          if (profile != null &&
              profile['full_name'] != null &&
              profile['full_name'].toString().trim().isNotEmpty) {
            senderName = profile['full_name'].toString().trim();
          }
        } catch (_) {}

        final preview = messageText.length > 60
            ? '${messageText.substring(0, 60)}…'
            : messageText;

        debugPrint(
            '[Notif] 💬 Incoming Chat Alert from $senderName: "$preview" for order $orderId');

        // 1. Trigger local sound / status bar notification
        await showImmediateNotification(
          title: '$senderName 💬',
          body: preview,
          type: 'chat',
          orderId: orderId,
        );
      }
    }, onError: (e) {
      debugPrint('[Notif] Realtime chat message stream error: $e');
    });
  }

  // ── Foreground / Background Handlers ──────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[Notif] Foreground message received: ${message.notification?.title}');
    debugPrint('[Notif]   data: ${message.data}');

    final notification = message.notification;
    // We check type regardless of whether there's a notification block
    final type = message.data['type'] ?? 'system';
    final orderId = message.data['order_id']?.toString();

    if (type == 'order_completed' && orderId != null) {
      debugPrint('[Notif] Foreground Order Completed detected! Auto-navigating...');
      _navigateToDeliveryComplete(orderId);
      return;
    }

    if (notification == null) {
      debugPrint('[Notif] ⚠ Foreground message has no notification block — data-only message');
      return;
    }

    // Emit to NotificationStore so it can cache locally
    NotificationService().onLocalNotification;
    NotificationService()._onLocalNotification.add({
      'title': notification.title ?? '',
      'body': notification.body ?? '',
      'type': type == 'promo'
          ? NotificationType.promo
          : type == 'system'
              ? NotificationType.system
              : NotificationType.order,
    });

    // Show local notification
    _showLocalNotification(message);

    // Fallback: Save to DB locally if received in foreground
    unawaited(saveDriverNotification(
      title: notification.title ?? 'New Update',
      message: notification.body ?? '',
      type: type,
      orderId: message.data['order_id'],
    ));
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',
          'Order Updates',
          channelDescription:
              'Fuel delivery order status and chat notifications',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFF4D00),
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[Notif] Notification tapped: ${message.data}');
    _navigateFromData(message.data);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[Notif] Local notification tapped, payload: ${response.payload}');
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (e) {
      debugPrint('[Notif] Failed to parse notification payload: $e');
    }
  }

  // ── Immediate Notification Helper ────────────────────────────────────

  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    try {
      // 1. Show Local Notification
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'immediate_notifications',
        'App Notifications',
        channelDescription: 'Real-time feedback for driver actions',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFFF6600),
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
      );

      // 2. Save to History for this driver
      unawaited(saveDriverNotification(
        title: title,
        message: body,
        type: type,
        orderId: orderId,
      ));
      
      debugPrint('[Notif] Immediate notification triggered: $title');
    } catch (e) {
      debugPrint('[Notif] Error showing immediate notification: $e');
    }
  }

  static Future<void> showTestNotification() async {
    await showImmediateNotification(
      title: 'Test Notification 🔔',
      body: 'This is a test to verify the system works.',
      type: 'system',
    );
  }

  // ── Navigation on Tap ───────────────────────────────────────────────────

  static void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final orderId = data['order_id']?.toString();
    final receiverId = data['receiver_id']?.toString();

    debugPrint('[Notif] Navigating from notification: type=$type, orderId=$orderId');

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[Notif] ⚠ Navigator not ready yet — cannot navigate');
      return;
    }

    if (type == 'chat' && orderId != null) {
      final customerId = data['sender_id']?.toString() ??
          data['customer_id']?.toString() ??
          receiverId ??
          '';
      final customerName = data['sender_name']?.toString() ??
          data['customer_name']?.toString() ??
          'Customer';
      navigator.pushNamed(
        '/chat',
        arguments: {
          'orderId': orderId,
          'customerId': customerId,
          'customerName': customerName,
        },
      );
    } else if (type == 'order_completed' && orderId != null) {
      _navigateToDeliveryComplete(orderId);
    } else if (type == 'order_update' || type == 'order_completed') {
      navigator.pushNamed('/assigned-orders');
    }
  }

  /// Fetches order details and navigates to DeliveryCompleteScreen.
  /// Used for both foreground and tapped notifications.
  static Future<void> _navigateToDeliveryComplete(String orderId) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    try {
      // Show a brief loading overlay if possible, or just fetch
      final res = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();

      if (res != null) {
        final double qty = (res['fuel_quantity'] ?? res['fuel_quantity_gallons'] ?? 0.0).toDouble();
        final double total = (res['total_amount'] ?? 0.0).toDouble();
        final double earned = (res['driver_earning'] ?? 0.0).toDouble();
        
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DeliveryCompleteScreen(
              orderId: orderId,
              deliveredGallons: qty,
              totalAmount: total,
              driverEarning: earned,
              fuelType: res['fuel_type'] ?? 'Fuel',
              address: res['delivery_address'] ?? 'Customer Location',
            ),
          ),
          (route) => false,
        );
      } else {
        // Fallback if order not found
        navigator.pushNamedAndRemoveUntil('/assigned-orders', (route) => false);
      }
    } catch (e) {
      debugPrint('[Notif] Error in _navigateToDeliveryComplete: $e');
      navigator.pushNamedAndRemoveUntil('/assigned-orders', (route) => false);
    }
  }
}
