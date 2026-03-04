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
    return groups.values.toList()..sort((a, b) {
      if (a.first['user_id'] == myId) return -1;
      if (b.first['user_id'] == myId) return 1;
      return DateTime.parse(b.first['created_at']).compareTo(DateTime.parse(a.first['created_at']));
    });
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

    final picker = ImagePicker();
    final isVideo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de historia'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Foto')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Video')),
        ],
      ),
    );

    if (isVideo == null) return;
    final file = isVideo ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        String? mediaUrl;
        if (isVideo) {
          mediaUrl = await MediaManager.uploadVideoToTelegram(File(file.path));
        } else {
          mediaUrl = await MediaManager.uploadToImgBB(File(file.path));
        }

        if (mediaUrl != null) {
          await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'media_url': mediaUrl,
            'type': isVideo ? 'video' : 'image',
          });
          _refreshStories();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            return _buildStoryCircle(username: 'Tu historia', isMe: true, onTap: _pickAndUploadStory, isUploading: _isUploading);
          }
          final groupIndex = hasMyStory ? index : index - 1;
          final userStories = _groupedStories[groupIndex];
          return _buildStoryCircle(
            username: userStories.first['username'],
            imageUrl: userStories.first['avatar_url'], // Corregido: avatar_url
            hasActiveStory: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(stories: userStories, initialIndex: 0))),
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({required String username, String? imageUrl, bool isMe = false, bool hasActiveStory = false, bool isUploading = false, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: hasActiveStory ? Colors.pink : Colors.grey[300],
              child: CircleAvatar(
                radius: 32,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: isUploading ? const CircularProgressIndicator() : (imageUrl == null ? const Icon(Icons.person) : null),
              ),
            ),
            const SizedBox(height: 4),
            Text(username, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
