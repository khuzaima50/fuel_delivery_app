import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../services/notification_service.dart';
import '../dashboard/dashboard_screen.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('[NotifsScreen] Loading notifications for user: ${user?.id}');
    
    if (user != null) {
      _notificationsFuture = Supabase.instance.client
          .from('notifications')
          .select()
          .or('driver_id.eq.${user.id},user_id.eq.${user.id}')
          .order('created_at', ascending: false);
      
      _notificationsFuture.then((data) {
        debugPrint('[NotifsScreen] Successfully fetched ${data.length} notifications');
      }).catchError((err) {
        debugPrint('[NotifsScreen] Error fetching notifications: $err');
      });
    } else {
      _notificationsFuture = Future.value([]);
    }
  }


  Future<void> _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('driver_id', user.id)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _loadNotifications();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationsMarkAllReadSuccess)),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.notificationsTitle,
          style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.grey, size: 20),
            onPressed: () async {
              await NotificationService.showImmediateNotification(
                title: 'Test Notification 🛠️',
                body: 'This is a manual test from the debug button.',
                type: 'system',
              );
              _loadNotifications();
            },
          ),
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              AppLocalizations.of(context)!.notificationsMarkRead,
              style: const TextStyle(color: Color(0xFFFF4D00), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],

      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF4D00),
        onRefresh: () async {
          setState(() {
            _loadNotifications();
          });
          await _notificationsFuture;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)));
          }
          final l10n = AppLocalizations.of(context)!;
          if (snapshot.hasError) {
            debugPrint('[NotificationsScreen] Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.common_error,
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadNotifications();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.common_retry),
                  ),
                ],
              ),
            );
          }

          final allNotifications = snapshot.data ?? [];
          
          // Apply filter logic
          final filteredNotifications = allNotifications.where((n) {
            if (_selectedFilter == 'Unread') return n['is_read'] != true;
            if (_selectedFilter == 'Order') return n['type'] == 'order' || (n['title']?.toString().toLowerCase().contains('order') ?? false);
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildFilterChip(l10n.notificationsFilterAll, 'All'),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.notificationsFilterUnread, 'Unread'),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.notificationsFilterOrder, 'Order'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              l10n.notificationsNoFilterNotifications(_selectedFilter.toLowerCase()),
                              style: const TextStyle(color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final n = filteredNotifications[index];
                          final createdAt = n['created_at'] != null 
                              ? DateTime.parse(n['created_at']) 
                              : DateTime.now();
                          
                          return _buildNotificationCard(
                            id: n['id'].toString(),
                            icon: _getIconForType(n['type']),
                            title: n['title'] ?? AppLocalizations.of(context)!.notificationsDefaultTitle,
                            // 'message' is new column; fall back to 'body' for old rows
                            description: n['message'] ?? n['body'] ?? '',
                            time: _timeAgo(createdAt),
                            // treat null is_read as unread
                            isUnread: n['is_read'] != true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
      bottomNavigationBar: const FloatingBottomNavBar(currentIndex: -1),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'order': return Icons.local_gas_station_rounded;
      case 'alert': return Icons.warning_rounded;
      case 'system': return Icons.info_outline_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4D00) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF888888),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isUnread) {
          await Supabase.instance.client
              .from('notifications')
              .update({'is_read': true})
              .eq('id', id);
          if (mounted) {
            setState(() {
              _loadNotifications();
            });
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFFE8DD).withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread ? Border.all(color: const Color(0xFFFFE8DD)) : null,
          boxShadow: [
            if (!isUnread)
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF4D00), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFFFF4D00), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
