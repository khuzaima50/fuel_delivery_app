import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import 'delivery_complete_screen.dart';



class SafetyComplianceScreen extends StatefulWidget {
  final String? meterPhotoUrl;
  final double deliveredGallons;
  final double pricePerGallon;
  final double? computedTotal;   // exact amount shown on DeliveryProofScreen
  final Map<String, dynamic>? order;
  const SafetyComplianceScreen({
    super.key,
    this.meterPhotoUrl,
    this.deliveredGallons = 0.0,
    this.pricePerGallon = 4.85,
    this.computedTotal,
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
  void dispose() {
    super.dispose();
  }

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
                        // ── Confirmation dialog before finalizing ───────────
                        final double previewTotal = widget.computedTotal ??
                            (widget.deliveredGallons * widget.pricePerGallon);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Confirm Delivery',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF1C2733),
                              ),
                            ),
                            content: Text(
                              'Order is \$${previewTotal.toStringAsFixed(2)} = '
                              '${widget.deliveredGallons.toStringAsFixed(2)} gallons. '
                              'Please confirm meter is set to '
                              '${widget.deliveredGallons.toStringAsFixed(2)} gallons.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF444444),
                                height: 1.5,
                              ),
                            ),
                            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF4D00),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text(
                                          'Yes',
                                          style: TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return; // driver tapped Cancel
                        _finalizeDelivery();
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
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Saving…',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : const Text(
                        'Complete Delivery',
                        style: TextStyle(
                          fontSize: 16,
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

  void _navigateToSuccess(Map<String, dynamic> completedOrder) {
    if (!mounted) return;

    final orderId = completedOrder['id']?.toString() ?? '';
    final qty = double.tryParse((completedOrder['fuel_quantity_gallons'] ?? completedOrder['fuel_quantity'])?.toString() ?? '0.0') ?? 0.0;
    final earned = double.tryParse((completedOrder['driver_earning'] ?? completedOrder['total_amount'])?.toString() ?? '0.0') ?? 0.0;
    final fuelType = completedOrder['fuel_type']?.toString() ?? 'Fuel';
    final location = completedOrder['delivery_address']?.toString() ?? 'Customer Location';

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DeliveryCompleteScreen(
          orderId: orderId,
          deliveredGallons: qty,
          totalAmount: earned,
          fuelType: fuelType,
          address: location,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _finalizeDelivery() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isFinalizing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      String? orderId = widget.order?['id']?.toString();
      if (orderId == null) {
        final res = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('driver_id', user.id)
            .inFilter('status', ['assigned', 'emergency'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (res == null) throw Exception('No active order found.');
        orderId = res['id']?.toString();
      }
      if (orderId == null) throw Exception('Order ID could not be determined.');

      final qty = widget.deliveredGallons;
      final unitPrice = double.tryParse(widget.order?['price_per_gallon']?.toString() ?? '') ??
                        double.tryParse(widget.order?['unit_price']?.toString() ?? '') ??
                        widget.pricePerGallon;
      final totalPrice = widget.computedTotal ?? (qty * unitPrice);
      final earningRate = double.tryParse(widget.order?['earning_rate']?.toString() ?? '0.1') ?? 0.1;
      final earned = totalPrice * earningRate;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      // 1. Order Update -> COMPLETED
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'COMPLETED',
            'fuel_quantity': qty,
            'fuel_quantity_gallons': qty,
            'total_amount': totalPrice,
            'driver_earning': earned,
            'completed_at': nowIso,
            'delivered_at': nowIso,
          })
          .eq('id', orderId);

      // 2. Delivery Proofs
      if (widget.meterPhotoUrl != null) {
        try {
          await Supabase.instance.client.from('delivery_proofs').insert({
            'order_id': orderId,
            'photo_url': widget.meterPhotoUrl,
            'proof_type': 'meter_reading',
          });
        } catch (e) {
          debugPrint('[SafetyCompliance] Delivery Proof Insert Error: $e');
        }
      }

      // 3. Safety Checklists
      try {
        await Supabase.instance.client.from('safety_checklists').insert({
          'driver_id': user.id,
          'order_id': orderId,
          'is_parking_brake_set': true,
          'is_engine_off': isFuelCapClosed,
          'no_smoking_or_flames': isNozzleSecured,
        });
      } catch (_) {}

      // 4. Earnings
      try {
        await Supabase.instance.client.from('earnings').insert({
          'driver_id': user.id,
          'order_id': orderId,
          'amount': earned,
          'tip_amount': 0.0,
          'description': 'Earnings from Order $orderId',
          'status': 'COMPLETED',
        });
      } catch (_) {}

      // 5. Notify customer
      final userId = widget.order?['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        try {
          NotificationService.notifyUserOrderCompleted(userId, orderId);
        } catch (_) {}
      }

      NotificationService.showImmediateNotification(
        title: 'Delivery Complete! ✅',
        body: 'Order #${orderId.substring(0, 4).toUpperCase()} confirmed.',
        type: 'order',
        orderId: orderId,
      );

      if (mounted) {
        setState(() => _isFinalizing = false);
        _navigateToSuccess({
          ...(widget.order ?? {}),
          'id': orderId,
          'status': 'COMPLETED',
          'total_amount': totalPrice,
          'driver_earning': earned,
          'fuel_quantity': qty,
          'fuel_quantity_gallons': qty,
          'fuel_type': widget.order?['fuel_type'] ?? 'Fuel',
          'delivery_address': widget.order?['delivery_address'] ?? 'Customer Location',
          'completed_at': nowIso,
          'delivered_at': nowIso,
        });
      }

    } catch (e) {
      debugPrint('[SafetyCompliance] _finalizeDelivery ERROR: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isFinalizing = false);
      }
    }
  }
}

