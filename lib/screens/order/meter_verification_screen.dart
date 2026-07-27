import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'meter_preview_screen.dart';

class MeterVerificationScreen extends StatefulWidget {
  final double deliveredGallons;
  final Map<String, dynamic>? order;
  const MeterVerificationScreen({super.key, this.deliveredGallons = 0.0, this.order});

  @override
  State<MeterVerificationScreen> createState() =>
      _MeterVerificationScreenState();
}

class _MeterVerificationScreenState extends State<MeterVerificationScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isTakingPicture = false;
  bool _flashOn = false;

  // Keep this widget alive when Android brings the camera activity to foreground
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from the camera preview / system camera UI,
    // the CameraController can become invalid. Re-init it on resume.
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      if (mounted) setState(() => _isReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (!mounted) return; // ← guard after async gap
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (!mounted) return; // ← guard after async gap
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.meterVerificationCameraError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      setState(() => _flashOn = !_flashOn);
      await _controller!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    if (mounted) setState(() => _isTakingPicture = true);

    try {
      // Turn off torch before capturing to avoid overexposure
      if (_flashOn) {
        await _controller!.setFlashMode(FlashMode.auto);
      }

      final XFile image = await _controller!.takePicture();

      // Release the camera BEFORE pushing the preview screen.
      // This prevents Android from killing/restarting the activity due to
      // competing camera resource ownership between Flutter and the OS.
      await _controller?.dispose();
      _controller = null;
      if (mounted) setState(() => _isReady = false);

      if (!mounted) return; // ← guard after async gap
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => MeterPreviewScreen(
            imagePath: image.path,
            deliveredGallons: widget.deliveredGallons,
            order: widget.order,
          ),
        ),
      );

      if (!mounted) return; // ← guard after returning from preview
      if (result != null) {
        Navigator.of(context).pop(result);
      }
      // Camera will be re-initialized by didChangeAppLifecycleState → resumed
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.meterVerificationCaptureFailed),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: _isReady && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4D00),
                      ),
                    ),
                  ),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'METER VERIFICATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _flashOn
                          ? Colors.yellow.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _flashOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        color: _flashOn ? Colors.yellow : Colors.white,
                        size: 22,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Central Capture Area
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    // Grid Lines
                    CustomPaint(painter: GridPainter(), child: Container()),
                    // Corners
                    const Positioned(
                      top: 0,
                      left: 0,
                      child: CornerWidget(quadrant: 1),
                    ),
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: CornerWidget(quadrant: 2),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      child: CornerWidget(quadrant: 3),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CornerWidget(quadrant: 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alignment Instructions
          Positioned(
            bottom: 240,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Align meter display',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ensure digits are clearly visible and legible',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xff2d2d2d),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CornerWidget extends StatelessWidget {
  final int quadrant;
  const CornerWidget({super.key, required this.quadrant});

  @override
  Widget build(BuildContext context) {
    const double length = 32;
    const double thickness = 4;
    const double radius = 8;
    const Color color = Color(0xFFFF4D00);

    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: CornerPainter(
          quadrant: quadrant,
          color: color,
          thickness: thickness,
          radius: radius,
        ),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  final int quadrant;
  final Color color;
  final double thickness;
  final double radius;

  CornerPainter({
    required this.quadrant,
    required this.color,
    required this.thickness,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (quadrant) {
      case 1: // Top Left
        path.moveTo(0, size.height);
        path.lineTo(0, radius);
        path.quadraticBezierTo(0, 0, radius, 0);
        path.lineTo(size.width, 0);
        break;
      case 2: // Top Right
        path.moveTo(0, 0);
        path.lineTo(size.width - radius, 0);
        path.quadraticBezierTo(size.width, 0, size.width, radius);
        path.lineTo(size.width, size.height);
        break;
      case 3: // Bottom Left
        path.moveTo(0, 0);
        path.lineTo(0, size.height - radius);
        path.quadraticBezierTo(0, size.height, radius, size.height);
        path.lineTo(size.width, size.height);
        break;
      case 4: // Bottom Right
        path.moveTo(0, size.height);
        path.lineTo(size.width - radius, size.height);
        path.quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - radius,
        );
        path.lineTo(size.width, 0);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, -20),
      Offset(size.width / 3, size.height + 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, -20),
      Offset(size.width * 2 / 3, size.height + 20),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(-20, size.height / 3),
      Offset(size.width + 20, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(-20, size.height * 2 / 3),
      Offset(size.width + 20, size.height * 2 / 3),
      paint,
    );

    // Middle accent line
    final accentPaint = Paint()
      ..color = const Color(0xFFFF4D00).withValues(alpha: 0.2)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(-20, size.height / 2),
      Offset(size.width + 20, size.height / 2),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
