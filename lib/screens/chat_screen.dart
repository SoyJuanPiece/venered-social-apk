import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import '../formatters.dart';
import '../utils.dart';

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

  bool _otherOnline = false;
  DateTime? _otherLastSeen;
  late StreamSubscription<List<Map<String, dynamic>>> _presenceSub;
  late StreamSubscription<List<Map<String, dynamic>>> _reuploadListener;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _setupStream();
    _markAsRead();
    _setupPresence();
    _setMyPresence(true);
    _setupReuploadListener();
  }

  @override
  void dispose() {
    _presenceSub.cancel();
    _reuploadListener.cancel();
    _setMyPresence(false);
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // --- ESCUCHA DE RESUBIDA (RESCATE) ---
  void _setupReuploadListener() {
    final myId = supabase.auth.currentUser!.id;
    // Escuchar si alguien nos pide resubir un audio que enviamos nosotros
    _reuploadListener = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', myId)
        .eq('type', 'voice')
        .eq('needs_reupload', true)
        .listen((List<Map<String, dynamic>> event) {
          for (var msg in event) {
            _handleResubmitRequest(msg);
          }
        });
  }

  Future<void> _handleResubmitRequest(Map<String, dynamic> msg) async {
    try {
      final fileName = p.basename(msg['audio_url']);
      final directory = await getApplicationDocumentsDirectory();
      final localPath = p.join(directory.path, 'voice_notes', fileName);
      final file = File(localPath);

      if (await file.exists()) {
        dPrint('RESCATE: Resubiendo audio borrado: $fileName');
        // Resubir al Storage
        await supabase.storage.from('voice-notes').upload(fileName, file, fileOptions: const FileOptions(upsert: true));
        // Marcar como resubido
        await supabase.from('messages').update({'needs_reupload': false}).eq('id', msg['id']);
      }
    } catch (e) {
      dPrint('Error en rescate de audio: $e');
    }
  }

  // --- LÓGICA DE AUDIO ---

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final voiceNotesDir = Directory(p.join(directory.path, 'voice_notes'));
        if (!await voiceNotesDir.exists()) await voiceNotesDir.create(recursive: true);

        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final path = p.join(voiceNotesDir.path, fileName);
        
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc, 
          bitRate: 16000,    // 16 kbps (Extremadamente bajo peso)
          sampleRate: 11025, // 11kHz
          numChannels: 1,    // Mono
        );
        await _audioRecorder.start(config, path: path);

        _recordingDuration = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingDuration++);
          if (_recordingDuration >= 60) _stopAndSendAudio();
        });

        setState(() { _isRecording = true; });
      }
    } catch (e) { dPrint('Error recording: $e'); }
  }

  Future<void> _stopAndSendAudio() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) _uploadVoiceNote(path);
  }

  Future<void> _uploadVoiceNote(String localPath) async {
    try {
      final myId = supabase.auth.currentUser!.id;
      final fileName = p.basename(localPath);
      final file = File(localPath);

      await supabase.storage.from('voice-notes').upload(fileName, file);
      final audioUrl = supabase.storage.from('voice-notes').getPublicUrl(fileName);

      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': myId,
        'type': 'voice',
        'audio_url': audioUrl,
        'content': '🎵 Nota de voz',
      });
      _updateConversation();
    } catch (e) { dPrint('Error upload: $e'); }
  }

  // --- LÓGICA GENERAL ---

  void _setupStream() {
    _messagesStream = supabase.from('messages').stream(primaryKey: ['id']).eq('conversation_id', widget.conversationId).order('created_at', ascending: true);
  }

  void _setupPresence() {
    _presenceSub = supabase.from('profiles').stream(primaryKey: ['id']).eq('id', widget.otherUser['id']).listen((List<Map<String, dynamic>> event) {
      if (event.isEmpty) return;
      final record = event.first;
      setState(() {
        _otherOnline = record['is_online'] == true;
        if (record['last_seen'] != null) _otherLastSeen = DateTime.tryParse(record['last_seen']);
      });
    });
  }

  Future<void> _setMyPresence(bool online) async {
    try { await supabase.from('profiles').update({'is_online': online, 'last_seen': online ? null : DateTime.now().toIso8601String()}).eq('id', supabase.auth.currentUser!.id); } catch (_) {}
  }

  Future<void> _markAsRead() async {
    final myId = supabase.auth.currentUser!.id;
    await supabase.from('messages').update({'is_read': true}).eq('conversation_id', widget.conversationId).neq('sender_id', myId);
    try { await supabase.from('notifications').update({'is_read': true}).eq('receiver_id', myId).eq('sender_id', widget.otherUser['id']).eq('type', 'message'); } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': supabase.auth.currentUser!.id,
        'content': content,
        'type': 'text',
      });
      _updateConversation();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUser['avatar_url'] != null ? NetworkImage(widget.otherUser['avatar_url']) : null,
              child: widget.otherUser['avatar_url'] == null ? const Icon(Icons.person, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser['username'] ?? 'Usuario', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_otherOnline ? 'En línea' : (_otherLastSeen != null ? 'Últ. vez ${formatHm(_otherLastSeen!)}' : ''), style: TextStyle(fontSize: 12, color: _otherOnline ? Colors.green : Colors.grey)),
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
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, msg['sender_id'] == myId, theme);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    final isVoice = msg['type'] == 'voice';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 0), bottomRight: Radius.circular(isMe ? 0 : 20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isVoice)
              VoiceNotePlayer(msg: msg, isMe: isMe)
            else
              Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(formatHm(DateTime.parse(msg['created_at'])), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(28)),
                child: TextField(
                  controller: _messageController,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Mensaje...', border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopAndSendAudio,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _isRecording ? Colors.red : theme.colorScheme.primary, shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_messageController.text.isNotEmpty ? Icons.send : (_isRecording ? Icons.mic : Icons.mic_none), color: Colors.white),
                    if (_isRecording) Text('${60 - _recordingDuration}s', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REPRODUCTOR CON CACHÉ LOCAL Y RESCATE ---

class VoiceNotePlayer extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const VoiceNotePlayer({super.key, required this.msg, required this.isMe});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isDownloading = false;
  bool _isMissing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
    _checkLocalFile();
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _checkLocalFile() async {
    final fileName = p.basename(widget.msg['audio_url']);
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'voice_notes', fileName);
    
    if (await File(path).exists()) {
      setState(() => _localPath = path);
    } else {
      _downloadFile(path);
    }
  }

  Future<void> _downloadFile(String targetPath) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(widget.msg['audio_url']));
      if (response.statusCode == 200) {
        final file = File(targetPath);
        final parentDir = file.parent;
        if (!await parentDir.exists()) await parentDir.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) setState(() { _localPath = targetPath; _isDownloading = false; _isMissing = false; });
      } else {
        throw 'File not on server';
      }
    } catch (e) {
      if (mounted) setState(() { _isDownloading = false; _isMissing = true; });
      // Si el audio no está, le pedimos al emisor que lo resuba
      if (!widget.isMe) _requestResubmit();
    }
  }

  Future<void> _requestResubmit() async {
    await Supabase.instance.client.from('messages').update({'needs_reupload': true}).eq('id', widget.msg['id']);
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else if (_localPath != null) {
      await _player.play(DeviceFileSource(_localPath!));
    } else if (_isMissing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El audio expiró. Pidiendo al emisor que lo resuba...')));
      _requestResubmit();
      return;
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) return const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isMissing ? Icons.refresh : (_isPlaying ? Icons.pause : Icons.play_arrow), color: widget.isMe ? Colors.white : Colors.blue),
          onPressed: _togglePlay,
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
            activeColor: widget.isMe ? Colors.white : Colors.blue,
            inactiveColor: widget.isMe ? Colors.white24 : Colors.grey[300],
            onChanged: (val) => _player.seek(Duration(seconds: val.toInt())),
          ),
        ),
      ],
    );
  }
}
