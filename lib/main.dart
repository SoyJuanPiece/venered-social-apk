import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:venered_social/screens/main_navigation_screen.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/register_page.dart';
import 'package:venered_social/widgets/post_card.dart';
import 'package:venered_social/services/notification_service.dart';

// --- GESTOR DE TEMA ---
class ThemeManager {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    if (theme == 'light') themeMode.value = ThemeMode.light;
    if (theme == 'dark') themeMode.value = ThemeMode.dark;
    if (theme == 'system') themeMode.value = ThemeMode.system;
  }

  static Future<void> updateTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

// --- GESTOR DE DEEP LINKS ---
class DeepLinkHandler {
  static final _appLinks = AppLinks();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void init() {
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  static void _handleUri(Uri uri) async {
    debugPrint('Incoming deep link: $uri');
    if (uri.pathSegments.contains('post')) {
      final postId = uri.pathSegments.last;
      _navigateToPost(postId);
    }
  }

  static void _navigateToPost(String postId) async {
    try {
      final post = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select()
          .eq('id', postId)
          .single();

      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Publicación')),
          body: SingleChildScrollView(child: PostCard(post: post)),
        ),
      ));
    } catch (e) {
      debugPrint('Error navigating to deep link post: $e');
    }
  }
}

// --- FUNCIÓN PRINCIPAL Y CONFIGURACIÓN DE LA APP ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialization
  await Supabase.initialize(
    url: 'https://nlwhegfakwzdtaxehood.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sd2hlZ2Zha3d6ZHRheGVob29kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDA5ODYsImV4cCI6MjA4NzQ3Njk4Nn0.DI8_BUf1_ON92rYHYzZzjjBHw_fKvdA6Nbg5E_BKOVk',
  );
  
  // Firebase Initialization (Requires google-services.json)
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e (Make sure google-services.json is present)');
  }
  
  await ThemeManager.init();
  DeepLinkHandler.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Venered Social',
          navigatorKey: DeepLinkHandler.navigatorKey, // Essential for Deep Linking navigation
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0095F6),
              secondary: Color(0xFF00C853),
              surface: Color(0xFF121212),
              background: Colors.black,
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: Colors.black,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
            dividerTheme: DividerThemeData(color: Colors.grey[900], thickness: 0.5),
          ),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0095F6),
              secondary: Color(0xFF00C853),
              surface: Colors.white,
              background: Color(0xFFFAFAFA),
              onSurface: Colors.black,
              onBackground: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.black),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF2F4F8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFFDBDBDB), thickness: 0.5),
          ),
          home: Supabase.instance.client.auth.currentSession == null
              ? const LoginPage()
              : const MainNavigationScreen(),
        );
      },
    );
  }
}
