import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final String otherId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.otherId,
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
  String _webVoiceExt = 'webm';
  String _webVoiceContentType = 'audio/webm';
  List<double> _liveWave = List<double>.filled(84, 0.22);
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _waveFallbackTimer;
  DateTime _lastWaveUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final math.Random _waveRandom = math.Random();
  double _waveEma = 0.22;
  int _waveStillFrames = 0;
  double _wavePhase = 0;
  String? _draftAudioPath;
  Uint8List? _draftAudioBytes;
  int _draftDurationSeconds = 0;
  bool _isDraftPlaying = false;
  Duration _draftPos = Duration.zero;
  Duration _draftDur = Duration.zero;

  late final AudioPlayer _draftPlayer;

  bool _otherOnline = false;
  DateTime? _otherLastSeen;
  late StreamSubscription<List<Map<String, dynamic>>> _presenceSub;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _draftPlayer = AudioPlayer();
    _draftPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isDraftPlaying = false);
    });
    _draftPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _draftPos = p);
    });
    _draftPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _draftDur = d);
    });
    _ampSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((amp) {
      if (!mounted || !_isRecording) return;
      _pushWaveFromAmplitude(amp.current);
    }, onError: (_) {});
    _setupStream();
    _markAsRead();
    _cleanupExpiredVoiceFromStorage();
    if (!kIsWeb) {
      _setupPresence();
      _setMyPresence(true);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _presenceSub.cancel();
      _setMyPresence(false);
    }
    _audioRecorder.dispose();
    _ampSub?.cancel();
    _waveFallbackTimer?.cancel();
    _draftPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _setupStream() {
    final myId = supabase.auth.currentUser?.id ?? '';
    // Stream all messages where I'm involved, then filter to the specific chat
    _messagesStream = supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.where((m) =>
        (m['sender_id'] == myId && m['receiver_id'] == widget.otherId) ||
        (m['sender_id'] == widget.otherId && m['receiver_id'] == myId),
      ).toList());
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
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', widget.otherId)
          .eq('receiver_id', myId);
    } catch (_) {}
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
            'sender_id': supabase.auth.currentUser!.id,
            'receiver_id': widget.otherId,
            'type': 'image',
            'media_url': imageUrl,
            'content': '📷 Foto',
          });
          _scrollToBottom();
        }
      } catch (e) { dPrint('Error image: $e'); } finally { if (mounted) setState(() => _isUploading = false); }
    }
  }

  Future<void> _startRecording() async {
    if (_draftAudioPath != null) {
      await _discardDraftAudio();
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de micrófono denegado en el navegador')),
        );
      }
      return;
    }

    try {
      if (kIsWeb) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        var started = false;

        try {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.opus),
            path: 'voice_$ts.webm',
          );
          _webVoiceExt = 'webm';
          _webVoiceContentType = 'audio/webm';
          started = true;
        } catch (_) {}

        if (!started) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: 'voice_$ts.wav',
          );
          _webVoiceExt = 'wav';
          _webVoiceContentType = 'audio/wav';
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await _audioRecorder.start(const RecordConfig(), path: path);
      }

      _waveFallbackTimer?.cancel();
      _waveFallbackTimer = Timer.periodic(const Duration(milliseconds: 95), (_) {
        if (!mounted || !_isRecording) return;
        _wavePhase += 0.22;
        final elapsed = DateTime.now().difference(_lastWaveUpdate).inMilliseconds;
        if (elapsed > 280) {
          final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
          final pulse = (math.sin(t * 8).abs() * 0.24);
          final randomPart = _waveRandom.nextDouble() * 0.45;
          final pseudo = (0.18 + pulse + randomPart).clamp(0.16, 0.95);
          _appendWaveBar(pseudo);
        }
      });

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _isCancelling = false;
        _waveEma = 0.22;
        _waveStillFrames = 0;
        _wavePhase = 0;
        _liveWave = List<double>.filled(84, 0.22);
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordingDuration++));
    } catch (e) {
      _waveFallbackTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la grabación: $e')),
        );
      }
    }
  }

  Future<void> _stopRecordingToDraft() async {
    _waveFallbackTimer?.cancel();
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null && !_isCancelling) {
      try {
        Uint8List? bytes;
        if (kIsWeb) {
          // En web record devuelve una blob URL
          final resp = await http.get(Uri.parse(path));
          if (resp.statusCode == 200) bytes = resp.bodyBytes;
        }

        if (kIsWeb && (bytes == null || bytes.isEmpty)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo procesar el audio grabado')),
            );
          }
        } else {
          setState(() {
            _draftAudioPath = path;
            _draftAudioBytes = bytes;
            _draftDurationSeconds = _recordingDuration;
            _draftPos = Duration.zero;
            _draftDur = Duration(seconds: _recordingDuration);
            _isDraftPlaying = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error preparando audio: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendDraftAudio() async {
    final draftPath = _draftAudioPath;
    if (draftPath == null) return;

    setState(() => _isUploading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      Uint8List? bytes = _draftAudioBytes;

      if (bytes == null || bytes.isEmpty) {
        if (kIsWeb) {
          final resp = await http.get(Uri.parse(draftPath));
          if (resp.statusCode == 200) bytes = resp.bodyBytes;
        } else {
          bytes = await File(draftPath).readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo procesar el audio para enviar')),
          );
        }
        return;
      }

      final upload = await MediaManager.uploadVoiceToSupabase(
        bytes: bytes,
        userId: myId,
        preferredExt: kIsWeb ? _webVoiceExt : null,
        preferredContentType: kIsWeb ? _webVoiceContentType : null,
      );

      if (upload == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo subir el audio')),
          );
        }
        return;
      }

      final inserted = await supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': widget.otherId,
        'type': 'voice',
        'media_url': upload['url'],
        'content': 'storage:${upload['path']}',
      }).select('id').single();

      if (!kIsWeb) {
        final msgId = inserted['id'].toString();
        await MediaManager.registerLocalMedia(msgId, draftPath, 'voice');
      }

      await _discardDraftAudio();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enviando audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _discardDraftAudio() async {
    if (_isDraftPlaying) {
      await _draftPlayer.stop();
    }
    if (!mounted) return;
    setState(() {
      _draftAudioPath = null;
      _draftAudioBytes = null;
      _draftDurationSeconds = 0;
      _isDraftPlaying = false;
      _draftPos = Duration.zero;
      _draftDur = Duration.zero;
    });
  }

  Future<void> _cancelRecording() async {
    _isCancelling = true;
    _waveFallbackTimer?.cancel();
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _isCancelling = false;
      _waveEma = 0.22;
      _waveStillFrames = 0;
      _wavePhase = 0;
      _liveWave = List<double>.filled(84, 0.22);
    });
  }

  void _appendWaveBar(double value) {
    _lastWaveUpdate = DateTime.now();
    setState(() {
      _wavePhase += 0.24;
      _liveWave.removeAt(0);
      _liveWave.add(value);
    });
  }

  void _pushWaveFromAmplitude(double rawDb) {
    final clamped = rawDb.clamp(-60.0, 0.0) as num;
    final normalized = ((clamped.toDouble() + 60.0) / 60.0).clamp(0.0, 1.0);
    var target = (0.16 + (normalized * 0.84)).clamp(0.16, 1.0);

    // Algunos navegadores web reportan amplitud casi constante; si eso pasa,
    // agregamos variación orgánica para evitar una "línea" plana.
    if ((target - _waveEma).abs() < 0.012) {
      _waveStillFrames++;
    } else {
      _waveStillFrames = 0;
    }

    if (_waveStillFrames > 4) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final pulse = 0.18 * math.sin(t * 10).abs();
      final jitter = (_waveRandom.nextDouble() * 0.22) - 0.05;
      target = (0.22 + pulse + jitter).clamp(0.16, 1.0);
    }

    _waveEma = (_waveEma * 0.58) + (target * 0.42);
    _appendWaveBar(_waveEma);
  }

  Widget _buildTelegramStyleWaveform(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, c) {
        const targetBars = 64;
        final maxBars = math.min(targetBars, _liveWave.length);
        final start = _liveWave.length - maxBars;
        final visible = _liveWave.sublist(start);

        return CustomPaint(
          painter: _TelegramWaveformPainter(
            samples: visible,
            phase: _wavePhase,
            color: theme.colorScheme.primary,
          ),
          size: Size(c.maxWidth, 30),
        );
      },
    );
  }

  Future<void> _toggleDraftAudioPlayback() async {
    final draftPath = _draftAudioPath;
    if (draftPath == null) return;

    if (_isDraftPlaying) {
      await _draftPlayer.pause();
      if (mounted) setState(() => _isDraftPlaying = false);
      return;
    }

    if (kIsWeb) {
      await _draftPlayer.play(UrlSource(draftPath));
    } else {
      await _draftPlayer.play(DeviceFileSource(draftPath));
    }
    if (mounted) setState(() => _isDraftPlaying = true);
  }

  String _formatRecordingTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _cleanupExpiredVoiceFromStorage() async {
    try {
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) return;
      final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String();
      final oldVoices = await supabase
          .from('messages')
          .select('id, content, created_at, media_url')
          .eq('sender_id', myId)
          .eq('type', 'voice')
          .lt('created_at', cutoff);

      for (final row in List<Map<String, dynamic>>.from(oldVoices)) {
        final content = row['content'] as String? ?? '';
        if (!content.startsWith('storage:')) continue;
        final objectPath = content.replaceFirst('storage:', '');
        if (objectPath.isEmpty) continue;

        try {
          await supabase.storage.from(MediaManager.voiceBucket).remove([objectPath]);
        } catch (_) {}

        try {
          await supabase.from('messages').update({'media_url': null}).eq('id', row['id']);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await supabase.from('messages').insert({
      'sender_id': supabase.auth.currentUser!.id,
      'receiver_id': widget.otherId,
      'content': content,
      'type': 'text'
    });
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
            CircleAvatar(radius: 18, backgroundImage: widget.otherUser['avatar_url'] != null ? NetworkImage(webSafeUrl(widget.otherUser['avatar_url'] as String)) : null),
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
              VoiceNotePlayer(
                messageId: msg['id'].toString(),
                url: (msg['media_url'] ?? '').toString(),
                isMe: isMe,
              )
            else if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _showFullScreen(msg['media_url']),
                  child: Image.network(webSafeUrl(msg['media_url'] as String)),
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: Center(child: InteractiveViewer(child: Image.network(webSafeUrl(url)))))));
  }

  Widget _buildInput(ThemeData theme) {
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
              Expanded(
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                          const SizedBox(width: 6),
                          Text('Grabando...', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          const Spacer(),
                          Text(_formatRecordingTime(_recordingDuration), style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildTelegramStyleWaveform(theme),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _stopRecordingToDraft,
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.stop, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_draftAudioPath != null) {
      final progress = _draftDur.inMilliseconds > 0
          ? (_draftPos.inMilliseconds / _draftDur.inMilliseconds).clamp(0, 1)
          : 0.0;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: _discardDraftAudio,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
              Expanded(
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.45)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _toggleDraftAudioPlayback,
                        icon: Icon(_isDraftPlaying ? Icons.pause_circle : Icons.play_circle, color: theme.colorScheme.primary),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Audio listo • ${_formatRecordingTime(_draftDurationSeconds)}', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress.toDouble(),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(999),
                              backgroundColor: theme.dividerColor.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _sendDraftAudio,
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
              onPressed: _pickAndSendImage,
            ),
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
            if (_messageController.text.isNotEmpty)
              IconButton(icon: Icon(Icons.send, color: theme.colorScheme.primary), onPressed: _sendMessage)
            else
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _startRecording,
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TelegramWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double phase;
  final Color color;

  const _TelegramWaveformPainter({
    required this.samples,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final baseLine = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), baseLine);

    if (samples.isEmpty) return;

    final spacing = size.width / samples.length;
    final barWidth = math.max(1.6, spacing * 0.34);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i].clamp(0.12, 1.0);
      final waveMotion = 0.72 + (0.28 * math.sin(phase + i * 0.42).abs());
      final emphasis = 0.78 + (0.22 * math.sin((i / samples.length) * math.pi));
      final amplitude = (sample * waveMotion * emphasis).clamp(0.14, 1.0);
      final halfHeight = (3 + amplitude * (size.height * 0.48)).clamp(3.0, size.height / 2);
      final x = (i * spacing) + (spacing / 2);

      paint
        ..strokeWidth = barWidth
        ..color = color.withOpacity((0.42 + (i / samples.length) * 0.58).clamp(0.42, 1.0));

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TelegramWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
  }
}

class VoiceNotePlayer extends StatefulWidget {
  final String messageId;
  final String url;
  final bool isMe;
  const VoiceNotePlayer({
    super.key,
    required this.messageId,
    required this.url,
    required this.isMe,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPositionChanged.listen((p) => setState(() => _pos = p));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
    _prepareLocalAudio();
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _prepareLocalAudio() async {
    if (kIsWeb) return;
    final cached = await MediaManager.getLocalPath(widget.messageId);
    if (cached != null) {
      if (mounted) setState(() => _localPath = cached);
      return;
    }
    final downloaded = await MediaManager.downloadAndCache(widget.messageId, widget.url, 'voice');
    if (downloaded != null && mounted) {
      setState(() => _localPath = downloaded);
    }
  }

  void _play() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (!kIsWeb && _localPath != null) {
        await _player.play(DeviceFileSource(_localPath!));
      } else if (widget.url.isNotEmpty) {
        await _player.play(UrlSource(widget.url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio no disponible en servidor y sin copia local')),
          );
        }
        return;
      }
    }
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
