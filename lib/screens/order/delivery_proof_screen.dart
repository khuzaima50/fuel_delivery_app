import 'package:flutter/material.dart';
import 'meter_verification_screen.dart';
import 'safety_compliance_screen.dart';

class DeliveryProofScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  const DeliveryProofScreen({super.key, this.order});

  @override
  State<DeliveryProofScreen> createState() => _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends State<DeliveryProofScreen> {
  final TextEditingController _gallonsController = TextEditingController();
  final FocusNode _gallonsFocus = FocusNode();
  double _estimatedTotal = 0.00;
  late final double _pricePerGallon;
  String? _meterPhotoUrl;

  @override
  void initState() {
    super.initState();
    // Calculate price per gallon dynamically from original order to maintain rate consistency
    final requestedTotal = double.tryParse(widget.order?['total_amount']?.toString() ?? '') ?? 0.0;
    final requestedQty = double.tryParse((widget.order?['fuel_quantity'] ?? widget.order?['fuel_quantity_gallons'])?.toString() ?? '') ?? 0.0;
    
    if (requestedTotal > 0 && requestedQty > 0) {
      _pricePerGallon = requestedTotal / requestedQty;
    } else {
      _pricePerGallon =
          double.tryParse(widget.order?['price_per_gallon']?.toString() ?? '') ??
          double.tryParse(widget.order?['unit_price']?.toString() ?? '') ??
          4.85;
    }
    _gallonsController.addListener(_calculateTotal);
    _gallonsFocus.addListener(() => setState(() {})); // rebuild on focus change
  }

  @override
  void dispose() {
    _gallonsController.removeListener(_calculateTotal);
    _gallonsController.dispose();
    _gallonsFocus.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final gallons = double.tryParse(_gallonsController.text) ?? 0.0;
    setState(() {
      _estimatedTotal = gallons * _pricePerGallon;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasValue = (double.tryParse(_gallonsController.text) ?? 0.0) > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      resizeToAvoidBottomInset: true,
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
          'Delivery Proof',
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
              const Text(
                'Dispensing Complete',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please capture the following media to document the successful fuel delivery and ensure compliance.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'VISUAL EVIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (context) => MeterVerificationScreen(
                        deliveredGallons: double.tryParse(_gallonsController.text) ?? 0.0,
                        order: widget.order,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _meterPhotoUrl = result;
                    });
                  }
                },
                child: CustomPaint(
                  painter: DashedRectPainter(
                    color: _meterPhotoUrl != null
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFCCCCCC),
                    strokeWidth: 1,
                    gap: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _meterPhotoUrl != null
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                      image: _meterPhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_meterPhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _meterPhotoUrl != null
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Color(0xFF888888),
                                    size: 32,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEEEEEE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_rounded,
                                        color: Color(0xFF888888),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Capture Meter Gauge Photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ensure the final digits are clearly visible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFAAAAAA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'MANUAL ENTRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Gallons Input — direct TextField, no GestureDetector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _gallonsFocus.hasFocus
                        ? const Color(0xFFFF4D00)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gas_meter_rounded,
                      color: hasValue ? const Color(0xFFFF4D00) : const Color(0xFFD0D7DE),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _gallonsController,
                        focusNode: _gallonsFocus,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: hasValue
                              ? const Color(0xFF1F1F1F)
                              : const Color(0xFF888888),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD0D7DE),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      'GALLONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: hasValue ? const Color(0xFF888888) : const Color(0xFFD0D7DE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Estimated Total Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'at \$$_pricePerGallon / gal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CB0C3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${_estimatedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: hasValue ? const Color(0xFFFF4D00) : const Color(0xFFF2F2F2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE8DD)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF4D00),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFFFF4D00),
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Manual entries are flagged for supervisor review. Please ensure the photo matches the entered quantity to avoid payment delays.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF4D00),
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: (_meterPhotoUrl != null && hasValue)
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SafetyComplianceScreen(
                          meterPhotoUrl: _meterPhotoUrl,
                          deliveredGallons: double.tryParse(_gallonsController.text) ?? 0.0,
                          pricePerGallon: _pricePerGallon,
                          order: widget.order,
                        ),
                      ),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please capture meter photo and enter gallons.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: (_meterPhotoUrl != null && hasValue)
                  ? const Color(0xFFFF4D00)
                  : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Complete Order',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
    );

    // Simple dash implementation
    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) => false;
}
