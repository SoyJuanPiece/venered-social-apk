import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/main_navigation_screen.dart';
import 'package:venered_social/screens/register_page.dart';
import 'package:venered_social/screens/mfa_verify_screen.dart';
import 'package:venered_social/services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.session != null) {
        NotificationService.login(response.user!.id);
        final factors =
            await Supabase.instance.client.auth.mfa.listFactors();
        if (factors.totp.isNotEmpty) {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const MfaVerifyScreen()));
          }
          return;
        }
      }
      NotificationService.startListening();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return constraints.maxWidth >= 800
          ? _buildWebLayout(context)
          : _buildMobileLayout(context);
    });
  }

  // ── WEB: two-column ───────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07070F) : const Color(0xFFF0F4FF),
      body: Row(
        children: [
          // Left brand panel
          Expanded(
            flex: 55,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF13133A), Color(0xFF0D0D28), Color(0xFF1A0A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative blobs
                  Positioned(top: -80, left: -80, child: _blob(300, const Color(0xFF6366F1), 0.18)),
                  Positioned(bottom: -60, right: -60, child: _blob(260, const Color(0xFFEC4899), 0.18)),
                  Positioned(top: 200, right: 80, child: _blob(150, const Color(0xFF818CF8), 0.12)),
                  // Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFFF472B6)],
                            ).createShader(b),
                            child: Text(
                              'Venered',
                              style: GoogleFonts.grandHotel(
                                fontSize: 72,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Conecta con el mundo\nde forma elegante.',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w300,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _featureLine(Icons.photo_library_outlined,
                              'Comparte fotos y momentos únicos'),
                          const SizedBox(height: 16),
                          _featureLine(Icons.people_outline_rounded,
                              'Conecta con personas de Venezuela'),
                          const SizedBox(height: 16),
                          _featureLine(Icons.verified_outlined,
                              'Perfiles verificados y seguros'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right form panel
          Expanded(
            flex: 45,
            child: Container(
              color: isDark ? const Color(0xFF0C0C1A) : Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(context, isWeb: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(opacity),
            Colors.transparent,
          ]),
        ),
      );

  Widget _featureLine(IconData icon, String text) => Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFF472B6)]).createShader(b),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.72), fontSize: 15)),
        ],
      );

  // ── MOBILE ────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ).createShader(b),
                  child: Text(
                    'Venered',
                    style: GoogleFonts.grandHotel(
                      fontSize: 72,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conecta con el mundo de forma elegante.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                _buildForm(context, isWeb: false),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SHARED FORM ───────────────────────────────────────────────────────────
  Widget _buildForm(BuildContext context, {required bool isWeb}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWeb) ...[
            Text('Bienvenido de vuelta',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                )),
            const SizedBox(height: 6),
            Text('Ingresa tus credenciales para continuar.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                )),
            const SizedBox(height: 36),
          ],
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email inválido' : null,
          ),
          const SizedBox(height: 14),
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text('¿Olvidaste tu contraseña?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 20),
          // Submit button
          Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Iniciar sesión',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿No tienes cuenta? ',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  )),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterPage())),
                child: Text('Regístrate',
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
