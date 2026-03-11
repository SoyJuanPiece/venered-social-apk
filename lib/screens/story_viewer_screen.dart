import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/media_manager.dart';
import '../utils.dart';

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
  String? _displayPath;
  bool _isLocal = false;
  int _viewCount = 0;
  bool _isUploadingNew = false;
  
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
    final mediaUrl = story['media_url'];
    final mediaType = (story['media_type'] ?? story['type'] ?? 'photo').toString();
    final myId = Supabase.instance.client.auth.currentUser?.id;

    try {
      if (myId != null && story['user_id'] != myId) {
        Supabase.instance.client.from('story_views').upsert({
          'story_id': storyId,
          'viewer_id': myId,
        }).then((_) {}).catchError((_) {});
      }

      if (myId != null && story['user_id'] == myId) {
        final viewsRes = await Supabase.instance.client.from('story_views').select('id').eq('story_id', storyId);
        if (mounted) setState(() => _viewCount = viewsRes.length);
      }

      String? localPath = await MediaManager.getLocalPath(storyId);
      
      if (localPath != null && await File(localPath).exists()) {
        _displayPath = localPath;
        _isLocal = true;
      } else if (mediaUrl != null && mediaUrl.toString().isNotEmpty) {
        _displayPath = mediaUrl.toString();
        _isLocal = false;
      } else if (fileId != null && fileId.toString().isNotEmpty) {
        final serverUrl = MediaManager.telegramServerUrl.replaceAll('/upload', '/api/url/$fileId');
        final response = await http.get(Uri.parse(serverUrl));

        if (response.statusCode == 200) {
          final url = json.decode(response.body)['url'];
          localPath = await MediaManager.downloadAndCache(storyId, url, mediaType == 'image' ? 'photo' : mediaType);
          _displayPath = localPath ?? url;
          _isLocal = localPath != null;
        }
      } else {
        throw 'Historia sin archivo asociado';
      }

      if (mediaType == 'video') {
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

  void _showStoryOptions(String storyId) {
    _progressController.stop();
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF171717),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white),
              title: const Text('Añadir más a tu historia', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _addNewStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar esta historia', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteStory(storyId);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).then((_) {
      if (!_isLoading && !_isUploadingNew) {
        _progressController.forward();
        _videoController?.play();
      }
    });
  }

  Future<void> _addNewStory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Color(0xFF171717), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nueva Historia', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.videocam, color: Colors.white)),
                title: const Text('Video', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.photo, color: Colors.white)),
                title: const Text('Foto', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final file = (source == 'video') ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploadingNew = true);
      try {
        final result = await MediaManager.uploadToTelegram(File(file.path), isStory: true);
        if (result != null) {
          final fileId = result['file_id'] ?? result['result']?['video']?['file_id'];
          final mediaUrl = result['url'] ?? result['media_url'];
          final mediaType = (source == 'video') ? 'video' : 'photo';
          Map<String, dynamic>? res;

          if (fileId != null) {
            try {
              res = await Supabase.instance.client.from('stories').insert({
                'user_id': user.id,
                'file_id': fileId,
                'media_type': mediaType,
              }).select().single();
            } catch (_) {}
          }

          if (res == null && mediaUrl != null) {
            res = await Supabase.instance.client.from('stories').insert({
              'user_id': user.id,
              'media_url': mediaUrl,
              'type': mediaType,
            }).select().single();
          }

          if (res == null) {
            throw 'No se pudo guardar la historia.';
          }

          await MediaManager.registerLocalMedia(res['id'].toString(), file.path, (source == 'video') ? 'video' : 'photo');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Historia añadida!')));
            Navigator.pop(context); // Cerrar visor para refrescar
          }
        }
      } catch (_) {} finally { if (mounted) setState(() => _isUploadingNew = false); }
    }
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text('¿Borrar historia?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
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
              child: _isLoading || _isUploadingNew
                  ? const CircularProgressIndicator(color: Colors.white)
                  : (story['media_type'] == 'video'
                      ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                      : (_isLocal 
                          ? Image.file(File(_displayPath!), fit: BoxFit.contain)
                          : Image.network(webSafeUrl(_displayPath!), fit: BoxFit.contain))),
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
                      CircleAvatar(radius: 18, backgroundImage: story['profile_pic_url'] != null ? NetworkImage(webSafeUrl(story['profile_pic_url'] as String)) : null, child: story['profile_pic_url'] == null ? const Icon(Icons.person) : null),
                      const SizedBox(width: 10),
                      Text(isMe ? 'Tu historia' : (story['username'] ?? 'Usuario'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isMe) 
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white), 
                          onPressed: () => _showStoryOptions(story['id'].toString())
                        ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),

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
