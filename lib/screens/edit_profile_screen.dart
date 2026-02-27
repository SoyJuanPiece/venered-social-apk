import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  File? _newProfilePicFile;
  bool _isLoading = false;

  // WARNING: HARDCODING API KEYS IS A SECURITY RISK.
  static const String _imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb'; // PROVIDED IMGBB API KEY


  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.initialProfile['username']);
    _bioController = TextEditingController(text: widget.initialProfile['bio']);
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
      setState(() {
        _newProfilePicFile = File(pickedFile.path);
      });
    } else {
    }
  }

  Future<void> _deleteImgbbImage(String deleteUrl) async {
    try {
      // ImgBB delete_url is usually a web page, but we try to trigger it
      await http.get(Uri.parse(deleteUrl));
    } catch (e) {
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? newProfilePicUrl = widget.initialProfile['profile_pic_url'];
      String? newProfilePicDeletehash = widget.initialProfile['profile_pic_deletehash'];

      // 1. Upload new profile picture if selected
      if (_newProfilePicFile != null) {
        // Attempt to delete old image if URL exists
        if (widget.initialProfile['profile_pic_deletehash'] != null &&
            widget.initialProfile['profile_pic_deletehash'].isNotEmpty) {
          await _deleteImgbbImage(widget.initialProfile['profile_pic_deletehash']);
        }

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        )..files.add(await http.MultipartFile.fromPath('image', _newProfilePicFile!.path));

        final response = await request.send();
        final responseBody = await response.stream.bytesToString(); // Read response body once


        if (response.statusCode != 200) {
          throw Exception('Error al subir la nueva imagen de perfil a ImgBB: ${response.statusCode} - $responseBody');
        }

        final decodedResponse = json.decode(responseBody);
        newProfilePicUrl = decodedResponse['data']['url'];
        newProfilePicDeletehash = decodedResponse['data']['delete_url']; // Use delete_url consistently


        if (newProfilePicUrl == null) {
          throw Exception('No se pudo obtener la URL de la nueva imagen de ImgBB. Respuesta: $responseBody');
        }
      } else {
        }

      // 2. Update profile data in Supabase
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile_pic_url': newProfilePicUrl,
        'profile_pic_deletehash': newProfilePicDeletehash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil actualizado exitosamente!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Go back to ProfileScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al actualizar perfil: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _updateProfile,
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), 
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: _newProfilePicFile != null
                      ? FileImage(_newProfilePicFile!)
                      : (widget.initialProfile['profile_pic_url'] != null && widget.initialProfile['profile_pic_url'].isNotEmpty
                          ? NetworkImage(widget.initialProfile['profile_pic_url']) as ImageProvider
                          : null),
                  child: _newProfilePicFile == null && (widget.initialProfile['profile_pic_url'] == null || widget.initialProfile['profile_pic_url'].isEmpty)
                      ? Icon(Icons.person, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.6))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Cambiar foto de perfil'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  fillColor: theme.colorScheme.surface,
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El nombre de usuario es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  fillColor: theme.colorScheme.surface,
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                maxLines: 3,
                minLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}