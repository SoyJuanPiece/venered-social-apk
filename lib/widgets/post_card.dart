import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:transparent_image/transparent_image.dart'; // Added for FadeInImage
import 'package:venered_social/widgets/comments_sheet.dart'; // Import CommentsSheet
import 'package:http/http.dart' as http; // Required for deleting image

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onDelete; // Optional callback when deleted

  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isSaved; 
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likes_count'] ?? 0;
    _isLiked = widget.post['is_liked_by_user'] ?? false;
    _isSaved = widget.post['is_saved_by_user'] ?? false;
  }

  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
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
    }
  }

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await Supabase.instance.client
            .from('saved_posts')
            .delete()
            .eq('post_id', widget.post['id'])
            .eq('user_id', _userId);
        setState(() => _isSaved = false);
      } else {
        await Supabase.instance.client.from('saved_posts').insert({
          'post_id': widget.post['id'],
          'user_id': _userId,
        });
        setState(() => _isSaved = true);
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsSheet(postId: widget.post['id']),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación? Esto también borrará la imagen permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 1. Delete image from ImgBB if deletehash/URL exists
        final deleteUrl = widget.post['image_deletehash'] as String?;
        if (deleteUrl != null && deleteUrl.isNotEmpty) {
          debugPrint('Deleting image from ImgBB: $deleteUrl');
          // ImgBB provides a delete page, but we can try to GET it to trigger deletion
          // or at least notify the user. ImgBB's API for deletion is restricted via API key
          // usually, but the delete_url they provide is a web link.
          await http.get(Uri.parse(deleteUrl)); 
        }

        // 2. Delete record from Supabase
        await Supabase.instance.client.from('posts').delete().eq('id', widget.post['id']);
        
        if (widget.onDelete != null) widget.onDelete!();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
      } catch (e) {
        debugPrint('Error deleting post: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _showMoreOptions() {
    final isOwner = widget.post['user_id'] == _userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartir'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar enlace'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? profilesData = widget.post['profiles'] is Map ? widget.post['profiles'] : null;
    final String username = profilesData?['username'] ?? 'Usuario';
    final String? profilePicUrl = profilesData?['profile_pic_url'] as String?;
    final String description = widget.post['description'] ?? '';
    final String? imageUrl = widget.post['image_url'] as String?;
    final int commentsCount = widget.post['comments_count'] ?? 0;

    return Container(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
                  child: profilePicUrl == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          // Image
          if (imageUrl != null)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 400,
              ),
            ),
          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null),
                onPressed: _toggleLike,
              ),
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _showComments),
              IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
              const Spacer(),
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.blue : null),
                onPressed: _toggleSave,
              ),
            ],
          ),
          // Likes Count
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Text('$_likeCount Me gusta', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          // Description
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: description),
                  ],
                ),
              ),
            ),
          // Comments Link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            child: InkWell(
              onTap: _showComments,
              child: Text(
                commentsCount > 0 ? 'Ver los $commentsCount comentarios' : 'Añadir un comentario...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
