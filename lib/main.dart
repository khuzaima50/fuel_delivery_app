import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/notification_store.dart';
import 'services/app_globals.dart';
import 'services/locale_service.dart';
import 'widgets/app_lifecycle_manager.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/order/assigned_orders_screen.dart';
import 'screens/chat/chat_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM_BG] Background message ID: ${message.messageId} | data: ${message.data}');

  try {
    final notification = message.notification;
    String title = notification?.title ?? message.data['title'] ?? message.data['sender_name'] ?? '';
    String body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

    if (title.isEmpty && body.isEmpty) {
      if (message.data['type'] == 'chat') {
        title = message.data['sender_name'] ?? 'Customer 💬';
        body = message.data['message'] ?? 'New chat message received';
      }
    }

    if (title.isNotEmpty || body.isNotEmpty) {
      final localPlugin = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await localPlugin.initialize(settings: const InitializationSettings(android: androidSettings));

      const channel = AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Fuel delivery order status and chat notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await localPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await localPlugin.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_updates',
            'Order Updates',
            channelDescription: 'Fuel delivery order status and chat notifications',
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
  } catch (e) {
    debugPrint('[FCM_BG] Error handling background message: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Load saved locale before app starts
  await LocaleService().loadSavedLocale();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      NotificationService.initialize().catchError((e) {
        debugPrint("Notification service init failed: $e");
      });
    }
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(AppLifecycleManager(child: FuelDirectApp(localeService: LocaleService())));
}

// ─────────────────────────────────────────────────────────────────────────────
// FuelDirectApp — StatefulWidget so we can hold a Stream subscription
// ─────────────────────────────────────────────────────────────────────────────
class FuelDirectApp extends StatefulWidget {
  final LocaleService localeService;
  const FuelDirectApp({super.key, required this.localeService});

  @override
  State<FuelDirectApp> createState() => _FuelDirectAppState();
}

class _FuelDirectAppState extends State<FuelDirectApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
    // Rebuild when locale changes
    widget.localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    widget.localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  /// Global auth state listener.
  /// Sirf MANUAL sign-out par Onboarding par bhejo.
  /// Token refresh / background session events ko IGNORE karo.
  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        debugPrint('[Auth] Event: $event | Session: ${session != null ? "exists" : "null"}');

        if (session != null) {
          final driverId = session.user.id;
          debugPrint('[Auth] Session active — syncing FCM token, NotificationStore & chat listener for $driverId');
          NotificationService.syncToken();
          NotificationStore.instance.syncWithSupabase(driverId);
          NotificationService.startRealtimeMessageListener(driverId);
        }

        if (event == AuthChangeEvent.signedOut) {
          debugPrint('[Auth] signedOut detected — waiting briefly to check for token refresh...');

          // 800ms wait — agar token auto-refresh ho raha tha toh wapis aa jayega
          await Future.delayed(const Duration(milliseconds: 800));

          final recoveredSession = Supabase.instance.client.auth.currentSession;

          if (recoveredSession != null && !recoveredSession.isExpired) {
            // Session wapis aa gaya — ye sirf token refresh tha, driver ko mat hataao
            debugPrint('[Auth] Token refreshed successfully. Driver stays logged in. ✅');
            return;
          }

          // Ab session waqai khatam hai — driver ne khud logout kiya
          debugPrint('[Auth] Manual sign-out confirmed — navigating to onboarding.');
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          }
        }
      },
      onError: (e) => debugPrint('[Auth] Auth stream error: $e'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelDirect',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // ── Localization ──────────────────────────────────────────────────────
      locale: widget.localeService.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ─────────────────────────────────────────────────────────────────────

      theme: ThemeData(
        primaryColor: const Color(0xFFFF4D00),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            // Smooth fade+slide — prevents black flash on back navigation
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/assigned-orders': (context) => const AssignedOrdersScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ChatScreen(
            orderId: args?['orderId'] ?? '',
            customerId: args?['customerId'] ?? '',
            customerName: args?['customerName'] ?? 'Customer',
          );
        },
      },
    );
  }
}
