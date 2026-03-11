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
  List<List<Map<String, dynamic>>> _groupedStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStories();
  }

  List<List<Map<String, dynamic>>> _groupStories(List<Map<String, dynamic>> allStories) {
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
  }

  Future<void> _refreshStories() async {
    try {
      final response = await Supabase.instance.client.from('stories_with_profiles').select();
      if (mounted) {
        setState(() {
          _groupedStories = _groupStories(List<Map<String, dynamic>>.from(response));
          _isLoading = false;
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _pickAndUploadStory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final isVideo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text('¿Qué quieres subir?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(context, Icons.photo, 'Foto', false),
                _buildOption(context, Icons.videocam, 'Video', true),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (isVideo == null) return;
    final picker = ImagePicker();
    final file = isVideo ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final upload = await MediaManager.uploadToTelegram(File(file.path), isStory: true);
        if (upload == null) {
          throw 'No se pudo subir el archivo.';
        }

        final String? fileId = upload['file_id'] ?? upload['result']?['video']?['file_id'];
        final String? mediaUrl = upload['url'] ?? upload['media_url'];
        final mediaType = isVideo ? 'video' : 'photo';

        bool inserted = false;

        // Soporta esquema antiguo: stories(file_id, media_type)
        if (fileId != null) {
          try {
            await Supabase.instance.client.from('stories').insert({
              'user_id': user.id,
              'file_id': fileId,
              'media_type': mediaType,
            });
            inserted = true;
          } catch (_) {}
        }

        // Soporta esquema nuevo: stories(media_url, type)
        if (!inserted && mediaUrl != null) {
          await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'media_url': mediaUrl,
            'type': mediaType,
          });
          inserted = true;
        }

        if (!inserted) {
          throw 'No se pudo guardar la historia en la base de datos.';
        }

        _refreshStories();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, bool val) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, val),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF6366F1))),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool hasMyStory = _groupedStories.any((g) => g.first['user_id'] == currentUser?.id);

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groupedStories.length + (hasMyStory ? 0 : 1),
        itemBuilder: (context, index) {
          if (!hasMyStory && index == 0) {
            return _buildStoryCircle(theme: theme, username: 'Tú', isMe: true, onTap: _pickAndUploadStory, isUploading: _isUploading);
          }
          final groupIndex = hasMyStory ? index : index - 1;
          final userStories = _groupedStories[groupIndex];
          final isMe = userStories.first['user_id'] == currentUser?.id;

          return _buildStoryCircle(
            theme: theme,
            username: isMe ? 'Tú' : (userStories.first['username'] ?? 'Usuario'),
            imageUrl: userStories.first['avatar_url'],
            isMe: isMe,
            hasActiveStory: true,
            isUploading: isMe ? _isUploading : false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(stories: userStories, initialIndex: 0))),
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({required ThemeData theme, required String username, String? imageUrl, bool isMe = false, bool hasActiveStory = false, bool isUploading = false, required VoidCallback onTap}) {
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
                    gradient: (hasActiveStory || isUploading) ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    border: (!hasActiveStory && !isUploading) ? Border.all(color: Colors.grey[300]!, width: 1) : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imageUrl != null ? NetworkImage(webSafeUrl(imageUrl)) : null,
                      child: isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))) 
                        : (imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null),
                    ),
                  ),
                ),
                if (isMe && !hasActiveStory && !isUploading)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(username, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
