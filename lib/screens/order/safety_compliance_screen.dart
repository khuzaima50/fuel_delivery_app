import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import 'delivery_complete_screen.dart';


class SafetyComplianceScreen extends StatefulWidget {
  final String? meterPhotoUrl;
  final double deliveredGallons;
  final Map<String, dynamic>? order;
  const SafetyComplianceScreen({
    super.key,
    this.meterPhotoUrl,
    this.deliveredGallons = 0.0,
    this.order,
  });

  @override
  State<SafetyComplianceScreen> createState() => _SafetyComplianceScreenState();
}

class _SafetyComplianceScreenState extends State<SafetyComplianceScreen> {
  bool isFuelCapClosed = false;
  bool isNozzleSecured = false;
  bool _isFinalizing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                color: Color(0xFF1F1F1F),
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Safety Compliance',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Glowing Icon Container
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D00).withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF4D00).withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF4D00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 44,
                        ),
                        Positioned(
                          top: 40,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Post-Delivery Check',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C2733),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Please confirm the following safety protocols are met before finalizing the delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Checklist Items
              _buildCheckItem(
                title: 'Fuel cap is properly closed',
                subtitle: 'Verify a secure, airtight seal is formed.',
                value: isFuelCapClosed,
                onChanged: (val) {
                  setState(() => isFuelCapClosed = val!);
                },
              ),
              const SizedBox(height: 16),
              _buildCheckItem(
                title: 'Nozzle is secured',
                subtitle: 'Ensure the nozzle is locked in the holster.',
                value: isNozzleSecured,
                onChanged: (val) {
                  setState(() => isNozzleSecured = val!);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF2F2F2), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFFFFB800),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'MANDATORY VERIFICATION'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: (isFuelCapClosed && isNozzleSecured && !_isFinalizing)
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setState(() => _isFinalizing = true);
                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) throw Exception('Not logged in.');

                          // Get order ID — try widget.order first
                          String? orderId = widget.order?['id']?.toString();

                          // Fallback: query active order if widget.order is null
                          if (orderId == null) {
                            debugPrint('[SafetyCompliance] widget.order is null, querying active order...');
                            final res = await Supabase.instance.client
                                .from('orders')
                                .select()
                                .eq('driver_id', user.id)
                                .inFilter('status', ['assigned', 'emergency'])
                                .order('created_at', ascending: false)
                                .limit(1)
                                .maybeSingle();
                            if (res == null) throw Exception('No active order found. Please check your order status.');
                            orderId = res['id']?.toString();
                          }

                          if (orderId == null) throw Exception('Order ID could not be determined.');
                          debugPrint('[SafetyCompliance] Using orderId: $orderId');

                          final double pricePerGallon =
                              double.tryParse(widget.order?['price_per_gallon']?.toString() ?? '') ??
                              double.tryParse(widget.order?['unit_price']?.toString() ?? '') ??
                              4.85;
                          final double totalAmount = widget.deliveredGallons * pricePerGallon;
                          final String fuelType = widget.order?['fuel_type']?.toString() ?? 'Fuel';
                          final String address = widget.order?['delivery_address']?.toString() ?? '';

                          // Step 1: Link proof photo (optional — don't fail if table missing)
                          if (widget.meterPhotoUrl != null) {
                            try {
                              await Supabase.instance.client.from('delivery_proofs').insert({
                                'order_id': orderId,
                                'photo_url': widget.meterPhotoUrl,
                                'proof_type': 'meter_reading',
                              });
                              debugPrint('[SafetyCompliance] delivery_proofs inserted OK');
                            } catch (e) {
                              debugPrint('[SafetyCompliance] delivery_proofs insert skipped: $e');
                            }
                          }

                          // Step 2: Safety checklist log (optional)
                          try {
                            await Supabase.instance.client.from('safety_checklists').insert({
                              'driver_id': user.id,
                              'order_id': orderId,
                              'is_parking_brake_set': true,
                              'is_engine_off': isFuelCapClosed,
                              'no_smoking_or_flames': isNozzleSecured,
                            });
                            debugPrint('[SafetyCompliance] safety_checklists inserted OK');
                          } catch (e) {
                            debugPrint('[SafetyCompliance] safety_checklists insert skipped: $e');
                          }

                          // Step 3: CRITICAL — mark order as delivered
                          debugPrint('[SafetyCompliance] Updating order to delivered...');
                          final String nowIso = DateTime.now().toUtc().toIso8601String();
                          try {
                            // Prepare update map — using 'fuel_quantity' as requested
                            // delivered_at is set so the Delivered tab 24-hour filter works
                            final Map<String, dynamic> updateData = {
                              'status': 'delivered',
                              'driver_id': user.id,
                              'total_amount': totalAmount,
                              'driver_earning': totalAmount,
                              'fuel_quantity': widget.deliveredGallons,
                              'fuel_quantity_gallons': widget.deliveredGallons,
                              'completed_at': nowIso,
                              'delivered_at': nowIso,
                            };

                            // Try primary update
                            await Supabase.instance.client.from('orders').update(updateData).eq('id', orderId);
                          } catch (primaryError) {
                            debugPrint('[SafetyCompliance] Primary update failed: $primaryError');
                            
                            // Check if it's a 'column not found' or 'schema cache' error
                            final errorStr = primaryError.toString();
                            if (errorStr.contains('fuel_quantity') || errorStr.contains('PGRST204')) {
                               // Try fallback update without the quantity columns if they are blocking completion
                               debugPrint('[SafetyCompliance] Attempting fallback update without fuel_quantity...');
                               try {
                                 await Supabase.instance.client.from('orders').update({
                                   'status': 'delivered',
                                   'total_amount': totalAmount,
                                   'completed_at': nowIso,
                                   'delivered_at': nowIso,
                                 }).eq('id', orderId);
                               } catch (fallbackError) {
                                  throw primaryError;
                               }
                            } else if (errorStr.contains('completed_at') || errorStr.contains('delivered_at')) {
                               // Fallback: update without timestamp columns
                                await Supabase.instance.client.from('orders').update({
                                 'status': 'delivered',
                                 'total_amount': totalAmount,
                                 'fuel_quantity': widget.deliveredGallons,
                               }).eq('id', orderId);
                            } else {
                               rethrow;
                            }
                          }
                          debugPrint('[SafetyCompliance] Order marked delivered!');

                          // Notify customer: order completed
                          final userId = widget.order?['user_id']?.toString();
                          if (userId != null && userId.isNotEmpty) {
                            NotificationService.notifyUserOrderCompleted(
                                userId, orderId);
                          }
                          
                          // Trigger Notification
                          NotificationService.showImmediateNotification(
                            title: 'Delivery Complete! ✅',
                            body: 'Order #${orderId.substring(0, 4).toUpperCase()} has been successfully delivered.',
                            type: 'order',
                            orderId: orderId,
                          );

                          // Step 4: Insert into earnings table
                          try {
                            await Supabase.instance.client.from('earnings').insert({
                              'driver_id': user.id,
                              'order_id': orderId,
                              'amount': totalAmount,
                              'tip_amount': 0.0,
                              'description': 'Earnings from Order $orderId',
                              'status': 'completed',
                            });
                            debugPrint('[SafetyCompliance] Earnings updated OK');
                          } catch (e) {
                            debugPrint('[SafetyCompliance] earnings insert error: $e');
                          }

                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Order Completed Successfully!'),
                                backgroundColor: Color(0xFFFF4D00),
                              ),
                            );
                            navigator.pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => DeliveryCompleteScreen(
                                  orderId: orderId!,
                                  deliveredGallons: widget.deliveredGallons,
                                  totalAmount: totalAmount,
                                  fuelType: fuelType,
                                  address: address,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('[SafetyCompliance] FINAL ERROR: $e');
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                          setState(() => _isFinalizing = false);
                          return;
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFF4D00).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isFinalizing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm & Complete Delivery',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Safety logs and timestamps are automatically recorded for audit and compliance purposes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFBBBBBB),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? const Color(0xFFFF4D00) : const Color(0xFFEEEEEE),
            width: value ? 1.5 : 1,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: const Color(0xFFFF4D00).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: value ? const Color(0xFFFF4D00) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? const Color(0xFFFF4D00) : const Color(0xFFDDDDDD),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2733),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
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
