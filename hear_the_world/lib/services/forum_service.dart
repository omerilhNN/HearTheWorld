import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/forum_models.dart';

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;

  ForumService._internal();

  List<ForumMemory> _memories = [];
  bool _isInitialized = false;
  final _memoriesStreamController = StreamController<List<ForumMemory>>.broadcast();
  Stream<List<ForumMemory>> get memoriesStream => _memoriesStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadMemories();
    if (_memories.isEmpty) {
      _memories = _generateMockMemories();
      await _saveMemories();
    }

    _memoriesStreamController.add(_memories);
    _isInitialized = true;
  }

  Future<List<ForumMemory>> getMemories() async {
    if (!_isInitialized) await initialize();
    return _memories;
  }

  Future<ForumMemory?> getMemoryById(String id) async {
    if (!_isInitialized) await initialize();
    try {
      return _memories.firstWhere((memory) => memory.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addMemory(ForumMemory memory) async {
    if (!_isInitialized) await initialize();
    
    try {
      _memories.insert(0, memory);
      await _saveMemories();
      _memoriesStreamController.add(_memories);
      return true;
    } catch (e) {
      print('Error adding memory: $e');
      return false;
    }
  }

  Future<bool> updateMemory(ForumMemory updatedMemory) async {
    if (!_isInitialized) await initialize();
    
    try {
      final index = _memories.indexWhere((mem) => mem.id == updatedMemory.id);
      if (index >= 0) {
        _memories[index] = updatedMemory;
        await _saveMemories();
        _memoriesStreamController.add(_memories);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating memory: $e');
      return false;
    }
  }

  Future<bool> deleteMemory(String id) async {
    if (!_isInitialized) await initialize();
    
    try {
      _memories.removeWhere((memory) => memory.id == id);
      await _saveMemories();
      _memoriesStreamController.add(_memories);
      return true;
    } catch (e) {
      print('Error deleting memory: $e');
      return false;
    }
  }

  Future<bool> addComment(String memoryId, ForumComment comment) async {
    if (!_isInitialized) await initialize();
    
    try {
      final memoryIndex = _memories.indexWhere((mem) => mem.id == memoryId);
      if (memoryIndex >= 0) {
        final updatedMemory = _memories[memoryIndex].copyWith(
          comments: [..._memories[memoryIndex].comments, comment],
          commentCount: _memories[memoryIndex].commentCount + 1,
        );
        
        _memories[memoryIndex] = updatedMemory;
        await _saveMemories();
        _memoriesStreamController.add(_memories);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  Future<bool> likeMemory(String id) async {
    if (!_isInitialized) await initialize();
    
    try {
      final memoryIndex = _memories.indexWhere((mem) => mem.id == id);
      if (memoryIndex >= 0) {
        final updatedMemory = _memories[memoryIndex].copyWith(
          likeCount: _memories[memoryIndex].likeCount + 1,
        );
        
        _memories[memoryIndex] = updatedMemory;
        await _saveMemories();
        _memoriesStreamController.add(_memories);
        return true;
      }
      return false;
    } catch (e) {
      print('Error liking memory: $e');
      return false;
    }
  }

  Future<void> _loadMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoriesJson = prefs.getStringList('forum_memories');
      
      if (memoriesJson != null) {
        _memories = memoriesJson
            .map((json) => ForumMemory.fromJson(jsonDecode(json)))
            .toList();
      }
    } catch (e) {
      print('Error loading memories: $e');
      _memories = [];
    }
  }

  Future<void> _saveMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoriesJson = _memories
          .map((memory) => jsonEncode(memory.toJson()))
          .toList();
      
      await prefs.setStringList('forum_memories', memoriesJson);
    } catch (e) {
      print('Error saving memories: $e');
    }
  }

  List<ForumMemory> _generateMockMemories() {
    return [
      ForumMemory(
        title: "My First Day with a Guide Dog",
        description: "Today marks one month since I got my guide dog, Max. The bond we've developed is incredible. He's not just a guide - he's become my best friend. I wanted to share what the first day was like when we met and started our journey together.",
        authorName: "Ahmet Yılmaz",
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        durationSeconds: 125,
        audioUrl: "assets/audio/memory1.mp3",
        likeCount: 24,
        commentCount: 3,
        comments: [
          ForumComment(
            content: "Max sounds amazing! My guide dog changed my life too.",
            authorName: "Zeynep K.",
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
          ),
          ForumComment(
            content: "Thank you for sharing this special memory.",
            authorName: "Mehmet A.",
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ForumComment(
            content: "Would love to hear more about your journey with Max!",
            authorName: "Ayşe B.",
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
      ForumMemory(
        title: "First Concert Experience",
        description: "I attended my first concert last weekend. The music was incredible, and the vibrations I felt through the floor added an entirely new dimension to the experience. I loved how the venue had audio descriptions of the stage setup and performers.",
        authorName: "Elif Demir",
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        durationSeconds: 180,
        audioUrl: "assets/audio/memory2.mp3",
        likeCount: 42,
        commentCount: 5,
        comments: [
          ForumComment(
            content: "Which artist was it? I've been wanting to attend concerts too!",
            authorName: "Can Y.",
            timestamp: DateTime.now().subtract(const Duration(days: 11)),
          ),
          ForumComment(
            content: "The vibration aspect is so important! Glad you had this experience.",
            authorName: "Selin T.",
            timestamp: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ],
      ),
      ForumMemory(
        title: "A Day at the Beach",
        description: "Yesterday I visited the Mediterranean coast for the first time in years. The sound of waves, the smell of salt water, and the feeling of sand between my toes was pure joy. I found a beach with accessibility features and an audio guide that described the surroundings.",
        authorName: "Murat Kaya",
        timestamp: DateTime.now().subtract(const Duration(days: 20)),
        durationSeconds: 210,
        audioUrl: "assets/audio/memory3.mp3",
        likeCount: 35,
        commentCount: 4,
        comments: [
          ForumComment(
            content: "Which beach was this? I'd love to visit a place with good accessibility.",
            authorName: "Deniz A.",
            timestamp: DateTime.now().subtract(const Duration(days: 19)),
          ),
          ForumComment(
            content: "The sound of waves is so peaceful. Thanks for sharing this beautiful memory.",
            authorName: "Berna K.",
            timestamp: DateTime.now().subtract(const Duration(days: 18)),
          ),
        ],
      ),
    ];
  }

  void dispose() {
    _memoriesStreamController.close();
  }
}
