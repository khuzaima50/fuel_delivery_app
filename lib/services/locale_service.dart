import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocaleService — manages the app's current locale.
/// Listens via ChangeNotifier so the entire app rebuilds on language change.
class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  static const Locale _defaultLocale = Locale('en');

  Locale _locale = _defaultLocale;

  Locale get locale => _locale;

  /// Singleton instance
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  /// Load saved locale from SharedPreferences on app start
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey) ?? 'en';
      _locale = Locale(code);
    } catch (_) {
      _locale = _defaultLocale;
    }
  }

  /// Change locale and persist it
  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    } catch (_) {}
  }

  /// Get display name for a language code
  static String getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
      default:
        return 'English (US)';
    }
  }

  /// All supported languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English (US)', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  ];
}
