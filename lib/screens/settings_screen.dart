import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/terms_and_conditions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        new MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Center(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () => _logout(context),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Términos y Condiciones'),
              onTap: () {
                Navigator.of(context).push(
                  new MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}