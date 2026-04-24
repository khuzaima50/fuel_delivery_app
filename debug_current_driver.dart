import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  debugPrint('--- Finding the Active Driver ---');
  final driverRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,updated_at,fcm_token&order=updated_at.desc&limit=1'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  
  if (driverRes.statusCode != 200) {
    debugPrint('Error fetching drivers: ${driverRes.body}');
    return;
  }

  final drivers = jsonDecode(driverRes.body) as List;
  if (drivers.isEmpty) {
    debugPrint('No drivers found!');
    return;
  }

  final latestDriver = drivers.first;
  final driverId = latestDriver['id'];
  debugPrint('Latest Active Driver: ${latestDriver['full_name']} ($driverId)');
  debugPrint('Token Present: ${latestDriver['fcm_token'] != null}');
  if (latestDriver['fcm_token'] != null) {
      debugPrint('Token: ${latestDriver['fcm_token'].substring(0, 20)}...');
  }

  debugPrint('\n--- Checking for Notifications for THIS Driver ---');
  final notifRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/notifications?select=*&driver_id=eq.$driverId&limit=5&order=created_at.desc'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  debugPrint('Notifs for current driver: ${notifRes.body}');
    
  debugPrint('\n--- Checking for ANY Order assigned to THIS driver ---');
  final orderRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/orders?select=id,status,updated_at&driver_id=eq.$driverId&order=updated_at.desc&limit=1'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  debugPrint('Orders for current driver: ${orderRes.body}');
}
