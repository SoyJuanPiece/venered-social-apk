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
    }
  }

  Future<void> _deleteImgbbImage(String deletehash) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.imgbb.com/1/delete/$deletehash?key=$_imgbbApiKey'),
      );
      if (response.statusCode == 200) {
        debugPrint('Old profile picture deleted from ImgBB.');
      } else {
        debugPrint('Failed to delete old profile picture from ImgBB: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting old profile picture from ImgBB: $e');
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
        // Delete old image from ImgBB if it exists
        if (widget.initialProfile['profile_pic_deletehash'] != null &&
            widget.initialProfile['profile_pic_deletehash'].isNotEmpty) {
          await _deleteImgbbImage(widget.initialProfile['profile_pic_deletehash']);
        }

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        )..files.add(await http.MultipartFile.fromPath('image', _newProfilePicFile!.path));

        final response = await request.send();

        if (response.statusCode != 200) {
          final responseBody = await response.stream.bytesToString();
          throw Exception('Error al subir la nueva imagen de perfil a ImgBB: ${response.statusCode} - $responseBody');
        }

        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        newProfilePicUrl = decodedResponse['data']['url'];
        newProfilePicDeletehash = decodedResponse['data']['deletehash'];

        if (newProfilePicUrl == null || newProfilePicDeletehash == null) {
          throw Exception('No se pudo obtener la URL o el deletehash de la nueva imagen de ImgBB.');
        }
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
              backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : TextButton(
                  onPressed: _updateProfile,
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  backgroundImage: _newProfilePicFile != null
                      ? FileImage(_newProfilePicFile!)
                      : (widget.initialProfile['profile_pic_url'] != null
                          ? NetworkImage(widget.initialProfile['profile_pic_url']) as ImageProvider
                          : null),
                  child: _newProfilePicFile == null && widget.initialProfile['profile_pic_url'] == null
                      ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                      : null,
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Cambiar foto de perfil'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El nombre de usuario es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Biografía'),
                maxLines: 3,
                minLines: 1,
              ),
              // const SizedBox(height: 32),
              // ElevatedButton(
              //   onPressed: _updateProfile,
              //   child: const Text('Guardar Cambios'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
