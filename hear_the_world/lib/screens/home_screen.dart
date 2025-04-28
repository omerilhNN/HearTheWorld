import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/accessibility_service.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../models/chat_models.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data for previous sessions - in a real app, this would come from storage
  final List<ChatSession> _recentSessions = [
    ChatSession(
      id: '1',
      summary: 'Objects on desk: pen, notebook, coffee mug',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      messages: [],
    ),
    ChatSession(
      id: '2',
      summary: 'Kitchen items: plate with sandwich, apple, glass of water',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      messages: [],
    ),
    ChatSession(
      id: '3',
      summary: 'Living room: TV remote, books on shelf, reading glasses',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      messages: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'Home screen. Tap the center of the screen to start a new chat.',
      );
    });
  }

  void _handleTabChange(int index) {
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  void _startNewChat() {
    AccessibilityService().speakWithFeedback(
      'Starting new chat. Connecting to Raspberry Pi...',
      FeedbackType.info,
    );
    context.go('/chat');
  }

  void _playAudio(String summary) {
    AccessibilityService().speak(summary);
  }

  void _deleteSession(String id) {
    // In a real app, this would delete from storage
    setState(() {
      _recentSessions.removeWhere((session) => session.id == id);
    });
    AccessibilityService().speakWithFeedback(
      'Chat session deleted',
      FeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                  AccessibilityService().speak('Menu opened');
                },
                tooltip: 'Open menu',
              ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppTheme.primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hearing, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Hear The World',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                  AccessibilityService().speak('Settings screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  AccessibilityService().speak(
                    'About this application. Hear The World is a visual-to-speech app that helps visually impaired users understand their surroundings.',
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context);
                  AccessibilityService().speak(
                    'Sign out is not implemented in this demo',
                  );
                  // In a real app, this would handle sign out
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // New Chat Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _startNewChat,
              child: Semantics(
                button: true,
                label: 'New Chat. Tap to request live image from Raspberry Pi',
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLightColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat,
                            size: 32,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New Chat',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Request live image from Raspberry Pi',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Previous Prompts Section Title
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Previous Prompts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // Previous Prompts Carousel
          if (_recentSessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No previous sessions yet'),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentSessions.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final session = _recentSessions[index];
                  return Semantics(
                    label:
                        'Previous session from ${session.formattedDate}. ${session.summary}',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.formattedDate,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.smallTextSize,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                session.summary,
                                style: TextStyle(
                                  fontSize: AppTheme.regularTextSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.volume_up),
                                    tooltip: 'Play audio',
                                    onPressed:
                                        () => _playAudio(session.summary),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete this session',
                                    onPressed: () => _deleteSession(session.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: AccessibleBottomNav(onTabChanged: _handleTabChange),
    );
  }
}
