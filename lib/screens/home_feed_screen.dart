import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils.dart';
import 'package:venered_social/widgets/post_card.dart';
import 'package:venered_social/screens/create_post_screen.dart';
import 'package:venered_social/screens/notifications_screen.dart';
import 'package:venered_social/screens/messages_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select('*')
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      dPrint('Error fetching posts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Venered',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 28),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.messenger_outline_rounded, size: 26),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MessagesScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() { _postsFuture = _fetchPosts(); });
          await _postsFuture;
        },
        child: CustomScrollView(
          slivers: [
            // Stories Section
            SliverToBoxAdapter(
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey, width: 0.5)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return _buildStoryItem(index == 0, theme);
                  },
                ),
              ),
            ),
            // Feed Section
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('No hay publicaciones.')));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(
                      post: posts[index],
                      onDelete: () { setState(() { _postsFuture = _fetchPosts(); }); },
                    ),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreatePostScreen()));
          setState(() { _postsFuture = _fetchPosts(); });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStoryItem(bool isMe, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe ? null : const LinearGradient(
                colors: [Color(0xFFFCAF45), Color(0xFFF77737), Color(0xFFE1306C), Color(0xFFC13584)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              color: isMe ? Colors.grey[300] : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: isMe ? const Icon(Icons.add, color: Colors.blue) : const Icon(Icons.person, color: Colors.grey, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? 'Tu historia' : 'Usuario',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
