import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId;

  static Future<void> init() async {
    // 1. Inicializar OneSignal (El motor principal)
    // OneSignal 5.x ya maneja internamente la conexión con Firebase
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6");
    OneSignal.Notifications.requestPermission(true);

    // 2. Vincular usuario si ya está logueado
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      login(currentUser.id);
    }
  }

  static void login(String userId) {
    OneSignal.login(userId);
    startListening();
  }

  // Escucha cambios en la tabla de notificaciones para mostrar avisos IN-APP
  static void startListening() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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

          // Aquí podrías mostrar un banner elegante dentro de la app
          dPrint('Nueva notificación detectada en DB: ${lastNotif['content']}');
        }, onError: (e) {
          dPrint('Error en stream de notificaciones: $e');
        });
  }
}
