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
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final userId = supabase.auth.currentUser!.id;

    // Escuchamos cambios en la tabla 'conversations'
    // Como .stream() no soporta .or(), escuchamos la tabla y el filtrado real
    // se hace dentro del asyncMap usando la vista SQL que ya tiene el filtro de usuario.
    _conversationsStream = supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((event) async {
          // La vista 'view_conversations' ya filtra por auth.uid()
          final res = await supabase
              .from('view_conversations')
              .select()
              .order('last_message_at', ascending: false);
          
          return List<Map<String, dynamic>>.from(res);
        });
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chat = conversations[index];
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
                ),
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
                    backgroundImage: otherAvatar != null ? NetworkImage(otherAvatar) : null,
                    child: otherAvatar == null ? Icon(Icons.person, color: theme.colorScheme.primary) : null,
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
          );
        },
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
