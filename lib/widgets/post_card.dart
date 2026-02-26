import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:venered_social/widgets/comments_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onDelete;

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
        await Supabase.instance.client.from('likes').delete().eq('post_id', widget.post['id']).eq('user_id', _userId);
        setState(() { _isLiked = false; _likeCount--; });
      } else {
        await Supabase.instance.client.from('likes').insert({'post_id': widget.post['id'], 'user_id': _userId});
        setState(() { _isLiked = true; _likeCount++; });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await Supabase.instance.client.from('saved_posts').delete().eq('post_id', widget.post['id']).eq('user_id', _userId);
        setState(() => _isSaved = false);
      } else {
        await Supabase.instance.client.from('saved_posts').insert({'post_id': widget.post['id'], 'user_id': _userId});
        setState(() => _isSaved = true);
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  void _sharePost() {
    final String text = '¡Mira esta publicación de ${widget.post['profiles']['username']} en Venered!\n\n${widget.post['image_url']}';
    Share.share(text);
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CommentsSheet(postId: widget.post['id']),
    );
  }

  void _showMoreOptions() {
    final isOwner = widget.post['user_id'] == _userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                onTap: () { Navigator.pop(context); _deletePost(); },
              ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.onSurface),
              title: const Text('Compartir'),
              onTap: () { Navigator.pop(context); _sharePost(); },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Theme.of(context).colorScheme.onSurface),
              title: const Text('Copiar enlace'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Borrar permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final deleteUrl = widget.post['image_deletehash'];
        if (deleteUrl != null) await http.get(Uri.parse(deleteUrl));
        await Supabase.instance.client.from('posts').delete().eq('id', widget.post['id']);
        if (widget.onDelete != null) widget.onDelete!();
      } catch (e) {
        debugPrint('Error deleting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.post['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? 'Usuario';
    final profilePic = profile?['profile_pic_url'];

    return Container(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                  child: profilePic == null ? const Icon(Icons.person, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Text(username, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface), onPressed: _showMoreOptions),
              ],
            ),
          ),
          if (widget.post['image_url'] != null)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: widget.post['image_url'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 400,
              ),
            ),
          Row(
            children: [
              IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : theme.colorScheme.onSurface), onPressed: _toggleLike),
              IconButton(icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onSurface), onPressed: _showComments),
              IconButton(icon: Icon(Icons.send_outlined, color: theme.colorScheme.onSurface), onPressed: _sharePost),
              const Spacer(),
              IconButton(icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.blue : theme.colorScheme.onSurface), onPressed: _toggleSave),
            ],
          ),
          if (_likeCount > 0)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_likeCount Me gusta', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
          if (widget.post['description'] != null && widget.post['description'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  children: [
                    TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: widget.post['description']),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: InkWell(
              onTap: _showComments,
              child: Text(
                widget.post['comments_count'] > 0 ? 'Ver los ${widget.post['comments_count']} comentarios' : 'Añadir un comentario...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
