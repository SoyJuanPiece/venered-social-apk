import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // NECESARIO PARA EL CONTENT-TYPE
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/utils.dart';

class MediaManager {
  static Database? _database;
  static final Map<String, dynamic> _webGeneralCache = {};
  static final Map<String, Map<String, String>> _webMediaCache = {};
  static const String telegramServerUrl = 'http://toby.hidencloud.com:24652/upload';
  static const String imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb';
  static const String voiceBucket = 'voice-notes';

  static String _buildImgName({
    required String category,
    String? userId,
    String? extensionHint,
  }) {
    final safeCategory = category.trim().isEmpty ? 'misc' : category.trim().toLowerCase();
    final cleanedUserId = (userId ?? '').replaceAll('-', '');
    final uid = cleanedUserId.isNotEmpty
        ? cleanedUserId.substring(0, cleanedUserId.length >= 8 ? 8 : cleanedUserId.length)
        : 'anon';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = (extensionHint == null || extensionHint.trim().isEmpty) ? 'jpg' : extensionHint.trim().toLowerCase();
    return 'venered_${safeCategory}_${uid}_$ts.$ext';
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'venered_cache_v8.db');
    return await openDatabase(path, version: 8, onCreate: (db, version) async {
      await db.execute('CREATE TABLE media_cache (message_id TEXT PRIMARY KEY, local_path TEXT, media_type TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
      await db.execute('CREATE TABLE general_cache (id TEXT PRIMARY KEY, data TEXT, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    });
  }

  // --- SUBIDA DE IMÁGENES A IMGBB ---
  static Future<String?> uploadToImgBB(
    File file, {
    String category = 'misc',
    String? userId,
  }) async {
    try {
      if (kIsWeb) {
        dPrint('Error ImgBB: Upload no soportado en Web (requiere dart:io)');
        return null;
      }
      final compressed = await compressImage(file);
      final uploadFile = compressed ?? file;
      final ext = extension(uploadFile.path).replaceFirst('.', '');
      final currentUserId = userId ?? Supabase.instance.client.auth.currentUser?.id;
      final imageName = _buildImgName(
        category: category,
        userId: currentUserId,
        extensionHint: ext,
      );
      final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'))
        ..fields['name'] = imageName
        ..files.add(await http.MultipartFile.fromPath('image', uploadFile.path, filename: imageName));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) return json.decode(responseBody)['data']['url'];
    } catch (e) { dPrint('Error ImgBB: $e'); }
    return null;
  }

  // --- SUBIDA DE IMÁGENES A IMGBB DESDE WEB (sin dart:io) ---
  static Future<String?> uploadImageBytesToImgBB(
    Uint8List bytes, {
    String category = 'misc',
    String? userId,
    String extensionHint = 'jpg',
  }) async {
    try {
      final currentUserId = userId ?? Supabase.instance.client.auth.currentUser?.id;
      final imageName = _buildImgName(
        category: category,
        userId: currentUserId,
        extensionHint: extensionHint,
      );
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': imgbbApiKey,
          'name': imageName,
          'image': base64Encode(bytes),
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded['data']?['url'] as String?;
      }

      dPrint('Error ImgBB Web: ${response.statusCode} ${response.body}');
    } catch (e) {
      dPrint('Error ImgBB Web: $e');
    }
    return null;
  }

  // --- SUBIDA HIBRIDA (Local backend con fallback Telegram) ---
  static Future<Map<String, dynamic>?> uploadToTelegram(
    File file, {
    bool isStory = true,
    int expiresInSec = 86400,
    bool preferLocal = true,
    bool forceTelegram = false,
  }) async {
    try {
      if (kIsWeb) {
        dPrint('Error Técnico Telegram: Upload no soportado en Web (requiere dart:io)');
        return null;
      }
      var request = http.MultipartRequest('POST', Uri.parse(telegramServerUrl));
      
      // DETECTAR TIPO DE ARCHIVO PARA EVITAR "FORMATO NO SOPORTADO"
      final ext = extension(file.path).toLowerCase();
      MediaType contentType;
      if (ext == '.mp4') contentType = MediaType('video', 'mp4');
      else if (ext == '.jpg' || ext == '.jpeg') contentType = MediaType('image', 'jpeg');
      else if (ext == '.png') contentType = MediaType('image', 'png');
      else contentType = MediaType('application', 'octet-stream');

      request.files.add(await http.MultipartFile.fromPath(
        'media', 
        file.path, 
        filename: basename(file.path),
        contentType: contentType, // AQUÍ ESTÁ LA SOLUCIÓN
      ));
      
      request.fields['isStory'] = isStory.toString();
      request.fields['expiresInSec'] = expiresInSec.toString();
      request.fields['preferLocal'] = preferLocal.toString();
      request.fields['forceTelegram'] = forceTelegram.toString();
      var streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) return json.decode(response.body);
      else dPrint('Error Servidor Telegram: ${response.body}');
    } catch (e) { dPrint('Error Técnico Telegram: $e'); }
    return null;
  }

