import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/chat_screen.dart';
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

  Future<void> _openChatWithUser() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _profile == null) return;
    if (widget.userId == myId) return;

    try {
      final existing = await supabase
          .from('conversations')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.${widget.userId}),and(user1_id.eq.${widget.userId},user2_id.eq.$myId)')
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'];
      } else {
        final newConv = await supabase.from('conversations').insert({
          'user1_id': myId,
          'user2_id': widget.userId,
        }).select('id').single();
        convId = newConv['id'];
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            otherUser: _profile!,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null) return const Scaffold(body: Center(child: Text('Perfil no encontrado')));

    final isMe = widget.userId == supabase.auth.currentUser?.id;
    final avatar = _profile!['avatar_url'] as String?;
    final displayName = (_profile!['display_name'] as String?)?.isNotEmpty == true
        ? _profile!['display_name'] as String
        : (_profile!['username'] as String? ?? '');
    final username = _profile!['username'] as String? ?? '';
    final bio = _profile!['bio'] as String?;
    final estado = _profile!['estado'] as String?;
    final isVerified = _profile!['is_verified'] == true;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(username, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Color(0xFF6366F1), size: 18),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar con anillo degradado
                        _buildAvatar(avatar, 44, theme),
                        const SizedBox(width: 24),
                        // Stats
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statCol(_posts.length.toString(), 'publicaciones', theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Nombre y check verificado
                    if (displayName.isNotEmpty)
                      Row(
                        children: [
                          Text(displayName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFF6366F1), size: 15),
                          ],
                        ],
                      ),
                    // Bio
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(bio, style: GoogleFonts.poppins(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.85))),
                    ],
                    // Estado
                    if (estado != null && estado.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(estado, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Botón de acción
                    if (isMe)
                      _actionButton(label: 'Editar perfil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _profile!))).then((_) => _loadData()), theme: theme, outlined: true)
                    else
                      _actionButton(label: 'Mensaje', icon: Icons.chat_bubble_outline_rounded, onTap: _openChatWithUser, theme: theme, outlined: false),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: Container(height: 1, color: theme.dividerColor)),
            // Grid de posts o estado vacío
            if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_on_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('Sin publicaciones aún', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(1),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final post = _posts[i];
                      final media = post['media_url'] as String?;
                      return GestureDetector(
                        onTap: () => _showPostDetail(post),
                        child: media != null
                            ? Image.network(media, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: theme.cardColor,
                                  child: Icon(Icons.broken_image_outlined, color: Colors.grey[500]),
                                ))
                            : Container(
                                color: theme.cardColor,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(8),
                                child: Text(post['content'] ?? '', maxLines: 5, overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 11, color: theme.colorScheme.onSurface)),
                              ),
                      );
                    },
                    childCount: _posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPostDetail(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              PostCard(post: post, onDelete: _loadData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatar, double radius, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: radius,
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          onBackgroundImageError: (_, __) {},
          backgroundColor: Colors.grey[200],
          child: avatar == null ? Icon(Icons.person, size: radius, color: Colors.grey) : null,
        ),
      ),
    );
  }

  Widget _statCol(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap, required ThemeData theme, bool outlined = false, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: outlined ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: theme.dividerColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: outlined ? theme.colorScheme.onSurface : Colors.white), const SizedBox(width: 6)],
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: outlined ? theme.colorScheme.onSurface : Colors.white)),
          ],
        ),
      ),
    );
  }
}
