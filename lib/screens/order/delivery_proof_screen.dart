import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Photo state
  File? _localImage;         // shown as preview immediately
  String? _meterPhotoUrl;    // Supabase Storage public URL (set after upload)
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // ── Resolve price per gallon ───────────────────────────────────────────
    final requestedTotal =
        double.tryParse(widget.order?['total_amount']?.toString() ?? '') ?? 0.0;
    final requestedQty = double.tryParse(
          (widget.order?['fuel_quantity'] ??
                  widget.order?['fuel_quantity_gallons'])
              ?.toString() ??
              '',
        ) ??
        0.0;

    if (requestedTotal > 0 && requestedQty > 0) {
      _pricePerGallon =
          double.parse((requestedTotal / requestedQty).toStringAsFixed(4));
    } else {
      _pricePerGallon =
          double.tryParse(widget.order?['price_per_gallon']?.toString() ?? '') ??
          double.tryParse(widget.order?['unit_price']?.toString() ?? '') ??
          4.85;
    }

    _gallonsController.addListener(_calculateTotal);
    _gallonsFocus.addListener(() => setState(() {}));
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

  // ── Take photo → upload → set URL ────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return; // driver cancelled

      final file = File(picked.path);
      setState(() {
        _localImage = file;   // show preview immediately
        _meterPhotoUrl = null; // reset old URL while we upload
        _isUploading = true;
      });

      // Upload to Supabase Storage bucket "delivery-proofs"
      final fileExt = picked.path.split('.').last;
      final fileName =
          'meter_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'meter_readings/$fileName';

      await Supabase.instance.client.storage
          .from('delivery-proofs')
          .upload(storagePath, file);

      final publicUrl = Supabase.instance.client.storage
          .from('delivery-proofs')
          .getPublicUrl(storagePath);

      if (mounted) {
        setState(() {
          _meterPhotoUrl = publicUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully ✅'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DeliveryProof] Upload error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().split(']').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = (double.tryParse(_gallonsController.text) ?? 0.0) > 0;
    final bool photoReady = _meterPhotoUrl != null && !_isUploading;
    final bool canProceed = photoReady && hasValue;

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
                'Capture the fuel meter and enter the delivered gallons to complete the order.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // ── Section label ──────────────────────────────────────────
              const Text(
                'METER GAUGE PHOTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── Photo capture widget ───────────────────────────────────
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadPhoto,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _localImage != null
                        ? Colors.black
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: photoReady
                          ? const Color(0xFF4CAF50)
                          : _localImage != null
                              ? const Color(0xFFFF4D00)
                              : const Color(0xFFDDDDDD),
                      width: photoReady ? 2 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _buildPhotoWidget(photoReady),
                ),
              ),
              const SizedBox(height: 8),

              // Retake button (shows after a photo is taken)
              if (_localImage != null && !_isUploading)
                TextButton.icon(
                  onPressed: _pickAndUploadPhoto,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: Color(0xFFFF4D00)),
                  label: const Text(
                    'Retake Photo',
                    style: TextStyle(
                      color: Color(0xFFFF4D00),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Manual Entry label ─────────────────────────────────────
              const Text(
                'MANUAL ENTRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── Gallons input ──────────────────────────────────────────
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
                      color: hasValue
                          ? const Color(0xFFFF4D00)
                          : const Color(0xFFD0D7DE),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                        color: hasValue
                            ? const Color(0xFF888888)
                            : const Color(0xFFD0D7DE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Estimated Total card ───────────────────────────────────
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
                          'at \$${_pricePerGallon.toStringAsFixed(2)} / gal',
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
                        color: hasValue
                            ? const Color(0xFFFF4D00)
                            : const Color(0xFFF2F2F2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Required steps checklist ───────────────────────────────
              _buildRequirementRow(
                done: photoReady,
                loading: _isUploading,
                label: photoReady
                    ? 'Meter photo uploaded'
                    : _isUploading
                        ? 'Uploading photo…'
                        : 'Take meter gauge photo (required)',
              ),
              const SizedBox(height: 8),
              _buildRequirementRow(
                done: hasValue,
                label: hasValue
                    ? 'Gallons entered: ${_gallonsController.text}'
                    : 'Enter delivered gallons (required)',
              ),
              const SizedBox(height: 24),

              // ── Compliance note ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE8DD)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFFF4D00),
                      size: 16,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manual entries are flagged for supervisor review. Ensure the photo clearly shows the meter digits matching the entered quantity.',
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
            onPressed: canProceed
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SafetyComplianceScreen(
                          meterPhotoUrl: _meterPhotoUrl,
                          deliveredGallons:
                              double.tryParse(_gallonsController.text) ?? 0.0,
                          pricePerGallon: _pricePerGallon,
                          computedTotal: _estimatedTotal,
                          order: widget.order,
                        ),
                      ),
                    );
                  }
                : () {
                    final msg = _isUploading
                        ? 'Please wait for the photo to finish uploading.'
                        : !photoReady
                            ? 'Please take a photo of the fuel meter first.'
                            : 'Please enter the delivered gallons.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canProceed ? const Color(0xFFFF4D00) : const Color(0xFFCCCCCC),
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

  // ── Photo area widget ────────────────────────────────────────────────────
  Widget _buildPhotoWidget(bool photoReady) {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF4D00)),
            SizedBox(height: 16),
            Text(
              'Uploading…',
              style: TextStyle(
                color: Color(0xFFFF4D00),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_localImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_localImage!, fit: BoxFit.cover),
          // Green overlay when upload done
          if (photoReady)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50),
                      size: 52,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Photo Saved',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Empty state
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.camera_alt_rounded,
          color: Color(0xFFAAAAAA),
          size: 40,
        ),
        SizedBox(height: 12),
        Text(
          'Tap to take meter photo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF888888),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Ensure the final digits are clearly visible',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Requirement row ──────────────────────────────────────────────────────
  Widget _buildRequirementRow({
    required bool done,
    required String label,
    bool loading = false,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? const Color(0xFF4CAF50)
                : loading
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFEEEEEE),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  done ? Icons.check : Icons.circle_outlined,
                  size: 14,
                  color: done ? Colors.white : const Color(0xFFCCCCCC),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: done
                  ? const Color(0xFF4CAF50)
                  : loading
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashed border painter (kept for any other usages) ──────────────────────
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
