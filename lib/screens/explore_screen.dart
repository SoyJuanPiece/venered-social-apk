import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/profile_screen.dart'; // Import ProfileScreen - placeholder for now

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
    'Fotografía',
    'Movimiento',
    'Audio',
    'Tecnología',
    'Naturaleza',
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
          .limit(50);

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
          .ilike('username', '%$query%') // Case-insensitive search
          .limit(20);

      setState(() {
        _searchResults = response as List<Map<String, dynamic>>;
      });
    } catch (e) {
      dPrint('Error searching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar usuarios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: _searchUsers,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isSearching
          ? _buildSearchResults()
          : Column(
              children: [
                // Category Chips
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Chip(
                          label: Text(_categories[index]),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Posts Grid
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _explorePostsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error.toString()}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No hay publicaciones para explorar.'));
                      } else {
                        final posts = snapshot.data!;
                        return GridView.builder(
                          padding: const EdgeInsets.all(2.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 columns
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final postImageUrl = post['image_url'];
                            return postImageUrl != null
                                ? Image.network(
                                    postImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Theme.of(context).colorScheme.surface);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final profilePicUrl = user['profile_pic_url'];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
            child: profilePicUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user['username'] ?? 'Usuario desconocido'),
          subtitle: Text(user['bio'] ?? ''),
          onTap: () {
            // Navigate to profile (TODO: Implement generic profile screen)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ir al perfil de ${user['username']}')),
            );
          },
        );
      },
    );
  }
}