import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../settings.dart';

class ChatTraceLogger {
  ChatTraceLogger._();

  static bool enabled = true;

  static File? _file;
  static Future<void> _pendingWrite = Future<void>.value();
  static String? _activeSession;

  static Future<String?> resetSession(String sessionLabel) async {
    if (!enabled || !traceLoggingEnabled) {
      return null;
    }

    final file = await _ensureFile();
    final normalizedLabel = sessionLabel.trim().isEmpty
        ? 'unknown'
        : sessionLabel.trim();
    _activeSession = normalizedLabel;
    final header =
        '\n===== CHAT TRACE SESSION: $normalizedLabel @ ${DateTime.now().toIso8601String()} =====\n';
    await file.writeAsString(header, mode: FileMode.append, flush: true);
    debugPrint('[ChatTrace] file: ${file.path}');
    return file.path;
  }

  static Future<void> log(String scope, String message) async {
    if (!enabled || !traceLoggingEnabled) {
      return;
    }

    final file = await _ensureFile();
    final timestamp = DateTime.now().toIso8601String();
    final session = _activeSession == null ? '' : ' [$_activeSession]';
    final line = '$timestamp$session [$scope] $message\n';

    debugPrint('[ChatTrace] $scope $message');
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
    final file = File('${directory.path}/chat_trace.log');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    _file = file;
    return file;
  }
}
