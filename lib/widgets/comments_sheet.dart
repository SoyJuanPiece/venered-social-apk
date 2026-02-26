import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  Future<List<Map<String, dynamic>>> _fetchComments() async {
    try {
      // Explicit join to avoid schema cache issues
      final response = await Supabase.instance.client
          .from('comments')
          .select('id, content, created_at, user_id, profiles!user_id(username, profile_pic_url)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);
      
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('comments').insert({
        'user_id': userId,
        'post_id': widget.postId,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();
      setState(() { _commentsFuture = _fetchComments(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4, width: 40,
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Comentarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) return const Center(child: Text('No hay comentarios aún.', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final profile = comment['profiles'] as Map<String, dynamic>?;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: profile?['profile_pic_url'] != null ? NetworkImage(profile!['profile_pic_url']) : null,
                        child: profile?['profile_pic_url'] == null ? const Icon(Icons.person, size: 16) : null,
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          children: [
                            TextSpan(text: '${profile?['username'] ?? 'Usuario'} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: comment['content']),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        DateTime.parse(comment['created_at']).toLocal().toString().substring(0, 16),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Añade un comentario...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: theme.colorScheme.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isPosting ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
