import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils.dart';
import '../formatters.dart';
import '../screens/profile_screen.dart';
import '../widgets/comments_sheet.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onDelete;

  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _expanded = false;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes_count'] ?? 0;
    _checkIfLiked();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    final res = await supabase.from('likes').select().eq('post_id', widget.post['id']).eq('user_id', myId).maybeSingle();
    if (mounted) setState(() => _isLiked = res != null);
  }

  Future<void> _toggleLike() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    final prev = _isLiked;
    final prevCount = _likesCount;
    setState(() { _isLiked = !_isLiked; _likesCount += _isLiked ? 1 : -1; });
    if (_isLiked) _heartCtrl.forward(from: 0);
    try {
      if (_isLiked) {
        await supabase.from('likes').insert({'post_id': widget.post['id'], 'user_id': myId});
      } else {
        await supabase.from('likes').delete().eq('post_id', widget.post['id']).eq('user_id', myId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLiked = prev; _likesCount = prevCount; });
    }
  }

  Future<void> _deletePost() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleted = await supabase
          .from('posts')
          .delete()
          .eq('id', widget.post['id'])
          .eq('user_id', myId)
          .select('id');

      if ((deleted as List).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar (sin permisos o ya no existe)')),
        );
        return;
      }

      if (!mounted) return;
      widget.onDelete?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la publicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = supabase.auth.currentUser?.id;
    final avatar = widget.post['avatar_url'] as String?;
    final media = widget.post['media_url'] as String?;
    final username = widget.post['username'] as String? ?? 'Usuario';
    final content = widget.post['content'] as String? ?? '';
    final isOwner = widget.post['user_id'] == myId;
    final isVerified = widget.post['is_verified'] == true;
    final createdAt = widget.post['created_at'] != null ? DateTime.tryParse(widget.post['created_at']) : null;
    final timeAgo = createdAt != null ? formatTimeAgo(createdAt) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.post['user_id']),
                )),
                child: _avatarRing(avatar, radius: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                fit: FlexFit.loose,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: widget.post['user_id']),
                  )),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5, color: theme.colorScheme.onSurface),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.verified_rounded, color: Color(0xFF6366F1), size: 14),
                          ],
                        ],
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: Colors.grey[400], size: 22),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: widget.post['user_id']),
                    ));
                  }
                  if (value == 'delete') {
                    _deletePost();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('Ver perfil'),
                  ),
                  if (isOwner)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar publicación'),
                    ),
                ],
              ),
            ],
          ),
        ),
        // ── Image (doble tap = like) ──
        if (media != null)
          GestureDetector(
            onDoubleTap: () { if (!_isLiked) _toggleLike(); },
            child: Image.network(
              webSafeUrl(media),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: theme.cardColor,
                child: Icon(Icons.broken_image_outlined, size: 42, color: Colors.grey[500]),
              ),
            ),
          ),
        // ── Botones ──
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
          child: Row(
            children: [
              ScaleTransition(
                scale: _heartScale,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  icon: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isLiked ? const Color(0xFFEF4444) : theme.colorScheme.onSurface,
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                ),
              ),
              IconButton(
                padding: const EdgeInsets.all(6),
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 24, color: theme.colorScheme.onSurface),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CommentsSheet(postId: widget.post['id']),
                ),
              ),
            ],
          ),
        ),
        // ── Likes count ──
        if (_likesCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_likesCount me gusta',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface),
            ),
          ),
        // ── Caption con "ver más" ──
        if (content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$username ',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: _expanded || content.length <= 110 ? content : '${content.substring(0, 110)}... ',
                      style: GoogleFonts.poppins(fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    if (!_expanded && content.length > 110)
                      TextSpan(
                        text: 'ver más',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Divider(color: theme.dividerColor.withOpacity(0.2), height: 1),
      ],
    );
  }

  Widget _avatarRing(String? avatar, {required double radius}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: avatar != null ? NetworkImage(webSafeUrl(avatar)) : null,
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.grey[300],
        child: avatar == null ? Icon(Icons.person, size: radius, color: Colors.grey[600]) : null,
      ),
    );
  }
}
