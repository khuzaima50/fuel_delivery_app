import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'safety_compliance_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeliveryProofScreen — main screen (image_picker REMOVED)
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryProofScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  const DeliveryProofScreen({super.key, this.order});
  @override
  State<DeliveryProofScreen> createState() => _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends State<DeliveryProofScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _gallonsController = TextEditingController();
  final FocusNode _gallonsFocus = FocusNode();
  double _estimatedTotal = 0.00;
  late final double _pricePerGallon;

  // Photo state
  File? _localImage;
  String? _meterPhotoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() => _estimatedTotal = gallons * _pricePerGallon);
  }

  // ── Open in-app camera, get back a File, then upload ────────────────────
  Future<void> _openCameraAndUpload() async {
    // Navigate to in-app camera — returns File path or null
    final String? imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _InAppCameraScreen(),
      ),
    );

    // Strict null guard
    if (imagePath == null || imagePath.isEmpty) return;

    final file = File(imagePath);
    // Verify file actually exists before using it to prevent red screen
    if (!file.existsSync()) return;

    // State protection
    if (!mounted) return;

    setState(() {
      _localImage = file;
      _meterPhotoUrl = null;
      _isUploading = true;
    });

    try {
      final fileExt = imagePath.split('.').last;
      final fileName = 'meter_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'meter_readings/$fileName';

      await Supabase.instance.client.storage
          .from('delivery-proofs')
          .upload(storagePath, file);

      if (!mounted) return;

      final publicUrl = Supabase.instance.client.storage
          .from('delivery-proofs')
          .getPublicUrl(storagePath);

      setState(() {
        _meterPhotoUrl = publicUrl;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.proofPhotoUploaded),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('[DeliveryProof] Upload error: $e');
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.proofUploadFailed(e.toString().split(']').last)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
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
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.proofTitle,
          style: const TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.proofDispensingComplete,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              Text(
                l10n.proofDispensingCompleteDesc,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    height: 1.5,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Text(l10n.proofMeterGaugePhoto,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),

              // ── Photo capture widget ──────────────────────────────────
              GestureDetector(
                onTap: _isUploading ? null : _openCameraAndUpload,
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
              if (_localImage != null && !_isUploading)
                TextButton.icon(
                  onPressed: _openCameraAndUpload,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: Color(0xFFFF4D00)),
                  label: Text(l10n.proofRetakePhoto,
                      style: const TextStyle(
                          color: Color(0xFFFF4D00),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              const SizedBox(height: 20),
              Text(l10n.proofManualEntry,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),

              // ── Gallons input ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                    Icon(Icons.gas_meter_rounded,
                        color: hasValue
                            ? const Color(0xFFFF4D00)
                            : const Color(0xFFD0D7DE),
                        size: 24),
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
                                : const Color(0xFF888888)),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD0D7DE)),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(l10n.proofGallons,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: hasValue
                                ? const Color(0xFF888888)
                                : const Color(0xFFD0D7DE))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Estimated Total ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFEEEEEE))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.proofEstimatedTotal,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF555555))),
                        const SizedBox(height: 4),
                        Text(
                            l10n.proofPricePerGal(_pricePerGallon.toStringAsFixed(2)),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CB0C3),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('\$${_estimatedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: hasValue
                                ? const Color(0xFFFF4D00)
                                : const Color(0xFFF2F2F2))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildRequirementRow(
                done: photoReady,
                loading: _isUploading,
                label: photoReady
                    ? l10n.proofMeterPhotoUploaded
                    : _isUploading
                        ? l10n.proofUploadingPhoto
                        : l10n.proofTakeMeterPhoto,
              ),
              const SizedBox(height: 8),
              _buildRequirementRow(
                done: hasValue,
                label: hasValue
                    ? l10n.proofGallonsEntered(_gallonsController.text)
                    : l10n.proofEnterGallons,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFFE8DD))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFF4D00), size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.proofSupervisorReviewDesc,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF4D00),
                            height: 1.5,
                            fontWeight: FontWeight.w600),
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
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SafetyComplianceScreen(
                          meterPhotoUrl: _meterPhotoUrl,
                          deliveredGallons:
                              double.tryParse(_gallonsController.text) ?? 0.0,
                          pricePerGallon: _pricePerGallon,
                          computedTotal: _estimatedTotal,
                          order: widget.order,
                        ),
                      ),
                    )
                : () {
                    final msg = _isUploading
                        ? l10n.proofWaitUpload
                        : !photoReady
                            ? l10n.proofTakePhotoFirst
                            : l10n.proofEnterGallonsFirst;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed
                  ? const Color(0xFFFF4D00)
                  : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.proofCompleteOrder,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(bool photoReady) {
    final l10n = AppLocalizations.of(context)!;
    if (_localImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _localImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(l10n.proofWaitingImage, style: const TextStyle(color: Color(0xFF888888))),
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(l10n.proofUploadingPhoto,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            )
          else if (photoReady)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 52),
                    const SizedBox(height: 8),
                    Text(l10n.proofPhotoSaved,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF4D00)),
            const SizedBox(height: 16),
            Text(l10n.proofWaitingImage,
                style: const TextStyle(
                    color: Color(0xFFFF4D00),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_rounded, color: Color(0xFFAAAAAA), size: 40),
        const SizedBox(height: 12),
        Text(l10n.proofTapToTakePhoto,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888))),
        const SizedBox(height: 6),
        Text(l10n.proofDigitsVisible,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

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
              : Icon(done ? Icons.check : Icons.circle_outlined,
                  size: 14,
                  color: done ? Colors.white : const Color(0xFFCCCCCC)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: done
                      ? const Color(0xFF4CAF50)
                      : loading
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF888888))),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InAppCameraScreen — full-screen in-app camera, no external intent.
// Pops with the captured image path (String) or null if cancelled.
// ─────────────────────────────────────────────────────────────────────────────
class _InAppCameraScreen extends StatefulWidget {
  const _InAppCameraScreen();
  @override
  State<_InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<_InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isReady = false;
  bool _isTakingPicture = false;
  bool _isPopping = false; // True once we are navigating away — blocks any further build/setState
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[CAMERA_DEBUG] initState called');
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[CAMERA_DEBUG] dispose called');
    final ctrl = _controller;
    _controller = null;
    ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[CAMERA_DEBUG] Lifecycle state changed to: $state');
    if (state == AppLifecycleState.inactive) {
      debugPrint('[CAMERA_DEBUG] Inactive -> disposing controller safely');
      final ctrl = _controller;
      _controller = null;
      if (mounted) setState(() => _isReady = false);
      ctrl?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[CAMERA_DEBUG] Resumed -> reinitializing camera');
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final token = ++_initToken;
    debugPrint('[CAMERA_DEBUG] _initCamera started with token $token');

    try {
      if (mounted) setState(() => _isReady = false);

      if (_controller != null) {
        debugPrint('[CAMERA_DEBUG] Disposing old controller before re-init');
        await _controller!.dispose();
        _controller = null;
      }

      debugPrint('[CAMERA_DEBUG] Calling availableCameras()');
      final cameras = await availableCameras();
      debugPrint('[CAMERA_DEBUG] availableCameras() returned ${cameras.length} cameras');
      
      if (!mounted || token != _initToken) {
         debugPrint('[CAMERA_DEBUG] Aborting init (token mismatch or unmounted)');
         return;
      }

      if (cameras.isEmpty) {
         debugPrint('[CAMERA_DEBUG] No cameras available!');
         return;
      }

      // Find back camera
      CameraDescription? selectedCamera;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.back) {
          selectedCamera = c;
          break;
        }
      }
      // Fallback if no back camera found
      selectedCamera ??= cameras[0];

