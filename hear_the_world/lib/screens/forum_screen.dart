import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/forum_models.dart';
import '../services/accessibility_service.dart';
import '../services/forum_service.dart';
import '../services/locale_provider.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../utils/app_theme.dart';
import '../main.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with AutomaticKeepAliveClientMixin {
  final ForumService _forumService = ForumService();
  final ScrollController _scrollController = ScrollController();
  
  List<ForumMemory> _memories = [];
  bool _isLoading = true;
  int? _playingMemoryId;
  String _searchText = '';
  bool _isTurkish = false;
  StreamSubscription? _memoriesSubscription;
  
  // Override to keep the state alive
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    
    // Load saved state
    _loadPlayingState();
    _loadSearchText();
    _loadMemories();
    
    // Set up scroll listener
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _saveScrollPosition();
      }
    });
    
    // Set completion callback for TTS
    AccessibilityService().setCompletionCallback(() {
      setState(() {
        _playingMemoryId = null;
        _savePlayingState();
      });
    });
    
    // Subscribe to memory updates
    _memoriesSubscription = _forumService.memoriesStream.listen((updatedMemories) {
      setState(() {
        _memories = updatedMemories;
        _isLoading = false;
      });
      
      // After getting memories, restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition();
      });
    });
    
    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        _isTurkish
            ? 'Forum ekranı. Burada görme engelli kullanıcıların paylaştığı anıları dinleyebilirsiniz. Ekranı yukarı ve aşağı kaydırarak anıları gezebilirsiniz.'
            : 'Forum screen. Here you can listen to memories shared by visually impaired users. Swipe up and down to browse memories.',
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateLanguageState();
    
    // When screen becomes active again, check if we need to update the list
    if (!_isLoading && _memories.isEmpty) {
      _loadMemories();
    }
  }

  void _updateLanguageState() {
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final languageCode = localeProvider.locale.languageCode;
      final isTurkish = languageCode == 'tr';
      
      if (_isTurkish != isTurkish) {
        setState(() {
          _isTurkish = isTurkish;
        });
      }
    } catch (e) {
      print('Dil kontrolü sırasında hata: $e');
    }
  }
  
  void _loadMemories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memories = await _forumService.getMemories();
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading memories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTabChange(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        // Already on forum screen
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }  void _toggleAudio(ForumMemory memory) {
    final int? memoryId = int.tryParse(memory.id);
    
    // First stop any currently playing audio
    if (_playingMemoryId != null) {
      AccessibilityService().stopSpeaking();
    }
    
    setState(() {
      if (_playingMemoryId != null && memoryId == _playingMemoryId) {
        // If this memory is already playing, stop it
        _playingMemoryId = null;
        AccessibilityService().speak(_isTurkish ? 'Ses durduruldu' : 'Audio stopped');
      } else {
        // Start playing this memory
        _playingMemoryId = memoryId;
        
        // Play full description for better accessibility
        String textToSpeak = '${memory.title}. ${memory.description}';
        AccessibilityService().speak(textToSpeak);
        
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
      }
      
      // Save the current playing state
      _savePlayingState();
    });
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(text: _searchText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isTurkish ? 'Anılarda Ara' : 'Search Memories'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: _isTurkish ? 'Anahtar kelime girin' : 'Enter keywords',
            prefixIcon: const Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AccessibilityService().speak(_isTurkish ? 'Arama iptal edildi' : 'Search canceled');
            },
            child: Text(_isTurkish ? 'İPTAL' : 'CANCEL'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchText = searchController.text.trim();
              });
              Navigator.of(context).pop();
              AccessibilityService().speak(
                _searchText.isEmpty
                    ? (_isTurkish ? 'Tüm anılar gösteriliyor' : 'Showing all memories')
                    : (_isTurkish
                        ? '$_searchText için arama sonuçları'
                        : 'Search results for $_searchText'),
              );
              _saveSearchText();
            },
            child: Text(_isTurkish ? 'ARA' : 'SEARCH'),
          ),
        ],
      ),
    );
  }  void _openMemoryDetail(ForumMemory memory) {
    // Navigate to the memory detail screen
    context.go('/memory/${memory.id}');
  }
    // Removed unused method _showMemoryBottomSheet

  List<ForumMemory> get _filteredMemories {
    if (_searchText.isEmpty) {
      return _memories;
    }
    
    final searchLower = _searchText.toLowerCase();
    return _memories.where((memory) {
      return memory.title.toLowerCase().contains(searchLower) ||
          memory.description.toLowerCase().contains(searchLower) ||
          memory.authorName.toLowerCase().contains(searchLower);
    }).toList();
  }  // Removed _shareForum method as it's no longer needed
  
  void _addNewMemory() {
    AccessibilityService().speak(
      _isTurkish
          ? 'Yeni anı ekleme sayfasına gidiliyor'
          : 'Navigating to add new memory page',
    );
    context.go('/create-memory');
  }

  // Save the current playing memory ID to SharedPreferences
  Future<void> _savePlayingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_playingMemoryId != null) {
      await prefs.setInt('forum_playing_memory_id', _playingMemoryId!);
    } else {
      await prefs.remove('forum_playing_memory_id');
    }
  }
  // Load the previously playing memory ID from SharedPreferences
  Future<void> _loadPlayingState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlayingMemoryId = prefs.getInt('forum_playing_memory_id');
    
    // Only restore the playing state if the audio was actually playing
    if (savedPlayingMemoryId != null) {
      // We need to verify if this memory still exists in our list before setting the state
      setState(() {
        // This will be validated once memories are loaded
        _playingMemoryId = savedPlayingMemoryId;
      });
    }
  }

  // Save the scroll position for state restoration
  Future<void> _saveScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('forum_scroll_position', _scrollController.offset);
  }

  // Restore the scroll position when returning to the screen
  Future<void> _restoreScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPosition = prefs.getDouble('forum_scroll_position');
    if (savedPosition != null && _scrollController.hasClients) {
      _scrollController.jumpTo(savedPosition);
    }
  }

  // Save the search text
  Future<void> _saveSearchText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('forum_search_text', _searchText);
  }

  // Load the search text
  Future<void> _loadSearchText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearchText = prefs.getString('forum_search_text');
    if (savedSearchText != null) {
      setState(() {
        _searchText = savedSearchText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Update the navigation controller to reflect current screen
    final navigationController = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    navigationController.changeIndex(2); // Forum is now the 3rd tab (index 2)

    return Scaffold(      appBar: AppBar(
        title: Text(_isTurkish ? 'Anılar Forumu' : 'Memories Forum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
            AccessibilityService().speak(_isTurkish ? 'Ana ekrana dön' : 'Back to home screen');
          },
          tooltip: _isTurkish ? 'Ana ekrana dön' : 'Back to home',
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: _isTurkish ? 'Anılarda ara' : 'Search memories',
          ),
          // Removed share button
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredMemories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.forum,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isTurkish ? 'Anı bulunamadı' : 'No memories found',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchText.isNotEmpty
                            ? (_isTurkish
                                ? 'Arama kriterlerinizi değiştirmeyi deneyin'
                                : 'Try adjusting your search criteria')
                            : (_isTurkish
                                ? 'Henüz paylaşılmış anı yok'
                                : 'No memories have been shared yet'),
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredMemories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {                    final memory = _filteredMemories[index];
                    final memoryId = int.tryParse(memory.id);
                    final bool isPlaying = _playingMemoryId == memoryId;
                    
                    // Force refresh button state when audio state changes
                    if (_playingMemoryId != null && _playingMemoryId != memoryId) {
                      // Ensure only one memory plays at a time
                      AccessibilityService().stopSpeaking();
                    }
                    
                    return Semantics(
                      button: true,
                      label: memory.accessibilityLabel,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: InkWell(
                          onTap: () => _openMemoryDetail(memory),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Memory content
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      memory.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Description
                                    Text(
                                      memory.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Author and date
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          memory.authorName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(memory.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Action bar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [                                    // Compact play/stop button that matches screenshot
                                    TextButton.icon(
                                      onPressed: () => _toggleAudio(memory),
                                      style: TextButton.styleFrom(
                                        backgroundColor: isPlaying ? Colors.red.shade50 : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      ),
                                      icon: Icon(
                                        isPlaying ? Icons.stop : Icons.play_arrow,
                                        color: isPlaying ? Colors.red : AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        isPlaying ? 'Stop' : (_isTurkish ? 'Dinle' : 'Play'),
                                        style: TextStyle(
                                          color: isPlaying ? Colors.red : AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    
                                    // Like button
                                    TextButton.icon(
                                      onPressed: () {
                                        _forumService.likeMemory(memory.id);
                                        AccessibilityService().speakWithFeedback(
                                          _isTurkish ? 'Beğenildi' : 'Liked',
                                          FeedbackType.success,
                                        );
                                      },
                                      icon: const Icon(Icons.favorite_border, color: AppTheme.primaryColor),
                                      label: Text(
                                        '${memory.likeCount}',
                                        style: const TextStyle(color: AppTheme.primaryColor),
                                      ),
                                    ),
                                    
                                    // Comments button
                                    TextButton.icon(
                                      onPressed: () => _openMemoryDetail(memory),
                                      icon: const Icon(Icons.comment_outlined, color: AppTheme.primaryColor),
                                      label: Text(
                                        '${memory.commentCount}',
                                        style: const TextStyle(color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMemory,
        tooltip: _isTurkish ? 'Yeni anı paylaş' : 'Share new memory',
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AccessibleBottomNav(onTabChanged: _handleTabChange),
    );
  }  @override
  void dispose() {
    // Stop any playing audio when navigating away
    if (_playingMemoryId != null) {
      AccessibilityService().stopSpeaking();
    }
    
    // Clear the completion callback
    AccessibilityService().clearCompletionCallback();
    
    // Save state before disposing
    if (_scrollController.hasClients) {
      _saveScrollPosition();
    }
    
    _memoriesSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
