import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class SessionManager extends ChangeNotifier {
  static const String _storageKey = 'recentSessions';
  List<ChatSession> _sessions = [];

  // Sessions getter - returns an unmodifiable view for safety
  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  // Default constructor for singleton pattern
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  // Initialize and load saved sessions
  Future<void> initialize() async {
    await loadSessions();
  }

  // Load saved sessions from SharedPreferences
  Future<void> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSessionsJson = prefs.getStringList(_storageKey);

      if (savedSessionsJson != null && savedSessionsJson.isNotEmpty) {
        final loadedSessions =
            savedSessionsJson
                .map(
                  (sessionJson) =>
                      ChatSession.fromJson(jsonDecode(sessionJson)),
                )
                .toList();

        // Sort sessions by timestamp, most recent first
        loadedSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _sessions = loadedSessions;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved sessions: $e');
      }
    }
  }

  // Save sessions to SharedPreferences
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson =
          _sessions.map((session) => jsonEncode(session.toJson())).toList();

      await prefs.setStringList(_storageKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving sessions: $e');
      }
    }
  }

  // Add new session
  Future<void> addSession(ChatSession session) async {
    try {
      _sessions.add(session);
      await _saveSessions(); // Local storage'a kaydet
      notifyListeners(); // UI'ı güncelle
      print('Session added and saved: ${session.id}');
    } catch (e) {
      print('Error adding session: $e');
      throw Exception('Failed to add session: $e');
    }
  }

  // Delete a session
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((session) => session.id == id);
    notifyListeners();
    await _saveSessions();
  }

  // Get session by ID
  ChatSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update a session
  Future<void> updateSession(ChatSession updatedSession) async {
    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      notifyListeners();
      await _saveSessions();
    }
  }

  // Clear all sessions
  Future<void> clearAllSessions() async {
    _sessions.clear();
    notifyListeners();
    await _saveSessions();
  }
}
