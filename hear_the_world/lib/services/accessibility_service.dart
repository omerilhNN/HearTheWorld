import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum FeedbackType { success, error, info, warning }

enum VoiceCommand { home, back, next, stop, help, settings, unknown }

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Text-to-speech
  late FlutterTts _flutterTts;
  bool _audioEnabled = true;
  bool _hapticEnabled = true;
  String _language = 'en-US';
  Function? _onCompletionCallback;

  // Speech-to-text
  bool _isListening = false;
  String _lastRecognizedWords = '';
  final StreamController<String> _recognizedWordsController =
      StreamController<String>.broadcast();
  final StreamController<VoiceCommand> _commandController =
      StreamController<VoiceCommand>.broadcast();
  bool _speechEnabled = false;
  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _audioEnabled = prefs.getBool('audioEnabled') ?? true;
    _hapticEnabled = prefs.getBool('hapticEnabled') ?? true;
    _language = prefs.getString('language') ?? 'en-US';
    _speechEnabled = prefs.getBool('speechEnabled') ?? true;

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

  // Speech recognition methods
  Stream<String> get recognizedWords => _recognizedWordsController.stream;
  Stream<VoiceCommand> get commands => _commandController.stream;
  bool get isListening => _isListening;
  bool get isSpeechEnabled => _speechEnabled;
  String get lastRecognizedWords => _lastRecognizedWords;

  Future<void> startListening() async {
    if (!_speechEnabled || _isListening) return;

    _isListening = true;

    // Let user know listening started
    HapticFeedback.mediumImpact();
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    HapticFeedback.lightImpact();
  }

  void _processVoiceCommand(String text) {
    VoiceCommand command = VoiceCommand.unknown;

    if (text.contains('home') || text.contains('main screen')) {
      command = VoiceCommand.home;
    } else if (text.contains('back') ||
        text.contains('previous') ||
        text.contains('return')) {
      command = VoiceCommand.back;
    } else if (text.contains('next') ||
        text.contains('forward') ||
        text.contains('continue')) {
      command = VoiceCommand.next;
    } else if (text.contains('stop') ||
        text.contains('cancel') ||
        text.contains('exit')) {
      command = VoiceCommand.stop;
    } else if (text.contains('help') || text.contains('what can i say')) {
      command = VoiceCommand.help;
    } else if (text.contains('settings') ||
        text.contains('options') ||
        text.contains('preferences')) {
      command = VoiceCommand.settings;
    }

    _commandController.add(command);

    // Give feedback for recognized command
    if (command != VoiceCommand.unknown) {
      speakWithFeedback(
        "Command recognized: ${command.toString().split('.').last}",
        FeedbackType.success,
      );
    }
  }

  Future<void> setSpeechEnabled(bool enabled) async {
    _speechEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('speechEnabled', enabled);
  }

  Future<void> speakScreenDescription(
    String screenName,
    String description,
  ) async {
    await speak("$screenName screen. $description");
  }

  Future<void> speakHelp() async {
    await speak(
      "Available voice commands: home, back, next, stop, help, and settings. "
      "You can also ask 'what can I say' to hear this list again.",
    );
  }

  void dispose() {
    _recognizedWordsController.close();
    _commandController.close();
  }
}

// Extension to provide easy access to the accessibility service from any widget
extension AccessibilityHelpers on BuildContext {
  AccessibilityService get accessibility => AccessibilityService();

  Future<void> speak(String text) => accessibility.speak(text);

  Future<void> speakWithFeedback(String text, FeedbackType type) =>
      accessibility.speakWithFeedback(text, type);

  Future<void> speakScreenDescription(String screenName, String description) =>
      accessibility.speakScreenDescription(screenName, description);

  Future<void> startVoiceRecognition() => accessibility.startListening();

  Future<void> stopVoiceRecognition() => accessibility.stopListening();

  Stream<String> get recognizedWords => accessibility.recognizedWords;

  Stream<VoiceCommand> get voiceCommands => accessibility.commands;
}
