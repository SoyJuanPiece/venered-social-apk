import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/profile_screen.dart';
import 'package:venered_social/widgets/comments_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:venered_social/formatters.dart'; // Import the formatters utility

import '../utils.dart';

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

  void _navigateToProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: widget.post['user_id']),
    ));
  }

  void _showMoreOptions() {
    final isOwner = widget.post['user_id'] == _userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text('Eliminar post', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () { Navigator.pop(context); _deletePost(); },
                ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text('Copiar enlace', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () { 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Enlace copiado al portapapeles'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                },
              ),
              const SizedBox(height: 12),
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
        title: Text('¿Eliminar publicación?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Esta acción no se puede deshacer.', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
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
    final isDark = theme.brightness == Brightness.dark;
    final profile = widget.post['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? 'Usuario';
    final profilePic = profile?['profile_pic_url'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                    child: profilePic == null ? Icon(Icons.person, color: theme.colorScheme.primary, size: 20) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (widget.post['created_at'] != null)
                          Text(
                            formatTimeAgo(DateTime.parse(widget.post['created_at'])),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20), 
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          
          // Media/Content
          if (widget.post['image_url'] != null)
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onDoubleTap: _handleDoubleTap,
                  onTap: () => _showFullScreen(widget.post['image_url'], 'post_image_${widget.post['id']}'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'post_image_${widget.post['id']}',
                      child: Image.network(
                        widget.post['image_url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 400,
                      ),
                    ),
                  ),
                ),
                if (_showBigHeart) 
                  ScaleTransition(
                    scale: _heartAnimation, 
                    child: const Icon(Icons.favorite, color: Colors.white, size: 80, shadows: [Shadow(blurRadius: 20, color: Colors.black26)])
                  ),
              ],
            )
          else if (widget.post['description'] != null && widget.post['description'].isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                widget.post['description'],
                style: GoogleFonts.poppins(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600, 
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Actions & Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: _isLiked ? Colors.redAccent : theme.colorScheme.onSurface,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: theme.colorScheme.onSurface,
                      onTap: _showComments,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.send_outlined,
                      color: theme.colorScheme.onSurface,
                      onTap: () {},
                    ),
                    const Spacer(),
                    _ActionButton(
                      icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: _isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      onTap: _toggleSave,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_likeCount > 0) 
                        Text(
                          '$_likeCount Me gusta', 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      if (widget.post['image_url'] != null && widget.post['description'] != null && widget.post['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 13, height: 1.3),
                              children: [
                                TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: widget.post['description']),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showComments,
                        child: Text(
                          widget.post['comments_count'] > 0 
                              ? 'Ver los ${widget.post['comments_count']} comentarios' 
                              : 'Sé el primero en comentar...',
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurface.withOpacity(0.5), 
                            fontSize: 12, 
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 26),
    );
  }
}
