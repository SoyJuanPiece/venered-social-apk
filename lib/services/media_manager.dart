import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    final path = join(dbPath, 'venered_cache_v6.db');
    return await openDatabase(path, version: 6, onCreate: (db, version) async {
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
      if (response.statusCode == 200) {
        return json.decode(responseBody)['data']['url'];
      }
    } catch (e) { dPrint('Error ImgBB: $e'); }
    return null;
  }

  // --- SUBIDA DE VIDEOS A TELEGRAM BACKEND ---
  static Future<String?> uploadVideoToTelegram(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(telegramServerUrl));
      request.files.add(await http.MultipartFile.fromPath('media', file.path, filename: basename(file.path)));
      request.fields['isStory'] = 'true';

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // El backend devuelve el file_id, el cual el visor de historias sabe procesar
        return data['file_id']; 
      }
    } catch (e) { dPrint('Error Telegram Backend: $e'); }
    return null;
  }

  // --- SUBIDA DE AUDIO A SUPABASE ---
  static Future<String?> uploadAudioToSupabase(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      await Supabase.instance.client.storage.from('media').upload('audio/$fileName', file);
      return Supabase.instance.client.storage.from('media').getPublicUrl('audio/$fileName');
    } catch (e) { dPrint('Error Supabase Audio: $e'); }
    return null;
  }

  // --- CACHE ---
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
}
