import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';

// Manejador para mensajes en segundo plano (debe ser una función global)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No necesitamos hacer nada aquí si enviamos notificaciones con 'notification' payload, 
  // Firebase las muestra solo. Si enviamos solo 'data', aquí llamaríamos a _showLocalNotification.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;
  
  static Future<void> init() async {
    // Request permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM Token and save to Supabase
    final token = await messaging.getToken();
    if (token != null) {
      _saveToken(token);
    }

    // Listen for token refreshes
    messaging.onTokenRefresh.listen(_saveToken);

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
      },
    );

    // Listen for foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        message.notification?.title ?? 'Venered', 
        message.notification?.body ?? '',
      );
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Aquí podrías navegar a la pantalla de chat si quisieras
    });

    // --- ESCUCHAR NOTIFICACIONES DE SUPABASE (Solo para cuando la app está abierta) ---
    _startSupabaseListener();
  }

  static void _startSupabaseListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _supabaseSub?.cancel();
    _supabaseSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) async {
          if (data.isEmpty) return;
          
          // Filtrar manualmente por receptor y tipo en el cliente para mayor compatibilidad
          final myNotifs = data.where((n) => 
            n['receiver_id'] == user.id && 
            n['is_read'] == false &&
            (DateTime.now().difference(DateTime.parse(n['created_at'])).inSeconds < 10)
          ).toList();

          if (myNotifs.isEmpty) return;
          
          final lastNotif = myNotifs.last;

          // Obtener nombre del remitente para el título
          final senderData = await Supabase.instance.client
              .from('profiles')
              .select('username')
              .eq('id', lastNotif['sender_id'])
              .maybeSingle();
          
          final senderName = senderData?['username'] ?? 'Alguien';
          String title = 'Venered Social';
          String body = lastNotif['content'] ?? '';

          if (lastNotif['type'] == 'follow') {
            title = '¡Nuevo seguidor!';
            body = '$senderName $body';
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
        dPrint('FCM Token saved to Supabase');
      } catch (e) {
        dPrint('Error saving FCM token: $e');
      }
    }
  }

  static void _showLocalNotification(String title, String body) {
    _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'venered_notifications',
          'Venered Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
