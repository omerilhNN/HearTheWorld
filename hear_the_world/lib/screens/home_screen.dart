import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Bu importu geçici olarak kaldırıyorum
import 'package:provider/provider.dart';

import '../services/accessibility_service.dart';
import '../services/locale_provider.dart';
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

  // Ses çalma durumunu izleyen değişken
  int? _playingSessionId;
  
  // Dil durumu
  bool _isTurkish = false;

  @override
  void initState() {
    super.initState();
    
    // Başlangıçta ekran bildirimi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'Home screen. Tap the center of the screen to start a new chat.',
      );
    });
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
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
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
        context.go('/settings');
        break;
      case 3:
        context.go('/forum');
        break;
    }
  }

  void _startNewChat() {
    AccessibilityService().speakWithFeedback(
      _isTurkish 
          ? 'Yeni sohbet başlatılıyor. Raspberry Pi\'ye bağlanılıyor...'
          : 'Starting new chat. Connecting to Raspberry Pi...',
      FeedbackType.info,
    );
    context.go('/chat');
  }

  void _playAudio(ChatSession session) {
    setState(() {
      if (_playingSessionId == int.tryParse(session.id)) {
        // Eğer bu session zaten çalıyorsa, durdur
        _playingSessionId = null;
        AccessibilityService().stopSpeaking();
        AccessibilityService().speak(_isTurkish ? 'Ses durduruldu' : 'Audio stopped');
      } else {
        // Yeni sesli anlatımı başlat
        _playingSessionId = int.tryParse(session.id);
        AccessibilityService().speak(session.summary);
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
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _playAudio(session),
                          icon: const Icon(Icons.volume_up),
                          label: Text(_isTurkish ? 'Sesi Oynat' : 'Play Audio'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            AccessibilityService().speak(
                              _isTurkish 
                                ? 'Bu demoda görsel görüntüleme özelliği mevcut değil' 
                                : 'View image feature not implemented in this demo',
                            );
                          },
                          icon: const Icon(Icons.image),
                          label: Text(_isTurkish ? 'Görseli Görüntüle' : 'View Image'),
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
    // In a real app, this would delete from storage
    setState(() {
      _recentSessions.removeWhere((session) => session.id == id);
    });
    AccessibilityService().speakWithFeedback(
      _isTurkish ? 'Sohbet oturumu silindi' : 'Chat session deleted',
      FeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider değişikliklerini otomatik algılamak için Consumer kullanıyoruz
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        // Değişikliği kontrol ediyoruz
        final isTurkish = localeProvider.locale.languageCode == 'tr';
        
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
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                  AccessibilityService().speak(_isTurkish ? 'Menü açıldı' : 'Menu opened');
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
                        const Icon(Icons.hearing, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _isTurkish ? 'Dünyayı Duy' : 'Hear The World',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(_isTurkish ? 'Ayarlar' : 'Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                      AccessibilityService().speak(_isTurkish ? 'Ayarlar ekranı' : 'Settings screen');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.forum),
                    title: Text(_isTurkish ? 'Anılar Forumu' : 'Memories Forum'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/forum');
                      AccessibilityService().speak(_isTurkish ? 'Anılar forumu ekranı' : 'Memories forum screen');
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
              // New Chat Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: _startNewChat,
                  child: Semantics(
                    button: true,
                    label: _isTurkish 
                        ? 'Yeni Sohbet. Raspberry Pi\'den canlı görüntü istemek için dokunun'
                        : 'New Chat. Tap to request live image from Raspberry Pi',
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
                                    _isTurkish ? 'Yeni Sohbet' : 'New Chat',
                                    style:
                                        Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isTurkish 
                                        ? 'Raspberry Pi\'den canlı görüntü iste'
                                        : 'Request live image from Raspberry Pi',
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
                ),              ),
              
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
                    label: _isTurkish 
                        ? 'Anılar Forumu. Görme engelli kullanıcıların paylaştığı anıları dinlemek için dokunun'
                        : 'Memories Forum. Tap to listen to memories shared by visually impaired users',
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.accentColor.withOpacity(0.3), width: 1),
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
                                color: AppTheme.accentLightColor.withOpacity(0.2),
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
                                    _isTurkish ? 'Anılar Forumu' : 'Memories Forum',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isTurkish 
                                        ? 'Görme engelli kullanıcıların anılarını dinleyin'
                                        : 'Listen to memories from visually impaired users',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: AppTheme.textSecondary),
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

              // Previous Prompts Section Title
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isTurkish ? 'Önceki İstekler' : 'Previous Prompts',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),

              // Previous Prompts List - Alt Alta Düzenlenmiş
              if (_recentSessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_isTurkish ? 'Henüz oturum geçmişi yok' : 'No previous sessions yet'),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      itemCount: _recentSessions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemBuilder: (context, index) {
                        final session = _recentSessions[index];
                        final bool isPlaying = _playingSessionId == int.tryParse(session.id);
                        
                        return Semantics(
                          button: true,
                          label: _isTurkish 
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Tarih başlığı
                                            Text(
                                              session.formattedDate.split('•').first.trim(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            // Saat gösterimi
                                            Text(
                                              session.formattedDate.split('•').last.trim(),
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Ses butonu
                                        IconButton(
                                          onPressed: () => _playAudio(session),
                                          icon: Icon(
                                            isPlaying ? Icons.stop : Icons.volume_up,
                                            color: isPlaying ? Colors.blue : Colors.grey.shade700,
                                          ),
                                          tooltip: isPlaying 
                                              ? (_isTurkish ? 'Sesi durdur' : 'Stop audio')
                                              : (_isTurkish ? 'Sesi oynat' : 'Play audio'),
                                        ),
                                        // Silme butonu
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: _isTurkish ? 'Sil' : 'Delete',
                                          onPressed: () => _deleteSession(session.id),
                                        ),
                                        // Detay butonu
                                        TextButton.icon(
                                          onPressed: () => _openSessionDetail(session),
                                          icon: const Icon(Icons.chevron_right),
                                          label: Text(_isTurkish ? 'Detaylar' : 'Details'),
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
          bottomNavigationBar: AccessibleBottomNav(onTabChanged: _handleTabChange),
        );
      }
    );
  }
}
