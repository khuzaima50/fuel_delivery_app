import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  static final _supabase = Supabase.instance.client;

  /// Fetches the current wallet balance for the authenticated driver.
  static Future<double> getWalletBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final data = await _supabase
          .from('drivers')
          .select('wallet_balance')
          .eq('id', userId)
          .single();

      return double.tryParse(data['wallet_balance']?.toString() ?? '0.0') ?? 0.0;
    } catch (e) {
      debugPrint('[WalletService] Error fetching balance: $e');
      return 0.0;
    }
  }

  /// Fetches the transaction history for the authenticated driver.
  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('driver_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[WalletService] Error fetching history: $e');
      return [];
    }
  }

  /// Requests a payout (withdrawal) using the Edge Function.
  static Future<Map<String, dynamic>> requestPayout(double amount) async {
    try {
      final response = await _supabase.functions.invoke(
        'stripe-withdraw-funds',
        body: {
          'amount': amount,
          'driver_id': _supabase.auth.currentUser?.id,
        },
      );

      if (response.status == 200 || response.status == 201) {
        return {
          'success': true,
          'message': 'Payout requested successfully!',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['error'] ?? 'Withdrawal failed. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('[WalletService] Payout error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Fetches the Stripe Connect onboarding URL with detailed result.
  static Future<Map<String, dynamic>> getStripeOnboardingUrlWithResult() async {
    try {
      // Try the primary onboarding function first
      var response = await _supabase.functions.invoke(
        'create-stripe-connect-account',
        body: {},
      );

      // Fallback: If 404, try the generic stripe function with an action
      if (response.status == 404) {
        response = await _supabase.functions.invoke(
          'stripe-withdraw-funds',
          body: {'action': 'create_account_link'},
        );
      }

      if (response.status == 200 || response.status == 201) {
        return {'url': response.data['url']?.toString()};
      } else {
        return {
          'url': null,
          'error': 'Function returned status ${response.status}: ${response.data?['error'] ?? 'Unknown error'}'
        };
      }
    } catch (e) {
      return {'url': null, 'error': e.toString()};
    }
  }

  /// Checks if the driver has completed Stripe onboarding.
  static Future<bool> checkStripeStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _supabase
          .from('drivers')
          .select('stripe_onboarding_completed')
          .eq('id', userId)
          .single();

      return data['stripe_onboarding_completed'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
