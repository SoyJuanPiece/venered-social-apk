import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils.dart';
import '../screens/profile_screen.dart';
import '../widgets/comments_sheet.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onDelete;

  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final supabase = Supabase.instance.client;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes_count'] ?? 0;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    final res = await supabase.from('likes').select().eq('post_id', widget.post['id']).eq('user_id', myId).maybeSingle();
    if (mounted) setState(() => _isLiked = res != null);
  }

  Future<void> _toggleLike() async {
    final myId = supabase.auth.currentUser!.id;
    setState(() { _isLiked = !_isLiked; _likesCount += _isLiked ? 1 : -1; });
    try {
      if (_isLiked) {
        await supabase.from('likes').insert({'post_id': widget.post['id'], 'user_id': myId});
      } else {
        await supabase.from('likes').delete().eq('post_id', widget.post['id']).eq('user_id', myId);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = widget.post['avatar_url'];
    final media = widget.post['media_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.post['user_id']))),
              child: CircleAvatar(backgroundImage: avatar != null ? NetworkImage(avatar) : null),
            ),
            title: Text(widget.post['username'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.post['estado'] ?? '', style: const TextStyle(fontSize: 12)),
          ),
          if (media != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(media, fit: BoxFit.cover, width: double.infinity),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.post['content'] ?? ''),
          ),
          Row(
            children: [
              IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null), onPressed: _toggleLike),
              Text('$_likesCount'),
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => showModalBottomSheet(context: context, builder: (context) => CommentsSheet(postId: widget.post['id']))),
            ],
          )
        ],
      ),
    );
  }
}
