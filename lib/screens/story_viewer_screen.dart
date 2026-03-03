import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/media_manager.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _displayPath; // Puede ser URL o Path Local
  bool _isLocal = false;
  int _viewCount = 0;
  
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(vsync: this);
    
    _loadStory(_currentIndex);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  Future<void> _loadStory(int index) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _videoController?.dispose();
      _videoController = null;
      _viewCount = 0;
      _isLocal = false;
    });

    final story = widget.stories[index];
    final storyId = story['id'].toString();
    final fileId = story['file_id'];
    final myId = Supabase.instance.client.auth.currentUser?.id;

    try {
      // 1. Registrar vista (en segundo plano, no bloquea la carga)
      if (myId != null && story['user_id'] != myId) {
        Supabase.instance.client.from('story_views').upsert({
          'story_id': storyId,
          'viewer_id': myId,
        }).then((_) {}).catchError((_) {});
      }

      // 2. Conteo de vistas
      if (myId != null && story['user_id'] == myId) {
        final viewsRes = await Supabase.instance.client.from('story_views').select('id').eq('story_id', storyId);
        if (mounted) setState(() => _viewCount = viewsRes.length);
      }

      // 3. CACHE LOCAL: Revisar si ya lo tenemos descargado
      String? localPath = await MediaManager.getLocalPath(storyId);
      
      if (localPath != null && await File(localPath).exists()) {
        _displayPath = localPath;
        _isLocal = true;
      } else {
        // No está en cache, obtener URL fresca y descargar
        final serverUrl = MediaManager.telegramServerUrl.replaceAll('/upload', '/api/url/$fileId');
        final response = await http.get(Uri.parse(serverUrl));
        
        if (response.statusCode == 200) {
          final url = json.decode(response.body)['url'];
          // Descargar en segundo plano para la próxima vez
          localPath = await MediaManager.downloadAndCache(storyId, url, story['media_type']);
          _displayPath = localPath ?? url;
          _isLocal = localPath != null;
        }
      }

      // 4. Inicializar Reproductor
      if (story['media_type'] == 'video') {
        _videoController = _isLocal 
            ? VideoPlayerController.file(File(_displayPath!))
            : VideoPlayerController.networkUrl(Uri.parse(_displayPath!));
            
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _videoController!.play();
            _startProgress(duration: _videoController!.value.duration);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _startProgress(duration: const Duration(seconds: 5));
          });
        }
      }
    } catch (e) {
      print('Error historia: $e');
      _nextStory();
    }
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar historia?'),
        content: const Text('Se eliminará de los servidores y de Telegram.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('stories').delete().eq('id', storyId);
        if (mounted) Navigator.pop(context);
      } catch (_) {}
    }
  }

  void _startProgress({required Duration duration}) {
    _progressController.stop();
    _progressController.reset();
    _progressController.duration = duration;
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _loadStory(_currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _loadStory(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = story['user_id'] == myId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) { if (details.primaryVelocity! > 500) Navigator.pop(context); },
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) _previousStory();
          else if (details.globalPosition.dx > width * 2 / 3) _nextStory();
        },
        child: Stack(
          children: [
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : (story['media_type'] == 'video'
                      ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                      : (_isLocal 
                          ? Image.file(File(_displayPath!), fit: BoxFit.contain)
                          : Image.network(_displayPath!, fit: BoxFit.contain))),
            ),

            // Barras y Perfil
            Container(
              padding: const EdgeInsets.only(top: 50, left: 10, right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: widget.stories.asMap().entries.map((entry) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) => LinearProgressIndicator(
                              value: entry.key == _currentIndex ? _progressController.value : (entry.key < _currentIndex ? 1.0 : 0.0),
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundImage: story['profile_pic_url'] != null ? NetworkImage(story['profile_pic_url']) : null, child: story['profile_pic_url'] == null ? const Icon(Icons.person) : null),
                      const SizedBox(width: 10),
                      Text(isMe ? 'Tu historia' : (story['username'] ?? 'Usuario'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isMe) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: () => _deleteStory(story['id'].toString())),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: isMe ? _buildMyStoryFooter() : _buildViewerFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerFooter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white38)),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enviar mensaje...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
              onTap: () { _progressController.stop(); _videoController?.pause(); },
              onSubmitted: (val) { _progressController.forward(); _videoController?.play(); },
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28), onPressed: () {}),
        IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 28), onPressed: () {}),
      ],
    );
  }

  Widget _buildMyStoryFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility_outlined, color: Colors.white),
        const SizedBox(height: 4),
        Text('$_viewCount vistas', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
