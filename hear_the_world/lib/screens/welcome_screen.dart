import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';
import '../services/accessibility_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        "Welcome to Hear The World. Visual-to-Speech for the Visually Impaired. "
        "Tap the center of the screen to get started, or the top right for help.",
      );
    });
  }

  void _playHelpAudio() {
    AccessibilityService().speakWithFeedback(
      "Hear The World helps you understand your surroundings. "
      "Point your camera at objects and get audio descriptions. "
      "This app connects to your Raspberry Pi camera to identify objects "
      "and read text. Swipe with two fingers to navigate between screens.",
      FeedbackType.info,
    );
  }

  void _navigateToHome() {
    context.go('/home');
    AccessibilityService().speak("Welcome to the main screen.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Semantics(
                    button: true,
                    label: "Help button. Tap to hear app instructions",
                    child: IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: _playHelpAudio,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Logo and App Name
              const Icon(Icons.hearing, size: 120, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Hear The World',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Visual-to-Speech for the Visually Impaired',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
