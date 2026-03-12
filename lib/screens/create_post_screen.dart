import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:venered_social/services/media_manager.dart';
import 'package:venered_social/services/draft_manager.dart';
import '../utils.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  File? _mediaFile;
  XFile? _pickedMedia;
  Uint8List? _webPreviewBytes;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      DraftManager.savePostDraft(PostDraft(
        caption: _captionController.text,
        mediaPath: _mediaFile?.path,
        mediaType: ((_mediaFile != null || _pickedMedia != null) ? 'image' : 'text'),
      ));
    });
  }

  Future<void> _loadDraft() async {
    final draft = await DraftManager.loadPostDraft();
    if (draft != null && mounted) {
      setState(() {
        _captionController.text = draft.caption;
        if (draft.mediaPath != null && !kIsWeb) {
          _mediaFile = File(draft.mediaPath!);
        }
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedMedia = pickedFile;
          _webPreviewBytes = bytes;
          _mediaFile = null;
        });
        return;
      }

      setState(() {
        _mediaFile = File(pickedFile.path);
        _pickedMedia = pickedFile;
        _webPreviewBytes = null;
      });
    }
  }

  Future<void> _publishPost() async {
    final caption = _captionController.text.trim();
    if (_mediaFile == null && caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agrega una imagen o escribe algo')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw 'Debes iniciar sesión para publicar';
      final userId = currentUser.id;
      
      // Check rate limit (50 posts per day)
      final postsToday = await Supabase.instance.client
          .from('rate_limit_attempts')
          .select()
          .eq('user_id', userId)
          .eq('action', 'post')
          .gt('created_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String());
      
      if (postsToday.length >= 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Límite diario de publicaciones alcanzado.'))
          );
        }
        return;
      }
      
      // Log the attempt
      await Supabase.instance.client.from('rate_limit_attempts').insert({
        'user_id': userId,
        'action': 'post',
      });
      
      String? mediaUrl;

      if (kIsWeb && _pickedMedia != null) {
        setState(() => _uploadProgress = 0.3);
        final bytes = _webPreviewBytes ?? await _pickedMedia!.readAsBytes();
        mediaUrl = await MediaManager.uploadImageBytesToImgBB(bytes);
        setState(() => _uploadProgress = 0.8);
        if (mediaUrl == null) throw 'No se pudo subir la imagen desde Web';
      } else if (_mediaFile != null) {
        setState(() => _uploadProgress = 0.3);
        mediaUrl = await MediaManager.uploadToImgBB(_mediaFile!);
        setState(() => _uploadProgress = 0.8);
        if (mediaUrl == null) throw 'Error al subir el archivo';
      }
      
      setState(() => _uploadProgress = 0.9);
      
      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'content': caption,
        'media_url': mediaUrl,
        'type': ((_mediaFile != null || _pickedMedia != null) ? 'image' : 'text'),
      });
      
      // Clear draft after successful publish
      await DraftManager.deletePostDraft();
      
      if (mounted) {
        setState(() {
          _mediaFile = null;
          _pickedMedia = null;
          _webPreviewBytes = null;
          _captionController.clear();
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('¡Publicado con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 800;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('Nueva publicación',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: _publishPost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text('Publicar',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
            ),
          ],
          bottom: _uploadProgress > 0 ? PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: _uploadProgress),
          ) : null,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Media picker ────────────────────────────────────────
                  GestureDetector(
                    onTap: _showPickerOptions,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDark
                            ? const Color(0xFF141428)
                            : const Color(0xFFF0F4FF),
                        border: Border.all(
                          color: _mediaFile != null
                              ? Colors.transparent
                              : (isDark
                                  ? const Color(0xFF2A2A50)
                                  : const Color(0xFFD0D8F0)),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _mediaFile != null
                          ? Image.file(_mediaFile!,
                            fit: BoxFit.cover,
                            width: double.infinity)
                          : (_webPreviewBytes != null
                              ? Image.memory(_webPreviewBytes!, fit: BoxFit.cover, width: double.infinity)
                              : _mediaPlaceholder(isDark)),
                    ),
                  ),
                  if (_mediaFile != null || _webPreviewBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _mediaFile = null;
                              _pickedMedia = null;
                              _webPreviewBytes = null;
                            }),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text('Quitar',
                                style:
                                    GoogleFonts.poppins(fontSize: 13)),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent),
                          ),
                          TextButton.icon(
                            onPressed: _showPickerOptions,
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: Text('Cambiar',
                                style:
                                    GoogleFonts.poppins(fontSize: 13)),
                            style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // ── Caption ─────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0xFF141428)
                          : const Color(0xFFF0F4FF),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A2A50)
                            : const Color(0xFFD0D8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 6,
                      maxLength: 500,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '¿Qué quieres compartir?',
                        hintStyle: GoogleFonts.poppins(
                            color: isDark
                                ? Colors.grey[600]
                                : Colors.grey[500],
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(18),
                        counterStyle: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── Publish button (shown at bottom for mobile) ──────────
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _publishPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                      label: _isLoading
                          ? const SizedBox.shrink()
                          : Text('Compartir',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _mediaPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.1),
              Colors.transparent,
            ]),
          ),
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFF472B6)]).createShader(b),
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 52, color: Colors.white),
          ),
        ),
        const SizedBox(height: 14),
        Text('Toca para agregar una foto',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            )),
        const SizedBox(height: 6),
        Text('PNG, JPG',
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[400])),
      ],
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151525) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3), blurRadius: 20)
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Text('Seleccionar contenido',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                _pickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Foto de la galería',
                  subtitle: 'JPG, PNG',
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.08),
          ]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF818CF8), Color(0xFFF472B6)]).createShader(b),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
      title: Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.grey)),
    );
  }
}
