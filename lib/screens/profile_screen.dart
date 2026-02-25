import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:venered_social/widgets/post_card.dart'; // No longer needed for grid display in ProfileScreen
import 'package:venered_social/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:venered_social/screens/edit_profile_screen.dart'; // Import EditProfileScreen

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
        .select('image_url') // Only image_url for grid display
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
            final username = profileSnapshot.data!['username'] ?? 'Usuario'; // Define username here
            final profilePicUrl = profileSnapshot.data!['profile_pic_url'];
            final bio = profileSnapshot.data!['bio'] ?? 'No hay biografía.';

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  username, // Display username as title
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined), // Settings icon
                    onPressed: () {
                      Navigator.of(context).push(
                        new MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header (Pic, Username, Stats)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profilePicUrl != null
                                  ? NetworkImage(profilePicUrl)
                                  : null,
                              child: profilePicUrl == null
                                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatColumn('Posts', 0), // TODO: Fetch actual count
                                      _buildStatColumn('Seguidores', 0), // TODO: Fetch actual count
                                      _buildStatColumn('Seguidos', 0), // TODO: Fetch actual count
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Edit Profile Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          new MaterialPageRoute(
                                            builder: (context) => EditProfileScreen(
                                              initialProfile: profileSnapshot.data!,
                                            ),
                                          ),
                                        );
                                        // Refresh profile data after returning from edit screen
                                        setState(() {
                                          _profileFuture = _fetchProfile();
                                          _userPostsFuture = _fetchUserPosts();
                                        });
                                      },
                                      child: const Text('Editar Perfil'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Username and Bio
                        Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        // Posts Grid Header
                        const Text(
                          'Publicaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // User Posts Grid
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
                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 columns for posts
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = userPosts[index];
                            final postImageUrl = post['image_url'];
                            return postImageUrl != null
                                ? Image.network(
                                    postImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.grey[300]);
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

  // Helper method for building stat columns (Posts, Followers, Following)
  Column _buildStatColumn(String label, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
