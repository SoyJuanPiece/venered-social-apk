import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late Stream<int> _unreadMessagesStream;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
    _unreadMessagesStream = _setupUnreadCounter();
  }

  Stream<int> _setupUnreadCounter() {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    // Escuchamos todos los cambios y filtramos en el cliente para evitar errores de tipo en el StreamBuilder
    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((event) {
          return event.where((n) => 
            n['receiver_id'] == myId && 
            n['type'] == 'message' && 
            n['is_read'] == false
          ).length;
        });
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Venered',
            style: GoogleFonts.grandHotel(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border_rounded, color: theme.colorScheme.onSurface, size: 26),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen())),
          ),
          StreamBuilder<int>(
            stream: _unreadMessagesStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                backgroundColor: theme.colorScheme.secondary,
                child: IconButton(
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.onSurface, size: 24),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MessagesScreen())),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() { _postsFuture = _fetchPosts(); });
          await _postsFuture;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Stories Section
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[200]!, width: 0.5)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Aún no hay publicaciones.',
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
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
    );
  }

  Widget _buildStoryItem(bool isMe, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe ? null : const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: isMe ? Colors.grey[300] : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surface,
                child: isMe 
                    ? Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: 30) 
                    : Icon(Icons.person_rounded, color: Colors.grey[400], size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMe ? 'Tu historia' : 'Usuario',
            style: GoogleFonts.poppins(
              fontSize: 11, 
              color: theme.colorScheme.onSurface,
              fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
