import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';

class OrderSummaryScreen extends StatelessWidget {
  final DateTime? scheduledDateTime;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? deliveryAddress;

  const OrderSummaryScreen({
    super.key,
    this.scheduledDateTime,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.orderSummaryTitle,
          style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fuel Details Card
            _buildSummaryCard(
              title: l10n.orderSummaryFuelDetails,
              icon: Icons.local_gas_station_rounded,
              iconColor: const Color(0xFFFF6600),
              iconBgColor: const Color(0xFFFFECE0),
              children: [
                _buildInfoRow(l10n.orderSummaryFuelType, l10n.orderSummaryRegular),
                _buildInfoRow(l10n.orderSummaryPricePerGallon, l10n.orderSummaryPriceVal('3.49')),
                _buildInfoRow(l10n.orderSummaryQuantity, l10n.orderSummaryQuantityVal('15')),
                const Divider(height: 32),
                _buildInfoRow(l10n.orderSummaryFuelTotal, l10n.orderSummaryFuelTotalVal('52.35'), isBold: true),
              ],
            ),
            const SizedBox(height: 24),
            
            // Delivery Details Card
            _buildSummaryCard(
              title: l10n.orderSummaryDeliveryDetails,
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF2F80ED),
              iconBgColor: const Color(0xFFE8F1FF),
              children: [
                _buildDeliveryInfoRow(
                  icon: Icons.directions_car_outlined,
                  title: l10n.orderSummaryVehicle,
                  value: l10n.orderSummaryPlaceholderVehicle,
                  subtitle: l10n.orderSummaryPlaceholderVehicleSub,
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.location_on_outlined,
                  title: l10n.orderSummaryAddress,
                  value: l10n.orderSummaryPlaceholderAddress,
                  subtitle: l10n.orderSummaryPlaceholderAddressSub,
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.access_time_outlined,
                  title: l10n.orderSummaryScheduledTime,
                  value: scheduledDateTime != null 
                      ? DateFormat('EEE MMM dd, yyyy · hh:mm a').format(scheduledDateTime!)
                      : l10n.orderSummaryNotScheduled,
                  valueColor: scheduledDateTime != null ? const Color(0xFF333333) : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: Color(0xFFFF6600), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.orderSummaryPaymentSummary,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(l10n.orderSummaryFuelCost, l10n.orderSummaryFuelTotalVal('52.35')), // Fixing the split $52 .35 from screenshot to a clean one or matching? Screenshot has $52 and .35 below.
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.orderSummaryTotalDueToday,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
                      ),
                      Text(
                        l10n.orderSummaryFuelTotalVal('52.35'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFFF6600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
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
                      children: [
                        const Text(
                          '•••• 4242',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          l10n.orderSummaryDefaultPayment,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      l10n.orderSummaryChange,
                      style: const TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold),
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
                  SnackBar(content: Text(l10n.orderSummaryLoginRequired)),
                );
                return;
              }

              // Implementation of saving to Supabase
              try {
                final orderData = {
                  'user_id': user.id,
                  'fuel_type': 'Regular',
                  'fuel_quantity': 15.0,
                  'total_amount': 52.35,
                  'status': 'assigned', // For demo purposes, auto-assigning
                  'scheduled_time': scheduledDateTime?.toIso8601String(),
                  'delivery_address': deliveryAddress ?? '123 Innovation Drive, San Francisco, CA 94105',
                  'delivery_lat': deliveryLat ?? 24.8607,
                  'delivery_lng': deliveryLng ?? 67.0011,
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
                        deliveryLat: deliveryLat ?? 24.8607,
                        deliveryLng: deliveryLng ?? 67.0011,
                        deliveryAddress: orderData['delivery_address'] as String?,
                        fuelInfo: 'Regular · 15 Gallons',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.orderSummaryPlaceError(e.toString()))),
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
              children: [
                Text(
                  l10n.orderSummaryPlaceOrderButton('52.35'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.check, size: 20),
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
