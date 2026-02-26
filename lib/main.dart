import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:venered_social/screens/main_navigation_screen.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/register_page.dart';

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

// --- FUNCIÓN PRINCIPAL Y CONFIGURACIÓN DE LA APP ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONECTADO A TU BACKEND DE SUPABASE ---
  await Supabase.initialize(
    url: 'https://nlwhegfakwzdtaxehood.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sd2hlZ2Zha3d6ZHRheGVob29kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDA5ODYsImV4cCI6MjA4NzQ3Njk4Nn0.DI8_BUf1_ON92rYHYzZzjjBHw_fKvdA6Nbg5E_BKOVk',
  );
  
  await ThemeManager.init();
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
          themeMode: mode,
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0095F6),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0095F6),
              brightness: Brightness.dark,
              primary: const Color(0xFF0095F6),
              secondary: const Color(0xFF00C853),
              surface: const Color(0xFF121212),
              background: Colors.black,
              error: const Color(0xFFCF6679),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onBackground: Colors.white,
              onError: Colors.black,
            ),
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0.0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF121212),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey,
              elevation: 0.0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
              bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
              bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0095F6),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0095F6),
              primary: const Color(0xFF0095F6),
              secondary: const Color(0xFF00C853),
              surface: Colors.white,
              background: const Color(0xFFFAFAFA), // Light grey background
              error: const Color(0xFFEF5350),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: const Color(0xFF262626),
              onBackground: const Color(0xFF262626),
              onError: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1A1A1B),
              elevation: 0.5,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF1A1A1B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Color(0xFF1A1A1B)),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Color(0xFF65676B),
              elevation: 0.0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1B)),
              bodyLarge: TextStyle(fontSize: 16.0, color: Color(0xFF1A1A1B)),
              bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF65676B)),
            ),
          ),
          home: Supabase.instance.client.auth.currentSession == null
              ? const LoginPage()
              : const MainNavigationScreen(),
        );
      },
    );
  }
}
