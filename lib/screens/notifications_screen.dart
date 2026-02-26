import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
    _markAsRead();
  }

  void _setupStream() {
    _notificationsStream = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);
  }

  Future<void> _markAsRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', supabase.auth.currentUser!.id)
        .eq('is_read', false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, ThemeData theme) {
    final createdAt = DateTime.parse(notification['created_at']);
    final isRead = notification['is_read'];

    IconData icon;
    Color iconColor;
    String text;

    switch (notification['type']) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        text = 'le dio me gusta a tu publicación.';
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        text = 'comentó tu publicación: "${notification['content']}"';
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.green;
        text = 'comenzó a seguirte.';
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        text = notification['content'] ?? 'nueva notificación';
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: supabase.from('profiles').select().eq('id', notification['sender_id']).single(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isRead ? theme.cardColor : theme.colorScheme.primary.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url']) : null,
              child: profile?['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                children: [
                  TextSpan(
                    text: profile?['username'] ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $text'),
                ],
              ),
            ),
            subtitle: Text(
              DateFormat.MMMd().add_Hm().format(createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: notification['post_id'] != null
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.image, size: 20, color: Colors.grey),
                  )
                : Icon(icon, color: iconColor, size: 16),
          ),
        );
      },
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
            child: Icon(Icons.notifications_none_outlined, size: 64, color: theme.colorScheme.onBackground),
          ),
          const SizedBox(height: 24),
          const Text('Aún no tienes notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Aquí verás los likes, comentarios y seguidores nuevos.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
