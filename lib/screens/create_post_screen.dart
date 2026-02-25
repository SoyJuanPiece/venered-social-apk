import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; // Required for File class
import 'package:http/http.dart' as http; // Required for HTTP requests
import 'dart:convert'; // Required for JSON encoding/decoding

class CreatePostScreen extends StatefulWidget {
  CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  // WARNING: HARDCODING API KEYS IS A SECURITY RISK.
  // In a production app, use environment variables, a backend proxy,
  // or build-time injection to secure this key.
  static const String _imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb'; // PROVIDED IMGBB API KEY

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen y añade una descripción.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // 1. Upload image to ImgBB
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
      )..files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      final response = await request.send();

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Error al subir la imagen a ImgBB: ${response.statusCode} - $responseBody');
      }

      final responseBody = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseBody);
      final imgbbUrl = decodedResponse['data']['url'];

      if (imgbbUrl == null) {
        throw Exception('No se pudo obtener la URL de la imagen de ImgBB.');
      }

      // 2. Insert post data into Supabase Database
      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'image_url': imgbbUrl, // Use ImgBB URL
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada exitosamente!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Go back to feed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear publicación: ${e.toString()}'), backgroundColor: Colors.red),
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
        title: const Text('Crear Publicación'),
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
                  onPressed: _uploadPost,
                  child: Text(
                    'Publicar',
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
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: _imageFile != null
                    ? Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text('Toca para seleccionar imagen', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Escribe una descripción...',
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
