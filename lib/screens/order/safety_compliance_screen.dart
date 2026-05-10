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
  bool _awaitingConfirmation = false; // true while waiting for customer to confirm
  String? _pendingOrderId;            // order ID after driver taps "Request Confirmation"
  RealtimeChannel? _orderChannel;
  StreamSubscription? _orderSubscription;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _orderSubscription?.cancel();
    _orderChannel?.unsubscribe();
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
                        'Request Customer Confirmation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Waiting for customer panel ──────────────────────────────────
            if (_awaitingConfirmation)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF8C00),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Waiting for Customer Confirmation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2733),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The customer has been notified. This screen will update automatically once they confirm receipt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pollOnce(_pendingOrderId!),
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF8C00), size: 18),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(
                              color: Color(0xFFFF8C00),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: _cancelWaiting,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  // ── Cancel waiting — reset to pre-confirmation state ──────────────────────
  Future<void> _cancelWaiting() async {
    final orderId = _pendingOrderId;
    _pollTimer?.cancel();
    _orderSubscription?.cancel();
    _orderChannel?.unsubscribe();
    _orderChannel = null;
    _orderSubscription = null;
    if (orderId != null) {
      try {
        await Supabase.instance.client
            .from('orders')
            .update({'status': 'assigned'})
            .eq('id', orderId);
      } catch (e) {
        debugPrint('[SafetyCompliance] Cancel reset failed: $e');
      }
    }
    if (mounted) setState(() => _awaitingConfirmation = false);
  }

  // ── Subscribe to order status changes ──────────────────────────────────────
  Timer? _pollTimer; // fallback poll in case Realtime misses the event

  bool _isDeliveredStatus(String? s) {
    if (s == null) return false;
    final v = s.toUpperCase().trim();
    // We only wait for 'COMPLETED' (or synonyms) from the customer.
    // 'DELIVERED' is the status the driver sets while WAITING for confirmation.
    return v == 'COMPLETED' || v == 'CONFIRMED' || v == 'COMPLETED_BY_CUSTOMER';
  }

  void _listenForCustomerConfirmation(String orderId) {
    _orderChannel?.unsubscribe();
    _orderSubscription?.cancel();
    _pollTimer?.cancel();

    // 1. Realtime Stream (Recommended) - Monitor for COMPLETED status
    _orderSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final status = data.first['status']?.toString().toUpperCase().trim();
        debugPrint('[SafetyCompliance] Realtime Status Sync → $status');
        
        if (status == 'COMPLETED') {
          debugPrint('[SafetyCompliance] Order COMPLETED detected via Stream!');
          _pollTimer?.cancel();
          _orderSubscription?.cancel();
          
          // Stop any local loading spinners
          setState(() {
            _isFinalizing = false;
            _awaitingConfirmation = false;
          });
          
          _completeAfterConfirmation(orderId);
        } else if (_isDeliveredStatus(status)) {
          // Other delivered statuses
          _pollTimer?.cancel();
          _orderSubscription?.cancel();
          _completeAfterConfirmation(orderId);
        }
      }
    });

    // 2. Polling Fallback: poll every 5 seconds as requested
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _pollOnce(orderId);
    });
  }

  // One-shot DB check — navigates if customer already confirmed
  Future<void> _pollOnce(String orderId) async {
    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .maybeSingle();
      debugPrint('[SafetyCompliance] Poll status → ${row?['status']}');
      if (_isDeliveredStatus(row?['status']?.toString()) && mounted) {
        _pollTimer?.cancel();
        _orderSubscription?.cancel();
        _orderChannel?.unsubscribe();
        _completeAfterConfirmation(orderId);
      }
    } catch (e) {
      debugPrint('[SafetyCompliance] Poll error: $e');
    }
  }

  // ── Run all DB writes AFTER customer confirms ───────────────────────────────
  Future<void> _completeAfterConfirmation(String orderId) async {
    if (!mounted) return;
    setState(() => _isFinalizing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final double totalAmount =
          widget.computedTotal ?? (widget.deliveredGallons * widget.pricePerGallon);
      final String nowIso = DateTime.now().toUtc().toIso8601String();

      // Link proof photo
      if (widget.meterPhotoUrl != null) {
        try {
          await Supabase.instance.client.from('delivery_proofs').insert({
            'order_id': orderId,
            'photo_url': widget.meterPhotoUrl,
            'proof_type': 'meter_reading',
          });
        } catch (e) {
          debugPrint('[SafetyCompliance] delivery_proofs insert skipped: $e');
        }
      }

      // Safety checklist log
      try {
        await Supabase.instance.client.from('safety_checklists').insert({
          'driver_id': user.id,
          'order_id': orderId,
          'is_parking_brake_set': true,
          'is_engine_off': isFuelCapClosed,
          'no_smoking_or_flames': isNozzleSecured,
        });
      } catch (e) {
        debugPrint('[SafetyCompliance] safety_checklists insert skipped: $e');
      }

      // Final order update (only timestamps and housekeeping)
      // Prices and Gallons were already saved in _finalizeDelivery.
      try {
        await Supabase.instance.client.from('orders').update({
          'driver_id': user.id,
          'completed_at': nowIso,
          'delivered_at': nowIso,
          'is_delivered': true,
        }).eq('id', orderId);
      } catch (e) {
        debugPrint('[SafetyCompliance] Final metadata update skipped: $e');
      }

      // Notify customer
      final userId = widget.order?['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        NotificationService.notifyUserOrderCompleted(userId, orderId);
      }
      NotificationService.showImmediateNotification(
        title: 'Delivery Complete! ✅',
        body: 'Order #${orderId.substring(0, 4).toUpperCase()} confirmed.',
        type: 'order',
        orderId: orderId,
      );

      // Earnings
      try {
        await Supabase.instance.client.from('earnings').insert({
          'driver_id': user.id,
          'order_id': orderId,
          'amount': totalAmount,
          'tip_amount': 0.0,
          'description': 'Earnings from Order $orderId',
          'status': 'COMPLETED',
        });
      } catch (e) {
        debugPrint('[SafetyCompliance] earnings insert error: $e');
      }

      if (mounted) {
        setState(() => _isFinalizing = false);
        _navigateToSuccess({
          ...(widget.order ?? {}),
          'id': orderId,
          'status': 'COMPLETED',
          'total_amount': totalAmount,
          'driver_earning': totalAmount,
          'fuel_quantity': widget.deliveredGallons,
          'fuel_quantity_gallons': widget.deliveredGallons,
          'fuel_type': widget.order?['fuel_type'] ?? 'Fuel',
          'delivery_address':
              widget.order?['delivery_address'] ?? 'Customer Location',
          'completed_at': nowIso,
          'delivered_at': nowIso,
        });
      }
    } catch (e) {
      debugPrint('[SafetyCompliance] _completeAfterConfirmation ERROR: $e');
      if (mounted) {
        setState(() {
          _isFinalizing = false;
          _awaitingConfirmation = false; // Reset waiting state on error to allow retry
        });
      }
    }
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

  /// Driver taps "Request Customer Confirmation"
  Future<void> _finalizeDelivery() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isFinalizing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      // Resolve order ID
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

      // Set status → 'delivered' so customer sees confirmation prompt in their app.
      // IMPORTANT: Do NOT set 'completed' here — that status is reserved for when
      // the CUSTOMER presses "Submit & Go Home". Setting it here would cause an
      // immediate false-positive in the polling loop.
      final qty = widget.deliveredGallons;
      final unitPrice = double.tryParse(widget.order?['price_per_gallon']?.toString() ?? '') ??
                        double.tryParse(widget.order?['unit_price']?.toString() ?? '') ??
                        widget.pricePerGallon;
      final totalPrice = widget.computedTotal ?? (qty * unitPrice);
      final earningRate = double.tryParse(widget.order?['earning_rate']?.toString() ?? '0.1') ?? 0.1;
      final earned = totalPrice * earningRate;

      // 3. Database Update (Source of Truth)
      // We attempt to save everything, but if it fails, we fall back to just the status.
      // This ensures the delivery flow continues even if some columns are missing in the schema.
      try {
        debugPrint('[SafetyCompliance] Attempting full DB Update: status → DELIVERED for order $orderId');
        await Supabase.instance.client
            .from('orders')
            .update({
              'status': 'DELIVERED',
              'fuel_quantity': qty,
              'fuel_quantity_gallons': qty,
              'total_amount': totalPrice,
              'driver_earning': earned,
              'delivered_at': DateTime.now().toUtc().toIso8601String(),
              'meter_photo_url': widget.meterPhotoUrl,
            })
            .eq('id', orderId);
        debugPrint('[SafetyCompliance] SUCCESS: Full order update complete.');
      } catch (fullError) {
        debugPrint('[SafetyCompliance] Full update failed, trying status-only update: $fullError');
        try {
          await Supabase.instance.client
              .from('orders')
              .update({
                'status': 'DELIVERED',
              })
              .eq('id', orderId);
          debugPrint('[SafetyCompliance] SUCCESS: Status-only update complete.');
        } catch (statusError) {
          debugPrint('[SafetyCompliance] CRITICAL: Status update failed: $statusError');
          // If status update fails, we cannot proceed. Rethrow to show error in UI.
          rethrow;
        }
      }

      // Notify customer to confirm
      final userId = widget.order?['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        try {
          NotificationService.notifyUserAwaitingConfirmation(userId, orderId);
        } catch (_) {}
      }

      _pendingOrderId = orderId;
      if (mounted) {
        setState(() {
          _isFinalizing = false;
          _awaitingConfirmation = true;
        });
        // Start listening for customer confirmation
        _listenForCustomerConfirmation(orderId);
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

