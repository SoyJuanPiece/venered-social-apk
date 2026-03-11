import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/profile_screen.dart';
import 'package:venered_social/widgets/post_card.dart';
import '../utils.dart';

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
      final res = await supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url, is_verified')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);
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
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Sin resultados', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final user = _searchResults[i];
        final isVerified = user['is_verified'] == true;
        final displayName = (user['display_name'] as String?)?.isNotEmpty == true ? user['display_name'] as String : null;
        return ListTile(
          leading: CircleAvatar(backgroundImage: user['avatar_url'] != null ? NetworkImage(webSafeUrl(user['avatar_url'])) : null, onBackgroundImageError: (_, __) {}, child: user['avatar_url'] == null ? const Icon(Icons.person) : null),
          title: Row(
            children: [
              Text(user['username'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              if (isVerified) ...[ const SizedBox(width: 4), const Icon(Icons.verified_rounded, color: Color(0xFF6366F1), size: 14) ],
            ],
          ),
          subtitle: displayName != null ? Text(displayName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)) : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id']))),
        );
      },
    );
  }

  Widget _buildTrendingGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_trendingPosts.isEmpty) {
      return Center(child: Text('No hay contenido todavía', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.5, mainAxisSpacing: 1.5),
      itemCount: _trendingPosts.length,
      itemBuilder: (context, i) {
        final post = _trendingPosts[i];
        return GestureDetector(
          onTap: () {},
          child: post['media_url'] != null
              ? Image.network(webSafeUrl(post['media_url']), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)))
              : Container(
                  color: Theme.of(context).cardColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(4),
                  child: Text(post['content'] ?? '', maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).colorScheme.onSurface)),
                ),
        );
      },
    );
  }
}
