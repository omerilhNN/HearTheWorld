import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import '../services/accessibility_service.dart';
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
  bool _isProcessing = false;

  // For recording voice input
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    // Initial loading message when screen opens
    _addMessage('Sending request to Raspberry Pi...', MessageType.loading);

    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'New chat screen. Requesting image from Raspberry Pi. Please wait.',
      );

      // Simulate receiving a response after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _simulateResponse();
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _simulateResponse() {
    // Remove loading message
    if (_messages.isNotEmpty && _messages.last.type == MessageType.loading) {
      setState(() {
        _messages.removeLast();
      });
    }

    // Add simulated system message
    _addMessage(
      'I can see several objects on your desk:\n'
      '1. A pair of sunglasses with black frames\n'
      '2. A smartphone (appears to be an iPhone)\n'
      '3. A coffee mug with steam rising\n'
      '4. A notebook with a pen on top\n\n'
      'Would you like me to provide more details about any of these items?',
      MessageType.system,
    );

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Announce the response is ready
    AccessibilityService().speakWithFeedback(
      'Response ready. I can see several objects on your desk.',
      FeedbackType.success,
    );
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
