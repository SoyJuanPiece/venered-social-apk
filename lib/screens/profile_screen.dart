import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final response = await Supabase.instance.client
        .from('profiles')
        .select('*, followers:followers!following_id(count), following:followers!follower_id(count)')
        .eq('id', _userId)
        .single();

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
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('image_url')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (response as List).cast();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al ${isCurrentlyFollowed ? 'dejar de seguir' : 'seguir'} usuario.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<String> _getOrCreateConversation(
      String otherUserId, Map<String, dynamic> otherUser) async {
    final myId = Supabase.instance.client.auth.currentUser!.id;

    // Check if a conversation already exists
    final response = await Supabase.instance.client
        .from('conversations')
        .select('id')
        .or('and(user1_id.eq.$myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$myId)');

    if (response.isNotEmpty) {
      return response.first['id'] as String;
    }

    // Create a new conversation
    final newConversation = await Supabase.instance.client
        .from('conversations')
        .insert({
          'user1_id': myId,
          'user2_id': otherUserId,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return newConversation['id'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) => Text(
            snapshot.data?['username'] ?? (_isCurrentUser ? 'Perfil' : ''),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground),
          ),
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen())),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final profile = snapshot.data!;
                    final followers = profile['followers']?[0]?['count'] ?? 0;
                    final following = profile['following']?[0]?['count'] ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(profile['profile_pic_url'] ?? ''),
                              ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _postsFuture,
                                    builder: (context, postSnapshot) {
                                      return _buildStat(postSnapshot.data?.length ?? 0, 'Posts');
                                    }
                                  ),
                                  _buildStat(followers, 'Seguidores'),
                                  _buildStat(following, 'Seguidos'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(profile['username'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (profile['bio'] != null) Text(profile['bio']),
                        const SizedBox(height: 16),
                        if (_isCurrentUser)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            EditProfileScreen(initialProfile: profile)));
                                _refreshData();
                              },
                              child: const Text('Editar perfil'),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: profile['is_followed'] ? Colors.grey : theme.primaryColor,
                                  ),
                                  child: Text(profile['is_followed'] ? 'Dejar de seguir' : 'Seguir'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final profile = await _profileFuture;
                                    final conversationId =
                                        await _getOrCreateConversation(
                                            _userId, profile);
                                    if (mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            conversationId: conversationId,
                                            otherUser: profile,
                                          ),
                                        ),
                                      );
                                    }
                                  },
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
              const Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Image.network(post['image_url'],
                          fit: BoxFit.cover);
                    },
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
      children: [
        Text(count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
