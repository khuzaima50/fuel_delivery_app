import 'package:flutter/material.dart';
import '../services/driver_database_service.dart';

/// Wraps the root widget and uses [WidgetsBindingObserver] to track
/// app lifecycle state — foreground, background, and close events —
/// syncing each transition to Supabase via [DriverDatabaseService].
///
/// Usage in main.dart:
///   runApp(const AppLifecycleManager(child: FuelDirectApp()));
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Log the first open — safe to fire-and-forget
    DriverDatabaseService.instance.logDriverAction(action: 'APP_OPENED');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        DriverDatabaseService.instance.logDriverAction(action: 'APP_RESUMED');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // App moved to background (e.g. driver switches apps or locks phone)
        DriverDatabaseService.instance
            .logDriverAction(action: 'APP_BACKGROUNDED');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        DriverDatabaseService.instance.logDriverAction(action: 'APP_CLOSED');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
