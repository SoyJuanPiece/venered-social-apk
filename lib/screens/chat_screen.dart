import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../formatters.dart';
import '../utils.dart';
import '../services/media_manager.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isCancelling = false;
  bool _isUploading = false;

  bool _otherOnline = false;
  DateTime? _otherLastSeen;
  late StreamSubscription<List<Map<String, dynamic>>> _presenceSub;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _setupStream();
    _markAsRead();
    _setupPresence();
    _setMyPresence(true);
  }

  @override
  void dispose() {
    _presenceSub.cancel();
    _setMyPresence(false);
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _setupStream() {
    _messagesStream = supabase.from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);
  }

  void _setupPresence() {
    _presenceSub = supabase.from('profiles').stream(primaryKey: ['id']).eq('id', widget.otherUser['id']).listen((List<Map<String, dynamic>> event) {
      if (event.isEmpty) return;
      final record = event.first;
      if (mounted) setState(() { _otherOnline = record['is_online'] == true; if (record['last_seen'] != null) _otherLastSeen = DateTime.tryParse(record['last_seen']); });
    });
  }

  Future<void> _setMyPresence(bool online) async {
    try { await supabase.from('profiles').update({'is_online': online, 'last_seen': online ? null : DateTime.now().toIso8601String()}).eq('id', supabase.auth.currentUser!.id); } catch (_) {}
  }

  Future<void> _markAsRead() async {
    final myId = supabase.auth.currentUser!.id;
    await supabase.from('messages').update({'is_read': true}).eq('conversation_id', widget.conversationId).neq('sender_id', myId);
  }

  // --- SUBIDA DE IMAGEN ---
  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final imageUrl = await MediaManager.uploadToImgBB(File(pickedFile.path));
        if (imageUrl != null) {
          await supabase.from('messages').insert({
            'conversation_id': widget.conversationId,
            'sender_id': supabase.auth.currentUser!.id,
            'type': 'image',
            'media_url': imageUrl,
            'content': '📷 Foto',
          });
          _updateConversation();
        }
      } catch (e) { dPrint('Error image: $e'); } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  // --- SUBIDA DE AUDIO ---
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = p.join(directory.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() { _isRecording = true; _recordingDuration = 0; });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordingDuration++));
    }
  }

  Future<void> _stopAndSendAudio() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null && !_isCancelling) {
      setState(() => _isUploading = true);
      final result = await MediaManager.uploadToTelegram(File(path), isStory: false);
      if (result != null && result['ok'] == true) {
        await supabase.from('messages').insert({
          'conversation_id': widget.conversationId,
          'sender_id': supabase.auth.currentUser!.id,
          'type': 'voice',
          'media_url': result['url'],
          'content': result['file_id'],
        });
        _updateConversation();
      }
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': supabase.auth.currentUser!.id,
      'content': content,
      'type': 'text'
    });
    _updateConversation();
  }

  Future<void> _updateConversation() async {
    await supabase.from('conversations').update({'last_message_at': DateTime.now().toIso8601String()}).eq('id', widget.conversationId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: widget.otherUser['avatar_url'] != null ? NetworkImage(widget.otherUser['avatar_url']) : null),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser['username'] ?? 'Usuario', style: const TextStyle(fontSize: 16)),
                Text(_otherOnline ? 'En línea' : 'Desconectado', style: TextStyle(fontSize: 11, color: _otherOnline ? Colors.green : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg['sender_id'] == myId;
                    return _buildBubble(msg, isMe, theme);
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(),
          _buildInput(theme),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: msg['type'] == 'image' 
          ? Image.network(msg['media_url']) 
          : Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image), onPressed: () => _pickAndSendImage(ImageSource.gallery)),
          Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Mensaje...'))),
          IconButton(icon: Icon(_isRecording ? Icons.stop : Icons.mic), onPressed: _isRecording ? _stopAndSendAudio : _startRecording),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
