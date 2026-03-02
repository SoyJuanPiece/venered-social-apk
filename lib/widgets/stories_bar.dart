import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/media_manager.dart';
import '../utils.dart';
import '../screens/story_viewer_screen.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  bool _isUploading = false;
  late Future<List<Map<String, dynamic>>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _fetchStories();
  }

  Future<List<Map<String, dynamic>>> _fetchStories() async {
    try {
      final response = await Supabase.instance.client
          .from('stories_with_profiles')
          .select();
      
      // Agrupar por usuario para mostrar un círculo por persona (como Instagram)
      final List<Map<String, dynamic>> allStories = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> uniqueUsers = {};

      for (var story in allStories) {
        final userId = story['user_id'];
        if (!uniqueUsers.containsKey(userId)) {
          uniqueUsers[userId] = story;
        }
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      dPrint('Error fetching stories: $e');
      return [];
    }
  }

  Future<void> _pickAndUploadStory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Subir Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Subir Foto'),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = (source == 'video') 
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploading = true);
      
      try {
        // 1. Subir a Telegram
        final result = await MediaManager.uploadToTelegram(File(file.path), isStory: true);
        
        if (result != null && result['file_id'] != null) {
          // 2. Registrar en Supabase
          await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'file_id': result['file_id'],
            'media_type': (source == 'video') ? 'video' : 'photo',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Historia publicada!'), backgroundColor: Colors.green),
          );
          
          // 3. Refrescar la lista
          setState(() {
            _storiesFuture = _fetchStories();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _storiesFuture,
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];
          
          // Verificar si yo tengo una historia activa
          final bool hasMyStory = stories.any((s) => s['user_id'] == currentUser?.id);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length + (hasMyStory ? 0 : 1),
            itemBuilder: (context, index) {
              // El primer elemento es siempre "Tu historia" si no tengo una
              if (!hasMyStory && index == 0) {
                return _buildStoryCircle(
                  theme: theme,
                  username: 'Tu historia',
                  imageUrl: null,
                  isMe: true,
                  isUploading: _isUploading,
                  onTap: _pickAndUploadStory,
                );
              }

              // Ajustar el índice para los demás
              final storyIndex = hasMyStory ? index : index - 1;
              final story = stories[storyIndex];
              final isMe = story['user_id'] == currentUser?.id;

              return _buildStoryCircle(
                theme: theme,
                username: isMe ? 'Tu historia' : story['username'],
                imageUrl: story['profile_pic_url'],
                isMe: isMe,
                isUploading: isMe ? _isUploading : false,
                onTap: () {
                  if (isMe && !_isUploading) {
                    _pickAndUploadStory();
                  } else {
                    // Abrir el visor de historias
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewerScreen(
                          stories: stories,
                          initialIndex: storyIndex,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({
    required ThemeData theme,
    required String username,
    String? imageUrl,
    bool isMe = false,
    bool isUploading = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isMe && !isUploading) 
                      ? null 
                      : const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    border: (isMe && !isUploading) ? Border.all(color: Colors.grey[300]!, width: 2) : null,
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.cardColor,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: isUploading
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : (imageUrl == null ? Icon(Icons.person, size: 32, color: Colors.grey[400]) : null),
                  ),
                ),
                if (isMe && !isUploading)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 74,
              child: Text(
                username,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isMe ? FontWeight.w400 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
