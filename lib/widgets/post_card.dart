import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:flutter/foundation.dart'; // Required for debugPrint

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likes_count'] ?? 0;
    _isLiked = widget.post['is_liked_by_user'] ?? false;
  }

  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
        // Unlike the post
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('post_id', widget.post['id'])
            .eq('user_id', _userId);
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        // Like the post
        await Supabase.instance.client.from('likes').insert({
          'post_id': widget.post['id'],
          'user_id': _userId,
        });
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el like: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Robust null checks for profiles data
    final Map<String, dynamic>? profilesData = widget.post['profiles'] is Map ? widget.post['profiles'] : null;
    final String username = profilesData?['username'] ?? 'Usuario Desconocido';
    final String? profilePicUrl = profilesData?['profile_pic_url'] as String?;
    final String description = widget.post['description'] ?? '';
    final String? imageUrl = widget.post['image_url'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Adjust margin for a more feed-like look
      elevation: 0, // Remove card elevation for Instagram feel
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header (Profile Pic, Username)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profilePicUrl != null
                      ? NetworkImage(profilePicUrl)
                      : null,
                  child: profilePicUrl == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Post Image
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300, // Make image taller for better display
            )
          else
            Container(
              height: 300,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          // Action Buttons (Like, Comment - Placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likeCount'), // Display like count
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comentar (TODO)')),
                    );
                  },
                ),
                // Add more actions like share if needed
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Text(
              '${username}: $description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
