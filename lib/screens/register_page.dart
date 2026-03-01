import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
          setState(() {
            _isOutsideVenezuela = true;
            _isLocating = false;
          });
          return;
        }

        // Mapeo básico para asegurar coincidencia con nuestra lista
        String detectedRegion = regionName;
        if (detectedRegion == 'Caracas') detectedRegion = 'Distrito Capital';
        if (detectedRegion == 'Estado Vargas') detectedRegion = 'Vargas';

        // Buscar coincidencia exacta en nuestra lista de estados
        final match = estadosVenezuela.firstWhere(
          (e) => e.toLowerCase() == detectedRegion.toLowerCase(),
          orElse: () => '',
        );

        setState(() {
          if (match.isNotEmpty) _selectedEstado = match;
          _isLocating = false;
        });
      }
    } catch (e) {
      dPrint('Error detectando ubicación: $e');
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
        const SnackBar(content: Text('Venered Social es exclusivo para Venezuela.'))
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedEstado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona tu estado'),
          backgroundColor: Colors.orange,
        ),
      );
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
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Registro exitoso! Revisa tu email.'), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isOutsideVenezuela) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.public_off_rounded, size: 80, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  'Acceso Restringido',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Venered Social es una red exclusiva para personas dentro de Venezuela.\n\nHemos detectado que te encuentras en otro país.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Volver al inicio', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Venered',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.grandHotel(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Regístrate para ver fotos y videos\nde tus amigos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre de usuario',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedEstado,
                        decoration: const InputDecoration(
                          hintText: 'Selecciona tu estado',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                        items: estadosVenezuela.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(estado, style: GoogleFonts.poppins(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedEstado = value),
                        validator: (value) => value == null ? 'Selecciona un estado' : null,
                        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (_isLocating)
                        const Padding(
                          padding: EdgeInsets.only(right: 40.0),
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading || _isOutsideVenezuela ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Registrarse',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta? ',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Inicia sesión',
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
