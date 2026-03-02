import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class MediaManager {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'venered_media.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE media_cache (
            message_id TEXT PRIMARY KEY,
            local_path TEXT,
            media_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  /// Obtiene la ruta local de un archivo si ya existe en el teléfono.
  static Future<String?> getLocalPath(String messageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );

    if (maps.isNotEmpty) {
      final path = maps.first['local_path'] as String;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// Descarga un archivo y lo guarda permanentemente en la carpeta de la app.
  static Future<String?> downloadAndCache(String messageId, String url, String type) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(join(directory.path, 'Venered', type == 'voice' ? 'VoiceNotes' : 'Images'));
      if (!await folder.exists()) await folder.create(recursive: true);

      final extension = type == 'voice' ? '.m4a' : '.jpg';
      final localPath = join(folder.path, 'med_$messageId$extension');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        // Guardar en SQLite
        final db = await database;
        await db.insert(
          'media_cache',
          {
            'message_id': messageId,
            'local_path': localPath,
            'media_type': type,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return localPath;
      }
    } catch (e) {
      print('Error caching media: $e');
    }
    return null;
  }

  /// Registra un archivo que el mismo usuario acaba de enviar (ya es local).
  static Future<void> registerLocalMedia(String messageId, String localPath, String type) async {
    final db = await database;
    await db.insert(
      'media_cache',
      {
        'message_id': messageId,
        'local_path': localPath,
        'media_type': type,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
