import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/chat_screen.dart';
import 'package:venered_social/widgets/user_search_dialog.dart';

import '../utils.dart';
import '../formatters.dart';
import '../services/media_manager.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtime();
    _markNotificationsAsRead();
  }

  Future<void> _loadInitialData() async {
    // 1. Cargar cache inmediatamente
    final cached = await MediaManager.getFromCache('conversations_list');
    if (cached != null) {
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(cached);
        _loading = false;
      });
    }
    // 2. Refrescar desde el servidor
    _loadConversations();
  }

  Future<void> _markNotificationsAsRead() async {
    final myId = supabase.auth.currentUser!.id;
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', myId)
          .eq('type', 'message');
    } catch (e) {
      dPrint('Error marking notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await supabase
          .from('view_conversations')
          .select();
      
      final list = List<Map<String, dynamic>>.from(res);
      // Sort by last message time
      list.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      // Guardar en cache
      await MediaManager.saveToCache('conversations_list', list);

      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
      }
    } catch (e) {
      dPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setupRealtime() {
    _channel = supabase.channel('messages_list_updates').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) => _loadConversations(),
    ).subscribe();
  }

  String _formatLastMessagePreview(Map<String, dynamic> chat, String? rawContent) {
    final type = (chat['type'] as String?) ?? 'text';
    if (type == 'voice') return '🎤 Mensaje de voz';
    if (type == 'image') return '📷 Foto';

    final content = (rawContent ?? '').trim();
    if (content.isEmpty) return '¡Di hola!';
    if (content.startsWith('storage:')) return '🎤 Mensaje de voz';
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mensajes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: _loading && _conversations.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
            ? _buildEmptyState(theme)
            : RefreshIndicator(
                onRefresh: _loadConversations,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                      // view_conversations devuelve sender_id/receiver_id del último mensaje
                      final otherId = chat['sender_id'] == myId
                        ? chat['receiver_id'] as String
                        : chat['sender_id'] as String;
                      final otherUsername = (chat['other_username'] as String?) ?? 'Usuario';
                      final otherAvatar = chat['other_avatar_url'] as String?;
                      final lastContent = chat['content'] as String?;
                      final lastSender = chat['sender_id'] as String?;
                      final isRead = chat['is_read'] == true;
                      final updatedAt = DateTime.tryParse(chat['created_at'] ?? '') ?? DateTime.now();

                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              otherId: otherId,
                            otherUser: {
                                'id': otherId,
                              'username': otherUsername,
                              'avatar_url': otherAvatar,
                            },
                          ),
                        ),
                      ).then((_) => _loadConversations()),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          backgroundImage: (otherAvatar != null && otherAvatar.isNotEmpty) ? NetworkImage(webSafeUrl(otherAvatar)) : null,
                          child: (otherAvatar == null || otherAvatar.isEmpty) ? Icon(Icons.person, color: theme.colorScheme.primary) : null,
                        ),
                      ),
                      title: Text(
                        otherUsername,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, 
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        _formatLastMessagePreview(chat, lastContent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                            color: (!isRead && lastSender != myId) ? theme.colorScheme.onSurface : Colors.grey,
                            fontWeight: (!isRead && lastSender != myId) ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: Text(
                        formatHm(updatedAt),
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Future<void> _startNewChat() async {
    final profile = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const UserSearchDialog(),
    );

    if (profile == null) return;

    final otherId = profile['id'] as String;
    final myId = supabase.auth.currentUser!.id;

    if (otherId == myId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes chatear contigo mismo')));
      return;
    }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherId: otherId,
            otherUser: profile,
          ),
        ),
      );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            ),
            child: Icon(Icons.messenger_outline_rounded, size: 72, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Envía mensajes a tus amigos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Envía fotos y mensajes privados a un amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startNewChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Buscar usuario', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
