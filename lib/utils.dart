import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// En web, redirige URLs de ImgBB y Telegram a través de un proxy CORS.
/// En otras plataformas devuelve la URL sin cambios.
String webSafeUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (!kIsWeb) return url;

  // Compatibilidad con URLs antiguas ya proxyeadas por wsrv.nl
  if (url.startsWith('https://wsrv.nl') || url.startsWith('http://wsrv.nl')) {
    final legacy = Uri.tryParse(url);
    final legacySource = legacy?.queryParameters['url'];
    if (legacySource != null && legacySource.isNotEmpty) {
      final decoded = Uri.decodeComponent(legacySource);
      final normalized = decoded.replaceFirst(RegExp(r'^https?://'), '');
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(normalized)}';
    }
  }

  if (url.startsWith('https://i.ibb.co') ||
      url.startsWith('http://i.ibb.co') ||
      url.startsWith('https://cdn.telegram.org') ||
      url.startsWith('https://api.telegram.org')) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) return url;
    final path = parsed.hasQuery ? '${parsed.path}?${parsed.query}' : parsed.path;
    final source = '${parsed.host}$path';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(source)}';
  }
  return url;
}

/// A debug-only print helper.
void dPrint(Object? object) {
  assert(() {
    debugPrint(object?.toString());
    return true;
  }());
}

/// COMPRESOR GLOBAL DE IMÁGENES
/// Reduce cualquier imagen a un máximo de 500KB manteniendo calidad profesional.
Future<File?> compressImage(File file) async {
  try {
    final directory = await getTemporaryDirectory();
    final targetPath = p.join(directory.path, "comp_${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // El punto dulce entre peso y nitidez
      minWidth: 1080,
      minHeight: 1080,
    );

    if (result == null) return file;
    return File(result.path);
  } catch (e) {
    dPrint('Error comprimiendo imagen: $e');
    return file; // Si falla, devolvemos la original para no bloquear al usuario
  }
}

const List<String> estadosVenezuela = [
  'Amazonas',
  'Anzoátegui',
  'Apure',
  'Aragua',
  'Barinas',
  'Bolívar',
  'Carabobo',
  'Cojedes',
  'Delta Amacuro',
  'Distrito Capital',
  'Falcón',
  'Guárico',
  'Lara',
  'Mérida',
  'Miranda',
  'Monagas',
  'Nueva Esparta',
  'Portuguesa',
  'Sucre',
  'Táchira',
  'Trujillo',
  'Vargas',
  'Yaracuy',
  'Zulia',
];
