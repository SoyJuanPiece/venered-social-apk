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

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late bool _isSaved; 
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  
  bool _showBigHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likes_count'] ?? 0;
    _isLiked = widget.post['is_liked_by_user'] ?? false;
    _isSaved = widget.post['is_saved_by_user'] ?? false;

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartAnimation = CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTap() async {
    if (!_isLiked) {
      _toggleLike();
    }
    setState(() => _showBigHeart = true);
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showBigHeart = false);
      });
    });
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
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: widget.post['id']),
    );
  }

  void _showMoreOptions() {
    final isOwner = widget.post['user_id'] == _userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
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
      ),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('¿Eliminar publicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCAF45), Color(0xFFF77737), Color(0xFFE1306C), Color(0xFFC13584)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                      child: profilePic == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(username, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface), onPressed: _showMoreOptions),
              ],
            ),
          ),
          // Content with Animation Stack
          Stack(
            alignment: Alignment.center,
            children: [
              if (widget.post['image_url'] != null)
                GestureDetector(
                  onDoubleTap: _handleDoubleTap,
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: widget.post['image_url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width,
                  ),
                ),
              if (_showBigHeart)
                ScaleTransition(
                  scale: _heartAnimation,
                  child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                ),
            ],
          ),
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : theme.colorScheme.onSurface,
                onPressed: _toggleLike,
              ),
              _ActionButton(icon: Icons.chat_bubble_outline, onPressed: _showComments),
              _ActionButton(icon: Icons.send_outlined, onPressed: _sharePost),
              const Spacer(),
              _ActionButton(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? Colors.blue : theme.colorScheme.onSurface,
                onPressed: _toggleSave,
              ),
            ],
          ),
          // Stats & Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_likeCount > 0)
                  Text('$_likeCount Me gusta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                if (widget.post['description'] != null && widget.post['description'].isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      children: [
                        TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: widget.post['description']),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showComments,
                  child: Text(
                    widget.post['comments_count'] > 0 ? 'Ver los ${widget.post['comments_count']} comentarios' : 'Añadir un comentario...',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateTime.parse(widget.post['created_at']).toLocal().toString().substring(0, 10),
                  style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}
