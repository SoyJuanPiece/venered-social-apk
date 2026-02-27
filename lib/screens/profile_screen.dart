import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/settings_screen.dart';
import 'package:venered_social/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<int> _postsCountFuture;
  late Future<int> _followersCountFuture;
  late Future<int> _followingCountFuture;
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _fetchProfile();
      _postsCountFuture = _fetchPostsCount();
      _followersCountFuture = _fetchFollowersCount();
      _followingCountFuture = _fetchFollowingCount();
    });
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    return await Supabase.instance.client
        .from('profiles')
        .select('username, profile_pic_url, bio, profile_pic_deletehash')
        .eq('id', _userId)
        .single();
  }

  Future<int> _fetchPostsCount() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('id')
        .eq('user_id', _userId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<int> _fetchFollowersCount() async {
    final response = await Supabase.instance.client
        .from('followers')
        .select('id')
        .eq('following_id', _userId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<int> _fetchFollowingCount() async {
    final response = await Supabase.instance.client
        .from('followers')
        .select('id')
        .eq('follower_id', _userId)
        .count(CountOption.exact);
    return response.count;
  }

  // We'll no longer fetch all posts at once; the PaginatedPostGrid below
  // will call the database in chunks. These helper methods provide the
  // requested page range.
  Future<List<Map<String, dynamic>>> _fetchUserPosts({required int offset, required int limit}) async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('image_url')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).cast();
  }

  Future<List<Map<String, dynamic>>> _fetchSavedPosts({required int offset, required int limit}) async {
    final response = await Supabase.instance.client
        .from('saved_posts')
        .select('posts(image_url)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final list = (response as List)
        .map((e) => e['posts'] as Map<String, dynamic>)
        .toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) => Text(
              snapshot.data?['username'] ?? 'Perfil',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _refreshProfile(),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FutureBuilder<Map<String, dynamic>>(
                            future: _profileFuture,
                            builder: (context, snapshot) {
                              final url = snapshot.data?['profile_pic_url'];
                              return Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 37,
                                  backgroundColor: theme.scaffoldBackgroundColor,
                                  backgroundImage: url != null ? NetworkImage(url) : null,
                                  child: url == null
                                      ? Icon(Icons.person, size: 40, color: Colors.grey)
                                      : null,
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatFuture(_postsCountFuture, 'Posts'),
                                _buildStatFuture(_followersCountFuture, 'Seguidores'),
                                _buildStatFuture(_followingCountFuture, 'Seguidos'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(snapshot.data?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (snapshot.data?['bio'] != null) Text(snapshot.data!['bio']),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                if (snapshot.hasData) {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(initialProfile: snapshot.data!),
                                  ));
                                  _refreshProfile();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Editar perfil', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                PaginatedPostGrid(
                  fetchPage: _fetchUserPosts,
                  emptyMsg: 'No has publicado nada aún.',
                ),
                PaginatedPostGrid(
                  fetchPage: _fetchSavedPosts,
                  emptyMsg: 'No tienes publicaciones guardadas.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatFuture(Future<int> future, String label) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) => Column(
        children: [
          Text(snapshot.hasData ? snapshot.data.toString() : '0', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  // Generic widget that shows a grid and loads more as the user scrolls.
  // This keeps the app within Supabase free-tier by limiting the number of
  // rows fetched in each request.

}

// ------------------------------------------------------------
// Helper widget for pagination
// ------------------------------------------------------------

class PaginatedPostGrid extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(int offset, int limit) fetchPage;
  final String emptyMsg;

  const PaginatedPostGrid({super.key, required this.fetchPage, required this.emptyMsg});

  @override
  State<PaginatedPostGrid> createState() => _PaginatedPostGridState();
}

class _PaginatedPostGridState extends State<PaginatedPostGrid> {
  static const int _pageSize = 18;
  final List<Map<String, dynamic>> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNext();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200 && !_loading && _hasMore) {
        _loadNext();
      }
    });
  }

  Future<void> _loadNext() async {
    if (_loading) return;
    setState(() => _loading = true);
    final newItems = await widget.fetchPage(_posts.length, _pageSize);
    setState(() {
      _loading = false;
      _posts.addAll(newItems);
      if (newItems.length < _pageSize) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && !_loading) {
      return Center(child: Text(widget.emptyMsg));
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _posts.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final url = _posts[index]['image_url'];
        return Image.network(url, fit: BoxFit.cover);
      },
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    // Rebuild when the tab bar changes (also covers theme toggles)
    return oldDelegate._tabBar != _tabBar;
  }
}