import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:venered_social/utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String? _selectedEstado;
  File? _newProfilePicFile;
  bool _isLoading = false;

  static const String _imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb'; 

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.initialProfile['username']);
    _bioController = TextEditingController(text: widget.initialProfile['bio']);
    _selectedEstado = widget.initialProfile['estado'];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newProfilePicFile = File(pickedFile.path));
    }
  }

  Future<void> _deleteImgbbImage(String deleteUrl) async {
    try { await http.get(Uri.parse(deleteUrl)); } catch (_) {}
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? newProfilePicUrl = widget.initialProfile['profile_pic_url'];
      String? newProfilePicDeletehash = widget.initialProfile['profile_pic_deletehash'];

      if (_newProfilePicFile != null) {
        if (widget.initialProfile['profile_pic_deletehash'] != null) {
          await _deleteImgbbImage(widget.initialProfile['profile_pic_deletehash']);
        }

        // COMPRESIÓN ANTES DE SUBIR PERFIL
        final compressedFile = await compressImage(_newProfilePicFile!);
        final uploadFile = compressedFile ?? _newProfilePicFile!;

        final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'))
          ..files.add(await http.MultipartFile.fromPath('image', uploadFile.path));

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(responseBody);
          newProfilePicUrl = decodedResponse['data']['url'];
          newProfilePicDeletehash = decodedResponse['data']['delete_url'];
        }
      }

      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'estado': _selectedEstado,
        'profile_pic_url': newProfilePicUrl,
        'profile_pic_deletehash': newProfilePicDeletehash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Solo puedes cambiar tu estado')) msg = 'Restricción: 7 días para cambiar estado.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        elevation: 0,
        actions: [
          if (_isLoading) const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else TextButton(onPressed: _updateProfile, child: Text('Guardar', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), 
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: _newProfilePicFile != null
                            ? FileImage(_newProfilePicFile!)
                            : (widget.initialProfile['profile_pic_url'] != null ? NetworkImage(widget.initialProfile['profile_pic_url']) : null),
                        child: _newProfilePicFile == null && (widget.initialProfile['profile_pic_url'] == null)
                            ? const Icon(Icons.person, size: 60) : null,
                      ),
                    ),
                    TextButton(onPressed: _pickImage, child: const Text('Cambiar foto')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Información básica', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Nombre de Usuario', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Biografía', prefixIcon: Icon(Icons.info_outline)), maxLines: 3),
              const SizedBox(height: 24),
              const Text('Ubicación Regional', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(labelText: 'Estado de Venezuela', prefixIcon: Icon(Icons.location_on_outlined), helperText: 'Cambio permitido cada 7 días.'),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                items: estadosVenezuela.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedEstado = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
