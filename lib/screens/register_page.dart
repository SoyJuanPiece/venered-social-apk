import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:venered_social/services/notification_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _selectedEstado;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLocating = true;
  bool _isOutsideVenezuela = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['countryCode'];
        final regionName = data['regionName'];
        if (countryCode != 'VE') {
          setState(() { _isOutsideVenezuela = true; _isLocating = false; });
          return;
        }
        String detectedRegion = regionName;
        if (detectedRegion == 'Caracas') detectedRegion = 'Distrito Capital';
        if (detectedRegion == 'Estado Vargas') detectedRegion = 'Vargas';
        final match = estadosVenezuela.firstWhere(
          (e) => e.toLowerCase() == detectedRegion.toLowerCase(),
          orElse: () => '',
        );
        setState(() {
          if (match.isNotEmpty) _selectedEstado = match;
          _isLocating = false;
        });
      }
    } catch (_) {
      setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isOutsideVenezuela) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venered Social es exclusivo para Venezuela.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEstado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecciona tu estado'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
          'estado': _selectedEstado,
        },
      );
      if (response.user != null) {
        NotificationService.login(response.user!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('¡Registro exitoso! Revisa tu email.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isOutsideVenezuela) return _buildBlockedScreen(theme);
    return LayoutBuilder(builder: (context, constraints) {
      return constraints.maxWidth >= 800
          ? _buildWebLayout(context)
          : _buildMobileLayout(context);
    });
  }

  Widget _buildBlockedScreen(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.redAccent.withOpacity(0.2),
                    Colors.transparent,
                  ]),
                ),
                child: const Icon(Icons.public_off_rounded, size: 72, color: Colors.redAccent),
              ),
              const SizedBox(height: 24),
              Text('Acceso Restringido',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text(
                'Venered Social es una red exclusiva para personas dentro de Venezuela.\n\nHemos detectado que te encuentras en otro país.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.6),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Volver al inicio',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WEB ───────────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07070F) : const Color(0xFFF0F4FF),
      body: Row(
        children: [
          Expanded(
            flex: 55,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF0D0D28), Color(0xFF13133A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(top: -80, right: -80, child: _blob(300, const Color(0xFFEC4899), 0.18)),
                  Positioned(bottom: -60, left: -60, child: _blob(260, const Color(0xFF6366F1), 0.18)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFFF472B6), Color(0xFF818CF8)]).createShader(b),
                            child: Text('Únete hoy',
                                style: GoogleFonts.poppins(
                                    fontSize: 52,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Regístrate para ver fotos y videos\nde tus amigos en Venezuela.',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.78),
                              fontWeight: FontWeight.w300,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _featureLine(Icons.location_on_outlined, 'Conecta con tu comunidad local'),
                          const SizedBox(height: 16),
                          _featureLine(Icons.security_outlined, 'Privacidad y seguridad garantizada'),
                          const SizedBox(height: 16),
                          _featureLine(Icons.star_outline_rounded, 'Contenido auténtico venezolano'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          gradient: RadialGradient(
              colors: [color.withOpacity(opacity), Colors.transparent]),
        ),
      );

  Widget _featureLine(IconData icon, String text) => Row(children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFF818CF8)]).createShader(b),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(text,
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.72), fontSize: 15)),
      ]);

  // ── MOBILE ────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)]).createShader(b),
                child: Text('Venered',
                    style: GoogleFonts.grandHotel(
                        fontSize: 64, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text('Regístrate para ver fotos y videos de tus amigos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 36),
              _buildForm(context, isWeb: false),
              const SizedBox(height: 24),
            ],
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
            Text('Crear cuenta',
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text('Únete a la comunidad venezolana.',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 36),
          ],
          TextFormField(
            controller: _usernameController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Nombre de usuario',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 14),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Selecciona tu estado',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                items: estadosVenezuela
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.poppins(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEstado = v),
                validator: (v) => v == null ? 'Selecciona un estado' : null,
              ),
              if (_isLocating)
                const Padding(
                  padding: EdgeInsets.only(right: 42),
                  child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email inválido' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 28),
          Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
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
              onPressed: _isLoading ? null : _register,
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
                  : Text('Crear cuenta',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿Ya tienes cuenta? ',
                  style: GoogleFonts.poppins(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: Text('Inicia sesión',
                    style: GoogleFonts.poppins(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
