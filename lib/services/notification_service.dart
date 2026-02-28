import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejado automáticamente si trae 'notification'
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId;

  // Definición del canal para Android (Importancia Máxima)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'venered_high_importance_channel', // id
    'Notificaciones de Venered', // title
    description: 'Este canal se usa para notificaciones importantes de mensajes.', // description
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    
    // 1. Pedir permisos de forma explícita
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      dPrint('Permiso de notificaciones concedido');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Inicializar notificaciones locales
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        // Manejar clic en la notificación
      },
    );

    // 4. Token de Firebase
    final token = await messaging.getToken();
    if (token != null) _saveToken(token);
    messaging.onTokenRefresh.listen(_saveToken);

    // 5. Escuchar mensajes de Firebase (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _showLocalNotification(notification.title ?? 'Venered', notification.body ?? '');
      }
    });

    _startSupabaseListener();
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
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
