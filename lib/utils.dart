import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A debug-only print helper. Any call to [dPrint] will be stripped out of
/// release binaries by the Dart compiler thanks to the `assert` guard.
void dPrint(Object? object) {
  assert(() {
    debugPrint(object?.toString());
    return true;
  }());
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
