import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';
import 'services/app_globals.dart';
import 'widgets/app_lifecycle_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/order/assigned_orders_screen.dart';
import 'screens/chat/chat_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    await Firebase.initializeApp();
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Initialize notification service without blocking the main app launch
      NotificationService.initialize().catchError((e) {
        debugPrint("Notification service init failed: $e");
      });
    }
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const AppLifecycleManager(child: FuelDirectApp()));
}

class FuelDirectApp extends StatelessWidget {
  const FuelDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelDirect',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      // Named routes for notification tap navigation (avoids circular imports)
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
