import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

  debugPrint('Initializing Supabase...');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  final client = Supabase.instance.client;
  
  // Note: This script assumes you are running it in an environment where you can provide a session or it's public.
  // In a real debug scenario, we'd need a valid session.
  // Let's at least check the table schema by trying to fetch one row (if any are public).
  
  debugPrint('Table: notifications');
  try {
    final res = await client.from('notifications').select().limit(1);
    debugPrint('Publicly visible notifications: ${res.length}');
    if (res.isNotEmpty) {
      debugPrint('Columns found: ${res.first.keys.toList()}');
    }
  } catch (e) {
    debugPrint('Error fetching notifications: $e');
  }

  exit(0);
}
