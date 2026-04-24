import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  final res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/debug_schema?select=info'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  
  if (res.statusCode == 200) {
    debugPrint('DEBUG INFO:');
    final data = jsonDecode(res.body) as List;
    for (var item in data) {
      debugPrint(item['info']);
    }
  } else {
    debugPrint('ERROR: ${res.statusCode}');
    debugPrint(res.body);
  }
}
