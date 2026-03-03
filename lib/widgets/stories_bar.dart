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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Cargar cache local inmediatamente
    final cached = await MediaManager.getFromCache('stories_list');
    if (cached != null) {
      final List<Map<String, dynamic>> allStories = List<Map<String, dynamic>>.from(cached);
      // FILTRO: No mostrar historias que ya expiraron en el cel
      final now = DateTime.now();
      final activeStories = allStories.where((s) {
        final expiresAt = DateTime.parse(s['expires_at']);
        return expiresAt.isAfter(now);
      }).toList();

      if (mounted) {
        setState(() {
          _groupedStories = _groupStories(activeStories);
          _isLoading = false;
        });
      }
    }
    // 2. Sincronizar con el servidor
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
      final List<Map<String, dynamic>> freshStories = List<Map<String, dynamic>>.from(response);
      
      // Guardar en cache
      await MediaManager.saveToCache('stories_list', freshStories);

      if (mounted) {
        setState(() {
          _groupedStories = _groupStories(freshStories);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Publicar Historia', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.videocam, color: Colors.white)), title: const Text('Video'), onTap: () => Navigator.pop(context, 'video')),
              ListTile(leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.photo, color: Colors.white)), title: const Text('Foto'), onTap: () => Navigator.pop(context, 'photo')),
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

          await MediaManager.registerLocalMedia(res['id'].toString(), file.path, (source == 'video') ? 'video' : 'photo');
          _refreshStories();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool hasMyStory = _groupedStories.any((g) => g.first['user_id'] == currentUser?.id);

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groupedStories.length + (hasMyStory ? 0 : 1),
        itemBuilder: (context, index) {
          if (!hasMyStory && index == 0) {
            return _buildStoryCircle(theme: theme, username: 'Tu historia', isMe: true, onTap: _pickAndUploadStory, isUploading: _isUploading);
          }
          final groupIndex = hasMyStory ? index : index - 1;
          final userStories = _groupedStories[groupIndex];
          final isMe = userStories.first['user_id'] == currentUser?.id;

          return _buildStoryCircle(
            theme: theme,
            username: isMe ? 'Tu historia' : userStories.first['username'],
            imageUrl: userStories.first['profile_pic_url'],
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
                    bottom: 2, right: 2,
                    child: GestureDetector(
                      onTap: _pickAndUploadStory,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
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
