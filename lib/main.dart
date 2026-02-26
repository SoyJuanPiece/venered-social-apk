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
            cardTheme: const CardThemeData(
              color: Colors.black,
              elevation: 0,
              margin: EdgeInsets.zero,
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
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
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
