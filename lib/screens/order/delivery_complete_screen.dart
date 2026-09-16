import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../dashboard/dashboard_screen.dart';

class DeliveryCompleteScreen extends StatelessWidget {
  final String orderId;
  final double deliveredGallons;
  final double totalAmount;
  final double driverEarning;
  final String fuelType;
  final String address;

  const DeliveryCompleteScreen({
    super.key,
    required this.orderId,
    required this.deliveredGallons,
    required this.totalAmount,
    required this.driverEarning,
    this.fuelType = 'Regular',
    this.address = 'Customer Location',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
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
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ),
          title: const Text(
            'Confirmation',
            style: TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
  
              // Success Icon (Scalloped Circle)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: ScallopedCirclePainter(),
                    ),
                    const Icon(Icons.check, color: Colors.white, size: 50),
                  ],
                ),
              ),
  
              const SizedBox(height: 32),
  
              const Text(
                'Delivery Successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${orderId.toString().substring(0, 8).toUpperCase()} has been finalized',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
  
              const SizedBox(height: 48),
  
              // Delivery Summary Card
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Quantity', '${deliveredGallons.toStringAsFixed(2)} Gal'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Fuel Type', fuelType),
                      const SizedBox(height: 16),
                      _buildInfoRow('Location', address),
                    ],
                  ),
                ),
              ),
  
              const Spacer(),
  
              // Ready for Next Task Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
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
                    'Ready for Next Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F1F1F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class ScallopedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4D00)
      ..style = PaintingStyle.fill;

    final path = Path();
    final int points = 40;
    final double innerRadius = size.width / 2;
    final double outerRadius = innerRadius + 6;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    for (int i = 0; i < points * 2; i++) {
      final double radius = i % 2 == 0 ? outerRadius : innerRadius;
      final double angle = (i * math.pi) / points;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
