import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/chat_screen.dart';
import 'package:intl/intl.dart';

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
    // Note: In a real app, we'd use a view or a more complex query.
    // For now, we listen to conversation_participants to know which chats we belong to.
    _conversationsStream = supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', supabase.auth.currentUser!.id)
        .asyncMap((event) async {
          List<Map<String, dynamic>> conversations = [];
          for (var participant in event) {
            final convId = participant['conversation_id'];
            
            // Get conversation details
            final convData = await supabase
                .from('conversations')
                .select()
                .eq('id', convId)
                .single();
            
            // Get other participant profile
            final otherParticipant = await supabase
                .from('conversation_participants')
                .select('user_id')
                .eq('conversation_id', convId)
                .neq('user_id', supabase.auth.currentUser!.id)
                .maybeSingle();
            
            if (otherParticipant != null) {
              final otherProfile = await supabase
                  .from('profiles')
                  .select()
                  .eq('id', otherParticipant['user_id'])
                  .single();
              
              // Get last message
              final lastMessage = await supabase
                  .from('messages')
                  .select()
                  .eq('conversation_id', convId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              conversations.add({
                'id': convId,
                'other_user': otherProfile,
                'last_message': lastMessage,
                'updated_at': convData['last_message_at'],
              });
            }
          }
          // Sort by date
          conversations.sort((a, b) => (b['updated_at'] as String).compareTo(a['updated_at'] as String));
          return conversations;
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
            onPressed: () {
              // TODO: Implement new chat search
            },
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
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final otherUser = chat['other_user'];
              final lastMsg = chat['last_message'];
              final updatedAt = DateTime.parse(chat['updated_at']);

              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      conversationId: chat['id'],
                      otherUser: otherUser,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: otherUser['avatar_url'] != null 
                      ? NetworkImage(otherUser['avatar_url']) 
                      : null,
                  child: otherUser['avatar_url'] == null 
                      ? const Icon(Icons.person, color: Colors.grey) 
                      : null,
                ),
                title: Text(
                  otherUser['username'] ?? 'Usuario',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  lastMsg != null ? lastMsg['content'] : 'No hay mensajes aún',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: lastMsg != null && !lastMsg['is_read'] && lastMsg['sender_id'] != supabase.auth.currentUser!.id
                        ? theme.colorScheme.onSurface
                        : Colors.grey,
                    fontWeight: lastMsg != null && !lastMsg['is_read'] && lastMsg['sender_id'] != supabase.auth.currentUser!.id
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  DateFormat.Hm().format(updatedAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.onBackground, width: 2),
            ),
            child: Icon(Icons.messenger_outline_rounded, size: 64, color: theme.colorScheme.onBackground),
          ),
          const SizedBox(height: 24),
          const Text('Envía mensajes a tus amigos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Envía fotos y mensajes privados a un amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Enviar mensaje', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
