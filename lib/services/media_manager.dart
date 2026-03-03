import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MediaManager {
  static Database? _database;
  static const String telegramServerUrl = 'http://toby.hidencloud.com:24652/upload';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'venered_cache_v3.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE media_cache (
            message_id TEXT PRIMARY KEY,
            local_path TEXT,
            media_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.execute('''
          CREATE TABLE feed_cache (
            id TEXT PRIMARY KEY,
            data TEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS feed_cache (id TEXT PRIMARY KEY, data TEXT, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
        }
      }
    );
  }

  // --- GESTIÓN DE CACHE GENÉRICO (Feed, Mensajes, etc) ---
  static Future<void> saveToCache(String key, dynamic data) async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS general_cache (id TEXT PRIMARY KEY, data TEXT, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.insert('general_cache', {'id': key, 'data': json.encode(data)}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<dynamic> getFromCache(String key) async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS general_cache (id TEXT PRIMARY KEY, data TEXT, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    final res = await db.query('general_cache', where: 'id = ?', whereArgs: [key]);
    if (res.isNotEmpty) return json.decode(res.first['data'] as String);
    return null;
  }

  static Future<void> cacheFeed(List<Map<String, dynamic>> posts) async => saveToCache('main_feed', posts);
  static Future<List<Map<String, dynamic>>> getCachedFeed() async {
    final data = await getFromCache('main_feed');
    return data != null ? List<Map<String, dynamic>>.from(data) : [];
  }

  // --- GESTIÓN DE MEDIA ---
  static Future<Map<String, dynamic>?> uploadToTelegram(File file, {bool isStory = true}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(telegramServerUrl));
      final ext = extension(file.path).toLowerCase();
      MediaType? contentType;
      if (ext == '.mp4') contentType = MediaType('video', 'mp4');
      else if (ext == '.jpg' || ext == '.jpeg') contentType = MediaType('image', 'jpeg');
      else if (ext == '.png') contentType = MediaType('image', 'png');
      else if (ext == '.m4a') contentType = MediaType('audio', 'mp4');

      request.files.add(await http.MultipartFile.fromPath('media', file.path, filename: basename(file.path), contentType: contentType));
      request.fields['isStory'] = isStory.toString();

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}
    return null;
  }

  static Future<String?> getLocalPath(String messageId) async {
    final db = await database;
    final maps = await db.query('media_cache', where: 'message_id = ?', whereArgs: [messageId]);
    if (maps.isNotEmpty) {
      final path = maps.first['local_path'] as String;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  static Future<String?> downloadAndCache(String messageId, String url, String type) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(join(directory.path, 'Venered', type == 'voice' ? 'VoiceNotes' : 'Images'));
      if (!await folder.exists()) await folder.create(recursive: true);

      final extension = type == 'voice' ? '.m4a' : '.jpg';
      final localPath = join(folder.path, 'med_$messageId$extension');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(localPath).writeAsBytes(response.bodyBytes);
        final db = await database;
        await db.insert('media_cache', {'message_id': messageId, 'local_path': localPath, 'media_type': type}, conflictAlgorithm: ConflictAlgorithm.replace);
        return localPath;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> registerLocalMedia(String messageId, String localPath, String type) async {
    final db = await database;
    await db.insert('media_cache', {'message_id': messageId, 'local_path': localPath, 'media_type': type}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
