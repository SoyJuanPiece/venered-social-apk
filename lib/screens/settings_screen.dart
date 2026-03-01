import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/terms_and_conditions_screen.dart';
import 'package:venered_social/screens/mfa_setup_screen.dart';
import 'package:venered_social/screens/verification_request_screen.dart';
import 'package:venered_social/screens/moderation_panel_screen.dart';
import 'package:venered_social/main.dart'; // Import for ThemeManager

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final res = await Supabase.instance.client.from('profiles').select('role').eq('id', user.id).single();
      setState(() => _userRole = res['role'] ?? 'user');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Seguridad y Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Color(0xFF6366F1)),
            title: const Text('Autenticación de Dos Factores (2FA)'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MfaSetupScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined, color: Colors.blue),
            title: const Text('Solicitar Verificación'),
            subtitle: const Text('Obtén el check azul en tu perfil'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationRequestScreen())),
          ),
          if (_userRole == 'moderator' || _userRole == 'admin') ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Administración', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
              title: const Text('Panel de Moderación'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ModerationPanelScreen())),
            ),
          ],
          const Divider(),
...

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
