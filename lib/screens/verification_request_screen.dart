import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationRequestScreen extends StatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  State<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  final _messageController = TextEditingController();
  String _selectedCategory = 'Creador de contenido';
  bool _isLoading = false;
  final List<String> _categories = [
    'Creador de contenido',
    'Artista',
    'Figura pública',
    'Negocio / Empresa',
    'Deportista',
    'Otro'
  ];

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('verification_requests').insert({
        'user_id': user!.id,
        'category': _selectedCategory,
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solicitud enviada! Revisaremos tu perfil pronto.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Verificación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.verified_rounded, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Verifica tu cuenta',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Las cuentas verificadas tienen un check azul para indicar que son perfiles auténticos de personas notables o marcas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 24),
            const Text('¿Por qué deberíamos verificarte?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Cuéntanos un poco sobre ti o tu marca...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar Solicitud', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
