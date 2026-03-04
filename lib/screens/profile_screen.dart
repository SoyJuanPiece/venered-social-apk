import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/edit_profile_screen.dart';
import 'package:venered_social/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profileRes = await supabase.from('profiles').select().eq('id', widget.userId).single();
      final postsRes = await supabase.from('posts_with_likes_count').select().eq('user_id', widget.userId).order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _profile = profileRes;
          _posts = List<Map<String, dynamic>>.from(postsRes);
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null) return const Scaffold(body: Center(child: Text('Perfil no encontrado')));

    final isMe = widget.userId == supabase.auth.currentUser!.id;
    final avatar = _profile!['avatar_url'];

    return Scaffold(
      appBar: AppBar(title: Text(_profile!['username'] ?? '')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(radius: 50, backgroundImage: avatar != null ? NetworkImage(avatar) : null),
            const SizedBox(height: 10),
            Text(_profile!['display_name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_profile!['estado'] ?? '', style: const TextStyle(color: Colors.grey)),
            if (isMe) ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _profile!))).then((_) => _loadData()), child: const Text('Editar Perfil')),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              itemBuilder: (context, i) => PostCard(post: _posts[i]),
            )
          ],
        ),
      ),
    );
  }
}
