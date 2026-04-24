// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  String? targetDriverId;
  if (args.isNotEmpty) {
    targetDriverId = args[0];
    print('Using manually provided Driver ID: $targetDriverId');
  } else {
    print('Searching for the most RECENT driver with a token...');
    // We try to find the driver with a non-null token. 
    // Ideally we'd sort by updated_at if it exists.
    final res = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,fcm_token&fcm_token=not.is.null&limit=5'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );

    if (res.statusCode != 200) {
      print('Failed to fetch drivers: ${res.body}');
      return;
    }

    final drivers = jsonDecode(res.body) as List;
    if (drivers.isEmpty) {
      print('No drivers with FCM tokens found in DB!');
      return;
    }

    // For this test, let's just pick the first one, but list the others
    print('Available drivers with tokens:');
    for (var d in drivers) {
      print(' - ${d['full_name'] ?? 'Unknown'} (${d['id']})');
    }
    
    targetDriverId = drivers.first['id'];
    print('\nAuto-selected Driver: ${drivers.first['full_name']} ($targetDriverId)');
  }

  print('Calling Edge Function for ID: $targetDriverId...');
  
  final fnRes = await http.post(
    Uri.parse('$supabaseUrl/functions/v1/send-notification'),
    headers: {
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'target_type': 'driver',
      'target_id': targetDriverId,
      'title': 'Test Push 🚀',
      'body': 'This is a test notification from your fresh test script!',
      'data': {'type': 'test', 'sent_at': DateTime.now().toIso8601String()}
    }),
  );

  print('Edge Function Response (${fnRes.statusCode}):');
  print(fnRes.body);

  if (fnRes.statusCode == 500 && fnRes.body.contains('UNREGISTERED')) {
    print('\nTIP: This driver\'s token is STALE (Unregistered).');
    print('Please open the app on your device to refresh your token, or try a different Driver ID.');
  }
}
