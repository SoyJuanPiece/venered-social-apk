import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/main_navigation_screen.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/register_page.dart';

// --- FUNCIÓN PRINCIPAL Y CONFIGURACIÓN DE LA APP ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONECTADO A TU BACKEND DE SUPABASE ---
  await Supabase.initialize(
    url: 'https://nlwhegfakwzdtaxehood.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sd2hlZ2Zha3d6ZHRheGVob29kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDA5ODYsImV4cCI6MjA4NzQ3Njk4Nn0.DI8_BUf1_ON92rYHYzZzjjBHw_fKvdA6Nbg5E_BKOVk',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venered Social',
      theme: ThemeData(
        useMaterial3: true, // Activate Material 3
        brightness: Brightness.light,
                  primaryColor: const Color(0xFF0095F6), // Instagram-like blue
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF0095F6), // Primary color for seed
                    primary: const Color(0xFF0095F6), // Instagram-like blue
                    secondary: const Color(0xFF00C853), // Keep vibrant green accent
                    surface: Colors.white, // Keep white for cards, input fills
                    background: Colors.white, // Pure white background
                    error: const Color(0xFFEF5350), // Error color
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    onSurface: const Color(0xFF262626), // Dark text for white surfaces
                    onBackground: const Color(0xFF262626), // Dark text for white background
                    onError: Colors.white,
                  ),        scaffoldBackgroundColor: Colors.white, // Pure white background

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1B), // App bar text/icons are dark
          elevation: 0.0, // No shadow for app bar
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1B)),
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFFF8F9FA), // Use surface color for cards
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for cards
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), // Adjust margin
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3F51B5), // Active icon color
          unselectedItemColor: const Color(0xFF65676B), // Inactive icon color
          elevation: 0.0, // No shadow for bottom nav bar
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
        
        navigationBarTheme: NavigationBarThemeData( // For Material 3 NavigationBar
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF3F51B5).withOpacity(0.1), // Subtle indicator
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: Color(0xFF3F51B5), fontSize: 12, fontWeight: FontWeight.bold);
            }
            return const TextStyle(color: Color(0xFF65676B), fontSize: 12);
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFF3F51B5));
            }
            return const IconThemeData(color: Color(0xFF65676B));
          }),
        ),

        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1B)),
          headlineMedium: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1B)),
          titleLarge: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1B)),
          bodyLarge: TextStyle(fontSize: 16.0, color: const Color(0xFF1A1A1B)),
          bodyMedium: TextStyle(fontSize: 14.0, color: const Color(0xFF65676B)),
          labelLarge: const TextStyle(fontWeight: FontWeight.bold),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: const Color(0xFF3F51B5), // Text color for button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: const StadiumBorder(), // Rounded button shape
            elevation: 0, // No shadow for elevated buttons
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3F51B5), // Text color for button
            side: const BorderSide(color: Color(0xFF3F51B5)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA), // Input fill color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Rounded input borders
            borderSide: BorderSide.none, // No border line
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1), // Focused border
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          labelStyle: const TextStyle(color: Color(0xFF65676B)),
          hintStyle: const TextStyle(color: Color(0xFF65676B)),
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // --- LÓGICA DE NAVEGACIÓN INICIAL ---
      // Si el usuario ya está logueado, va a HomePage, si no, a LoginPage.
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const MainNavigationScreen(),
    );
  }
}
