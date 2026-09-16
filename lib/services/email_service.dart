import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static const String _baseUrl = 'https://api.resend.com/emails';

  static Future<bool> sendOTP(String email, String otp) async {
    final String? apiKey = dotenv.env['RESEND_API_KEY'];
    final cleanEmail = email.trim().toLowerCase();
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[EmailService] Error: RESEND_API_KEY is missing from .env file');
      return false;
    }

    try {
      debugPrint('[EmailService] Sending OTP email to $cleanEmail via Resend...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'no-reply@fueldirectusa.com', 
          'to': cleanEmail,
          'subject': 'Your Verification Code - FuelDirect',
          'html': '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
              <h2 style="color: #FF4D00; text-align: center;">FuelDirect Verification</h2>
              <p>Hello,</p>
              <p>Your verification code for FuelDirect is:</p>
              <div style="background-color: #f8f8f8; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1F1F1F;">$otp</span>
              </div>
              <p>This code will expire in 10 minutes. If you did not request this code, please ignore this email.</p>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
              <p style="font-size: 12px; color: #666; text-align: center;">&copy; 2024 FuelDirect. All rights reserved.</p>
            </div>
          ''',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[EmailService] Email sent successfully to $cleanEmail (status ${response.statusCode})');
        return true;
      } else {
        debugPrint('[EmailService] Failed to send email. Status: ${response.statusCode}');
        debugPrint('[EmailService] Response Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailService] Exception during email send: $e');
      return false;
    }
  }
}
