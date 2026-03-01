import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/terms_and_conditions_screen.dart';
import 'package:venered_social/screens/mfa_setup_screen.dart';
import 'package:venered_social/main.dart'; // Import for ThemeManager

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Seguridad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Color(0xFF6366F1)),
            title: const Text('Autenticación de Dos Factores (2FA)'),
            subtitle: const Text('Añade una capa extra de protección'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MfaSetupScreen()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Apariencia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager.themeMode,
            builder: (context, currentMode, child) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Predeterminado del sistema'),
                    value: ThemeMode.system,
                    groupValue: currentMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) ThemeManager.updateTheme(value);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Modo Claro'),
                    value: ThemeMode.light,
                    groupValue: currentMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) ThemeManager.updateTheme(value);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Modo Oscuro'),
                    value: ThemeMode.dark,
                    groupValue: currentMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) ThemeManager.updateTheme(value);
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y Condiciones'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
