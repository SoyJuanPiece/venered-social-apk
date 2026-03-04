import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:venered_social/services/media_manager.dart';
import '../utils.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  File? _mediaFile;
  bool _isVideo = false;

  Future<void> _pickMedia(bool isVideo) async {
    final picker = ImagePicker();
    final pickedFile = isVideo 
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
        
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _isVideo = isVideo;
      });
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Foto de la galería'),
                onTap: () { Navigator.pop(context); _pickMedia(false); },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Video de la galería'),
                onTap: () { Navigator.pop(context); _pickMedia(true); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    final description = _descriptionController.text.trim();
    if (_mediaFile == null && description.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? mediaUrl;

      if (_mediaFile != null) {
        if (_isVideo) {
          mediaUrl = await MediaManager.uploadVideoToTelegram(_mediaFile!);
        } else {
          mediaUrl = await MediaManager.uploadToImgBB(_mediaFile!);
        }
        if (mediaUrl == null) throw 'Error al subir el archivo';
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'content': description,
        'media_url': mediaUrl,
        'type': _isVideo ? 'video' : (_mediaFile != null ? 'image' : 'text'),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Publicado con éxito!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        actions: [
          if (_isLoading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))
          else TextButton(onPressed: _uploadPost, child: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPickerOptions,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: _mediaFile != null 
                  ? (_isVideo ? const Icon(Icons.play_circle_fill, size: 64) : Image.file(_mediaFile!, fit: BoxFit.cover))
                  : const Icon(Icons.add_a_photo_outlined, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '¿Qué quieres compartir?'),
            ),
          ],
        ),
      ),
    );
  }
}
