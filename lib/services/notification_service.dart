import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/utils.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;

  static Future<void> init() async {
    // 1. Solicitar permisos (iOS y Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      dPrint('Usuario concedió permiso para notificaciones');
    }

    // 2. Configurar Notificaciones Locales (para cuando la app está abierta)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    // 3. Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Vincular token si el usuario ya está logueado
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _saveToken(user.id);
      startListening();
    }
  }

  static Future<void> _saveToken(String userId) async {
    String? token = await _fcm.getToken();
    if (token != null) {
      dPrint('Guardando FCM Token para $userId: $token');
      await Supabase.instance.client.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static void login(String userId) {
    _saveToken(userId);
    startListening();
  }

  static void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'venered_messages',
      'Mensajes de Venered',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  static void startListening() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _supabaseSub?.cancel();
    _supabaseSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          // Lógica in-app opcional aquí
        });
  }
}
