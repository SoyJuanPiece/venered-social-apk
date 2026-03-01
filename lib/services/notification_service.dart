import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejado por el sistema
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'venered_messages_v2',
    'Canal de Mensajes Venered',
    description: 'Notificaciones emergentes de chat.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  
  static Future<void> init() async {
    // 1. Inicializar OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6");
    OneSignal.Notifications.requestPermission(true);

    // 2. Inicializar Notificaciones Locales con el icono correcto
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    
    try {
      await _localNotifications.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    } catch (e) {
      dPrint('Error inicializando notificaciones locales: $e');
    }

    // 3. Si ya hay un usuario al arrancar, vincular OneSignal
    if (Supabase.instance.client.auth.currentUser != null) {
      startListening();
      OneSignal.login(Supabase.instance.client.auth.currentUser!.id);
    }

    // 4. Configurar Firebase (con escudo contra errores)
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showLocalNotification(message.notification!.title ?? 'Venered', message.notification!.body ?? '');
        }
      });

      final token = await messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) _saveToken(token);
    } catch (e) {
      dPrint('Firebase no disponible: $e');
    }
  }

  static void startListening() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    OneSignal.login(user.id);

    _supabaseSub?.cancel();
    _supabaseSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) async {
          
          final myUnread = data.where((n) => 
            n['receiver_id'] == user.id && 
            n['is_read'] == false
          ).toList();

          if (myUnread.isEmpty) return;
          
          final lastNotif = myUnread.last;
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
        }, onError: (e) {
          dPrint('DEBUG NOTIF ERROR: $e');
        });
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('profiles').update({'fcm_token': token}).eq('id', user.id);
      } catch (e) {
        dPrint('Error guardando token FCM: $e');
      }
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
          icon: '@mipmap/launcher_icon', // Nombre corregido aquí también
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
