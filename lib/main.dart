import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/main_navigation_screen.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/register_page.dart';
import 'package:venered_social/widgets/post_card.dart';

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

  // Supabase Initialization
  await Supabase.initialize(
    url: 'https://tmpbeurmpiocsefpwnkq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtcGJldXJtcGlvY3NlZnB3bmtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyMTY5NTgsImV4cCI6MjA4Nzc5Mjk1OH0.AtPvatPKCTHGkA5nL17YyNp5edxEQBvpB7-_GzZkwKI',
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
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1), // Indigo vibrante
              secondary: Color(0xFFEC4899), // Rosa vibrante
              surface: Color(0xFF171717),
              background: Color(0xFF0A0A0A),
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF171717),
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF0A0A0A),
              selectedItemColor: Color(0xFF6366F1),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 10,
            ),
            dividerTheme: DividerThemeData(color: Colors.grey[900], thickness: 0.5),
          ),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFFEC4899),
              surface: Colors.white,
              background: Color(0xFFF8FAFC),
              onSurface: Color(0xFF1E293B),
              onBackground: Color(0xFF1E293B),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E293B),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.05),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF6366F1),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 10,
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 0.5),
          ),
          home: Supabase.instance.client.auth.currentSession == null
              ? const LoginPage()
              : const MainNavigationScreen(),
        );
      },
    );
  }
}
