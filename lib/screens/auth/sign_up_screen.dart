import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'document_verification_screen.dart';
import '../../services/otp_service.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signUpFillAllFields)),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signUpPasswordMismatch)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone, 'role': 'driver'},
      );

      final user = res.user;
      if (user != null) {
        // Check if this user is a customer
        String? role;
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          role = profileData?['role'] as String?;
        } catch (_) {}

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

        // Check identities — if user already existed, identities will be empty
        if (user.identities != null && user.identities!.isEmpty) {
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

        // Upsert role into drivers & profiles table
        try {
          await Supabase.instance.client.from('drivers').upsert({
            'id': user.id,
            'full_name': name,
            'email': email,
            'phone': phone,
          }, onConflict: 'id');

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'full_name': name,
            'phone_number': phone,
            'role': 'driver',
          }, onConflict: 'id');
        } catch (e) {
          debugPrint('SignUp DB upsert warning: $e');
        }

        final otpSent = await OtpService.sendOtp(email);

        if (mounted) {
          if (!otpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.signUpAccountCreatedPartial),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                nextScreen: const DocumentVerificationScreen(),
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.signUpUnexpectedError)),
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.signUpCreateAccount,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.signUpGetStarted,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),
                _buildLabel(l10n.signUpFullName),
                _buildTextField(l10n.signUpFullNameHint, controller: _nameController),
                const SizedBox(height: 20),
                _buildLabel(l10n.signUpEmailAddress),
                _buildTextField(
                  l10n.signUpEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _buildLabel(l10n.signUpPhoneNumber),
                _buildTextField(
                  l10n.signUpPhoneHint,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
                const SizedBox(height: 20),
                _buildLabel(l10n.signUpPassword),
                _buildTextField(
                  l10n.signUpPasswordHint,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel(l10n.signUpConfirmPassword),
                _buildTextField(
                  l10n.signUpConfirmPasswordHint,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  controller: _confirmPasswordController,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(text: l10n.signUpAgreeText),
                          TextSpan(
                            text: l10n.signUpTermsOfService,
                            style: const TextStyle(
                              color: Color(0xFFFF4D00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: l10n.signUpAnd),
                          TextSpan(
                            text: l10n.signUpPrivacyPolicy,
                            style: const TextStyle(
                              color: Color(0xFFFF4D00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
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
                                l10n.signUpButton,
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
                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.signUpAlreadyAccount,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.signUpSignIn,
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
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}
