import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/profile_screen.dart';

import '../utils.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Map<String, dynamic>>> _explorePostsFuture;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Para ti',
    'Tendencias',
    'Fotografía',
    'Arte',
    'Tecnología',
    'Viajes',
    'Deportes',
  ];

  @override
  void initState() {
    super.initState();
    _explorePostsFuture = _fetchExplorePosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchExplorePosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select('image_url')
          .order('created_at', ascending: false)
          .limit(60);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      dPrint('Error fetching explore posts: $e');
      return [];
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, username, profile_pic_url, bio')
          .ilike('username', '%$query%')
          .limit(20);

      setState(() {
        _searchResults = response as List<Map<String, dynamic>>;
      });
    } catch (e) {
      dPrint('Error searching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar personas...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _searchUsers,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isSearching
          ? _buildSearchResults(theme)
          : Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: index == 0 ? theme.colorScheme.primary : (isDark ? Colors.grey[900] : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: index == 0 ? Colors.transparent : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                                color: index == 0 ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _explorePostsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty) {
                        return Center(child: Text('No hay nada para explorar aún.', style: GoogleFonts.poppins(color: Colors.grey)));
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(2.0),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final postImageUrl = post['image_url'];
                          return ClipRRect(
                            child: postImageUrl != null
                                ? Image.network(
                                    postImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: isDark ? Colors.grey[900] : Colors.grey[200]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No se encontraron usuarios.', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final profilePicUrl = user['profile_pic_url'];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
            child: profilePicUrl == null ? Icon(Icons.person, color: theme.colorScheme.primary) : null,
          ),
          title: Text(user['username'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text(user['bio'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12)),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user['id']),
            ));
          },
        );
      },
    );
  }
}