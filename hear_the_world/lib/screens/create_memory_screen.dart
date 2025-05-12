import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/forum_models.dart';
import '../services/accessibility_service.dart';
import '../services/forum_service.dart';
import '../services/locale_provider.dart';
import '../utils/app_theme.dart';

class CreateMemoryScreen extends StatefulWidget {
  const CreateMemoryScreen({super.key});

  @override
  State<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

class _CreateMemoryScreenState extends State<CreateMemoryScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTurkish = false;
  String _recordingStatus = '';
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();

    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        _isTurkish
            ? 'Yeni anı oluşturma ekranı. Burada görme engelli kullanıcılar için paylaşılacak bir anı oluşturabilirsiniz.'
            : 'Create new memory screen. Here you can create a memory to be shared for visually impaired users.',
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

  void _toggleRecording() {
    HapticFeedback.mediumImpact();
    
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        _recordingStatus = _isTurkish ? 'Ses kaydı tamamlandı.' : 'Recording completed.';
      });
      
      AccessibilityService().speakWithFeedback(
        _isTurkish 
            ? 'Ses kaydı durduruldu. ${ _recordingDuration } saniye kaydedildi.' 
            : 'Recording stopped. $_recordingDuration seconds recorded.',
        FeedbackType.success,
      );
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _recordingStatus = _isTurkish ? 'Ses kaydediliyor...' : 'Recording in progress...';
      });
      
      AccessibilityService().speak(
        _isTurkish
            ? 'Ses kaydı başladı. Anınızı anlatmaya başlayın ve bitirdiğinizde tekrar dokunun.'
            : 'Recording started. Start telling your memory and tap again when you finish.',
      );
      
      // Simulate recording duration increase
      _startRecordingSimulation();
    }
  }
  
  void _startRecordingSimulation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration++;
        });
        _startRecordingSimulation(); // Continue simulation
      }
    });
  }

  Future<void> _submitMemory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });
      
      AccessibilityService().speakWithFeedback(
        _isTurkish ? 'Anı kaydediliyor...' : 'Saving memory...',
        FeedbackType.info,
      );
      
      // Create new memory
      final memory = ForumMemory(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        authorName: _isTurkish ? 'Kullanıcı (Siz)' : 'User (You)',
        audioUrl: 'assets/audio/memory_record.mp3', // This would be a real audio URL in a production app
        durationSeconds: _recordingDuration > 0 ? _recordingDuration : null,
      );
      
      try {
        final forumService = ForumService();
        final success = await forumService.addMemory(memory);
        
        if (success) {
          // Navigate back to forum
          if (mounted) {
            AccessibilityService().speakWithFeedback(
              _isTurkish ? 'Anı başarıyla kaydedildi!' : 'Memory saved successfully!',
              FeedbackType.success,
            );
            
            // Delay a bit so the user can hear the feedback
            await Future.delayed(const Duration(milliseconds: 800));
            
            if (mounted) {
              context.go('/forum');
            }
          }
        } else {
          _showErrorMessage();
        }
      } catch (e) {
        _showErrorMessage();
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTurkish ? 'Anı kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.' : 
                       'An error occurred while saving your memory. Please try again.',
        ),
        backgroundColor: AppTheme.error,
      ),
    );
    
    AccessibilityService().speakWithFeedback(
      _isTurkish ? 'Hata oluştu' : 'Error occurred',
      FeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTurkish ? 'Yeni Anı Paylaş' : 'Share New Memory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/forum');
            AccessibilityService().speak(_isTurkish ? 'Forum ekranına dön' : 'Back to forum screen');
          },
          tooltip: _isTurkish ? 'Geri' : 'Back',
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _isTurkish ? 'Anınız kaydediliyor...' : 'Saving your memory...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form title and instructions
                    Text(
                      _isTurkish ? 'Anınızı Paylaşın' : 'Share Your Memory',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTurkish
                          ? 'Hikayenizi yazıp sesli bir kayıt ekleyebilirsiniz. Sesli kayıt eklemek görme engelli kullanıcıların deneyimini zenginleştirecektir.'
                          : 'You can write your story and add an audio recording. Adding an audio recording will enrich the experience for visually impaired users.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.regularTextSize,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title field
                    Semantics(
                      label: _isTurkish ? 'Anı başlığı' : 'Memory title',
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _isTurkish ? 'Başlık' : 'Title',
                          hintText: _isTurkish ? 'Anınız için kısa bir başlık' : 'A short title for your memory',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isTurkish ? 'Lütfen bir başlık girin' : 'Please enter a title';
                          }
                          if (value.trim().length < 3) {
                            return _isTurkish ? 'Başlık çok kısa' : 'Title is too short';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Description field
                    Semantics(
                      label: _isTurkish ? 'Anı açıklaması' : 'Memory description',
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: _isTurkish ? 'Açıklama' : 'Description',
                          hintText: _isTurkish ? 'Anınızı detaylı bir şekilde anlatın' : 'Describe your memory in detail',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isTurkish ? 'Lütfen bir açıklama girin' : 'Please enter a description';
                          }
                          if (value.trim().length < 20) {
                            return _isTurkish ? 'Açıklama çok kısa (en az 20 karakter)' : 'Description is too short (min 20 chars)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Audio recording section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTurkish ? 'Sesli Anlatım' : 'Audio Recording',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isTurkish
                                ? 'Anınızı sesli olarak anlatarak görme engelli kullanıcılar için erişilebilirliği artırın.'
                                : 'Enhance accessibility for visually impaired users by narrating your memory.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          
                          // Recording status and duration
                          if (_recordingStatus.isNotEmpty || _recordingDuration > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _isRecording ? Icons.mic : Icons.mic_off,
                                    color: _isRecording ? AppTheme.error : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _recordingStatus,
                                    style: TextStyle(
                                      color: _isRecording ? AppTheme.error : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_recordingDuration > 0)
                                    Text(
                                      '${(_recordingDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isRecording ? AppTheme.error : AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          
                          // Record button
                          Center(
                            child: Semantics(
                              button: true,
                              label:
                                  _isRecording
                                      ? (_isTurkish ? 'Kaydı durdur' : 'Stop recording')
                                      : (_isTurkish ? 'Ses kaydını başlat' : 'Start voice recording'),
                              child: GestureDetector(
                                onTap: _toggleRecording,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        _isRecording
                                            ? AppTheme.error
                                            : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isRecording ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitMemory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isTurkish ? 'Anıyı Paylaş' : 'Share Memory',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
