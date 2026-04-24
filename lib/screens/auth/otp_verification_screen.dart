import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/otp_service.dart';
import '../../services/notification_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Widget nextScreen;

  const OtpVerificationScreen({
    super.key, 
    required this.email, 
    required this.nextScreen,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (i) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (i) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    _runTimer();
  }

  Future<void> _runTimer() async {
    while (_resendTimer > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _resendTimer--;
      });
    }
    setState(() {
      _canResend = true;
    });
  }

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 6-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await OtpService.verifyOtp(widget.email, otp);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        // Sync notification token now that user is logged in
        unawaited(NotificationService.syncToken());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification Successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid or expired OTP. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    bool sent = await OtpService.sendOtp(widget.email);
    setState(() => _isLoading = false);

    if (sent) {
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A new OTP has been sent to your email")),
        );
      }
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to resend OTP. Please try again later.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F1F1F), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Color(0xFF666666), height: 1.5),
                    children: [
                      const TextSpan(text: 'We have sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _canResend 
                          ? "Didn't receive the code?" 
                          : "Resend code in ${_resendTimer}s",
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                        ),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: _isLoading ? null : _resendOtp,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: Color(0xFFFF4D00),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus 
            ? const Color(0xFFFF4D00) 
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F1F1F),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (value.isNotEmpty && index == 5) {
             _verifyOtp();
          }
        },
      ),
    );
  }
}
