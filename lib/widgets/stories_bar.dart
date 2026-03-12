import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/media_manager.dart';
import '../services/logger_service.dart';
import '../utils.dart';
import '../screens/story_viewer_screen.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  bool _isUploading = false;
  List<List<Map<String, dynamic>>> _groupedStories = [];
  bool _isLoading = true;
  Map<String, dynamic>? _storageStatus;
  String? _storiesError;

  static const List<int> _storyDurationOptions = [3600, 21600, 43200, 86400];

  @override
  void initState() {
    super.initState();
    _refreshStories();
    _refreshStorageStatus();
  }

  Future<void> _refreshStorageStatus() async {
    final status = await MediaManager.getBackendStorageStatus();
    if (mounted) {
      setState(() => _storageStatus = status);
    }
  }

  String _formatDurationOption(int seconds) {
    if (seconds % 3600 == 0) {
      final h = seconds ~/ 3600;
      return h == 24 ? '1 día' : '$h h';
    }
    final m = seconds ~/ 60;
    return '$m min';
  }

  List<List<Map<String, dynamic>>> _groupStories(List<Map<String, dynamic>> allStories) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var story in allStories) {
      final userId = story['user_id'];
      if (!groups.containsKey(userId)) groups[userId] = [];
      groups[userId]!.add(story);
    }
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final sortedGroups = groups.values.toList()..sort((a, b) {
      if (a.first['user_id'] == myId) return -1;
      if (b.first['user_id'] == myId) return 1;
      return DateTime.parse(b.first['created_at']).compareTo(DateTime.parse(a.first['created_at']));
    });
    return sortedGroups;
  }

  Future<void> _refreshStories() async {
    try {
      final response = await Supabase.instance.client.from('stories_with_profiles').select();
      if (mounted) {
        setState(() {
          _groupedStories = _groupStories(List<Map<String, dynamic>>.from(response));
          _isLoading = false;
          _storiesError = null;
        });
      }
    } catch (e, st) {
      LoggerService.log('StoriesBar _refreshStories error', e, st);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _storiesError = 'No se pudieron cargar las historias.';
        });
      }
    }
  }

  Future<void> _pickAndUploadStory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final isVideo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text('¿Qué quieres subir?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(context, Icons.photo, 'Foto', false),
                _buildOption(context, Icons.videocam, 'Video', true),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (isVideo == null) return;
    final picker = ImagePicker();
    final file = isVideo ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      await _showStoryComposer(file.path, isVideo);
    }
  }

  Future<void> _showStoryComposer(String filePath, bool isVideo) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    int selectedDuration = 86400;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Previsualizar historia', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: Colors.black,
                        height: 220,
                        width: double.infinity,
                        child: isVideo
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.videocam, color: Colors.white, size: 44),
                                    SizedBox(height: 10),
                                    Text('Vista previa de video', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              )
                            : Image.file(File(filePath), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Duración visible', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _storyDurationOptions.map((sec) {
                        final selected = selectedDuration == sec;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(_formatDurationOption(sec)),
                          onSelected: (_) => setSheetState(() => selectedDuration = sec),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Publicar historia'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);
    try {
      final upload = await MediaManager.uploadToTelegram(
        File(filePath),
        isStory: true,
        expiresInSec: selectedDuration,
        preferLocal: true,
      );
      String? fallbackImageUrl;
      if (upload == null && !isVideo) {
        fallbackImageUrl = await MediaManager.uploadToImgBB(File(filePath));
      }
      if (upload == null && fallbackImageUrl == null) {
        throw 'No se pudo subir la historia. Verifica conexión del backend.';
      }

      final String? fileId = upload?['file_id'] ?? upload?['result']?['video']?['file_id'];
      final String? mediaUrl = upload?['url'] ?? upload?['media_url'] ?? fallbackImageUrl;
      final mediaType = isVideo ? 'video' : 'photo';
      final expiresAt = DateTime.now().add(Duration(seconds: selectedDuration)).toIso8601String();

      bool inserted = false;

      if (fileId != null) {
        try {
          try {
            await Supabase.instance.client.from('stories').insert({
              'user_id': user.id,
              'file_id': fileId,
              'media_type': mediaType,
              'expires_at': expiresAt,
            });
          } catch (_) {
            await Supabase.instance.client.from('stories').insert({
              'user_id': user.id,
              'file_id': fileId,
              'media_type': mediaType,
            });
          }
          inserted = true;
        } catch (_) {}
      }

      if (!inserted && mediaUrl != null) {
        try {
          await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'media_url': mediaUrl,
            'type': mediaType,
            'expires_at': expiresAt,
          });
        } catch (_) {
          await Supabase.instance.client.from('stories').insert({
            'user_id': user.id,
            'media_url': mediaUrl,
            'type': mediaType,
          });
        }
        inserted = true;
      }

      if (!inserted) {
        throw 'No se pudo guardar la historia en la base de datos.';
      }

      await _refreshStories();
      await _refreshStorageStatus();
      if (mounted && fallbackImageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historia subida con modo alterno de imagen.')),
        );
      }
    } catch (e) {
      LoggerService.log('StoriesBar upload error', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, bool val) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, val),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF6366F1))),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool hasMyStory = _groupedStories.any((g) => g.first['user_id'] == currentUser?.id);

    final usagePct = (_storageStatus?['usagePct'] as num?)?.toDouble();
    final usedGb = (_storageStatus?['usedGb'] as num?)?.toDouble();
    final limitGb = (_storageStatus?['limitGb'] as num?)?.toDouble();
    final showStorageBanner = kDebugMode && usagePct != null && usedGb != null && limitGb != null;

    return Column(
      children: [
        if (showStorageBanner)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Storage historias backend: ${usedGb.toStringAsFixed(2)}GB / ${limitGb.toStringAsFixed(0)}GB', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (usagePct / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  color: usagePct >= 90 ? Colors.redAccent : const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        if (_storiesError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _storiesError!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        Container(
          height: 110,
          margin: const EdgeInsets.only(top: 4, bottom: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groupedStories.length + (hasMyStory ? 0 : 1),
            itemBuilder: (context, index) {
              if (!hasMyStory && index == 0) {
                return _buildStoryCircle(theme: theme, username: 'Tú', isMe: true, onTap: _pickAndUploadStory, isUploading: _isUploading);
              }
              final groupIndex = hasMyStory ? index : index - 1;
              final userStories = _groupedStories[groupIndex];
              final isMe = userStories.first['user_id'] == currentUser?.id;

              return _buildStoryCircle(
                theme: theme,
                username: isMe ? 'Tú' : (userStories.first['username'] ?? 'Usuario'),
                imageUrl: userStories.first['avatar_url'],
                isMe: isMe,
                hasActiveStory: true,
                isUploading: isMe ? _isUploading : false,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(stories: userStories, initialIndex: 0))),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCircle({required ThemeData theme, required String username, String? imageUrl, bool isMe = false, bool hasActiveStory = false, bool isUploading = false, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (hasActiveStory || isUploading) ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    border: (!hasActiveStory && !isUploading) ? Border.all(color: Colors.grey[300]!, width: 1) : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imageUrl != null ? NetworkImage(webSafeUrl(imageUrl)) : null,
                      child: isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))) 
                        : (imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null),
                    ),
                  ),
                ),
                if (isMe && !hasActiveStory && !isUploading)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(username, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
