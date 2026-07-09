import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'real_time_delivery_screen.dart';

class FuelPickupScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const FuelPickupScreen({super.key, this.order});

  @override
  State<FuelPickupScreen> createState() => _FuelPickupScreenState();
}

class _FuelPickupScreenState extends State<FuelPickupScreen> {
  final TextEditingController _sealController = TextEditingController();
  bool _isSaving = false;
  DateTime? _arrivedAt;

  @override
  void initState() {
    super.initState();
    _arrivedAt = DateTime.now();
  }

  @override
  void dispose() {
    _sealController.dispose();
    super.dispose();
  }

  String get _arrivedAtStr {
    if (_arrivedAt == null) return 'Now';
    final h = _arrivedAt!.hour;
    final m = _arrivedAt!.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:$m $ampm';
  }

  Future<void> _confirmAndStartTrip() async {
    final sealNum = _sealController.text.trim();
    if (sealNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the tank seal number')),
      );
      return;
    }
    if (sealNum.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seal number must be at least 4 digits')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final orderId = widget.order?['id']?.toString();
      if (orderId != null) {
        // Save seal number and pickup time to orders table
        await Supabase.instance.client.from('orders').update({
          'tank_seal_number': sealNum,
          'pickup_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'IN_PROGRESS',
        }).eq('id', orderId);
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RealTimeDeliveryScreen(order: widget.order),
        ),
      );
    } catch (e) {
      debugPrint('[FuelPickup] save error: $e');
      if (!mounted) return;
      // Even if save fails, allow navigation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RealTimeDeliveryScreen(order: widget.order),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fuelType = widget.order?['fuel_type'] ?? 'Unknown Fuel Type';
    final volume = (widget.order?['fuel_quantity'] ?? widget.order?['fuel_quantity_gallons'])?.toString() ?? '—';
    final orderId = widget.order?['id']?.toString() ?? '—';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

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
                color: Colors.black,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Fuel Pickup',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Depot Verification Card
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
                      children: const [
                        Text(
                          'Depot Verification',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        Text(
                          'In Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF4D00),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Color(0xFFF2F2F2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF4D00),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Arrived at Source: $_arrivedAtStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'ORDER DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Order Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$shortId',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order?['delivery_address'] ?? 'Delivery address not available',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D18F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GEOFENCE CONFIRMED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00D18F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tank Seal Number Input
              const Text(
                'Tank Seal Check Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter numbers only — no letters or special characters.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // Input Field — digits only
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: TextField(
                  controller: _sealController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // only digits allowed
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'e.g. 12345678',
                    hintStyle: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verification ensures the integrity of the fuel cargo during transport.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Fuel Data Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2F2F2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fuel Type',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          fuelType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF2F2F2)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expected Volume',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$volume GAL',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF4D00),
                          ),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TOLERANCE: ±0.5%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB800),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'By clicking confirm, you verify that you have inspected the safety valves and recorded the correct volume.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _confirmAndStartTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFFAA88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_shipping, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Confirm & Start Trip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
