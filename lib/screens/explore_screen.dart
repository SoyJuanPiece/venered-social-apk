import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Map<String, dynamic>>> _explorePostsFuture;

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

  Future<List<Map<String, dynamic>>> _fetchExplorePosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts_with_likes_count') // Use the view for all posts
          .select('image_url') // Only image_url for grid display
          .order('created_at', ascending: false)
          .limit(50); // Limit to 50 posts for now

      debugPrint('Supabase explore posts response: $response');
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error fetching explore posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar publicaciones: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        automaticallyImplyLeading: false, // No back button on explore screen
      ),
      body: Column(
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
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
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
                  return Center(child: Text('Error: ${snapshot.error.toString()}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay publicaciones para explorar.'));
                } else {
                  final posts = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(2.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          : Container(color: Theme.of(context).colorScheme.surface);
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
}