import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/chat_conversation_details.dart';
import '../models/chat_conversations_response.dart';
import 'chat_cache_serializers.dart';

class ChatCacheStore {
  ChatCacheStore();

  Future<void> _pendingWrite = Future<void>.value();
  Directory? _cacheDirectory;

  Future<ChatConversationsResponse?> readConversations({
    required int userId,
  }) async {
    final json = await _readJson(_conversationsFileName(userId));
    if (json == null) {
      return null;
    }
    try {
      return ChatCacheSerializers.decodeConversationsResponse(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConversations({
    required int userId,
    required ChatConversationsResponse response,
  }) {
    return _writeJson(
      _conversationsFileName(userId),
      ChatCacheSerializers.encodeConversationsResponse(response),
    );
  }

  Future<ChatConversationDetailsModel?> readConversation({
    required int userId,
    required String cacheKey,
  }) async {
    final json = await _readJson(_conversationFileName(userId, cacheKey));
    if (json == null) {
      return null;
    }
    try {
      return ChatCacheSerializers.decodeConversationDetails(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConversation({
    required int userId,
    required String cacheKey,
    required ChatConversationDetailsModel details,
  }) {
    return _writeJson(
      _conversationFileName(userId, cacheKey),
      ChatCacheSerializers.encodeConversationDetails(details),
    );
  }

  Future<Map<String, dynamic>?> _readJson(String fileName) async {
    try {
      final file = await _resolveFile(fileName);
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJson(String fileName, Map<String, dynamic> payload) async {
    final normalizedPayload = <String, dynamic>{
      'cached_at': DateTime.now().toIso8601String(),
      ...payload,
    };
    _pendingWrite = _pendingWrite.then((_) async {
      final file = await _resolveFile(fileName);
      await file.writeAsString(jsonEncode(normalizedPayload), flush: true);
    });
    return _pendingWrite;
  }

  Future<File> _resolveFile(String fileName) async {
    final directory = await _resolveDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Directory> _resolveDirectory() async {
    final cached = _cacheDirectory;
    if (cached != null) {
      return cached;
    }
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/chat_cache');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cacheDirectory = directory;
    return directory;
  }

  String _conversationsFileName(int userId) {
    return 'chat_conversations_user_$userId.json';
  }

  String _conversationFileName(int userId, String cacheKey) {
    return 'chat_conversation_user_${userId}_${_sanitizeFileName(cacheKey)}.json';
  }

  String _sanitizeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_');
  }
}
