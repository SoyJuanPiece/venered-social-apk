import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:venered_social/utils.dart';
import 'package:venered_social/services/media_manager.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _selectedEstado;
  File? _newProfilePicFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialProfile['username']);
    _displayNameController = TextEditingController(text: widget.initialProfile['display_name']);
    _bioController = TextEditingController(text: widget.initialProfile['bio']);
    _selectedEstado = widget.initialProfile['estado'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _newProfilePicFile = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? avatarUrl = widget.initialProfile['avatar_url'];

      if (_newProfilePicFile != null) {
        avatarUrl = await MediaManager.uploadToImgBB(_newProfilePicFile!);
        if (avatarUrl == null) throw 'Error al subir la imagen a ImgBB';
      }

      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'estado': _selectedEstado,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (_isLoading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))
          else IconButton(icon: const Icon(Icons.check), onPressed: _updateProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _newProfilePicFile != null 
                    ? FileImage(_newProfilePicFile!) 
                    : (widget.initialProfile['avatar_url'] != null ? NetworkImage(widget.initialProfile['avatar_url']) : null) as ImageProvider?,
                  child: _newProfilePicFile == null && widget.initialProfile['avatar_url'] == null ? const Icon(Icons.camera_alt) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Nombre de usuario')),
              const SizedBox(height: 16),
              TextFormField(controller: _displayNameController, decoration: const InputDecoration(labelText: 'Nombre para mostrar')),
              const SizedBox(height: 16),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Biografía'), maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: estadosVenezuela.contains(_selectedEstado) ? _selectedEstado : null,
                decoration: const InputDecoration(labelText: 'Estado'),
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
