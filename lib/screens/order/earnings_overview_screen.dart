import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../dashboard/dashboard_screen.dart';
import 'earnings_history_screen.dart';
import 'order_details_screen.dart';

class EarningsOverviewScreen extends StatefulWidget {
  const EarningsOverviewScreen({super.key});

  @override
  State<EarningsOverviewScreen> createState() => _EarningsOverviewScreenState();
}

class _EarningsOverviewScreenState extends State<EarningsOverviewScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _ordersFuture = Supabase.instance.client
          .from('orders')
          .select()
          .eq('driver_id', user.id)
          .inFilter('status', ['completed', 'delivered'])
          .order('created_at', ascending: false)
          .then((data) {
            // Sort completed orders — those with completed_at first, then fallback to created_at
            final list = List<Map<String, dynamic>>.from(data);
            list.sort((a, b) {
              final aTime = a['completed_at'] ?? a['created_at'];
              final bTime = b['completed_at'] ?? b['created_at'];
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.toString().compareTo(aTime.toString());
            });
            return list;
          });
    } else {
      _ordersFuture = Future.value([]);
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 18,
              ),
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
        title: const Text(
          'Earnings Overview',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)));
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Double filter: Supabase stream already filters by driver_id,
          // but we also check here to guard against stale/cached data
          final currentUser = Supabase.instance.client.auth.currentUser;
          // Already filtered by status and driver_id in the query.
          // This secondary check guards against any stale/cached data.
          final orders = (snapshot.data ?? []).where((o) {
            final status = o['status']?.toString().toLowerCase();
            if (o['driver_id']?.toString() != currentUser?.id) return false;
            return status == 'completed' || status == 'delivered';
          }).toList();

          double totalEarnings = 0.0;
          double todayEarnings = 0.0;
          // Single 'now' reference used everywhere
          final now = DateTime.now();

          for (var order in orders) {
            final raw = order['driver_earning'] ?? order['total_amount'] ?? '0';
            final amount = double.tryParse(raw.toString()) ?? 0.0;
            totalEarnings += amount;

            // Use completed_at if available, fall back to created_at for "today" check
            final timeField = order['completed_at'] ?? order['created_at'];
            if (timeField != null) {
              try {
                final d = DateTime.parse(timeField.toString()).toLocal();
                if (d.year == now.year && d.month == now.month && d.day == now.day) {
                  todayEarnings += amount;
                }
              } catch (_) {}
            }
          }

          final int deliveries = orders.length;
          // Recent Deliveries = only TODAY's orders
          final List<Map<String, dynamic>> recentOrders = orders.where((o) {
            if (o['completed_at'] == null) return false;
            try {
              final d = DateTime.parse(o['completed_at']).toLocal();
              return d.year == now.year && d.month == now.month && d.day == now.day;
            } catch (_) {
              return false;
            }
          }).take(5).toList();

          // ── Weekly chart data (Mon–Sun of the current week) ──
          final startOfWeek =
              DateTime(now.year, now.month, now.day - (now.weekday - 1)); // Monday midnight
          final Map<int, double> weeklyEarnings = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
          double weeklyTotal = 0.0;

          for (final order in orders) {
            if (order['completed_at'] != null) {
              try {
                final d = DateTime.parse(order['completed_at']).toLocal();
                final orderDay = DateTime(d.year, d.month, d.day);
                final weekEnd = startOfWeek.add(const Duration(days: 7));
                // Check if this order is within current week (Mon to Sun)
                if (!orderDay.isBefore(startOfWeek) && orderDay.isBefore(weekEnd)) {
                  final amount =
                      double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
                  weeklyEarnings[d.weekday] = (weeklyEarnings[d.weekday] ?? 0) + amount;
                  weeklyTotal += amount;
                }
              } catch (_) {}
            }
          }

          // Find max for normalization
          final maxEarning = weeklyEarnings.values.fold(0.0, (a, b) => a > b ? a : b);
          final todayWeekday = now.weekday; // 1=Mon, 7=Sun

          return Column(
            children: [
              // ── Scrollable content ──
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFF4D00),
                  onRefresh: () async {
                    setState(() {
                      _loadOrders();
                    });
                    await _ordersFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Earnings Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'TOTAL EARNINGS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${totalEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 30, color: const Color(0xFFEEEEEE)),
                                Column(
                                  children: [
                                    const Text(
                                      'TODAY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFFF4D00),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${todayEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF4D00),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Weekly Chart Card (Static for visualization)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'WEEKLY PERFORMANCE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${weeklyTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Color(0xFF666666),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'This week',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF666666),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            // Dynamic Bar Chart — current week
                            SizedBox(
                              height: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildDynamicBar('MON', weeklyEarnings[1]!, maxEarning, todayWeekday == 1),
                                  _buildDynamicBar('TUE', weeklyEarnings[2]!, maxEarning, todayWeekday == 2),
                                  _buildDynamicBar('WED', weeklyEarnings[3]!, maxEarning, todayWeekday == 3),
                                  _buildDynamicBar('THU', weeklyEarnings[4]!, maxEarning, todayWeekday == 4),
                                  _buildDynamicBar('FRI', weeklyEarnings[5]!, maxEarning, todayWeekday == 5),
                                  _buildDynamicBar('SAT', weeklyEarnings[6]!, maxEarning, todayWeekday == 6),
                                  _buildDynamicBar('SUN', weeklyEarnings[7]!, maxEarning, todayWeekday == 7),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Summary Stats
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL DELIVERIES',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$deliveries',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Deliveries',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EarningsHistoryScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (recentOrders.isEmpty)
                        const Padding(
                           padding: EdgeInsets.all(20),
                           child: Center(child: Text("No deliveries today yet.", style: TextStyle(color: Colors.grey))),
                        ),

                      ...recentOrders.map((o) => _buildDeliveryItem(o)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                ),
              ),

              // ── Fixed Cash Out Now button at bottom ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested!')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cash Out Now',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
      bottomNavigationBar: const FloatingBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildDynamicBar(
    String label,
    double earnings,
    double maxEarning,
    bool isToday,
  ) {
    const double maxBarHeight = 130.0;
    const double minBarHeight = 6.0;
    final double heightFactor = maxEarning > 0 ? earnings / maxEarning : 0;
    final double barHeight = earnings > 0
        ? (minBarHeight + (maxBarHeight - minBarHeight) * heightFactor)
        : minBarHeight;

    final color = isToday
        ? const Color(0xFFFF4D00)
        : earnings > 0
            ? const Color(0xFFFFB49A)
            : const Color(0xFFF2F2F2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (earnings > 0)
          Text(
            '\$${earnings.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isToday ? const Color(0xFFFF4D00) : const Color(0xFF888888),
            ),
          ),
        if (earnings > 0) const SizedBox(height: 4),
        Container(
          width: 32,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isToday ? const Color(0xFFFF4D00) : const Color(0xFF888888),
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryItem(Map<String, dynamic> order) {
    final fuelQuantity = order['fuel_quantity'] ?? order['fuel_quantity_gallons'] ?? 0;
    final fuelType = order['fuel_type'] ?? 'Fuel';
    final amount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    
    // Format actual completion date/time
    String dateStr = 'Unknown';
    if (order['completed_at'] != null) {
      try {
        final d = DateTime.parse(order['completed_at']).toLocal();
        final now = DateTime.now();
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        final isYesterday = d.year == now.year && d.month == now.month && d.day == now.day - 1;

        final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
        final min = d.minute.toString().padLeft(2, '0');
        final ampm = d.hour >= 12 ? 'PM' : 'AM';
        final timeStr = '${hour.toString().padLeft(2, '0')}:$min $ampm';

        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        if (isToday) {
          dateStr = 'Today, $timeStr';
        } else if (isYesterday) {
          dateStr = 'Yesterday, $timeStr';
        } else {
          dateStr = '${months[d.month - 1]} ${d.day}, $timeStr';
        }
      } catch (_) {
        dateStr = 'Unknown';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFFFF4D00),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    '$fuelType ($fuelQuantity Gal)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
