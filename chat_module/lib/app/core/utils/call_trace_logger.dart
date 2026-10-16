import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../settings.dart';

class CallTraceLogger {
  CallTraceLogger._();

  static bool enabled = true;

  static File? _file;
  static Future<void> _pendingWrite = Future<void>.value();

  static Future<String?> ensureReady() async {
    if (!enabled || !callLoggingEnabled) {
      return null;
    }

    final file = await _ensureFile();
    debugPrint('[CallTrace] file: ${file.path}');
    return file.path;
  }

  static Future<void> log(String scope, String message) async {
    if (!enabled || !callLoggingEnabled) {
      return;
    }

    final file = await _ensureFile();
    final timestamp = DateTime.now().toIso8601String();
    final line = '$timestamp [$scope] $message\n';

    debugPrint('[CallTrace] $scope $message');
    _pendingWrite = _pendingWrite.then((_) async {
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    });
    await _pendingWrite;
  }

  static Future<File> _ensureFile() async {
    final existing = _file;
    if (existing != null) {
      return existing;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/call_trace.log');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    _file = file;
    return file;
  }
}
