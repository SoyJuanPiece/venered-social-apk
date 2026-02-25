import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:venered_social/screens/edit_profile_screen.dart'; // Import EditProfileScreen
import 'package:transparent_image/transparent_image.dart'; // Added for FadeInImage

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<int> _postsCountFuture; // New Future for posts count
  late Future<int> _followersCountFuture; // New Future for followers count
  late Future<int> _followingCountFuture; // New Future for following count
  late Future<List<Map<String, dynamic>>> _userPostsFuture; // Moved here for TabBarView
  final _userId = Supabase.instance.client.auth.currentUser!.id; // Get current user ID

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _postsCountFuture = _fetchPostsCount(); // Initialize posts count
    _followersCountFuture = _fetchFollowersCount(); // Initialize followers count
    _followingCountFuture = _fetchFollowingCount(); // Initialize following count
    _userPostsFuture = _fetchUserPosts(); // Initialize user posts
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

  Future<int> _fetchPostsCount() async {
    final response = await Supabase.instance.client
        .from('posts')
        .eq('user_id', _userId)
        .count(CountOption.exact);
    return response;
  }

  Future<int> _fetchFollowersCount() async {
    final response = await Supabase.instance.client
        .from('followers')
        .eq('following_id', _userId)
        .count(CountOption.exact);
    return response;
  }

  Future<int> _fetchFollowingCount() async {
    final response = await Supabase.instance.client
        .from('followers')
        .eq('follower_id', _userId)
        .count(CountOption.exact);
    return response;
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
    return DefaultTabController(
      length: 2, // Posts and Saved tabs
      child: Scaffold(
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

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    title: Text(
                      username, // Display username as title
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined), // Settings icon
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                    pinned: true,
                    floating: true,
                    snap: true,
                    forceElevated: innerBoxIsScrolled,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header (Pic, Stats)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
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
                              const SizedBox(width: 20), // Space between avatar and stats
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        FutureBuilder<int>(
                                          future: _postsCountFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return _buildStatColumn('Posts', 0);
                                            } else if (snapshot.hasError) {
                                              return _buildStatColumn('Posts', 0); // Or error indicator
                                            } else {
                                              return _buildStatColumn('Posts', snapshot.data ?? 0);
                                            }
                                          },
                                        ),
                                        FutureBuilder<int>(
                                          future: _followersCountFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return _buildStatColumn('Seguidores', 0);
                                            } else if (snapshot.hasError) {
                                              return _buildStatColumn('Seguidores', 0);
                                            } else {
                                              return _buildStatColumn('Seguidores', snapshot.data ?? 0);
                                            }
                                          },
                                        ),
                                        FutureBuilder<int>(
                                          future: _followingCountFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return _buildStatColumn('Seguidos', 0);
                                            } else if (snapshot.hasError) {
                                              return _buildStatColumn('Seguidos', 0);
                                            } else {
                                              return _buildStatColumn('Seguidos', snapshot.data ?? 0);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10), // Space between stats and button
                                    // Edit Profile Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => EditProfileScreen(
                                                initialProfile: profileSnapshot.data!,
                                              ),
                                            ),
                                          );
                                          // Refresh all data after returning from edit screen
                                          setState(() {
                                            _profileFuture = _fetchProfile();
                                            _postsCountFuture = _fetchPostsCount();
                                            _followersCountFuture = _fetchFollowersCount();
                                            _followingCountFuture = _fetchFollowingCount();
                                            _userPostsFuture = _fetchUserPosts(); // Also refresh posts
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
                          // Story Highlights Placeholder
                          SizedBox(
                            height: 100, // Height for horizontal highlights
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5, // Placeholder for a few highlights
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey[300],
                                        child: const Icon(Icons.add, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Highlight ${index + 1}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on)), // Posts tab
                          Tab(icon: Icon(Icons.bookmark_border)), // Saved tab
                        ],
                        indicatorColor: Theme.of(context).primaryColor,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                      ),
                    ),
                    pinned: true,
                  ),
                ],
                body: TabBarView(
                  children: [
                    // Posts Grid
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _userPostsFuture,
                      builder: (context, postsSnapshot) {
                        if (postsSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (postsSnapshot.hasError) {
                          return Center(child: Text('Error al cargar publicaciones: ${postsSnapshot.error}'));
                        } else if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
                          return const Center(child: Text('No has realizado ninguna publicación aún.'));
                        } else {
                          final userPosts = postsSnapshot.data!;
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 columns for posts
                              crossAxisSpacing: 2.0,
                              mainAxisSpacing: 2.0,
                            ),
                            itemCount: userPosts.length,
                            itemBuilder: (context, index) {
                              final post = userPosts[index];
                              final postImageUrl = post['image_url'];
                              return postImageUrl != null
                                  ? FadeInImage.memoryNetwork(
                                      placeholder: kTransparentImage,
                                      image: postImageUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey[300]);
                            },
                          );
                        }
                      },
                    ),
                    // Saved Posts Placeholder
                    const Center(
                      child: Text('Publicaciones Guardadas (TODO)'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Match scaffold background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}