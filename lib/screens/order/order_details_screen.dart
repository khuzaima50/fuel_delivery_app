import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';
import 'delivery_navigation_screen.dart';


class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late String _customerName;
  late String _customerPhone;

  @override
  void initState() {
    super.initState();
    _customerName = (widget.order['customer_name'] != null &&
            widget.order['customer_name'].toString().trim().isNotEmpty)
        ? widget.order['customer_name'].toString()
        : 'Loading...';
    _customerPhone = widget.order['customer_phone'] ?? '';
    _resolveCustomerInfo();
    // Always re-fetch fresh data for delivered/completed orders to ensure
    // amount, timestamps and status are not stale from the list cache.
    final rawStatus = widget.order['status']?.toString().toLowerCase() ?? '';
    if (rawStatus == 'delivered' || rawStatus == 'completed') {
      _refreshOrderFromDb();
    }
  }

  // Re-fetches the latest order row from Supabase and updates local state.
  Future<void> _refreshOrderFromDb() async {
    final orderId = widget.order['id']?.toString();
    if (orderId == null || orderId.isEmpty) return;
    try {
      final fresh = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();
      if (fresh != null && mounted) {
        // Merge fresh values into widget.order so build() picks them up
        fresh.forEach((k, v) => widget.order[k] = v);
        setState(() {});
      }
    } catch (e) {
      debugPrint('OrderDetails re-fetch error: $e');
    }
  }

  Future<void> _resolveCustomerInfo() async {
    final hasName = widget.order['customer_name'] != null &&
        widget.order['customer_name'].toString().trim().isNotEmpty;
    if (hasName) return; // already have it

    final userId = widget.order['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _customerName = 'Customer');
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone_number, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null && mounted) {
        setState(() {
          _customerName = profile['full_name']?.toString().trim().isNotEmpty == true
              ? profile['full_name'].toString()
              : 'Customer';
          _customerPhone = profile['phone_number']?.toString() ?? _customerPhone;
        });
      } else if (mounted) {
        setState(() => _customerName = 'Customer');
      }
    } catch (e) {
      debugPrint('OrderDetails profile fetch error: $e');
      if (mounted) setState(() => _customerName = 'Customer');
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available.')));
      }
      return;
    }
    final Uri callUri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone dialer.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final String shortId = '#ORD-${order['id'].toString().substring(0, 4).toUpperCase()}';
    final String status = order['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final String address = order['delivery_address'] ?? 'Unknown Location';
    final String fuelType = order['fuel_type'] ?? 'N/A';
    final double? qty = (order['fuel_quantity'] != null
            ? double.tryParse(order['fuel_quantity'].toString())
            : null) ??
        (order['fuel_quantity_gallons'] != null
            ? double.tryParse(order['fuel_quantity_gallons'].toString())
            : null);
    final String quantity = qty != null ? qty.toStringAsFixed(1) : 'N/A';
    final double? customerRating = order['customer_rating'] != null
        ? double.tryParse(order['customer_rating'].toString())
        : null;

    // Check multiple possible keys for the order amount.
    // driver_earning is always written at completion; fall back through other keys.
    final rawAmount = order['driver_earning'] ??
        order['total_amount'] ??
        order['total_price'] ??
        order['price'] ??
        order['amount'];
    final double amountVal = rawAmount != null
        ? (double.tryParse(rawAmount.toString()) ?? 0.0)
        : 0.0;
    final String amount = amountVal > 0 ? amountVal.toStringAsFixed(2) : '0.00';
    final bool isDelivered = status == 'DELIVERED' || status == 'COMPLETED';
    
    // Helper to format timeline dates (MMM dd, hh:mm a)
    String formatTimelineDate(String? isoString) {
      if (isoString == null || isoString.isEmpty) return '--:--';
      try {
        final date = DateTime.parse(isoString).toLocal();
        return DateFormat('MMM dd, hh:mm a').format(date);
      } catch (e) {
        return '--:--';
      }
    }

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
        title: Column(
          children: [
            Text(
              shortId,
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: (status == 'COMPLETED' || status == 'DELIVERED') ? Colors.green : const Color(0xFFFF4D00),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!(status == 'COMPLETED' || status == 'DELIVERED'))
            Padding(
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
                  icon: const Icon(Icons.phone, color: Colors.blueAccent, size: 20),
                  onPressed: () {
                    _makePhoneCall(context, _customerPhone);
                  },
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.person, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _customerName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (customerRating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFB800),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  customerRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFB800),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              _customerPhone.isNotEmpty ? _customerPhone : 'No contact info',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!(status == 'COMPLETED' || status == 'DELIVERED'))
                      GestureDetector(
                        onTap: () {
                          final userId = order['user_id']?.toString();
                          if (userId != null && userId.isNotEmpty) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (c) => ChatScreen(
                                orderId: order['id'].toString(),
                                customerId: userId,
                                customerName: _customerName,
                              ),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer information not available for chat.')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Type and Quantity Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'TYPE',
                      fuelType.split(' ').first,
                      fuelType,
                      Icons.directions_car,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      'QUANTITY',
                      quantity,
                      'Gallons',
                      Icons.local_gas_station,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Total Expected Earnings or Cost
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ORDER TOTAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      // For delivered/completed orders: never show 'Pending'.
                      // Show the amount if available, otherwise 'Completed ✓'.
                      isDelivered
                          ? (amountVal > 0 ? '\$$amount' : 'Completed ✓')
                          : (amountVal > 0 ? '\$$amount' : 'Pending'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDelivered
                            ? (amountVal > 0 ? const Color(0xFFFF4D00) : Colors.green)
                            : (amountVal > 0 ? const Color(0xFFFF4D00) : const Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Delivery Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DELIVERY LOCATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF888888),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!(status == 'COMPLETED' || status == 'DELIVERED'))
                          GestureDetector(
                            onTap: () async {
                              // Extract real customer coordinates
                              double? lat = double.tryParse(
                                  (order['customer_lat'] ?? order['delivery_lat'])?.toString() ?? '');
                              double? lng = double.tryParse(
                                  (order['customer_lng'] ?? order['delivery_lng'])?.toString() ?? '');
                              if (lat == 0.0) lat = null;
                              if (lng == 0.0) lng = null;

                              // Try to open in Google Maps first if coordinates exist
                              if (lat != null && lng != null) {
                                final mapUrl = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                                );
                                if (await canLaunchUrl(mapUrl)) {
                                  await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
                                  return;
                                }
                              }

                              // Fallback: open the in-app DeliveryNavigationScreen
                              if (status == 'ACCEPTED' || status == 'ASSIGNED') {
                                await Supabase.instance.client.from('orders').update({
                                  'status': 'in_progress',
                                  'accepted_at': DateTime.now().toUtc().toIso8601String(),
                                  'driver_id': Supabase.instance.client.auth.currentUser?.id,
                                }).eq('id', order['id']);
                                widget.order['status'] = 'in_progress';
                                if (context.mounted) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (c) => DeliveryNavigationScreen(order: order)));
                                }
                              }
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Navigate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF4D00),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.explore,
                                  color: Color(0xFFFF4D00),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Order Timeline Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER TIMELINE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      'Order Placed',
                      formatTimelineDate(order['created_at']),
                      Icons.receipt_long,
                      const Color(0xFF2196F3),
                    ),
                    _buildTimelineItem(
                      'Order Accepted',
                      formatTimelineDate(order['accepted_at']),
                      Icons.check_circle_outline,
                      order['accepted_at'] != null ? const Color(0xFF4CAF50) : Colors.grey,
                    ),
                    _buildTimelineItem(
                      'Driver Arrived',
                      formatTimelineDate(order['arrived_at']),
                      Icons.location_on,
                      order['arrived_at'] != null ? const Color(0xFFFFB800) : Colors.grey,
                    ),
                    _buildTimelineItem(
                      'Order Completed',
                      formatTimelineDate(order['completed_at'] ?? order['delivered_at']),
                      Icons.flag_outlined,
                      (order['completed_at'] != null || order['delivered_at'] != null) ? const Color(0xFFFF4900) : Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (status == 'COMPLETED' || status == 'DELIVERED')
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update order status to in_progress / en route
                      if (order['status'] == 'accepted') {
                        await Supabase.instance.client.from('orders').update({
                          'status': 'in_progress',
                          'accepted_at': DateTime.now().toUtc().toIso8601String(),
                          'driver_id': Supabase.instance.client.auth.currentUser?.id,
                        }).eq('id', order['id']);
                        widget.order['status'] = 'in_progress';

                        // Notify customer: delivery has started
                        final userId = order['user_id']?.toString();
                        if (userId != null && userId.isNotEmpty) {
                          NotificationService.notifyUserDeliveryStarted(
                              userId, order['id'].toString());
                        }

                        // Trigger Local Notification for Driver
                        NotificationService.showImmediateNotification(
                          title: 'Delivery Journey Started! 🚀',
                          body: 'Heading to source location for pickup.',
                          type: 'order',
                          orderId: order['id']?.toString(),
                        );
                      }

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DeliveryNavigationScreen(order: widget.order),
                          ),
                        );
                      }
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
                      'Start Delivery Journey',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFFFF4D00), size: 24),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
