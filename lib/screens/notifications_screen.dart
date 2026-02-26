import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxType.circle,
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
      ),
    );
  }
}
