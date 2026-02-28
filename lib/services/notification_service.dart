import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';

// Manejador para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejado automáticamente por Firebase si trae payload de 'notification'
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId; // Para evitar duplicados
  
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final token = await messaging.getToken();
    if (token != null) _saveToken(token);

    messaging.onTokenRefresh.listen(_saveToken);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        message.notification?.title ?? 'Venered', 
        message.notification?.body ?? '',
      );
    });

    _startSupabaseListener();
  }

  static void _startSupabaseListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _supabaseSub?.cancel();
    // Escuchamos la tabla de notificaciones filtrada por el usuario actual
    _supabaseSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .listen((List<Map<String, dynamic>> data) async {
          if (data.isEmpty) return;
          
          // Tomamos la última notificación que no sea leída
          final unread = data.where((n) => n['is_read'] == false).toList();
          if (unread.isEmpty) return;
          
          final lastNotif = unread.last;
          
          // Evitar repetir la misma notificación
          if (_lastNotifId == lastNotif['id']) return;
          _lastNotifId = lastNotif['id'];

          // Obtener nombre del remitente
          final senderData = await Supabase.instance.client
              .from('profiles')
              .select('username')
              .eq('id', lastNotif['sender_id'])
              .maybeSingle();
          
          final senderName = senderData?['username'] ?? 'Usuario';
          String title = 'Venered Social';
          String body = lastNotif['content'] ?? '';

          if (lastNotif['type'] == 'follow') {
            title = '¡Nuevo seguidor!';
            body = '$senderName ha comenzado a seguirte';
          } else if (lastNotif['type'] == 'message') {
            title = 'Mensaje de $senderName';
          }

          _showLocalNotification(title, body);
        });
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      } catch (_) {}
    }
  }

  static void _showLocalNotification(String title, String body) {
    _localNotifications.show(
      DateTime.now().hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'venered_notifications',
          'Venered Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }
}
