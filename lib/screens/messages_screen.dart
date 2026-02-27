import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/chat_screen.dart';
import 'package:venered_social/widgets/user_search_dialog.dart';

import '../utils.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    // We'll subscribe to the user's participant rows just to be notified about
    // any change (new conversation, participant removed, etc.). Every time the
    // event arrives we call an RPC that returns all the information in a
    // single query, avoiding the previous N+1 pattern.
    final userId = supabase.auth.currentUser!.id;

    _conversationsStream = supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((event) async {
          final res = await supabase.rpc('get_user_conversations', params: {
            'p_user_id': userId,
          });
          if (res.error != null) {
            // log and return empty list so the UI doesn't break
            dPrint('get_user_conversations rpc error: ${res.error}');
            return <Map<String, dynamic>>[];
          }
          return (res.data as List<dynamic>)
              .cast<Map<String, dynamic>>();
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final conversations = snapshot.data ?? [];
          
          if (conversations.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final otherUsername = chat['other_username'] as String?;
              final otherAvatar = chat['other_avatar_url'] as String?;
              final lastContent = chat['last_message_content'] as String?;
              final lastSender = chat['last_message_sender_id'];
              final updatedAt = DateTime.parse(chat['updated_at']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
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
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.onBackground.withOpacity(0.1),
                    backgroundImage: otherAvatar != null ? NetworkImage(otherAvatar) : null,
                    child: otherAvatar == null
                        ? Icon(Icons.person, color: theme.colorScheme.onBackground.withOpacity(0.4))
                        : null,
                  ),
                  title: Text(
                    otherUsername ?? 'Usuario',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    lastContent ?? 'No hay mensajes aún',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: lastContent != null && lastSender != supabase.auth.currentUser!.id
                          ? theme.colorScheme.onSurface.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: lastContent != null && lastSender != supabase.auth.currentUser!.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    formatHm(updatedAt),
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startNewChat() async {
    // show a richer search dialog that returns the selected profile map
    final profile = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const UserSearchDialog(),
    );

    if (profile == null) return;

    final otherId = profile['id'] as String;
    if (otherId == supabase.auth.currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes iniciar chat contigo mismo')),
      );
      return;
    }

    try {
      final convRes = await supabase.rpc('create_conversation', params: {
        'p_user1': supabase.auth.currentUser!.id,
        'p_user2': otherId,
      });

      if (convRes.error != null) {
        throw convRes.error!;
      }
      final convId = convRes.data as String;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: convId,
            otherUser: profile,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error iniciando chat: $e')),
      );
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
