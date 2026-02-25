import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/widgets/post_card.dart'; // Import PostCard
import 'package:venered_social/screens/create_post_screen.dart'; // MISSING IMPORT ADDED

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
          .from('posts_with_likes_count') // Query the view
          .select('*') // Select all columns from the view
          .order('created_at', ascending: false)
          .limit(10); // Limit to 10 posts for now

      debugPrint('Supabase posts response: $response'); // Log response
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error fetching posts: $e'); // Log error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar publicaciones: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return []; // Return empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar publicaciones: ${snapshot.error.toString()}')); // More descriptive error
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay publicaciones para mostrar.'));
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(post: post);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            new MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
          // Refresh posts after returning from CreatePostScreen
          setState(() {
            _postsFuture = _fetchPosts();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
