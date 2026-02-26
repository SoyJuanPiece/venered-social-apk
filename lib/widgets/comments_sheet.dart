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
  late final Stream<List<Map<String, dynamic>>> _commentsStream;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Real-time stream for comments
    _commentsStream = Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('comments').insert({
        'user_id': userId,
        'post_id': widget.postId,
        'content': content,
      });
      _commentController.clear();
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) return const Center(child: Text('No hay comentarios aún.', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    // Since Stream doesn't support complex joins easily, we fetch profile if needed or use a cached approach.
                    // For now, we'll display the content and user_id. 
                    // Note: Real-time with joins is complex in Supabase, best approach is usually a separate fetch or a view.
                    return ListTile(
                      leading: const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                      title: Text(comment['content'], style: TextStyle(color: theme.colorScheme.onSurface)),
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
