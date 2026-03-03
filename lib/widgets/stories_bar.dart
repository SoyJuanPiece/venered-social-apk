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
  late Future<List<List<Map<String, dynamic>>>> _groupedStoriesFuture;

  @override
  void initState() {
    super.initState();
    _groupedStoriesFuture = _fetchGroupedStories();
  }

  Future<List<List<Map<String, dynamic>>>> _fetchGroupedStories() async {
    try {
      final response = await Supabase.instance.client
          .from('stories_with_profiles')
          .select();
      
      final List<Map<String, dynamic>> allStories = List<Map<String, dynamic>>.from(response);
      final Map<String, List<Map<String, dynamic>>> groups = {};

      for (var story in allStories) {
        final userId = story['user_id'];
        if (!groups.containsKey(userId)) groups[userId] = [];
        groups[userId]!.add(story);
      }

      final myId = Supabase.instance.client.auth.currentUser?.id;
      final sortedGroups = groups.values.toList()..sort((a, b) {
        if (a.first['user_id'] == myId) return -1;
        if (b.first['user_id'] == myId) return 1;
        return DateTime.parse(b.first['created_at']).compareTo(DateTime.parse(a.first['created_at']));
      });

      return sortedGroups;
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Publicar Historia', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.videocam, color: Colors.white)),
                title: const Text('Grabar o subir Video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.photo, color: Colors.white)),
                title: const Text('Tomar o subir Foto'),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final file = (source == 'video') ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final result = await MediaManager.uploadToTelegram(File(file.path), isStory: true);
        if (result != null && result['file_id'] != null) {
          final res = await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'file_id': result['file_id'],
            'media_type': (source == 'video') ? 'video' : 'photo',
          }).select().single();

          // Guardar en cache local inmediatamente para que el dueño no tenga que descargarla
          await MediaManager.registerLocalMedia(res['id'].toString(), file.path, (source == 'video') ? 'video' : 'photo');

          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Historia publicada!'), backgroundColor: Colors.green));
          setState(() { _groupedStoriesFuture = _fetchGroupedStories(); });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _groupedStoriesFuture,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? [];
          final bool hasMyStory = groups.any((g) => g.first['user_id'] == currentUser?.id);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length + (hasMyStory ? 0 : 1),
            itemBuilder: (context, index) {
              if (!hasMyStory && index == 0) {
                return _buildStoryCircle(
                  theme: theme,
                  username: 'Tu historia',
                  imageUrl: null,
                  isMe: true,
                  hasActiveStory: false,
                  isUploading: _isUploading,
                  onTap: _pickAndUploadStory,
                );
              }

              final groupIndex = hasMyStory ? index : index - 1;
              final userStories = groups[groupIndex];
              final isMe = userStories.first['user_id'] == currentUser?.id;

              return _buildStoryCircle(
                theme: theme,
                username: isMe ? 'Tu historia' : userStories.first['username'],
                imageUrl: userStories.first['profile_pic_url'],
                isMe: isMe,
                hasActiveStory: true,
                isUploading: isMe ? _isUploading : false,
                onLongPress: isMe ? _pickAndUploadStory : null,
                onTap: () {
                  if (isMe && _isUploading) return;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(stories: userStories, initialIndex: 0)));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({required ThemeData theme, required String username, String? imageUrl, bool isMe = false, bool hasActiveStory = false, bool isUploading = false, required VoidCallback onTap, VoidCallback? onLongPress}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (!hasActiveStory && isMe && !isUploading) ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: (!hasActiveStory && isMe && !isUploading) ? Border.all(color: Colors.grey[300]!, width: 2) : null,
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.cardColor,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: isUploading ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : (imageUrl == null ? Icon(Icons.person, size: 32, color: Colors.grey[400]) : null),
                  ),
                ),
                if (isMe && !isUploading)
                  Positioned(
                    bottom: 2, 
                    right: 2, 
                    child: GestureDetector(
                      onTap: _pickAndUploadStory, // Botón explícito para añadir más
                      child: Container(
                        padding: const EdgeInsets.all(2), 
                        decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)), 
                        child: Icon(hasActiveStory ? Icons.add : Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(width: 74, child: Text(username, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: isMe ? FontWeight.w400 : FontWeight.w500, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
