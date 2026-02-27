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
