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
    final response = await Supabase.instance.client
        .from('comments')
        .select('id, content, created_at, user_id, profiles(username, profile_pic_url)')
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true);
    
    return response as List<Map<String, dynamic>>;
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('comments').insert({
        'user_id': userId,
        'post_id': widget.postId,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();
      // Refresh comments
      setState(() {
        _commentsFuture = _fetchComments();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar comentario: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Comentarios', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          
          // Comments List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Sé el primero en comentar.'));
                } else {
                  final comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final profile = comment['profiles'] as Map<String, dynamic>?;
                      final username = profile?['username'] ?? 'Usuario';
                      final profilePicUrl = profile?['profile_pic_url'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
                          child: profilePicUrl == null ? const Icon(Icons.person, size: 16) : null,
                          radius: 16,
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: '$username ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: comment['content']),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          // Simple date formatting
                          DateTime.parse(comment['created_at']).toLocal().toString().substring(0, 16),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Añade un comentario...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isPosting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send, color: Colors.blue),
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
