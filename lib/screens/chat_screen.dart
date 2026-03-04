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

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final imageUrl = await MediaManager.uploadToImgBB(File(pickedFile.path));
        if (imageUrl != null) {
          await supabase.from('messages').insert({
            'conversation_id': widget.conversationId,
            'sender_id': supabase.auth.currentUser!.id,
            'receiver_id': widget.otherUser['id'],
            'type': 'image',
            'media_url': imageUrl,
            'content': '📷 Foto',
          });
          _updateConversation();
        }
      } catch (e) { dPrint('Error image: $e'); } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = p.join(directory.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() { _isRecording = true; _recordingDuration = 0; _isCancelling = false; });
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
          'receiver_id': widget.otherUser['id'],
          'type': 'voice',
          'media_url': result['url'],
          'content': result['file_id'],
        });
        _updateConversation();
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': supabase.auth.currentUser!.id,
      'receiver_id': widget.otherUser['id'],
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
                Text(widget.otherUser['username'] ?? 'Usuario', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return _buildBubble(msg, msg['sender_id'] == myId, theme);
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
    final type = msg['type'] ?? 'text';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'voice')
              VoiceNotePlayer(url: msg['media_url'], isMe: isMe)
            else if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _showFullScreen(msg['media_url']),
                  child: Image.network(msg['media_url']),
                ),
              )
            else
              Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(formatHm(DateTime.parse(msg['created_at'])), style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(String url) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: Center(child: InteractiveViewer(child: Image.network(url))))));
  }

  Widget _buildInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary), onPressed: _pickAndSendImage),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _messageController.text.isNotEmpty
              ? IconButton(icon: Icon(Icons.send, color: theme.colorScheme.primary), onPressed: _sendMessage)
              : GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopAndSendAudio,
                  child: CircleAvatar(
                    backgroundColor: _isRecording ? Colors.red : theme.colorScheme.primary,
                    child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class VoiceNotePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const VoiceNotePlayer({super.key, required this.url, required this.isMe});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPositionChanged.listen((p) => setState(() => _pos = p));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  void _play() async {
    if (_isPlaying) { await _player.pause(); } 
    else { await _player.play(UrlSource(widget.url)); }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: widget.isMe ? Colors.white : Colors.blue), onPressed: _play),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: _dur.inSeconds > 0 ? _pos.inSeconds / _dur.inSeconds : 0,
            backgroundColor: widget.isMe ? Colors.white24 : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(widget.isMe ? Colors.white : Colors.blue),
          ),
        ),
      ],
    );
  }
}
