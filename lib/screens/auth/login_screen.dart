import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/otp_service.dart';
import '../../services/notification_service.dart';
import 'otp_verification_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import 'sign_up_screen.dart';
import 'profile_setup_screen.dart';
import 'vehicle_info_screen.dart';
import 'document_verification_screen.dart';
import 'forgot_password_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginEmptyFields)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        // Role-based security check: customer accounts cannot log in to driver app
        String? role;
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          role = profileData?['role'] as String?;
        } catch (_) {}

        final metaRole = user.userMetadata?['role'] as String?;
        final bool isDriverRole = (role == 'driver' || role == 'admin' || metaRole == 'driver' || metaRole == 'admin');

        if (role == 'customer') {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.loginCustomerAccountError),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!isDriverRole) {
          final driverCheck = await Supabase.instance.client
              .from('drivers')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (driverCheck == null) {
            await Supabase.instance.client.auth.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.loginCustomerAccountError),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        Widget nextRoute = const DashboardScreen();

        try {
          final profile = await Supabase.instance.client
              .from('drivers')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profile == null) {
            final userMeta = user.userMetadata;
            final fullName = userMeta?['full_name'] ?? email.split('@').first;

            await Supabase.instance.client.from('drivers').insert({
              'id': user.id,
              'full_name': fullName,
              'email': email,
              'phone': userMeta?['phone'] ?? '',
            });

            nextRoute = const DocumentVerificationScreen();
          } else {
            final docsSubmitted = profile['documents_submitted'] == true;
            final profileCompleted = profile['is_profile_completed'] == true;
            final vehicleAdded = profile['vehicle_type'] != null &&
                (profile['vehicle_type'] as String).isNotEmpty;

            if (!docsSubmitted) {
              nextRoute = const DocumentVerificationScreen();
            } else if (!profileCompleted) {
              nextRoute = const ProfileSetupScreen();
            } else if (!vehicleAdded) {
              nextRoute = const VehicleInfoScreen();
            }
          }
        } catch (e) {
          debugPrint("Failed to create/check driver profile on login: $e");
        }

        unawaited(NotificationService.syncToken());

        final otpSent = await OtpService.sendOtp(email);

        if (mounted) {
          if (otpSent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  email: email,
                  nextScreen: nextRoute,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.loginFailedVerification)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.loginUnexpectedError)),
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
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.loginWelcomeBack,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.loginSignInToContinue,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                _buildLabel(l10n.loginEmailAddress),
                _buildTextField(
                  l10n.loginEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                _buildLabel(l10n.loginPassword),
                _buildTextField(
                  l10n.loginPasswordHint,
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.loginForgotPassword,
                      style: const TextStyle(
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
                            children: [
                              Text(
                                l10n.loginSignIn,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
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
                      Text(
                        l10n.loginNoAccount,
                        style: const TextStyle(
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
                        child: Text(
                          l10n.loginSignUp,
                          style: const TextStyle(
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
