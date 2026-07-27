import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
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
          .inFilter('status', ['completed', 'delivered', 'COMPLETED', 'DELIVERED'])
          .order('created_at', ascending: false)
          .then((data) {
            // Sort completed orders — those with completed_at first, then fallback to created_at
            final list = List<Map<String, dynamic>>.from(data);
            list.sort((a, b) {
              final aTime = a['completed_at'] ?? a['delivered_at'] ?? a['updated_at'] ?? a['created_at'];
              final bTime = b['completed_at'] ?? b['delivered_at'] ?? b['updated_at'] ?? b['created_at'];
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

  String _formatDate(DateTime d, AppLocalizations l10n) {
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $ampm · ${months[d.month - 1]} ${d.day}';
  }

  String _dayLabel(DateTime d, DateTime now, AppLocalizations l10n) {
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(orderDay).inDays;
    if (diff == 0) return l10n.earningsToday;
    if (diff == 1) return l10n.earningsYesterday;
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.historyTitle,
          style: const TextStyle(
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
            return Center(child: Text(l10n.historyError(snapshot.error.toString())));
          }

          final currentUser = Supabase.instance.client.auth.currentUser;
          final now = DateTime.now();

          // Show all of THIS driver's completed/delivered orders
          final orders = (snapshot.data ?? []).where((o) {
            final status = o['status']?.toString().toLowerCase();
            if (o['driver_id']?.toString() != currentUser?.id) return false;
            return status == 'completed' || status == 'delivered';
          }).toList();

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 64, color: Color(0xFFDDDDDD)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.historyNoDeliveries,
                      style: const TextStyle(
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
            final timeField = order['completed_at'] ?? order['delivered_at'] ?? order['updated_at'] ?? order['created_at'];
            if (timeField != null) {
              try {
                var d = DateTime.parse(timeField.toString()).toLocal();
                if (d.isAfter(now)) {
                  d = now;
                }
                final label = _dayLabel(d, now, l10n);
                grouped.putIfAbsent(label, () => []).add(order);
              } catch (_) {}
            }
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
                  final rawEarning = order['driver_earning'] ?? order['total_amount'] ?? '0';
                  final amount = double.tryParse(rawEarning.toString()) ?? 0.0;
                  DateTime? d;
                  final timeField = order['completed_at'] ?? order['delivered_at'] ?? order['updated_at'] ?? order['created_at'];
                  if (timeField != null) {
                    try {
                      var parsedDate = DateTime.parse(timeField.toString()).toLocal();
                      if (parsedDate.isAfter(now)) {
                        parsedDate = now;
                      }
                      d = parsedDate;
                    } catch (_) {}
                  }
                  final timeStr = d != null ? _formatDate(d, l10n) : '—';

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
                        title: l10n.historyFuelQty(fuelType, qty.toString()),
                        subtitle: timeStr,
                        amount: amount,
                        completedLabel: l10n.historyCompleted,
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
    required String completedLabel,
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
              Text(
                completedLabel,
                style: const TextStyle(
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
