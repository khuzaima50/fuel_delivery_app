import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_store.dart';
import '../screens/notifications_screen.dart';

/// Drop-in bell icon for any AppBar.
/// Shows a red badge with the unread count; navigates to NotificationsScreen on tap.
///
/// Usage:
///   AppBar(actions: [const NotificationBell()])
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: NotificationStore.instance,
      child: Consumer<NotificationStore>(
        builder: (context, store, _) {
          final count = store.unreadCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
