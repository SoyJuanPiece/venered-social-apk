import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejado por el OS
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'venered_messages',
    'Mensajes de Venered',
    description: 'Canal para notificaciones de chat.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  
  static Future<void> init() async {
    // 1. PRIMERO: Activar el escucha de Supabase (Siempre debe funcionar)
    _startSupabaseListener();

    // 2. INICIALIZAR NOTIFICACIONES LOCALES
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. INTENTAR FIREBASE (Si falla, no bloquea lo anterior)
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Pedir permisos
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Configurar handlers
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showLocalNotification(message.notification!.title ?? 'Venered', message.notification!.body ?? '');
        }
      });

      // Intentar obtener token (aquí es donde daba el error TOO_MANY_REGISTRATIONS)
      final token = await messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) _saveToken(token);
      
    } catch (e) {
      dPrint('Aviso: Firebase no pudo registrarse, se usará solo Supabase: $e');
    }
  }

  static void _startSupabaseListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _supabaseSub?.cancel();
    _supabaseSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .listen((List<Map<String, dynamic>> data) async {
          if (data.isEmpty) return;
          
          final unread = data.where((n) => n['is_read'] == false).toList();
          if (unread.isEmpty) return;
          
          final lastNotif = unread.last;
          if (_lastNotifId == lastNotif['id']) return;
          _lastNotifId = lastNotif['id'];

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
        await Supabase.instance.client.from('profiles').update({'fcm_token': token}).eq('id', user.id);
      } catch (_) {}
    }
  }

  static void _showLocalNotification(String title, String body) {
    _localNotifications.show(
      DateTime.now().hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
