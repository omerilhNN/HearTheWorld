import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/forum_models.dart';
import '../services/accessibility_service.dart';
import '../services/forum_service.dart';
import '../services/locale_provider.dart';
import '../utils/app_theme.dart';

class MemoryDetailScreen extends StatefulWidget {
  final String memoryId;

  const MemoryDetailScreen({super.key, required this.memoryId});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _commentController = TextEditingController();

  ForumMemory? _memory;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isSendingComment = false;
  bool _isTurkish = false;

  @override
  void initState() {
    super.initState();
    _loadMemory();

    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        _isTurkish
            ? 'Anı detayları yükleniyor. Lütfen bekleyin.'
            : 'Loading memory details. Please wait.',
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
      final localeProvider = Provider.of<LocaleProvider>(
        context,
        listen: false,
      );
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

  Future<void> _loadMemory() async {
    try {
      final memory = await _forumService.getMemoryById(widget.memoryId);

      setState(() {
        _memory = memory;
        _isLoading = false;
      });

      if (memory != null) {
        AccessibilityService().speak(
          _isTurkish
              ? '${memory.title} anısı yüklendi. Anı ${memory.authorName} tarafından paylaşıldı.'
              : 'Memory ${memory.title} loaded. Shared by ${memory.authorName}.',
        );
      } else {
        AccessibilityService().speakWithFeedback(
          _isTurkish ? 'Anı bulunamadı' : 'Memory not found',
          FeedbackType.error,
        );

        // Navigate back if memory not found
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/forum');
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      AccessibilityService().speakWithFeedback(
        _isTurkish ? 'Anı yüklenirken hata oluştu' : 'Error loading memory',
        FeedbackType.error,
      );
    }
  }

  void _toggleAudio() {
    if (_memory == null) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // Start playing audio
      AccessibilityService().speakWithFeedback(
        '${_memory!.title}. ${_memory!.description}',
        FeedbackType.info,
      );

      // Provide haptic feedback
      HapticFeedback.mediumImpact();
    } else {
      // Stop audio
      AccessibilityService().stopSpeaking();
      AccessibilityService().speak(
        _isTurkish ? 'Ses durduruldu' : 'Audio stopped',
      );
    }
  }

  Future<void> _submitComment() async {
    if (_memory == null) return;

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      AccessibilityService().speak(
        _isTurkish ? 'Lütfen bir yorum yazın' : 'Please enter a comment',
      );
      return;
    }

    setState(() {
      _isSendingComment = true;
    });

    try {
      // Create new comment
      final comment = ForumComment(
        content: commentText,
        authorName: _isTurkish ? 'Kullanıcı (Siz)' : 'User (You)',
      );

      // Add comment to memory
      final success = await _forumService.addComment(_memory!.id, comment);

      if (success) {
        // Clear comment field
        _commentController.clear();

        // Reload memory to get updated comments
        await _loadMemory();

        AccessibilityService().speakWithFeedback(
          _isTurkish ? 'Yorumunuz eklendi' : 'Your comment was added',
          FeedbackType.success,
        );
      } else {
        AccessibilityService().speakWithFeedback(
          _isTurkish ? 'Yorum eklenirken hata oluştu' : 'Error adding comment',
          FeedbackType.error,
        );
      }
    } catch (e) {
      AccessibilityService().speakWithFeedback(
        _isTurkish ? 'Yorum eklenirken hata oluştu' : 'Error adding comment',
        FeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  void _likeMemory() {
    if (_memory == null) return;

    _forumService.likeMemory(_memory!.id);

    // Update UI immediately for better user experience
    setState(() {
      _memory = _memory!.copyWith(likeCount: _memory!.likeCount + 1);
    });

    // Provide feedback
    HapticFeedback.lightImpact();
    AccessibilityService().speakWithFeedback(
      _isTurkish ? 'Beğenildi' : 'Liked',
      FeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _memory?.title ?? (_isTurkish ? 'Anı Detayı' : 'Memory Detail'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AccessibilityService().speak(
              _isTurkish ? 'Forum ekranına dön' : 'Back to forum',
            );
            context.go('/forum');
          },
          tooltip: _isTurkish ? 'Geri' : 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              AccessibilityService().speak(
                _isTurkish
                    ? 'Paylaşım özelliği henüz uygulanmadı'
                    : 'Share feature not yet implemented',
              );
            },
            tooltip: _isTurkish ? 'Paylaş' : 'Share',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _memory == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTurkish ? 'Anı bulunamadı' : 'Memory not found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Memory title and author info
                    Text(
                      _memory!.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _memory!.authorName,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.smallTextSize,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_memory!.timestamp),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.smallTextSize,
                          ),
                        ),
                      ],
                    ),

                    // Audio player card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      color: Colors.grey.shade50,
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Play/pause button
                            Semantics(
                              button: true,
                              label:
                                  _isPlaying
                                      ? (_isTurkish
                                          ? 'Sesi durdur'
                                          : 'Stop audio')
                                      : (_isTurkish
                                          ? 'Sesi oynat'
                                          : 'Play audio'),
                              child: GestureDetector(
                                onTap: _toggleAudio,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color:
                                        _isPlaying
                                            ? AppTheme.error
                                            : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.stop : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Audio info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isTurkish
                                        ? 'Sesli Anlatım'
                                        : 'Audio Narration',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_memory!.durationSeconds != null)
                                    Text(
                                      _isTurkish
                                          ? 'Süre: ${_memory!.formattedDuration}'
                                          : 'Duration: ${_memory!.formattedDuration}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Like button
                            Column(
                              children: [
                                IconButton(
                                  onPressed: _likeMemory,
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: AppTheme.accentColor,
                                  ),
                                  tooltip: _isTurkish ? 'Beğen' : 'Like',
                                ),
                                Text(
                                  '${_memory!.likeCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Memory description
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _memory!.description,
                        style: TextStyle(
                          fontSize: AppTheme.regularTextSize,
                          height: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    // Memory image (if available)
                    if (_memory!.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTurkish ? 'Görsel' : 'Image',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 2,
                              clipBehavior: Clip.antiAlias,
                              child:
                                  (_memory!.imageUrl!.startsWith('assets/') ||
                                          _memory!.imageUrl!.startsWith('http'))
                                      // For network or asset images
                                      ? Image.network(
                                        _memory!.imageUrl!.startsWith('assets/')
                                            ? 'https://example.com/placeholder.jpg' // Replace with actual asset handling
                                            : _memory!.imageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                      // For file images (captured with camera)
                                      : Image.file(
                                        File(_memory!.imageUrl!),
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                            if (_memory!.imageDescription != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _memory!.imageDescription!,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Comments section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTurkish
                              ? 'Yorumlar (${_memory!.comments.length})'
                              : 'Comments (${_memory!.comments.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),

                    // Comments list
                    if (_memory!.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _isTurkish ? 'Henüz yorum yok' : 'No comments yet',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _memory!.comments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final comment = _memory!.comments[index];
                          return Semantics(
                            label:
                                'Comment by ${comment.authorName}: ${comment.content}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor:
                                                AppTheme.primaryLightColor,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            comment.authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(comment.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Add comment section
                    const SizedBox(height: 24),
                    Text(
                      _isTurkish ? 'Yorum Ekle' : 'Add a Comment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.regularTextSize,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText:
                                  _isTurkish
                                      ? 'Yorumunuzu yazın...'
                                      : 'Write your comment...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: 3,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          button: true,
                          label: _isTurkish ? 'Yorumu gönder' : 'Send comment',
                          child: GestureDetector(
                            onTap: _isSendingComment ? null : _submitComment,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child:
                                  _isSendingComment
                                      ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