      debugPrint('[CAMERA_DEBUG] Selected camera: ${selectedCamera.name}');
      debugPrint('[CAMERA_DEBUG] Lens direction: ${selectedCamera.lensDirection}');
      debugPrint('[CAMERA_DEBUG] Sensor orientation: ${selectedCamera.sensorOrientation}');

      debugPrint('[CAMERA_DEBUG] Creating CameraController instance');
      final ctrl = CameraController(
        selectedCamera,
        ResolutionPreset.low, // Forced safe Android config
        enableAudio: false,
      );
      
      debugPrint('[CAMERA_DEBUG] Calling ctrl.initialize()');
      // Add timeout protection
      await ctrl.initialize().timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('[CAMERA_DEBUG] Timeout during initialize()!');
        throw Exception('Camera initialization timed out after 10 seconds');
      });
      
      debugPrint('[CAMERA_DEBUG] ctrl.initialize() success!');

      if (!mounted || token != _initToken) {
        debugPrint('[CAMERA_DEBUG] Aborting after init (token mismatch or unmounted)');
        ctrl.dispose();
        return;
      }
      
      _controller = ctrl;
      setState(() => _isReady = true);
      debugPrint('[CAMERA_DEBUG] UI updated to show preview.');
    } on CameraException catch (e) {
      debugPrint('[CAMERA_DEBUG] CameraException code: ${e.code}');
      debugPrint('[CAMERA_DEBUG] CameraException description: ${e.description}');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deliveryProofCameraError(e.code))));
      }
    } catch (e) {
      debugPrint('[CAMERA_DEBUG] General init error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deliveryProofInitError(e.toString()))));
      }
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null) {
       debugPrint('[CAMERA_DEBUG] Capture ignored: controller is null');
       return;
    }
    if (!ctrl.value.isInitialized) {
       debugPrint('[CAMERA_DEBUG] Capture ignored: not initialized');
       return;
    }
    if (_isTakingPicture || _isPopping) {
       debugPrint('[CAMERA_DEBUG] Capture ignored: already taking picture or popping');
       return;
    }

    if (mounted) setState(() => _isTakingPicture = true);
    debugPrint('[CAMERA_DEBUG] Starting capture sequence');

    try {
      final XFile image = await ctrl.takePicture();
      debugPrint('[CAMERA_DEBUG] Picture captured: ${image.path}');

      if (!mounted) {
         debugPrint('[CAMERA_DEBUG] Component unmounted after takePicture');
         return;
      }

      // Set _isPopping BEFORE pop so that the final build() triggered by
      // Navigator does NOT attempt to render CameraPreview on a disposed controller.
      // The controller is NOT disposed here — widget.dispose() handles that cleanly.
      setState(() => _isPopping = true);

      debugPrint('[CAMERA_DEBUG] Navigator pop with image path');
      Navigator.of(context).pop(image.path);
      } catch (e) {
        debugPrint('[CAMERA_DEBUG] Capture error: $e');
        if (mounted) {
          setState(() {
            _isTakingPicture = false;
            _isPopping = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.proofCaptureFailed), backgroundColor: Colors.red),
          );
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(l10n.proofDebugCamera),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isReady && !_isTakingPicture) ? _capture : null,
        backgroundColor: (_isReady && !_isTakingPicture) ? Colors.red : Colors.grey,
        child: _isTakingPicture 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    // CRITICAL: If we are navigating away or capturing, show a safe black screen.
    // Never render CameraPreview when the controller may be in a disposed/intermediate state.
    if (_isPopping || _isTakingPicture) {
      debugPrint('[CAMERA_DEBUG] build: showing black screen (popping=$_isPopping, taking=$_isTakingPicture)');
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final ctrl = _controller;
    if (!_isReady || ctrl == null) {
       debugPrint('[CAMERA_DEBUG] build: rendering loading indicator (not ready)');
       return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (!ctrl.value.isInitialized) {
       debugPrint('[CAMERA_DEBUG] build: isInitialized is false — showing safe fallback');
       return const ColoredBox(
         color: Colors.black,
         child: Center(child: CircularProgressIndicator(color: Colors.white)),
       );
    }
    debugPrint('[CAMERA_DEBUG] build: Rendering CameraPreview');
    return Center(
      child: CameraPreview(ctrl),
    );
  }
}

// ── DashedRectPainter kept for any other usages ──────────────────────────────
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  DashedRectPainter(
      {required this.color, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16)));
    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
            metric.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter old) => false;
}
