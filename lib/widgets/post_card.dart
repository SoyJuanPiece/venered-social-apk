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

    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _heartAnimation = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTap() async {
    if (!_isLiked) _toggleLike();
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
      dPrint('Error toggling like: $e');
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
      dPrint('Error toggling save: $e');
    }
  }

  void _sharePost() {
    final String shareLink = 'https://venered.social/post/${widget.post['id']}';
    final String text = 'Mira esta publicación en Venered: $shareLink';
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

  void _showFullScreen(String? url, String tag) {
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Hero(
            tag: tag,
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      ),
    ));
  }

  void _showMoreOptions() {
    final isOwner = widget.post['user_id'] == _userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
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
                onTap: () { 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
                },
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
        title: const Text('¿Eliminar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final deleteUrl = widget.post['image_deletehash'] as String?;
        if (deleteUrl != null && deleteUrl.isNotEmpty) {
          await http.get(Uri.parse(deleteUrl)).timeout(const Duration(seconds: 5));
        }
        await Supabase.instance.client.from('posts').delete().eq('id', widget.post['id']);
        if (widget.onDelete != null) widget.onDelete!();
      } catch (e) {
        dPrint('Error deleting: $e');
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24), // More rounded for original feel
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFullScreen(profilePic, 'profile_pic_${widget.post['id']}'),
                    child: Hero(
                      tag: 'profile_pic_${widget.post['id']}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                        child: profilePic == null ? const Icon(Icons.person, size: 20) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(username, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, fontSize: 15)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withOpacity(0.6)), 
                    onPressed: _showMoreOptions,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (widget.post['image_url'] != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    onTap: () => _showFullScreen(widget.post['image_url'], 'post_image_${widget.post['id']}'),
                    child: Hero(
                      tag: 'post_image_${widget.post['id']}',
                      child: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: widget.post['image_url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 400,
                      ),
                    ),
                  ),
                  if (_showBigHeart) ScaleTransition(scale: _heartAnimation, child: const Icon(Icons.favorite, color: Colors.white, size: 100)),
                ],
              )
            else if (widget.post['description'] != null && widget.post['description'].isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary.withOpacity(0.15), theme.colorScheme.secondary.withOpacity(0.15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  widget.post['description'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
              ),
            // Actions & Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                        color: _isLiked ? Colors.red : theme.colorScheme.onSurface), 
                        onPressed: _toggleLike,
                      ),
                      IconButton(icon: Icon(Icons.chat_bubble_rounded, color: theme.colorScheme.onSurface), onPressed: _showComments),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                        color: _isSaved ? Colors.blue : theme.colorScheme.onSurface), 
                        onPressed: _toggleSave,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_likeCount > 0) 
                          Text('$_likeCount Me gusta', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 6),
                        if (widget.post['image_url'] != null && widget.post['description'] != null && widget.post['description'].isNotEmpty)
                          RichText(
                            text: TextSpan(
                              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                              children: [
                                TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(text: widget.post['description']),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showComments,
                          child: Text(
                            widget.post['comments_count'] > 0 ? 'Ver los ${widget.post['comments_count']} comentarios' : 'Sé el primero en comentar...',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
