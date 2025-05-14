import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Bu importu geçici olarak kaldırıyorum
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../services/accessibility_service.dart';
import '../services/locale_provider.dart';
import '../services/openai_service.dart';
import '../services/session_manager.dart';
import '../services/forum_service.dart';
import '../utils/permission_helper.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../models/chat_models.dart';
import '../models/forum_models.dart';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tools for photo capture
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  // Audio playback tracking variable
  int? _playingSessionId;

  // Loading state for image analysis
  bool _isAnalyzing = false;

  // Language state
  bool _isTurkish = false;

  // Firebase description state
  String? _description;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _fetchDescription();
    // Başlangıçta ekran bildirimi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'Home screen. Tap the center of the screen to start a new chat.',
      );
    });
  }

  Future<void> _fetchDescription() async {
    final description = await _firebaseService.fetchDescription();
    if (description != null) {
      setState(() {
        _description = description;
      });
    }
  }

  // didChangeDependencies metodunu ekleyerek dil değişikliklerini izliyoruz
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bu metod hem initState'den sonra hem de context bağımlı değişiklikler olduğunda çağrılır
    _updateLanguageState();
  }

  // Dil durumunu güncelleme metodu
  void _updateLanguageState() {
    try {
      final localeProvider = Provider.of<LocaleProvider>(
        context,
        listen: false,
      );
      final languageCode = localeProvider.locale.languageCode;
      final isTurkish = languageCode == 'tr';

      // Eğer _isTurkish değeri değiştiyse state'i güncelleyelim
      if (_isTurkish != isTurkish) {
        setState(() {
          _isTurkish = isTurkish;
        });
      }
    } catch (e) {
      // Provider erişim hatası olursa (örneğin context kullanılamadığında) hatayı yakala
      print('Dil kontrolü sırasında hata: $e');
    }
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
        context.go('/forum');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  // Capture photo and analyze with OpenAI
  Future<void> _captureAndAnalyzePhoto() async {
    try {
      // Request camera permission using the permission helper
      bool hasPermission = await PermissionHelper.requestCameraPermission(
        context,
      );

      if (!hasPermission) {
        AccessibilityService().speak(
          _isTurkish ? 'Kamera izni gereklidir' : 'Camera permission required',
        );
        return;
      }

      // Set analyzing state before launching camera to prevent UI glitches
      setState(() {
        _isAnalyzing = true;
      });

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
          _isAnalyzing = false;
        });
        AccessibilityService().speak(
          _isTurkish
              ? 'Kamera ile ilgili bir hata oluştu'
              : 'Camera error occurred',
        );
        if (kDebugMode) {
          print('Camera error: $cameraError');
        }
        return;
      }

      // Check if user canceled the photo
      if (photo == null) {
        setState(() {
          _isAnalyzing = false;
        });
        AccessibilityService().speak(
          _isTurkish
              ? 'Fotoğraf çekimi iptal edildi'
              : 'Photo capture canceled',
        );
        return;
      }

      // Camera has been successfully used, inform user that analysis is now happening
      AccessibilityService().speak(
        _isTurkish
            ? 'Fotoğraf analiz ediliyor, lütfen bekleyin'
            : 'Analyzing photo, please wait',
      );

      // Create a File object from the XFile
      File imageFile;
      try {
        imageFile = File(photo.path);

        if (!await imageFile.exists()) {
          throw Exception('Image file does not exist');
        }

        // Kontrol amaçlı dosya bilgilerini yazdır
        print('Image file path: ${imageFile.path}');
        print('Image file size: ${await imageFile.length()} bytes');
        print('Image exists: ${await imageFile.exists()}');
      } catch (fileError) {
        setState(() {
          _isAnalyzing = false;
        });
        AccessibilityService().speak(
          _isTurkish
              ? 'Dosya işleme hatası oluştu'
              : 'File processing error occurred',
        );
        if (kDebugMode) {
          print('File error: $fileError');
        }
        return;
      }

      // Use OpenAI service to analyze the image
      String? analysis;
      try {
        // Analiz sonucunu alırken null olabilir durumunu kontrol et
        analysis = await OpenAIService().analyzeImage(imageFile);

        if (analysis.isEmpty) {
          throw Exception('API returned empty result');
        }

        if (kDebugMode) {
          print('Received analysis from API: $analysis');
        }
      } catch (aiError) {
        setState(() {
          _isAnalyzing = false;
        });
        AccessibilityService().speak(
          _isTurkish
              ? 'Görsel analiz hatası oluştu'
              : 'Image analysis error occurred',
        );
        if (kDebugMode) {
          print('AI analysis error: $aiError');
        }

        // Kullanıcıya hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isTurkish
                  ? 'Görsel analizi yapılamadı: $aiError'
                  : 'Failed to analyze image: $aiError',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a new chat session with the analysis
      final sessionId = _uuid.v4();
      final newSession = ChatSession(
        id: sessionId,
        summary: analysis, // API'den gelen gerçek analiz sonucu
        timestamp: DateTime.now(),
        imageUrl: imageFile.path, // Store the image path for reference
        messages: [
          ChatMessage(
            id: _uuid.v4(),
            content: analysis, // API'den gelen gerçek analiz sonucu
            type: MessageType.system,
            timestamp: DateTime.now(),
          ),
        ],
      );

      // Add session using the SessionManager
      try {
        await Provider.of<SessionManager>(
          context,
          listen: false,
        ).addSession(newSession);
        print('Session added successfully: ${newSession.id}');
      } catch (e) {
        print('Error adding session: $e');
      }

      // Also add this as a memory to the forum so it appears on the main screen
      try {
        final forumMemory = ForumMemory(
          title: _isTurkish ? 'Fotoğraf Analizi' : 'Photo Analysis',
          description: analysis, // API'den gelen gerçek analiz sonucu
          authorName: _isTurkish ? 'Sistem' : 'System',
          imageUrl: imageFile.path,
          imageDescription:
              _isTurkish
                  ? 'Kamera ile çekilmiş fotoğraf'
                  : 'Photo taken with camera',
        );

        await ForumService().addMemory(forumMemory);
        print('Memory added to forum successfully');
      } catch (e) {
        print('Error adding memory to forum: $e');
      }

      // Update UI
      setState(() {
        _isAnalyzing = false;
      });

      // Provide audio feedback
      AccessibilityService().speak(
        _isTurkish ? 'Fotoğraf analizi tamamlandı' : 'Photo analysis complete',
      );

      // Session detaylarını göstermek için ekranı güncelle
      if (mounted) {
        setState(() {}); // UI'ı yenile
      }
    } catch (e) {
      // General error handler - this should catch any errors not handled in specific try-catch blocks
      setState(() {
        _isAnalyzing = false;
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

  void _playAudio(ChatSession session) {
    setState(() {
      if (_playingSessionId == int.tryParse(session.id)) {
        // If this session is already playing, stop it
        _playingSessionId = null;
        AccessibilityService().stopSpeaking();
        AccessibilityService().speak(
          _isTurkish ? 'Ses durduruldu' : 'Audio stopped',
        );
      } else {
        // Stop any currently playing audio first
        if (_playingSessionId != null) {
          AccessibilityService().stopSpeaking();
        }

        // Start a new audio playback
        _playingSessionId = int.tryParse(session.id);

        // Make sure we have a valid text to speak
        String textToSpeak = session.summary;
        if (textToSpeak.isEmpty) {
          textToSpeak =
              _isTurkish
                  ? 'Bu oturum için metin bulunamadı'
                  : 'No text found for this session';
        }

        // Start speaking the text
        AccessibilityService().speak(textToSpeak);

        // Provide haptic feedback for better user experience
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _openSessionDetail(ChatSession session) {
    // Show session details in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTurkish ? 'Oturum Detayları' : 'Session Details',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                            AccessibilityService().speak(
                              _isTurkish
                                  ? 'Detaylar kapatıldı'
                                  : 'Details closed',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date and time
                    Text(
                      session.formattedDate,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.smallTextSize,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    Text(
                      _isTurkish ? 'Özet' : 'Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.summary,
                      style: TextStyle(fontSize: AppTheme.regularTextSize),
                    ),

                    // Display image if available
                    if (session.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTurkish ? 'Görsel' : 'Image',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(session.imageUrl!),
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _playAudio(session),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _playingSessionId == int.tryParse(session.id)
                                    ? Colors.red.shade50
                                    : null,
                          ),
                          icon: Icon(
                            _playingSessionId == int.tryParse(session.id)
                                ? Icons.stop
                                : Icons.volume_up,
                          ),
                          label: Text(
                            _playingSessionId == int.tryParse(session.id)
                                ? (_isTurkish ? 'Durdur' : 'Stop')
                                : (_isTurkish ? 'Sesi Oynat' : 'Play Audio'),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              session.imageUrl != null
                                  ? () {
                                    // Show the image in a full-screen dialog
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => Dialog(
                                            insetPadding: const EdgeInsets.all(
                                              10,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AppBar(
                                                  title: Text(
                                                    _isTurkish
                                                        ? 'Fotoğraf'
                                                        : 'Photo',
                                                  ),
                                                  leading: IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: InteractiveViewer(
                                                    child: Image.file(
                                                      File(session.imageUrl!),
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Center(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 48,
                                                              ),
                                                              const SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                _isTurkish
                                                                    ? 'Görsel yüklenemedi'
                                                                    : 'Image could not be loaded',
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    );
                                  }
                                  : null, // Disable button if no image
                          icon: const Icon(Icons.image),
                          label: Text(
                            _isTurkish ? 'Görseli Görüntüle' : 'View Image',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSession(String id) {
    // Delete using SessionManager
    Provider.of<SessionManager>(context, listen: false).deleteSession(id);

    AccessibilityService().speakWithFeedback(
      _isTurkish ? 'Sohbet oturumu silindi' : 'Chat session deleted',
      FeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider değişikliklerini otomatik algılamak için Consumer kullanıyoruz
    return Consumer2<LocaleProvider, SessionManager>(
      builder: (context, localeProvider, sessionManager, _) {
        // Değişikliği kontrol ediyoruz
        final isTurkish = localeProvider.locale.languageCode == 'tr';
        final recentSessions = sessionManager.sessions;

        // _isTurkish değişkenini güncelleyelim (build içinde setState çağırmıyoruz)
        if (_isTurkish != isTurkish) {
          // Frame bitince güncelleme yapalım
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isTurkish = isTurkish;
            });
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isTurkish ? 'Ana Sayfa' : 'Home'),
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                      AccessibilityService().speak(
                        _isTurkish ? 'Menü açıldı' : 'Menu opened',
                      );
                    },
                    tooltip: _isTurkish ? 'Menüyü aç' : 'Open menu',
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
                        const Icon(
                          Icons.hearing,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isTurkish ? 'Dünyayı Duy' : 'Hear The World',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(_isTurkish ? 'Ayarlar' : 'Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                      AccessibilityService().speak(
                        _isTurkish ? 'Ayarlar ekranı' : 'Settings screen',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.forum),
                    title: Text(
                      _isTurkish ? 'Anılar Forumu' : 'Memories Forum',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/forum');
                      AccessibilityService().speak(
                        _isTurkish
                            ? 'Anılar forumu ekranı'
                            : 'Memories forum screen',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(_isTurkish ? 'Hakkında' : 'About'),
                    onTap: () {
                      Navigator.pop(context);
                      AccessibilityService().speak(
                        _isTurkish
                            ? 'Bu uygulama hakkında. Dünyayı Duy, görsel içerikleri sese çevirerek görme engelli kullanıcıların çevrelerini anlamalarına yardımcı olan bir uygulamadır.'
                            : 'About this application. Hear The World is a visual-to-speech app that helps visually impaired users understand their surroundings.',
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(_isTurkish ? 'Çıkış Yap' : 'Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      AccessibilityService().speak(
                        _isTurkish
                            ? 'Çıkış özelliği bu demoda uygulanmamıştır'
                            : 'Sign out is not implemented in this demo',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // Memories Forum Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    AccessibilityService().speakWithFeedback(
                      _isTurkish
                          ? 'Forum ekranına gidiliyor. Görme engelli kullanıcıların paylaştığı anıları dinleyebilirsiniz.'
                          : 'Going to forum screen. Listen to memories shared by visually impaired users.',
                      FeedbackType.info,
                    );
                    context.go('/forum');
                  },
                  child: Semantics(
                    button: true,
                    label:
                        _isTurkish
                            ? 'Anılar Forumu. Görme engelli kullanıcıların paylaştığı anıları dinlemek için dokunun'
                            : 'Memories Forum. Tap to listen to memories shared by visually impaired users',
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      elevation: 2,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.accentLightColor.withOpacity(
                                  0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.forum,
                                size: 28,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isTurkish
                                        ? 'Anılar Forumu'
                                        : 'Memories Forum',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _description ?? "",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
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

              // Camera Button - Take Photo Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Semantics(
                  button: true,
                  label:
                      _isTurkish
                          ? 'Fotoğraf çek butonu. Çevrenizdeki nesneleri tanımlamak için dokunun'
                          : 'Take photo button. Tap to identify objects around you',
                  child: Card(
                    color: AppTheme.primaryLightColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: _captureAndAnalyzePhoto,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 28,
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
                                    _isTurkish ? 'Fotoğraf Çek' : 'Take Photo',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isAnalyzing
                                ? const CircularProgressIndicator()
                                : Icon(
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
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isTurkish ? 'Önceki İstekler' : 'Previous Prompts',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ), // Previous Prompts List - Alt Alta Düzenlenmiş
              if (recentSessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _isTurkish
                        ? 'Henüz oturum geçmişi yok'
                        : 'No previous sessions yet',
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      itemCount: recentSessions.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12.0),
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemBuilder: (context, index) {
                        final session = recentSessions[index];
                        final bool isPlaying =
                            _playingSessionId == int.tryParse(session.id);

                        return Semantics(
                          button: true,
                          label:
                              _isTurkish
                                  ? 'Önceki oturum: ${session.formattedDate}. ${session.summary}'
                                  : 'Previous session from ${session.formattedDate}. ${session.summary}',
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: InkWell(
                              onTap: () => _openSessionDetail(session),
                              borderRadius: BorderRadius.circular(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Tarih başlığı
                                            Text(
                                              session.formattedDate
                                                  .split('•')
                                                  .first
                                                  .trim(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            // Saat gösterimi
                                            Text(
                                              session.formattedDate
                                                  .split('•')
                                                  .last
                                                  .trim(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Ana içerik
                                        Text(
                                          session.summary,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        // Show image thumbnail if available
                                        if (session.imageUrl != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.file(
                                                    File(session.imageUrl!),
                                                    height: 40,
                                                    width: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        height: 40,
                                                        width: 40,
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _isTurkish
                                                      ? 'Görsel içerir'
                                                      : 'Contains image',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Alt kısım - butonlar
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12.0),
                                        bottomRight: Radius.circular(12.0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Audio button
                                        TextButton.icon(
                                          onPressed: () => _playAudio(session),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                isPlaying
                                                    ? Colors.blue.shade50
                                                    : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                              vertical: 6.0,
                                            ),
                                          ),
                                          icon: Icon(
                                            isPlaying
                                                ? Icons.stop
                                                : Icons.volume_up,
                                            color:
                                                isPlaying
                                                    ? Colors.blue
                                                    : Colors.grey.shade700,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isPlaying
                                                ? 'Stop'
                                                : (_isTurkish
                                                    ? 'Dinle'
                                                    : 'Listen'),
                                            style: TextStyle(
                                              color:
                                                  isPlaying
                                                      ? Colors.blue
                                                      : Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        // Silme butonu
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip:
                                              _isTurkish ? 'Sil' : 'Delete',
                                          onPressed:
                                              () => _deleteSession(session.id),
                                        ),
                                        // Detay butonu
                                        TextButton.icon(
                                          onPressed:
                                              () => _openSessionDetail(session),
                                          icon: const Icon(Icons.chevron_right),
                                          label: Text(
                                            _isTurkish ? 'Detaylar' : 'Details',
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
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AccessibleBottomNav(
            onTabChanged: _handleTabChange,
          ),
        );
      },
    );
  }
}
