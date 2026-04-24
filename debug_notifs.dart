import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  debugPrint('--- Checking Recent Notifications ---');
  final notifRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/notifications?select=*&limit=5&order=created_at.desc'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  debugPrint('Notifs (${notifRes.statusCode}): ${notifRes.body}');

  debugPrint('\n--- Checking Drivers with/without tokens ---');
  final driverRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,fcm_token&limit=10&order=id.desc'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  debugPrint('Drivers (${driverRes.statusCode}): ${driverRes.body}');
  
  debugPrint('\n--- Checking Orders Status ---');
  final orderRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/orders?select=id,status,driver_id&limit=5&order=updated_at.desc'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  debugPrint('Orders (${orderRes.statusCode}): ${orderRes.body}');
}
