import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OrderSummaryScreen extends StatelessWidget {
  final DateTime? scheduledDateTime;
  const OrderSummaryScreen({super.key, this.scheduledDateTime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Order Summary',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fuel Details Card
            _buildSummaryCard(
              title: 'Fuel Details',
              icon: Icons.local_gas_station_rounded,
              iconColor: const Color(0xFFFF6600),
              iconBgColor: const Color(0xFFFFECE0),
              children: [
                _buildInfoRow('Fuel Type', 'Regular'),
                _buildInfoRow('Price per Gallon', '\$3.49'),
                _buildInfoRow('Quantity', '15 gallons'),
                const Divider(height: 32),
                _buildInfoRow('Fuel Total', '\$52.35', isBold: true),
              ],
            ),
            const SizedBox(height: 24),
            
            // Delivery Details Card
            _buildSummaryCard(
              title: 'Delivery Details',
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF2F80ED),
              iconBgColor: const Color(0xFFE8F1FF),
              children: [
                _buildDeliveryInfoRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle',
                  value: 'Tesla Model 3',
                  subtitle: 'ABC 1234',
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: 'Home',
                  subtitle: '123 Main Street, San Francisco, CA 94102',
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.access_time_outlined,
                  title: 'Scheduled Time',
                  value: scheduledDateTime != null 
                      ? DateFormat('EEE MMM dd, yyyy · hh:mm a').format(scheduledDateTime!)
                      : 'Not Scheduled',
                  valueColor: scheduledDateTime != null ? const Color(0xFF333333) : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Payment Summary Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.payment_rounded, color: Color(0xFFFF6600), size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Payment Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Fuel Cost', '\$52.35'), // Fixing the split $52 .35 from screenshot to a clean one or matching? Screenshot has $52 and .35 below.
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Total Due Today',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
                      ),
                      Text(
                        '\$52.35',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFFF6600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Method Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'VISA',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '•••• 4242',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          'Default payment',
                          style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Change',
                      style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to place an order')),
                );
                return;
              }

              // Implementation of saving to Supabase
              try {
                final orderData = {
                  'customer_id': user.id,
                  'fuel_type': 'Regular',
                  'fuel_quantity': 15.0,
                  'total_amount': 52.35,
                  'status': 'assigned', // For demo purposes, auto-assigning
                  'scheduled_time': scheduledDateTime?.toIso8601String(),
                  'delivery_address': '123 Main Street, San Francisco, CA 94102',
                  'created_at': DateTime.now().toIso8601String(),
                };

                final response = await Supabase.instance.client
                    .from('orders')
                    .insert(orderData)
                    .select()
                    .single();

                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderTrackingScreen(
                        order: response,
                        deliveryLat: 37.7749, // Dummy for demo
                        deliveryLng: -122.4194,
                        deliveryAddress: orderData['delivery_address'] as String?,
                        fuelInfo: 'Regular · 15 Gallons',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error placing order: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Place Order - \$52.35',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(width: 10),
                Icon(Icons.check, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? const Color(0xFF333333) : const Color(0xFFAAAAAA),
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoRow({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
