import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Future<List<Map<String, dynamic>>> _ordersHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _ordersHistoryFuture = Future.value([]);
      return;
    }
    _ordersHistoryFuture = Supabase.instance.client
        .from('orders')
        .select()
        .eq('driver_id', user.id)
        .inFilter('status', ['completed', 'delivered', 'COMPLETED', 'DELIVERED'])
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          l10n.orderHistoryTitle,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Color(0xFFAAAAAA)),
                  hintText: l10n.orderHistorySearchHint,
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF4D00),
              onRefresh: () async {
                setState(() {
                  _loadHistory();
                });
                await _ordersHistoryFuture;
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _ordersHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.orderHistoryError(snapshot.error.toString())));
                }

                final currentUser = Supabase.instance.client.auth.currentUser;
                final List<Map<String, dynamic>> allHistory = (snapshot.data ?? []).where((order) {
                  final matchesUser = order['driver_id'] == currentUser?.id;
                  final status = order['status']?.toString().toLowerCase();
                  final isCompleted = status == 'completed' || status == 'delivered';
                  if (!matchesUser || !isCompleted) return false;
                  
                  if (_searchQuery.isEmpty) return true;
                  final address = (order['delivery_address'] ?? '').toString().toLowerCase();
                  return address.contains(_searchQuery.toLowerCase());
                }).toList();

                if (allHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.orderHistoryNoOrders,
                          style: const TextStyle(color: Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: allHistory.length,
                  itemBuilder: (context, index) {
                    final order = allHistory[index];
                    
                    final rawTime = order['completed_at'] ?? order['delivered_at'] ?? order['updated_at'] ?? order['created_at'];
                    final now = DateTime.now();
                    var completedAt = rawTime != null 
                        ? DateTime.parse(rawTime.toString()).toLocal()
                        : now;
                    if (completedAt.isAfter(now)) {
                      completedAt = now;
                    }
                    
                    final fuelType = order['fuel_type']?.toString() ?? l10n.orderHistoryPlaceholderFuel;
                    final qty = (order['fuel_quantity'] ?? order['fuel_quantity_gallons'] ?? '0').toString();

                    return _buildOrderCard(
                      date: '${_getMonthName(completedAt.month, l10n)} ${completedAt.day}, ${completedAt.year} • ${_formatTime(completedAt)}',
                      vehicle: l10n.orderHistoryCardQty(fuelType, qty),
                      price: '\$${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                      address: order['delivery_address'] ?? 'Unknown Location',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ),
          ),
          const SizedBox(height: 100), // Space for floating bar
        ],
      ),
      bottomNavigationBar: const FloatingBottomNavBar(currentIndex: 3), 
    );
  }

  String _getMonthName(int month, AppLocalizations l10n) {
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildOrderCard({
    required String date,
    required String vehicle,
    required String price,
    required String address,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F5)),
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
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFFFF4D00), size: 28),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFFF4D00),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
