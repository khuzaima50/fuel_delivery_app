import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/notification_common.dart';
import '../services/notification_store.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: NotificationStore.instance,
      child: Consumer<NotificationStore>(
        builder: (context, store, _) {
          // Mark all read as soon as the screen opens
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (store.unreadCount > 0) store.markAllRead();
          });

          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1F1F1F), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                if (store.items.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All Notifications'),
                          content: const Text(
                              'This will permanently remove all notifications. Continue?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear All',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) store.clear();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: store.items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: store.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = store.items[index];
                      return _NotifCard(notif: notif);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                color: Color(0xFFFF4D00), size: 38),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You\'ll see order updates & alerts here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final Color accent = notif.type == NotificationType.order
        ? const Color(0xFFFF4D00)
        : notif.type == NotificationType.system
            ? const Color(0xFF2F80ED)
            : const Color(0xFF9B59B6);

    final IconData icon = notif.type == NotificationType.order
        ? Icons.local_shipping_rounded
        : notif.type == NotificationType.system
            ? Icons.info_rounded
            : Icons.campaign_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFF0F0F0)
              : accent.withValues(alpha: 0.3),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notif.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notif.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
