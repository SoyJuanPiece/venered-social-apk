import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/utils.dart';

class NotificationService {
  static StreamSubscription? _supabaseSub;
  static String? _lastNotifId;

  static Future<void> init() async {
    // Vincular usuario si ya está logueado
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      startListening();
    }
  }

  static void login(String userId) {
    dPrint('Iniciando escucha de notificaciones para usuario: $userId');
    startListening();
  }

  // Escucha cambios en la tabla de notificaciones para mostrar avisos IN-APP vía Supabase Realtime
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

          // Aquí es donde la app detecta la nueva notificación en tiempo real
          dPrint('Nueva notificación de Supabase: ${lastNotif['content']}');
          
          // TODO: Implementar un Overlay o Snackbar global para avisar al usuario
        }, onError: (e) {
          dPrint('Error en stream de notificaciones: $e');
        });
  }

  static void stopListening() {
    _supabaseSub?.cancel();
    _supabaseSub = null;
  }
}