  static Future<String?> uploadVideoToTelegram(File file) async {
    final res = await uploadToTelegram(file, isStory: true);
    if (res != null && res['ok'] == true) {
      return res['file_id'] ?? res['result']?['video']?['file_id'];
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getBackendStorageStatus() async {
    try {
      final uri = Uri.parse(telegramServerUrl.replaceAll('/upload', '/api/storage/status'));
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      dPrint('Error consultando storage backend: $e');
      return null;
    }
  }

  // --- SUBIDA DE AUDIOS A SUPABASE STORAGE ---
  static Future<Map<String, String>?> uploadVoiceToSupabase({
    required Uint8List bytes,
    required String userId,
    String? preferredExt,
    String? preferredContentType,
  }) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final isWebVoice = kIsWeb;
      final ext = preferredExt ?? (isWebVoice ? 'webm' : 'm4a');
      final contentType = preferredContentType ?? (isWebVoice ? 'audio/webm' : 'audio/mp4');
      final objectPath = '$userId/voice_$ts.$ext';
      await Supabase.instance.client.storage.from(voiceBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
      final publicUrl = Supabase.instance.client.storage.from(voiceBucket).getPublicUrl(objectPath);
      return {
        'url': publicUrl,
        'path': objectPath,
      };
    } catch (e) {
      dPrint('Error Storage Voz: $e');
      return null;
    }
  }

  // --- MÉTODOS DE CACHÉ ---
  static Future<void> cacheFeed(List<Map<String, dynamic>> posts) async => saveToCache('main_feed', posts);
  static Future<List<Map<String, dynamic>>> getCachedFeed() async {
    final data = await getFromCache('main_feed');
    return data != null ? List<Map<String, dynamic>>.from(data) : [];
  }

  static Future<void> saveToCache(String key, dynamic data) async {
    if (kIsWeb) {
      _webGeneralCache[key] = data;
      return;
    }
    final db = await database;
    await db.insert('general_cache', {'id': key, 'data': json.encode(data), 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<dynamic> getFromCache(String key) async {
    if (kIsWeb) {
      return _webGeneralCache[key];
    }
    final db = await database;
    final res = await db.query('general_cache', where: 'id = ?', whereArgs: [key]);
    if (res.isNotEmpty) return json.decode(res.first['data'] as String);
    return null;
  }

  // --- GESTIÓN LOCAL ---
  static Future<String?> getLocalPath(String messageId) async {
    if (kIsWeb) {
      return _webMediaCache[messageId]?['local_path'];
    }
    final db = await database;
    final maps = await db.query('media_cache', where: 'message_id = ?', whereArgs: [messageId]);
    if (maps.isNotEmpty) {
      final path = maps.first['local_path'] as String;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  static Future<void> registerLocalMedia(String messageId, String localPath, String type) async {
    if (kIsWeb) {
      _webMediaCache[messageId] = {'local_path': localPath, 'media_type': type};
      return;
    }
    final db = await database;
    await db.insert('media_cache', {'message_id': messageId, 'local_path': localPath, 'media_type': type}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> downloadAndCache(String messageId, String url, String type) async {
    try {
      if (url.isEmpty) return null;
      if (kIsWeb) {
        await registerLocalMedia(messageId, url, type);
        return url;
      }
      final directory = await getApplicationDocumentsDirectory();
      final folderName = type == 'video'
          ? 'Stories'
          : (type == 'voice' ? 'Audios' : 'Images');
      final folder = Directory(join(directory.path, 'Venered', folderName));
      if (!await folder.exists()) await folder.create(recursive: true);
      final ext = type == 'video'
          ? '.mp4'
          : (type == 'voice' ? '.m4a' : '.jpg');
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
