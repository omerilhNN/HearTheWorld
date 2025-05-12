import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final ScrollController _scrollController = ScrollController();
  
  List<ForumMemory> _memories = [];
  bool _isLoading = true;
  int? _playingMemoryId;
  String _searchText = '';
  bool _isTurkish = false;

  @override
  void initState() {
    super.initState();
    _loadMemories();
    
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
        context.go('/settings');
        break;
      case 3:
        // Already on forum screen
        break;
    }
  }

  void _toggleAudio(ForumMemory memory) {
    setState(() {
      if (_playingMemoryId != null && int.tryParse(memory.id) == _playingMemoryId) {
        // Stop audio if it's already playing
        _playingMemoryId = null;
        AccessibilityService().stopSpeaking();
        AccessibilityService().speak(_isTurkish ? 'Ses durduruldu' : 'Audio stopped');
      } else {
        // Start playing audio
        _playingMemoryId = int.tryParse(memory.id);
        
        // Play full description for better accessibility
        String textToSpeak = '${memory.title}. ${memory.description}';
        AccessibilityService().speak(textToSpeak);
        
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
      }
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
  }
  void _shareForum() {
    // In a complete implementation, this would share the forum
    AccessibilityService().speak(
      _isTurkish
          ? 'Paylaşım özelliği henüz uygulanmadı'
          : 'Share feature not yet implemented',
    );
  }
  
  void _addNewMemory() {
    AccessibilityService().speak(
      _isTurkish
          ? 'Yeni anı ekleme sayfasına gidiliyor'
          : 'Navigating to add new memory page',
    );
    context.go('/create-memory');
  }

  @override
  Widget build(BuildContext context) {
    // Update the navigation controller to reflect current screen
    final navigationController = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    navigationController.changeIndex(3); // Assuming forum is the 4th tab (index 3)

    return Scaffold(
      appBar: AppBar(
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
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareForum,
            tooltip: _isTurkish ? 'Forumu paylaş' : 'Share forum',
          ),
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
                  itemBuilder: (context, index) {
                    final memory = _filteredMemories[index];
                    final bool isPlaying = _playingMemoryId == int.tryParse(memory.id);
                    
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
                                  children: [
                                    // Play/stop button
                                    TextButton.icon(
                                      onPressed: () => _toggleAudio(memory),
                                      icon: Icon(
                                        isPlaying ? Icons.stop : Icons.volume_up,
                                        color: isPlaying ? AppTheme.error : AppTheme.primaryColor,
                                      ),
                                      label: Text(
                                        isPlaying
                                            ? (_isTurkish ? 'Durdur' : 'Stop')
                                            : (_isTurkish ? 'Dinle' : 'Listen'),
                                        style: TextStyle(
                                          color: isPlaying ? AppTheme.error : AppTheme.primaryColor,
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
