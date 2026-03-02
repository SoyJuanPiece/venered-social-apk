import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/chat_screen.dart';
import 'package:venered_social/screens/settings_screen.dart';
import 'package:venered_social/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _postsFuture;

  String get _userId =>
      widget.userId ?? Supabase.instance.client.auth.currentUser!.id;
  bool get _isCurrentUser =>
      widget.userId == null ||
      widget.userId == Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _postsFuture = _fetchPosts();
  }

  Future<void> _refreshData() async {
    setState(() {
      _profileFuture = _fetchProfile();
      _postsFuture = _fetchPosts();
    });
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*, followers:followers!following_id(count), following:followers!follower_id(count)')
          .eq('id', _userId)
          .maybeSingle();

      if (response == null) {
        throw Exception("El perfil no existe en la tabla 'profiles'.");
      }

      if (!_isCurrentUser) {
        final followCheck = await Supabase.instance.client
            .from('followers')
            .select('id')
            .eq('follower_id', Supabase.instance.client.auth.currentUser!.id)
            .eq('following_id', _userId)
            .maybeSingle();
        response['is_followed'] = followCheck != null;
      }
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('image_url')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return (response as List).cast();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final targetUserId = _userId;

    final profileData = await _profileFuture;
    final isCurrentlyFollowed = profileData['is_followed'] ?? false;

    try {
      if (isCurrentlyFollowed) {
        await Supabase.instance.client.from('followers').delete().match({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });
      } else {
        await Supabase.instance.client.from('followers').insert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });
      }
      _refreshData();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
  }

  Future<String> _getOrCreateConversation(
      String otherUserId, Map<String, dynamic> otherUser) async {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$myId)');

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      }

      final newConversation = await Supabase.instance.client
          .from('conversations')
          .insert({
            'user1_id': myId,
            'user2_id': otherUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .maybeSingle();

      return newConversation!['id'] as String;
    } catch (e) {
      debugPrint('Error in _getOrCreateConversation: $e');
      rethrow;
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
        centerTitle: true,
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile?['username'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: theme.colorScheme.onSurface),
                ),
                if (profile?['is_verified'] == true)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, color: Colors.blue, size: 18),
                  ),
              ],
            );
          },
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final profile = snapshot.data!;
                    final followersCount = (profile['followers'] as List?)?.firstOrNull?['count'] ?? 0;
                    final followingCount = (profile['following'] as List?)?.firstOrNull?['count'] ?? 0;
                    final String role = profile['role'] ?? 'user';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)])),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundImage: profile['profile_pic_url'] != null ? NetworkImage(profile['profile_pic_url']) : null,
                                  child: profile['profile_pic_url'] == null ? Icon(Icons.person, size: 40, color: theme.colorScheme.primary) : null,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _postsFuture,
                                    builder: (context, postSnapshot) => _buildStat(postSnapshot.data?.length ?? 0, 'Posts')
                                  ),
                                  _buildStat(followersCount, 'Seguidores'),
                                  _buildStat(followingCount, 'Seguidos'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(profile['username'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                            if (profile['is_verified'] == true)
                              const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 16)),
                          ],
                        ),
                        
                        // ETIQUETA DE ROL (DUEÑO/MOD)
                        if (role != 'user')
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: role == 'admin' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role == 'admin' ? 'DUEÑO' : 'MODERADOR',
                              style: TextStyle(
                                color: role == 'admin' ? Colors.orange : Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                        if (profile['bio'] != null && profile['bio'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(profile['bio'], style: GoogleFonts.poppins(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          ),
                        
                        // MOSTRAR ESTADO
                        if (profile['estado'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(profile['estado'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                        if (_isCurrentUser)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen(initialProfile: profile)));
                                _refreshData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                                foregroundColor: theme.colorScheme.onSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Editar perfil'),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: profile['is_followed'] ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                    color: profile['is_followed'] ? (isDark ? Colors.grey[900] : Colors.grey[200]) : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: profile['is_followed'] ? theme.colorScheme.onSurface : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(profile['is_followed'] ? 'Siguiendo' : 'Seguir', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final profile = await _profileFuture;
                                    final conversationId = await _getOrCreateConversation(_userId, profile);
                                    if (mounted) {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(conversationId: conversationId, otherUser: profile)));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                  ),
                                  child: const Text('Mensaje'),
                                ),
                              ),
                            ],
                          )
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final posts = snapshot.data!;
                  if (posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60.0),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Aún no hay publicaciones', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => Image.network(posts[index]['image_url'], fit: BoxFit.cover),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ],
    );
  }
}
