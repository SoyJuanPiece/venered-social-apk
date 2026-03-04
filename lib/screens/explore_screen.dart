import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/profile_screen.dart';
import 'package:venered_social/widgets/post_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _trendingPosts = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
  }

  Future<void> _loadTrendingContent() async {
    try {
      final res = await supabase.from('posts_with_likes_count').select().limit(20);
      if (mounted) setState(() { _trendingPosts = List<Map<String, dynamic>>.from(res); _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _onSearch(String query) async {
    if (query.isEmpty) { setState(() { _isSearching = false; _searchResults = []; }); return; }
    setState(() => _isSearching = true);
    try {
      final res = await supabase.from('profiles').select('id, username, avatar_url, is_verified').ilike('username', '%$query%').limit(15);
      if (mounted) setState(() => _searchResults = List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('Search error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          decoration: const InputDecoration(hintText: 'Buscar en Venered...', prefixIcon: Icon(Icons.search), border: InputBorder.none),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildTrendingGrid(),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final user = _searchResults[i];
        return ListTile(
          leading: CircleAvatar(backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null),
          title: Text(user['username'] ?? ''),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id']))),
        );
      },
    );
  }

  Widget _buildTrendingGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: _trendingPosts.length,
      itemBuilder: (context, i) {
        final post = _trendingPosts[i];
        return GestureDetector(
          onTap: () {}, // Abrir detalle del post
          child: post['media_url'] != null 
            ? Image.network(post['media_url'], fit: BoxFit.cover) 
            : Container(color: Colors.grey[900], child: const Icon(Icons.text_fields)),
        );
      },
    );
  }
}
