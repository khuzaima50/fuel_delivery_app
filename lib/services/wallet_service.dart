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
}

