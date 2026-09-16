import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_service.dart';

class OtpService {
  static final _supabase = Supabase.instance.client;

  static String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  static Future<bool> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final otp = _generateOtp();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    debugPrint('[OtpService] Attempting to send OTP $otp to $cleanEmail');

    // 1. Save to Supabase user_otps table
    try {
      await _supabase.from('user_otps').insert({
        'email': cleanEmail,
        'otp': otp,
        'expires_at': expiresAt.toIso8601String(),
        'verified': false,
      });
      debugPrint('[OtpService] OTP saved to DB successfully for $cleanEmail');
    } catch (e) {
      debugPrint('[OtpService] Warning: Error saving OTP to user_otps table: $e');
    }

    // 2. Send Email via Resend API
    try {
      final emailSent = await EmailService.sendOTP(cleanEmail, otp);
      debugPrint('[OtpService] EmailService.sendOTP result for $cleanEmail: $emailSent');
      return emailSent;
    } catch (e) {
      debugPrint('[OtpService] Exception calling EmailService.sendOTP: $e');
      return false;
    }
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    try {
      final response = await _supabase
          .from('user_otps')
          .select()
          .eq('email', cleanEmail)
          .eq('otp', cleanOtp)
          .eq('verified', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // Mark as verified
        await _supabase
            .from('user_otps')
            .update({'verified': true})
            .eq('id', response['id']);
        debugPrint('[OtpService] OTP verified successfully for $cleanEmail');
        return true;
      }
      debugPrint('[OtpService] verifyOtp: No active unverified OTP match found for $cleanEmail and code $cleanOtp');
      return false;
    } catch (e) {
      debugPrint('[OtpService] Error in verifyOtp: $e');
      return false;
    }
  }
}
