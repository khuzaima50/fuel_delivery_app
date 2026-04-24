import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/otp_service.dart';
import '../../services/notification_service.dart';
import 'otp_verification_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        try {
          final profile = await Supabase.instance.client
              .from('drivers')
              .select()
              .eq('id', res.user!.id)
              .maybeSingle();
              
          if (profile == null) {
            // Get name from user metadata if available
            final userMeta = res.user!.userMetadata;
            final fullName = userMeta?['full_name'] ?? email.split('@').first;
            
            await Supabase.instance.client.from('drivers').insert({
              'id': res.user!.id,
              'full_name': fullName,
              'email': email,
              'phone': userMeta?['phone'] ?? '',
            });
          }
        } catch (e) {
          debugPrint("Failed to create driver profile on login: $e");
        }

        // Sync notification token now that user is logged in
        unawaited(NotificationService.syncToken());

        // Trigger OTP
        final otpSent = await OtpService.sendOtp(email);
        
        if (mounted) {
          if (otpSent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  email: email,
                  nextScreen: const DashboardScreen(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to send verification code. Please try again.")),
            );
          }
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                _buildLabel('Email Address'),
                _buildTextField(
                  'alex@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                _buildLabel('Password'),
                _buildTextField(
                  'Enter your password',
                  isPassword: true,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFFF4D00),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(height: 48),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFFFF4D00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey[500],
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

}
