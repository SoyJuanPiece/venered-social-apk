import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/widgets/post_card.dart'; // Import PostCard

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _userPostsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _userPostsFuture = _fetchUserPosts();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('profiles')
        .select('username, profile_pic_url, bio')
        .eq('id', userId)
        .single();
    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchUserPosts() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('posts')
        .select('*, profiles(username, profile_pic_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response as List<Map<String, dynamic>>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (profileSnapshot.hasError) {
            return Center(child: Text('Error al cargar perfil: ${profileSnapshot.error}'));
          } else if (!profileSnapshot.hasData) {
            return const Center(child: Text('Perfil no encontrado.'));
          } else {
            final profile = profileSnapshot.data!;
            final username = profile['username'] ?? 'Usuario';
            final profilePicUrl = profile['profile_pic_url'];
            final bio = profile['bio'] ?? 'No hay biografía.';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(username),
                    background: profilePicUrl != null
                        ? Image.network(profilePicUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Implement Edit Profile functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Editar perfil (TODO)')),
                        );
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@$username',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(bio),
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text(
                          'Tus Publicaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _userPostsFuture,
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (postsSnapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(child: Text('Error al cargar publicaciones: ${postsSnapshot.error}')),
                      );
                    } else if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('No has realizado ninguna publicación aún.')),
                      );
                    } else {
                      final userPosts = postsSnapshot.data!;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = userPosts[index];
                            return PostCard(post: post);
                          },
                          childCount: userPosts.length,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}