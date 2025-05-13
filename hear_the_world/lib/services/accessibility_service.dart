import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeedbackType { success, error, info, warning }

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  late FlutterTts _flutterTts;
  bool _audioEnabled = true;
  bool _hapticEnabled = true;
  String _language = 'en-US';
  Function? _onCompletionCallback;
  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _audioEnabled = prefs.getBool('audioEnabled') ?? true;
    _hapticEnabled = prefs.getBool('hapticEnabled') ?? true;
    _language = prefs.getString('language') ?? 'en-US';

    // Configure TTS
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setSpeechRate(
      0.5,
    ); // Slower rate for better comprehension
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Set up completion listener
    _flutterTts.setCompletionHandler(() {
      if (_onCompletionCallback != null) {
        _onCompletionCallback!();
      }
    });
  }
  
  void setCompletionCallback(Function callback) {
    _onCompletionCallback = callback;
  }
  
  void clearCompletionCallback() {
    _onCompletionCallback = null;
  }

  Future<void> speak(String text) async {
    if (_audioEnabled) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  Future<void> speakWithFeedback(String text, FeedbackType type) async {
    if (_hapticEnabled) {
      switch (type) {
        case FeedbackType.success:
          HapticFeedback.mediumImpact();
          break;
        case FeedbackType.error:
          HapticFeedback.heavyImpact();
          break;
        case FeedbackType.warning:
        case FeedbackType.info:
          HapticFeedback.lightImpact();
          break;
      }
    }

    await speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> setAudioEnabled(bool enabled) async {
    _audioEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audioEnabled', enabled);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticEnabled', enabled);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  bool get isAudioEnabled => _audioEnabled;
  bool get isHapticEnabled => _hapticEnabled;
  String get language => _language;
}

// Extension to provide easy access to the accessibility service from any widget
extension AccessibilityHelpers on BuildContext {
  Future<void> speak(String text) => AccessibilityService().speak(text);

  Future<void> speakWithFeedback(String text, FeedbackType type) =>
      AccessibilityService().speakWithFeedback(text, type);
}
