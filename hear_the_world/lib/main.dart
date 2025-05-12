import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/forum_screen.dart';
import 'screens/create_memory_screen.dart';
import 'screens/memory_detail_screen.dart';
import 'services/accessibility_service.dart';
import 'services/locale_provider.dart';
import 'services/forum_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize services
  final accessibilityService = AccessibilityService();
  final localeProvider = LocaleProvider();
  final forumService = ForumService();
  
  await accessibilityService.initialize();
  await forumService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(
    accessibilityService: accessibilityService,
    localeProvider: localeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final AccessibilityService accessibilityService;
  final LocaleProvider localeProvider;
  
  MyApp({
    super.key, 
    required this.accessibilityService,
    required this.localeProvider,
  });
  // Setup router
  final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/forum',
        builder: (context, state) => const ForumScreen(),
      ),      GoRoute(
        path: '/create-memory',
        builder: (context, state) => const CreateMemoryScreen(),
      ),
      GoRoute(
        path: '/memory/:id',
        builder: (context, state) => MemoryDetailScreen(
          memoryId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationController()),
        Provider<AccessibilityService>.value(value: accessibilityService),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'Hear The World',
            theme: AppTheme.lightTheme(),
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            
            // Localization support - AppLocalizations.delegate geçici olarak kaldırıldı
            locale: localeProvider.locale,
            localizationsDelegates: const [
              // AppLocalizations.delegate, // Bu satırı geçici olarak kaldırıyoruz
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocaleProvider.supportedLocales,
            
            // Add accessibility features
            builder: (context, child) {
              return MediaQuery(
                // Large font scaling for accessibility
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.2),
                child: child!,
              );
            },
          );
        }
      ),
    );
  }
}

// Navigation controller for bottom navigation
class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
