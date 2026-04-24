import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> checkSchema() async {
  try {
    final client = Supabase.instance.client;
    // This is a bit of a hack to get column info without direct SQL
    // We try to insert a completely empty row and see what the error says
    final res = await client.from('notifications').insert({}).select();
    debugPrint('Insert result: $res');
  } on PostgrestException catch (e) {
    debugPrint('SCHEMA ERROR: ${e.message}');
    debugPrint('DETAILS: ${e.details}');
    debugPrint('HINT: ${e.hint}');
  } catch (e) {
    debugPrint('OTHER ERROR: $e');
  }
}
