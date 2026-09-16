import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../auth/vehicle_info_screen.dart';
import '../auth/document_verification_screen.dart';
import '../../services/notification_service.dart';
import '../../services/notification_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _resolveRoute);
  }

  Future<void> _resolveRoute() async {
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    // Not logged in → show onboarding
    if (session == null || session.isExpired || user == null) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    // Check role: only drivers and admins can use this app
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = profileData?['role'] as String?;
      if (role != 'driver' && role != 'admin') {
        debugPrint('[Splash] Non-driver role detected: $role — signing out');
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('[Splash] Profile role check error: $e');
    }

    // Logged in → check what step they're on
    unawaited(NotificationService.syncToken());
    NotificationStore.instance.syncWithSupabase(user.id);
    NotificationService.startRealtimeMessageListener(user.id);
    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('is_profile_completed, documents_submitted, vehicle_type')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (driver == null) {
        debugPrint('[Splash] No driver row found — sending to onboarding');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      final docsSubmitted = driver['documents_submitted'] == true;
      final profileCompleted = driver['is_profile_completed'] == true;
      final vehicleAdded = driver['vehicle_type'] != null &&
          (driver['vehicle_type'] as String).isNotEmpty;

      debugPrint('[Splash] docs=$docsSubmitted profile=$profileCompleted vehicle=$vehicleAdded');

      if (!docsSubmitted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DocumentVerificationScreen()),
        );
        return;
      }

      if (!profileCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
        return;
      }

      if (!vehicleAdded) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VehicleInfoScreen()),
        );
        return;
      }

      // ── Profile complete — Go to Dashboard ────────────────────────────────
      // Note: Auto-resume of active orders has been disabled per user request
      // to ensure the app starts fresh each time.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('[Splash] Route resolution error: $e — defaulting to Dashboard');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Image.asset(
                'assets/images/logo_icon.png.jpeg',
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                AppLocalizations.of(context)!.splashTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
