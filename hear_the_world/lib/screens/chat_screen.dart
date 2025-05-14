import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import '../services/accessibility_service.dart';
import '../services/openai_service.dart';
import '../services/session_manager.dart';
import '../utils/permission_helper.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;
  bool _isTurkish = false; // For localization support

  // For recording voice input
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    // Welcome message when screen opens
    _addMessage(
      'Welcome to Hear The World. Use the camera or type a question.',
      MessageType.system,
    );

    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'New chat screen. Use the camera button to take a photo or type a question.',
      );

      // Start camera process automatically
      Future.delayed(const Duration(milliseconds: 500), () {
        _captureAndAnalyzePhoto();
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Capture photo and analyze with OpenAI
  Future<void> _captureAndAnalyzePhoto() async {
    try {
      // Request camera permission
      bool hasPermission = await PermissionHelper.requestCameraPermission(
        context,
      );

      if (!hasPermission) {
        AccessibilityService().speak(
          _isTurkish ? 'Kamera izni gereklidir' : 'Camera permission required',
        );
        return;
      }

      // Set processing state
      setState(() {
        _isProcessing = true;
      });

      // Show loading message
      _addMessage(
        _isTurkish ? 'Kamera açılıyor...' : 'Opening camera...',
        MessageType.loading,
      );

      // Show a message to the user that the camera is opening
      AccessibilityService().speak(
        _isTurkish ? 'Kamera açılıyor' : 'Opening camera',
      );

      // Capture photo with camera
      XFile? photo;
      try {
        photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
      } catch (cameraError) {
        // Handle camera errors
        setState(() {
          _isProcessing = false;
          // Remove loading message if it exists
          if (_messages.isNotEmpty &&
              _messages.last.type == MessageType.loading) {
            _messages.removeLast();
          }
        });

        AccessibilityService().speak(
          _isTurkish ? 'Kamera hatası oluştu' : 'Camera error occurred',
        );
        if (kDebugMode) {
          print('Camera error: $cameraError');
        }
        return;
      }

      // Check if user canceled the photo
      if (photo == null) {
        setState(() {
          _isProcessing = false;
          // Remove loading message if it exists
          if (_messages.isNotEmpty &&
              _messages.last.type == MessageType.loading) {
            _messages.removeLast();
          }
        });

        AccessibilityService().speak(
          _isTurkish
              ? 'Fotoğraf çekimi iptal edildi'
              : 'Photo capture canceled',
        );
        return;
      }

      // Update loading message
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.type == MessageType.loading) {
          _messages.removeLast();
        }
        _addMessage(
          _isTurkish
              ? 'Fotoğraf analiz ediliyor, lütfen bekleyin...'
              : 'Analyzing photo, please wait...',
          MessageType.loading,
        );
      });

      // Camera has been successfully used, inform user that analysis is now happening
      AccessibilityService().speak(
        _isTurkish
            ? 'Fotoğraf analiz ediliyor, lütfen bekleyin'
            : 'Analyzing photo, please wait',
      );

      // Create a File object from the XFile
      File imageFile;
      try {
        // Geçici bir değişken kullan
        final String filePath = photo.path;

        if (kDebugMode) {
          print('Trying to create File from path: $filePath');
        }

        // Önce yolun boş olup olmadığını kontrol et
        if (filePath.isEmpty) {
          throw Exception('Photo path is empty');
        }

        // Dosyayı oluştur
        imageFile = File(filePath);

        // Dosya var mı diye kontrol et
        final bool fileExists = await imageFile.exists();

        if (kDebugMode) {
          print('File exists check result: $fileExists for path: $filePath');
        }

        if (!fileExists) {
          throw Exception('Image file does not exist at path: $filePath');
        }

        // Dosya boyutunu kontrol et
        final int fileSize = await imageFile.length();

        if (kDebugMode) {
          print('File size: $fileSize bytes');
        }

        if (fileSize <= 0) {
          throw Exception('Image file is empty (0 bytes)');
        }

        // Dosya okunabilir mi diye kontrol et
        try {
          final bytes = await imageFile.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('Could not read any bytes from file');
          }

          if (kDebugMode) {
            print('Successfully read ${bytes.length} bytes from file');
          }
        } catch (readError) {
          if (kDebugMode) {
            print('Error reading file bytes: $readError');
          }
          throw Exception('Failed to read file contents: $readError');
        }
      } catch (fileError) {
        setState(() {
          _isProcessing = false;
          // Remove loading message if it exists
          if (_messages.isNotEmpty &&
              _messages.last.type == MessageType.loading) {
            _messages.removeLast();
          }
        });

        // Detaylı hata mesajı ekleyin
        final String errorMessage =
            'File processing error: ${fileError.toString()}';

        AccessibilityService().speak(
          _isTurkish
              ? 'Dosya işleme hatası oluştu: ${fileError.toString()}'
              : errorMessage,
        );

        // Hata mesajını UI'da göster
        _addMessage(errorMessage, MessageType.system);

        if (kDebugMode) {
          print('File error: $fileError');
        }
        return;
      }

      // Use OpenAI service to analyze the image
      String? analysis;
      try {
        final result = await OpenAIService().analyzeImage(imageFile);

        if (result.isEmpty) {
          throw Exception('API returned empty result');
        }

        analysis = result;

        if (kDebugMode) {
          print(
            'Received analysis from API: ${analysis.substring(0, min(100, analysis.length))}...',
          );
        }
      } catch (aiError) {
        setState(() {
          _isProcessing = false;
          // Remove loading message if it exists
          if (_messages.isNotEmpty &&
              _messages.last.type == MessageType.loading) {
            _messages.removeLast();
          }
        });

        AccessibilityService().speak(
          _isTurkish
              ? 'Görsel analiz hatası oluştu'
              : 'Image analysis error occurred',
        );

        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isTurkish
                  ? 'Görsel analizi yapılamadı: ${aiError.toString()}'
                  : 'Failed to analyze image: ${aiError.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );

        if (kDebugMode) {
          print('AI analysis error: $aiError');
        }
        return;
      }

      // Remove loading message and add analysis
      setState(() {
        _isProcessing = false;
        // Remove loading message if it exists
        if (_messages.isNotEmpty &&
            _messages.last.type == MessageType.loading) {
          _messages.removeLast();
        }

        if (analysis != null) {
          // Ensure analysis is non-null
          _addMessage(analysis, MessageType.system);
        } else {
          throw Exception('Analysis result is null');
        }
      });

      // Create a new chat session with the analysis
      final newSession = ChatSession(
        id: _uuid.v4(),
        summary: analysis,
        timestamp: DateTime.now(),
        messages: [
          ChatMessage(
            id: _uuid.v4(),
            content: analysis,
            type: MessageType.system,
            timestamp: DateTime.now(),
          ),
        ],
      );

      // Add session to SessionManager
      Provider.of<SessionManager>(
        context,
        listen: false,
      ).addSession(newSession);

      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Announce the response is ready
      AccessibilityService().speakWithFeedback(
        _isTurkish
            ? 'Analiz tamamlandı. ${analysis.length > 50 ? analysis.substring(0, 50) + '...' : analysis}'
            : 'Analysis complete. ${analysis.length > 50 ? analysis.substring(0, 50) + '...' : analysis}',
        FeedbackType.success,
      );
    } catch (e) {
      // General error handler
      setState(() {
        _isProcessing = false;
        // Remove loading message if it exists
        if (_messages.isNotEmpty &&
            _messages.last.type == MessageType.loading) {
          _messages.removeLast();
        }
      });

      AccessibilityService().speak(
        _isTurkish
            ? 'Fotoğraf analizi sırasında hata oluştu'
            : 'Error analyzing photo',
      );
      if (kDebugMode) {
        print('Photo capture error: $e');
      }
    }
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();

      // Add user message
      _addMessage(text, MessageType.user);

      // Show processing indicator
      setState(() {
        _isProcessing = true;
      });

      // Simulate receiving a response after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isProcessing = false;
        });

        // Add system response based on user query
        if (text.toLowerCase().contains('sunglasses')) {
          _addMessage(
            'The sunglasses have black frames with polarized lenses. They appear to be Ray-Ban Wayfarer style. They are placed with lenses facing up.',
            MessageType.system,
          );
        } else if (text.toLowerCase().contains('phone') ||
            text.toLowerCase().contains('iphone')) {
          _addMessage(
            'The smartphone is an iPhone 13 Pro with a dark blue case. The screen is facing up and appears to be in sleep mode.',
            MessageType.system,
          );
        } else if (text.toLowerCase().contains('coffee') ||
            text.toLowerCase().contains('mug')) {
          _addMessage(
            'The coffee mug is white ceramic with steam rising, indicating it\'s hot. It\'s filled approximately 3/4 full with what appears to be black coffee. No cream or sugar visible.',
            MessageType.system,
          );
        } else if (text.toLowerCase().contains('notebook') ||
            text.toLowerCase().contains('pen')) {
          _addMessage(
            'The notebook is a spiral-bound notebook with blue cover. It\'s open to a page with some handwritten notes. The pen is a black ballpoint pen resting on top of the notebook.',
            MessageType.system,
          );
        } else {
          _addMessage(
            'I\'m not sure about that specific detail. Would you like me to describe one of the objects I can see? (sunglasses, phone, coffee mug, or notebook)',
            MessageType.system,
          );
        }

        // Provide haptic feedback and audio notification
        HapticFeedback.mediumImpact();
        AccessibilityService().speak('Response ready.');
      });
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      AccessibilityService().speak(
        'Voice recording started. Tap again to stop.',
      );
      // In a real app, this would start recording voice input
    } else {
      AccessibilityService().speak('Voice recording stopped.');

      // Simulate processing voice to text
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _textController.text = 'Tell me more about the coffee mug';
        });
        AccessibilityService().speak('Voice transcribed. Ready to send.');
      });
    }
  }

  void _addMessage(String text, MessageType type) {
    final message = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      type: type,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom after adding message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
          tooltip: 'Back to home',
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                // Different styling based on message type
                if (message.type == MessageType.loading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.regularTextSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isUserMessage = message.type == MessageType.user;

                return Semantics(
                  label:
                      isUserMessage
                          ? 'You said: ${message.content}'
                          : 'System response: ${message.content}',
                  child: Align(
                    alignment:
                        isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isUserMessage
                                ? AppTheme.primaryColor
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color:
                                  isUserMessage
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                              fontSize: AppTheme.regularTextSize,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.formattedTime,
                            style: TextStyle(
                              color:
                                  isUserMessage
                                      ? Colors.white.withOpacity(0.7)
                                      : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Microphone button
                  Semantics(
                    button: true,
                    label:
                        _isRecording
                            ? 'Stop recording voice input'
                            : 'Start recording voice input',
                    child: GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              _isRecording
                                  ? AppTheme.error
                                  : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tap to type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Semantics(
                    button: true,
                    label: 'Send message',
                    child: GestureDetector(
                      onTap: _handleSubmit,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              _isProcessing
                                  ? AppTheme.textSecondary
                                  : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isProcessing ? Icons.hourglass_top : Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
