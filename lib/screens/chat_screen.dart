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

  static const String _imgbbApiKey = 'c4fd2ded598485660696ba819347f0bb'; 

  // States
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isCancelling = false;
  bool _isUploading = false;

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

  // --- LÓGICA DE MEDIOS ---

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, color: Colors.white)),
                title: const Text('Cámara'),
                onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.image, color: Colors.white)),
                title: const Text('Galería'),
                onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final compressedFile = await compressImage(File(pickedFile.path));
        final uploadFile = compressedFile ?? File(pickedFile.path);

        final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'))
          ..files.add(await http.MultipartFile.fromPath('image', uploadFile.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final imageUrl = json.decode(responseData)['data']['url'];
          final myId = supabase.auth.currentUser!.id;
          
          final res = await supabase.from('messages').insert({
            'conversation_id': widget.conversationId,
            'sender_id': myId,
            'type': 'image',
            'audio_url': imageUrl,
            'content': '📷 Foto',
          }).select().single();

          // Registrar en cache local
          await MediaManager.registerLocalMedia(res['id'].toString(), uploadFile.path, 'image');
          _updateConversation();
        }
      } catch (e) {
        dPrint('Error image: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // --- LÓGICA DE AUDIO ---

  void _resetRecordingState() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (mounted) setState(() { _isRecording = false; _recordingDuration = 0; _isCancelling = false; });
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final folder = Directory(p.join(directory.path, 'Venered', 'VoiceNotes'));
        if (!await folder.exists()) await folder.create(recursive: true);

        final path = p.join(folder.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc, 
          bitRate: 64000, 
          sampleRate: 44100, 
          numChannels: 1
        );

        await _audioRecorder.start(config, path: path);
        HapticFeedback.mediumImpact();

        _recordingDuration = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordingDuration++);
            if (_recordingDuration >= 60) _stopAndSendAudio();
          } else { timer.cancel(); }
        });
        setState(() { _isRecording = true; _isCancelling = false; });
      }
    } catch (_) { _resetRecordingState(); }
  }

  Future<void> _stopAndSendAudio() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      final wasCancelling = _isCancelling;
      _resetRecordingState();
      if (path != null && !wasCancelling) _uploadVoiceNote(path);
    } catch (_) { _resetRecordingState(); }
  }

  Future<void> _uploadVoiceNote(String localPath) async {
    setState(() => _isUploading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      final fileName = p.basename(localPath);
      final file = File(localPath);

      await supabase.storage.from('voice-notes').upload(fileName, file);
      final audioUrl = supabase.storage.from('voice-notes').getPublicUrl(fileName);

      final res = await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': myId,
        'type': 'voice',
        'audio_url': audioUrl,
        'content': '🎵 Nota de voz',
      }).select().single();

      // Registrar en cache permanente
      await MediaManager.registerLocalMedia(res['id'].toString(), localPath, 'voice');
      _updateConversation();
    } catch (_) {} finally { if (mounted) setState(() => _isUploading = false); }
  }

  // --- RESCATE ---
  void _setupReuploadListener() {
    final myId = supabase.auth.currentUser!.id;
    _reuploadListener = supabase.from('messages').stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> event) {
      final myRequests = event.where((msg) => msg['sender_id'] == myId && msg['type'] == 'voice' && msg['needs_reupload'] == true);
      for (var msg in myRequests) { _handleResubmitRequest(msg); }
    });
  }

  Future<void> _handleResubmitRequest(Map<String, dynamic> msg) async {
    try {
      final localPath = await MediaManager.getLocalPath(msg['id'].toString());
      if (localPath != null) {
        final file = File(localPath);
        final fileName = p.basename(msg['audio_url']);
        await supabase.storage.from('voice-notes').upload(fileName, file, fileOptions: const FileOptions(upsert: true));
        await supabase.from('messages').update({'needs_reupload': false}).eq('id', msg['id']);
      }
    } catch (_) {}
  }

  // --- GENERAL ---

  void _setupStream() {
    _messagesStream = supabase.from('messages').stream(primaryKey: ['id']).eq('conversation_id', widget.conversationId).order('created_at', ascending: true);
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
    try { await supabase.from('notifications').update({'is_read': true}).eq('receiver_id', myId).eq('sender_id', widget.otherUser['id']).eq('type', 'message'); } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    setState(() {}); // Actualizar icono de enviar/mic
    try {
      await supabase.from('messages').insert({'conversation_id': widget.conversationId, 'sender_id': supabase.auth.currentUser!.id, 'content': content, 'type': 'text'});
      _updateConversation();
    } catch (_) {}
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
              backgroundImage: widget.otherUser['profile_pic_url'] != null ? NetworkImage(widget.otherUser['profile_pic_url']) : null,
              child: widget.otherUser['profile_pic_url'] == null ? const Icon(Icons.person, size: 20) : null,
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
          if (_isUploading) const LinearProgressIndicator(),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    final type = msg['type'] ?? 'text';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 0), bottomRight: Radius.circular(isMe ? 0 : 20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'voice')
              VoiceNotePlayer(msg: msg, isMe: isMe)
            else if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: () => _showFullScreen(msg['audio_url']),
                  child: Image.network(msg['audio_url'], fit: BoxFit.cover),
                ),
              )
            else
              Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface)),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
              child: Text(formatHm(DateTime.parse(msg['created_at'])), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(String url) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, body: Center(child: InteractiveViewer(child: Image.network(url))))));
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
              onPressed: _showMediaOptions,
            ),
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
            _messageController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary, size: 28),
                    onPressed: _sendMessage,
                  )
                : GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressUp: _stopAndSendAudio,
                    onLongPressMoveUpdate: (details) {
                      if (details.localOffsetFromOrigin.dy < -50 || details.localOffsetFromOrigin.dx < -50) {
                        if (!_isCancelling) { setState(() => _isCancelling = true); HapticFeedback.lightImpact(); }
                      } else { if (_isCancelling) setState(() => _isCancelling = false); }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_isRecording ? 16 : 12),
                      decoration: BoxDecoration(
                        color: _isCancelling ? Colors.grey : (_isRecording ? Colors.red : theme.colorScheme.primary),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isCancelling ? Icons.delete_outline : (_isRecording ? Icons.mic : Icons.mic_none), color: Colors.white),
                          if (_isRecording)
                            Text(
                              '${60 - _recordingDuration}s',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
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
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() => _isPlaying = false); });
    _checkLocalFile();
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _checkLocalFile() async {
    final messageId = widget.msg['id'].toString();
    final path = await MediaManager.getLocalPath(messageId);
    
    if (path != null) {
      if (mounted) setState(() => _localPath = path);
    } else {
      _downloadFile();
    }
  }

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    if (mounted) setState(() => _isDownloading = true);
    
    final messageId = widget.msg['id'].toString();
    final url = widget.msg['audio_url'];
    
    final path = await MediaManager.downloadAndCache(messageId, url, 'voice');
    
    if (mounted) {
      setState(() {
        _isDownloading = false;
        if (path != null) {
          _localPath = path;
          _isMissing = false;
        } else {
          _isMissing = true;
          if (!widget.isMe) _requestResubmit();
        }
      });
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
      _downloadFile(); // Reintentar descarga
      return;
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) return const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    return Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(_isMissing ? Icons.refresh : (_isPlaying ? Icons.pause : Icons.play_arrow), color: widget.isMe ? Colors.white : Colors.blue), onPressed: _togglePlay), Expanded(child: Slider(value: _position.inSeconds.toDouble(), max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0, activeColor: widget.isMe ? Colors.white : Colors.blue, inactiveColor: widget.isMe ? Colors.white24 : Colors.grey[300], onChanged: (val) => _player.seek(Duration(seconds: val.toInt()))))]);
  }
}
