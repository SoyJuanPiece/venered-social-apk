import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils.dart';
import 'package:venered_social/widgets/post_card.dart';
import 'package:venered_social/widgets/post_skeleton.dart';
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return Stream.value(0);

    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((event) {
          final unreadNotifications = event.where((n) => 
            n['receiver_id'] == user.id && 
            n['type'] == 'message' && 
            n['is_read'] == false
          );
          final uniqueSenders = unreadNotifications.map((n) => n['sender_id']).toSet();
          return uniqueSenders.length;
        })
        .handleError((e) => 0);
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('estado')
          .eq('id', user.id)
          .single();
      
      final userEstado = userProfile['estado'] as String?;

      final response = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select('*, profiles!inner(username, profile_pic_url, is_verified, estado)')
          .eq('profiles.estado', userEstado ?? '')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
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
            initialData: 0,
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
            // Feed Section
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const PostSkeleton(),
                      childCount: 3,
                    ),
                  );
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
}
