import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_details_screen.dart';

class EarningsHistoryScreen extends StatefulWidget {
  const EarningsHistoryScreen({super.key});

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
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
          .order('completed_at', ascending: false);
    } else {
      _ordersFuture = Future.value([]);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $ampm · ${months[d.month - 1]} ${d.day}';
  }

  String _dayLabel(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(orderDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Delivery History',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF4D00),
        onRefresh: () async {
          setState(() {
            _loadOrders();
          });
          await _ordersFuture;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D00)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final currentUser = Supabase.instance.client.auth.currentUser;
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          // Only show THIS driver's TODAY completed orders
          final orders = (snapshot.data ?? []).where((o) {
            final status = o['status']?.toString().toLowerCase();
            if (o['driver_id']?.toString() != currentUser?.id) return false;
            if (status != 'completed' && status != 'delivered') return false;
            if (o['completed_at'] == null) return false;
            try {
              final d = DateTime.parse(o['completed_at']).toLocal();
              return !d.isBefore(todayStart);
            } catch (_) {
              return false;
            }
          }).toList();

          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Color(0xFFDDDDDD)),
                    SizedBox(height: 16),
                    Text(
                      'No completed deliveries yet.',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }


          // Group orders by day label
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final order in orders) {
            try {
              final d = DateTime.parse(order['completed_at']).toLocal();
              final label = _dayLabel(d, now);
              grouped.putIfAbsent(label, () => []).add(order);
            } catch (_) {}
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: grouped.entries.expand((entry) {
              return [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                ...entry.value.map((order) {
                  final fuelType = order['fuel_type'] ?? 'Fuel';
                  final qty = order['fuel_quantity'] ?? order['fuel_quantity_gallons'] ?? 0;
                  final amount =
                      double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
                  DateTime? d;
                  try {
                    d = DateTime.parse(order['completed_at']).toLocal();
                  } catch (_) {}
                  final timeStr = d != null ? _formatDate(d) : '—';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                      child: _buildDeliveryItem(
                        title: '$fuelType ($qty Gal)',
                        subtitle: timeStr,
                        amount: amount,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ];
            }).toList(),
          );
        },
        ),
      ),
    );
  }

  Widget _buildDeliveryItem({
    required String title,
    required String subtitle,
    required double amount,
  }) {
    return Container(
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
                  title,
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
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
    );
  }
}
