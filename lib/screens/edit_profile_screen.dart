import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;


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


  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      // profile update without picture changes
      String? newProfilePicUrl = widget.initialProfile['profile_pic_url'];
      String? newProfilePicDeletehash = widget.initialProfile['profile_pic_deletehash'];

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