import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LoggerService {
  static File? _logFile;

  static String? get currentLogPath => _logFile?.path;

  static Future<void> init() async {
    try {
      if (kIsWeb) {
        debugPrint('LoggerService activo en modo web (solo consola).');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final errorDir = Directory('${directory.path}/venered_errors');
      
      if (!await errorDir.exists()) {
        await errorDir.create(recursive: true);
      }

      final fileName = 'error_log_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}.txt';
      _logFile = File('${errorDir.path}/$fileName');
      
      await log('--- SESIÓN INICIADA: ${DateTime.now()} ---');
    } catch (e) {
      debugPrint('Error al inicializar el logger: $e');
    }
  }

  static Future<void> log(String message, [dynamic error, StackTrace? stackTrace]) async {
    if (_logFile == null) return;

    final timestamp = DateTime.now().toString();
    
    String logEntry = '[$timestamp]\n';
    logEntry += 'MENSAJE: $message\n';
    if (error != null) {
      logEntry += 'ERROR: $error\n';
    }
    if (stackTrace != null) {
      logEntry += 'STACKTRACE:\n$stackTrace\n';
    }
    logEntry += '-------------------------------------------------------\n\n';

    try {
      await _logFile!.writeAsString(logEntry, mode: FileMode.append);
      if (kDebugMode) {
        debugPrint('--- ERROR DETECTADO ---');
        debugPrint(logEntry);
      } else {
        debugPrint('Error guardado en log local.');
      }
    } catch (e) {
      debugPrint('Fallo al escribir en el log file: $e');
    }
  }
}
