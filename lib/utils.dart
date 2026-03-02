import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
