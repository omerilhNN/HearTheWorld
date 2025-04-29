import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';
  static const Map<String, Locale> _supportedLocales = {
    'en-US': Locale('en', 'US'),
    'en-GB': Locale('en', 'GB'),
    'tr-TR': Locale('tr', 'TR'),
  };

  Locale _locale = const Locale('en', 'US');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  // Dil koduna göre UI dilini değiştir
  Future<void> setLocale(String languageCode) async {
    if (_supportedLocales.containsKey(languageCode)) {
      _locale = _supportedLocales[languageCode]!;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      
      notifyListeners();
    }
  }

  // Kaydedilmiş dil ayarını yükle
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLocale = prefs.getString(_localeKey);
    
    if (storedLocale != null && _supportedLocales.containsKey(storedLocale)) {
      _locale = _supportedLocales[storedLocale]!;
      notifyListeners();
    }
  }

  // Desteklenen tüm diller
  static List<Locale> get supportedLocales {
    return _supportedLocales.values.toList();
  }
}