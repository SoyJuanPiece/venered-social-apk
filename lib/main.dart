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
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2196F3), // A shade of blue
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo, // Darker primary for overall app
        ).copyWith(
          secondary: const Color(0xFF00C853), // Accent color (e.g., green for actions)
          background: Colors.white,
          surface: Colors.grey[50], // Light grey surface for cards etc.
        ),
        scaffoldBackgroundColor: Colors.grey[100], // Very light grey background

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // App bar text/icons are black
          elevation: 1.0, // Subtle shadow for app bar
          centerTitle: false, // Align title to left like Instagram
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0, // No shadow for cards, as per Instagram feel
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Sharp edges
          ),
          margin: EdgeInsets.zero, // Control margins from parent widgets
        ),

        bottomNavigationBarTheme: BottomNavigationBarTheme(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo, // Active icon color
          unselectedItemColor: Colors.grey[600], // Inactive icon color
          elevation: 1.0, // Subtle shadow
          type: BottomNavigationBarType.fixed, // Ensure icons are fixed
          showSelectedLabels: false, // Hide labels for a cleaner look
          showUnselectedLabels: false,
        ),

        textTheme: TextTheme(
          headlineMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900]),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
          labelLarge: const TextStyle(fontWeight: FontWeight.bold),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.indigo, // Text color for button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.indigo, // Text color for button
            side: const BorderSide(color: Colors.indigo),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
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
