import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../services/openai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../../App_Settings.dart';
import '../../../services/ai_comment_service.dart';

/// Provider لإدارة حالة الشات مع الذكاء الاصطناعي
class AIChatProvider extends ChangeNotifier {
  final OpenAIService _openAIService = OpenAIService();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isStreaming = false;
  String _currentStreamContent = '';

  // Getters
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStreaming => _isStreaming;
  String get currentStreamContent => _currentStreamContent;

  /// تهيئة الخدمة
  void initialize({String? apiKey}) {
    // استخدام API Key من الإعدادات إذا لم يتم تحديده
    final key = apiKey ?? AppSettings.aiApiKey;

    // التحقق من صحة الإعدادات
    final validation = AppSettings.validateAIConfig();
    if (validation != null) {
      _error = validation;
      notifyListeners();
      return;
    }

    _openAIService.initialize(key);
    _loadConversationHistory();
  }

  /// تحميل تاريخ المحادثة من التخزين المحلي
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationJson = prefs.getString('ai_chat_history');

      if (conversationJson != null) {
        final List<dynamic> decoded = json.decode(conversationJson);
        _messages = decoded.map((e) => ChatMessageModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
    }
  }

  /// حفظ تاريخ المحادثة في التخزين المحلي
  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationJson = json.encode(
        _messages.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('ai_chat_history', conversationJson);
    } catch (e) {
    }
  }

  /// إرسال رسالة
  Future<void> sendMessage(
    String content, {
    bool useStreaming = true,
    String? userId,
    String userType = 'free',
  }) async {
    if (content.trim().isEmpty) return;

    // التحقق من تفعيل AI
    if (!AppSettings.enableAI) {
      _error = 'ميزة الذكاء الاصطناعي معطلة';
      notifyListeners();
      return;
    }

    // التحقق من صلاحية المستخدم
    if (!AppSettings.canUserAccessAI(userType)) {
      _error =
          'هذه الميزة متاحة فقط لمستخدمي ${AppSettings.aiAccessLevel == 'pro' ? 'Pro' : 'VIP'}';
      notifyListeners();
      return;
    }

    // التحقق من عدد الأحرف
    if (content.trim().length > AppSettings.aiMaxCharactersPerRequest) {
      _error =
          'الرسالة طويلة جداً. الحد الأقصى ${AppSettings.aiMaxCharactersPerRequest} حرف';
      notifyListeners();
      return;
    }

    // التحقق من الحد اليومي واستهلاكه
    final allowed = await AICommentService.consumeQuota(
      userId,
      userType: userType,
    );
    if (!allowed) {
      _error = 'ai_bot_daily_limit'.tr;
      notifyListeners();
      return;
    }

    _error = null;

    // إضافة رسالة المستخدم
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    notifyListeners();

    // حفظ الرسالة
    await _saveConversationHistory();

    if (useStreaming) {
      await _sendMessageWithStreaming(content.trim());
    } else {
      await _sendMessageNormal(content.trim());
    }
  }

  /// إرسال رسالة عادية (بدون streaming)
  Future<void> _sendMessageNormal(String content) async {
    _isLoading = true;
    notifyListeners();

    try {
      // إضافة رسالة مؤقتة للتحميل
      final loadingMessage = ChatMessageModel(
        id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isLoading: true,
      );

      _messages.add(loadingMessage);
      notifyListeners();

      // إرسال الرسالة والحصول على الرد
      final history = _messages
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .toList();
      final cutoff = history.length >= 2 ? history.length - 2 : 0;

      final response = await _openAIService.sendMessage(
        message: content,
        conversationHistory: history.sublist(0, cutoff),
      );

      // استبدال رسالة التحميل بالرد
      _messages.removeLast();

      final assistantMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      _messages.add(assistantMessage);
      await _saveConversationHistory();
    } catch (e) {
      _error = e.toString();
      _messages.removeWhere((m) => m.isLoading);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إرسال رسالة مع streaming
  Future<void> _sendMessageWithStreaming(String content) async {
    _isStreaming = true;
    _currentStreamContent = '';

    // إضافة رسالة فارغة للـ streaming
    final streamMessage = ChatMessageModel(
      id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(streamMessage);
    notifyListeners();

    try {
      final history = _messages
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .toList();
      final cutoff = history.length >= 2 ? history.length - 2 : 0;

      final stream = _openAIService.sendMessageStream(
        message: content,
        conversationHistory: history.sublist(0, cutoff),
      );

      await for (final chunk in stream) {
        _currentStreamContent += chunk;

        // تحديث آخر رسالة
        _messages[_messages.length - 1] = ChatMessageModel(
          id: streamMessage.id,
          content: _currentStreamContent,
          role: MessageRole.assistant,
          timestamp: streamMessage.timestamp,
          isLoading: true,
        );
        notifyListeners();
      }

      // إنهاء الـ streaming
      _messages[_messages.length - 1] = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _currentStreamContent,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isLoading: false,
      );

      await _saveConversationHistory();
    } catch (e) {
      _error = e.toString();
      _messages.removeWhere((m) => m.id.startsWith('stream_'));
    } finally {
      _isStreaming = false;
      _currentStreamContent = '';
      notifyListeners();
    }
  }

  /// مسح المحادثة
  Future<void> clearConversation() async {
    _messages.clear();
    _error = null;
    await _saveConversationHistory();
    notifyListeners();
  }

  /// إضافة رسالة نظام (مثل: تم نشر المنشور)
  Future<void> addSystemMessage(String content, {int? postId}) async {
    final systemMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.system,
      timestamp: DateTime.now(),
      postId: postId,
    );

    _messages.add(systemMessage);
    await _saveConversationHistory();
    notifyListeners();
  }

  /// حذف رسالة معينة
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((m) => m.id == messageId);
    await _saveConversationHistory();
    notifyListeners();
  }

  /// إعادة إرسال آخر رسالة
  Future<void> regenerateLastResponse() async {
    if (_messages.isEmpty) return;

    // البحث عن آخر رسالة من المساعد
    final lastAssistantIndex = _messages.lastIndexWhere(
      (m) => m.role == MessageRole.assistant,
    );

    if (lastAssistantIndex == -1) return;

    // حذف الرد القديم
    _messages.removeAt(lastAssistantIndex);

    // البحث عن رسالة المستخدم المقابلة
    if (_messages.isEmpty) return;

    final lastUserMessage = _messages.last;
    if (lastUserMessage.role != MessageRole.user) return;

    // إعادة الإرسال
    final content = lastUserMessage.content;
    _messages.removeLast();
    notifyListeners();

    await sendMessage(content);
  }
}
