import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Geçici olarak kaldırıyoruz

import '../services/accessibility_service.dart';
import '../services/locale_provider.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../utils/app_theme.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _audioEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'en-US';

  final List<Map<String, dynamic>> _availableLanguages = [
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'tr-TR', 'name': 'Turkish'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'Settings screen. Here you can customize audio and haptic feedback preferences.',
      );
    });
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    final accessibilityService = AccessibilityService();
    setState(() {
      _audioEnabled = accessibilityService.isAudioEnabled;
      _vibrationEnabled = accessibilityService.isHapticEnabled;
      _selectedLanguage = accessibilityService.language;
    });
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
        // Already on settings screen
        break;
      case 3:
        context.go('/forum');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yerelleştirme için AppLocalizations'ı geçici olarak devre dışı bırakıyoruz
    // final AppLocalizations? locale = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Navigation controller'ı güncelle
    final navigationController = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    navigationController.changeIndex(2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'), // locale?.settingsScreenTitle ?? 'Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
            AccessibilityService().speak('Back to home screen');
          },
          tooltip: 'Back to home', // locale?.backToHome ?? 'Back to home',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Audio Mode Settings
          _buildSectionHeader('Audio & Feedback'), // locale?.audioFeedback ?? 'Audio & Feedback'),
          Semantics(
            toggled: _audioEnabled,
            container: true,
            label:
                'Audio mode toggle. ${_audioEnabled ? 'Currently enabled' : 'Currently disabled'}',
            child: SwitchListTile(
              title: Text('Voice Guidance'), // locale?.voiceGuidance ?? 'Voice Guidance'),
              subtitle: Text('Enable spoken feedback'), // locale?.enableSpokenFeedback ?? 'Enable spoken feedback'),
              value: _audioEnabled,
              onChanged: (value) {
                setState(() {
                  _audioEnabled = value;
                });
                AccessibilityService().setAudioEnabled(value);
                AccessibilityService().speakWithFeedback(
                  value ? 'Voice guidance enabled' : 'Voice guidance disabled',
                  FeedbackType.success,
                );
              },
              secondary: Icon(
                _audioEnabled ? Icons.volume_up : Icons.volume_off,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Divider(),
          Semantics(
            toggled: _vibrationEnabled,
            container: true,
            label:
                'Haptic feedback toggle. ${_vibrationEnabled ? 'Currently enabled' : 'Currently disabled'}',
            child: SwitchListTile(
              title: Text('Haptic Feedback'), // locale?.hapticFeedback ?? 'Haptic Feedback'),
              subtitle: Text('Enable vibration on actions'), // locale?.enableVibration ?? 'Enable vibration on actions'),
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                AccessibilityService().setHapticEnabled(value);
                if (_vibrationEnabled) {
                  AccessibilityService().speakWithFeedback(
                    'Haptic feedback enabled',
                    FeedbackType.success,
                  );
                } else {
                  AccessibilityService().speak('Haptic feedback disabled');
                }
              },
              secondary: Icon(
                _vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Language Settings
          _buildSectionHeader('Language'), // locale?.language ?? 'Language'),
          ..._availableLanguages.map((language) {
            final bool isSelected = _selectedLanguage == language['code'];
            return Semantics(
              toggled: isSelected,
              label:
                  '${language['name']} language option. ${isSelected ? 'Currently selected' : 'Not selected'}',
              child: RadioListTile<String>(
                title: Text(language['name']),
                value: language['code'],
                groupValue: _selectedLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                    
                    // Ses asistanı dilini değiştir
                    await AccessibilityService().setLanguage(value);
                    
                    // UI dilini değiştir
                    await localeProvider.setLocale(value);
                    
                    AccessibilityService().speakWithFeedback(
                      'Language changed to ${language['name']}',
                      FeedbackType.success,
                    );
                    
                    // Dil değişiminde arayüz diline yansıması için manuel çeviriler yapılıyor
                    // Manuel çeviri özelliği için kullanıcıya bildiri göster
                    if (value == 'tr-TR') {
                      _updateUILanguage(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dil Türkçe olarak değiştirildi'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else {
                      _updateUILanguage(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language changed to ${language['name']}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                secondary:
                    isSelected
                        ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                        )
                        : const Icon(Icons.language),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Account & Device
          _buildSectionHeader('Account & Device'), // locale?.accountDevice ?? 'Account & Device'),
          ListTile(
            leading: const Icon(Icons.devices, color: AppTheme.primaryColor),
            title: Text('Raspberry Pi Pairing'), // locale?.raspberryPiPairing ?? 'Raspberry Pi Pairing'),
            subtitle: const Text('Connected to MyRaspberryPi'),
            onTap: () {
              AccessibilityService().speak(
                'Raspberry Pi pairing settings. This feature is not implemented in this demo.',
              );
              _showFakeDeviceDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: Text('Sign Out'), // locale?.signOut ?? 'Sign Out'),
            onTap: () {
              AccessibilityService().speak(
                'Sign out is not implemented in this demo',
              );

              // In a real app, this would sign the user out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign out is not implemented in this demo'),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Help & Feedback
          _buildSectionHeader('Help & Feedback'), // locale?.helpFeedback ?? 'Help & Feedback'),
          ListTile(
            leading: const Icon(Icons.help, color: AppTheme.primaryColor),
            title: Text('Help Center'), // locale?.helpCenter ?? 'Help Center'),
            onTap: () {
              AccessibilityService().speak(
                'Help center not implemented in this demo',
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback, color: AppTheme.primaryColor),
            title: Text('Send Feedback'), // locale?.sendFeedback ?? 'Send Feedback'),
            onTap: () {
              AccessibilityService().speak(
                'Send feedback not implemented in this demo',
              );
            },
          ),

          const SizedBox(height: 24),

          // App version info
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Hear The World v1.0.0', // '${locale?.appTitle ?? 'Hear The World'} v1.0.0',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.smallTextSize,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AccessibleBottomNav(onTabChanged: _handleTabChange),
    );
  }

  // Arayüz dilini manuel olarak değiştir
  void _updateUILanguage(bool isTurkish) {
    // Gerçek bir çeviri API'si yerine bu örnekte manuel çeviriler yapıyoruz
    // Bu fonksiyon, gelecekte dil dosyalarının otomatik oluşturulmasıyla değiştirilecek
    setState(() {});
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.largeTextSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 1.5),
      ],
    );
  }

  void _showFakeDeviceDialog() {
    // Yerelleştirme için AppLocalizations'ı geçici olarak devre dışı bırakıyoruz
    // final AppLocalizations? locale = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Paired Devices'), // locale?.pairedDevices ?? 'Paired Devices'),
            content: SizedBox(
              height: 200,
              width: 300,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                    ),
                    title: const Text('MyRaspberryPi'),
                    subtitle: const Text('Online • Last used just now'),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.radio_button_unchecked),
                    title: Text('Add New Device'), // locale?.addNewDevice ?? 'Add New Device'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('CLOSE'), // locale?.close ?? 'CLOSE'),
              ),
            ],
          ),
    );
  }
}
