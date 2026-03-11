import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils.dart';
import '../services/media_manager.dart';
import 'package:venered_social/widgets/post_card.dart';
import 'package:venered_social/widgets/post_skeleton.dart';
import 'package:venered_social/screens/notifications_screen.dart';
import 'package:venered_social/widgets/stories_bar.dart';
import 'package:venered_social/widgets/fade_slide_in.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _feedError;
  int _pageSize = 15;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Cargar cache inmediatamente
    final cached = await MediaManager.getCachedFeed();
    if (cached.isNotEmpty) {
      setState(() {
        _posts = cached.take(_pageSize).toList();
        _isLoading = false;
      });
    }
    // 2. Refrescar desde el servidor en segundo plano
    _refreshFeed();
  }

  Future<void> _refreshFeed() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _feedError = 'No se encontró la sesión. Vuelve a iniciar sesión.';
            _isLoading = false;
          });
        }
        return;
      }

      // Usar la vista optimizada v6.0 que ya incluye likes_count y datos de perfil
      // Sin filtro por estado ya que la vista puede no incluir esa columna
      final response = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select()
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final newPosts = List<Map<String, dynamic>>.from(response);
      
      await MediaManager.cacheFeed(newPosts);

      if (mounted) {
        setState(() {
          _posts = newPosts;
          _offset = _pageSize;
          _hasMore = newPosts.length >= _pageSize;
          _feedError = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      dPrint('Error fetching posts: $e');
      if (mounted) {
        setState(() {
          _feedError = 'No se pudo cargar el feed.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    
    try {
      final response = await Supabase.instance.client
          .from('posts_with_likes_count')
          .select()
          .order('created_at', ascending: false)
          .range(_offset, _offset + _pageSize - 1);

      final newPosts = List<Map<String, dynamic>>.from(response);
      
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _offset += _pageSize;
          _hasMore = newPosts.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      dPrint('Error loading more posts: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.of(context).size.width >= 1000 ? 760.0 : double.infinity;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Venered',
            style: GoogleFonts.grandHotel(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border_rounded, color: theme.colorScheme.onSurface, size: 26),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: const FadeSlideIn(
                    delay: Duration(milliseconds: 40),
                    child: StoriesBar(),
                  ),
                ),
              ),
            ),
            if (_isLoading && _posts.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      children: const [
                        PostSkeleton(),
                        PostSkeleton(),
                        PostSkeleton(),
                      ],
                    ),
                  ),
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.dynamic_feed_rounded, size: 42, color: Colors.white),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _feedError ?? 'Aún no hay publicaciones.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _feedError == null
                              ? 'Cuando alguien publique algo, aparecerá aquí. También puedes crear tu primera publicación.'
                              : 'Revisa tu conexión o intenta refrescar deslizando hacia abajo.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _refreshFeed,
                          child: Text(_feedError == null ? 'Actualizar feed' : 'Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Mostrar botón "Cargar más" al final si hay más posts
                    if (index == _posts.length) {
                      if (!_hasMore) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No hay más publicaciones',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _isLoadingMore
                              ? const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(),
                                )
                              : ElevatedButton(
                                  onPressed: _loadMorePosts,
                                  child: const Text('Cargar más'),
                                ),
                        ),
                      );
                    }
                    
                    final post = _posts[index];
                    final postId = post['id'];
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 70 + (index * 35)),
                          beginOffset: const Offset(0, 0.05),
                          child: PostCard(
                            post: post,
                            onDelete: () {
                              setState(() {
                                _posts.removeWhere((p) => p['id'] == postId);
                              });
                              _refreshFeed();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _hasMore ? _posts.length + 1 : _posts.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
