import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class PostDraft {
  String caption;
  String? mediaPath;
  Uint8List? webMediaBytes;
  String mediaType; // 'image', 'video', 'text'
  DateTime lastModified;

  PostDraft({
    required this.caption,
    this.mediaPath,
    this.webMediaBytes,
    this.mediaType = 'text',
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'caption': caption,
    'mediaPath': mediaPath,
    'mediaType': mediaType,
    'lastModified': lastModified.toIso8601String(),
  };

  static PostDraft fromJson(Map<String, dynamic> json) => PostDraft(
    caption: json['caption'] ?? '',
    mediaPath: json['mediaPath'],
    mediaType: json['mediaType'] ?? 'text',
    lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
  );
}

class ChatDraft {
  String chatId;
  String content;
  DateTime lastModified;

  ChatDraft({
    required this.chatId,
    required this.content,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'content': content,
    'lastModified': lastModified.toIso8601String(),
  };

  static ChatDraft fromJson(Map<String, dynamic> json) => ChatDraft(
    chatId: json['chatId'] ?? '',
    content: json['content'] ?? '',
    lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
  );
}

class DraftManager {
  static const String _postDraftKey = 'post_draft';
  static const String _chatDraftsKey = 'chat_drafts';

  // POST DRAFT METHODS
  static Future<void> savePostDraft(PostDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_postDraftKey, jsonEncode(draft.toJson()));
  }

  static Future<PostDraft?> loadPostDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_postDraftKey);
    if (json == null) return null;
    try {
      return PostDraft.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  static Future<void> deletePostDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postDraftKey);
  }

  // CHAT DRAFT METHODS
  static Future<void> saveChatDraft(String chatId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing drafts
    final json = prefs.getString(_chatDraftsKey);
    Map<String, dynamic> drafts = {};
    if (json != null) {
      try {
        drafts = jsonDecode(json);
      } catch (_) {}
    }
    
    // Update or add draft
    if (content.isEmpty) {
      drafts.remove(chatId);
    } else {
      drafts[chatId] = {
        'content': content,
        'lastModified': DateTime.now().toIso8601String(),
      };
    }
    
    await prefs.setString(_chatDraftsKey, jsonEncode(drafts));
  }

  static Future<String?> loadChatDraft(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chatDraftsKey);
    if (json == null) return null;
    try {
      final drafts = jsonDecode(json) as Map<String, dynamic>;
      return drafts[chatId]?['content'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteChatDraft(String chatId) async {
    await saveChatDraft(chatId, '');
  }

  static Future<Map<String, dynamic>> loadAllChatDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chatDraftsKey);
    if (json == null) return {};
    try {
      final drafts = jsonDecode(json) as Map<String, dynamic>;
      return drafts;
    } catch (_) {
      return {};
    }
  }
}
