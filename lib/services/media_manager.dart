import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/utils.dart';

class MediaManager {
  static Database? _database;
  static const String telegramServerUrl = 'http://toby.hidencloud.com:24652/upload';
  static const String imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'venered_cache_v7.db');
    return await openDatabase(path, version: 7, onCreate: (db, version) async {
      await db.execute('CREATE TABLE media_cache (message_id TEXT PRIMARY KEY, local_path TEXT, media_type TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
      await db.execute('CREATE TABLE general_cache (id TEXT PRIMARY KEY, data TEXT, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    });
  }

  // --- SUBIDA DE IMÁGENES A IMGBB ---
  static Future<String?> uploadToImgBB(File file) async {
    try {
      final compressed = await compressImage(file);
      final uploadFile = compressed ?? file;
      final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'))
        ..files.add(await http.MultipartFile.fromPath('image', uploadFile.path));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) return json.decode(responseBody)['data']['url'];
    } catch (e) { dPrint('Error ImgBB: $e'); }
    return null;
  }

  // --- SUBIDA A TELEGRAM (Videos/Voz) ---
  static Future<Map<String, dynamic>?> uploadToTelegram(File file, {bool isStory = true}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(telegramServerUrl));
      request.files.add(await http.MultipartFile.fromPath('media', file.path, filename: basename(file.path)));
      request.fields['isStory'] = isStory.toString();
      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { dPrint('Error Telegram: $e'); }
    return null;
  }

  static Future<String?> uploadVideoToTelegram(File file) async {
    final res = await uploadToTelegram(file, isStory: true);
    if (res != null && res['ok'] == true) {
      // El backend de Telegram devuelve file_id o una estructura similar
      return res['file_id'] ?? res['result']?['video']?['file_id'];
    }
    return null;
  }

  // --- MÉTODOS DE CACHÉ REQUERIDOS POR LA APP ---
  static Future<void> cacheFeed(List<Map<String, dynamic>> posts) async => saveToCache('main_feed', posts);
  static Future<List<Map<String, dynamic>>> getCachedFeed() async {
    final data = await getFromCache('main_feed');
    return data != null ? List<Map<String, dynamic>>.from(data) : [];
  }

  static Future<void> saveToCache(String key, dynamic data) async {
    final db = await database;
    await db.insert('general_cache', {'id': key, 'data': json.encode(data), 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<dynamic> getFromCache(String key) async {
    final db = await database;
    final res = await db.query('general_cache', where: 'id = ?', whereArgs: [key]);
    if (res.isNotEmpty) return json.decode(res.first['data'] as String);
    return null;
  }

  // --- GESTIÓN LOCAL DE ARCHIVOS (Chat/Historias) ---
  static Future<String?> getLocalPath(String messageId) async {
    final db = await database;
    final maps = await db.query('media_cache', where: 'message_id = ?', whereArgs: [messageId]);
    if (maps.isNotEmpty) {
      final path = maps.first['local_path'] as String;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  static Future<void> registerLocalMedia(String messageId, String localPath, String type) async {
    final db = await database;
    await db.insert('media_cache', {'message_id': messageId, 'local_path': localPath, 'media_type': type}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> downloadAndCache(String messageId, String url, String type) async {
    try {
      if (url.isEmpty) return null;
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(join(directory.path, 'Venered', type == 'video' ? 'Stories' : 'Images'));
      if (!await folder.exists()) await folder.create(recursive: true);
      final ext = type == 'video' ? '.mp4' : '.jpg';
      final localPath = join(folder.path, 'med_$messageId$ext');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(localPath).writeAsBytes(response.bodyBytes);
        await registerLocalMedia(messageId, localPath, type);
        return localPath;
      }
    } catch (e) { dPrint('Error cache: $e'); }
    return null;
  }
}
