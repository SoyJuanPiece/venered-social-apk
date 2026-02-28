import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/chat_screen.dart';
import 'package:venered_social/widgets/user_search_dialog.dart';

import '../utils.dart';
import '../formatters.dart';

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
    _loadConversations();
    _setupRealtime();
    _markNotificationsAsRead();
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
        final dateA = DateTime.parse(a['last_message_at'] ?? DateTime.now().toIso8601String());
        final dateB = DateTime.parse(b['last_message_at'] ?? DateTime.now().toIso8601String());
        return dateB.compareTo(dateA);
      });

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
    final userId = supabase.auth.currentUser!.id;

    // Listen to changes in conversations and messages to refresh the list
    _channel = supabase.channel('messages_list_updates').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (payload) => _loadConversations(),
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) => _loadConversations(),
    ).subscribe();
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
      body: _loading 
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
                    final otherUsername = chat['other_username'] ?? 'Usuario';
                    final otherAvatar = chat['other_avatar_url'];
                    final lastContent = chat['last_message_content'];
                    final lastSender = chat['last_message_sender_id'];
                    final updatedAt = DateTime.parse(chat['last_message_at'] ?? DateTime.now().toIso8601String());

                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: chat['conversation_id'],
                            otherUser: {
                              'id': chat['other_user_id'],
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
                          backgroundImage: (otherAvatar != null && otherAvatar.isNotEmpty) ? NetworkImage(otherAvatar) : null,
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
                        lastContent ?? '¡Di hola!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: lastSender != myId ? theme.colorScheme.onSurface : Colors.grey,
                          fontWeight: lastSender != myId ? FontWeight.w600 : FontWeight.w400,
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

    try {
      // Verificar si ya existe
      final existing = await supabase
          .from('conversations')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.$otherId),and(user1_id.eq.$otherId,user2_id.eq.$myId)')
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'];
      } else {
        final newConv = await supabase.from('conversations').insert({
          'user1_id': myId,
          'user2_id': otherId,
        }).select('id').single();
        convId = newConv['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: convId,
              otherUser: profile,
            ),
          ),
        );
      }
    } catch (e) {
      dPrint('Error starting chat: $e');
    }
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
