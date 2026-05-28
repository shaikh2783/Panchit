import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/config/app_config.dart' show appConfig;
import 'package:shared_preferences/shared_preferences.dart';
import '../App_Settings.dart';
import '../main.dart' show configCfgP;
import 'package:flutter/foundation.dart';

/// خدمة الرد التلقائي بالذكاء الاصطناعي على التعليقات
class AICommentService {
  static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';

  // تتبع الاستخدام اليومي لكل مستخدم (في الذاكرة خلال جلسة التشغيل)
  static final Map<String, _DailyUsage> _dailyUsage = {};
  static SharedPreferences? _prefs;
  static const String _usagePrefsKey = 'ai_daily_usage_v1';
  static bool _usageLoaded = false;

  /// بناء headers مع authentication (api-key, timestamp, signature)
  static Map<String, String> _buildAuthHeaders({
    bool includeAuthToken = false,
    String? authToken,
  }) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final hmac = Hmac(sha256, utf8.encode(appConfig.apiSecret));
    final signature = hmac.convert(utf8.encode(timestamp)).toString();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': appConfig.apiKey,
      'x-timestamp': timestamp,
      'x-signature': signature,
      if (includeAuthToken && authToken != null) 'x-auth-token': authToken,
    };
  }

  /// الحصول على توكن تسجيل الدخول للبوت
  static Future<String?> _getBotAuthToken() async {
    try {

      final authEndpoint = configCfgP('auth_signin');
      final url = appConfig.endpoint(authEndpoint);

      final requestBody = {
        'username_email': AppSettings.aiBotEmail,
        'password': AppSettings.aiBotPassword,
        'device_type': 'W',
      };

      final response = await http
          .post(
            url,
            headers: _buildAuthHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          final token = data['data']['token'] as String?;
          if (token != null) {
            final preview = token.length > 20 ? token.substring(0, 20) : token;
          }
          return token;
        } else {
        }
      } else {
      }
      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// التحقق من وجود منشن للبوت في النص
  /// @param text نص التعليق
  /// @return true إذا كان يحتوي على @botusername
  static bool containsBotMention(String text) {
    if (!AppSettings.enableAIAutoReply) return false;

    final botMention = '@${AppSettings.aiBotUsername.toLowerCase()}';
    return text.toLowerCase().contains(botMention);
  }

  /// استخراج السؤال من التعليق (إزالة المنشن)
  /// @param text نص التعليق الكامل
  /// @return النص بدون المنشن
  static String extractQuestion(String text) {
    return text
        .replaceAll(
          RegExp('@${AppSettings.aiBotUsername}', caseSensitive: false),
          '',
        )
        .trim();
  }

  /// طلب رد من الذكاء الاصطناعي
  /// @param question السؤال المطلوب الإجابة عليه
  /// @param context سياق إضافي (اختياري) مثل محتوى المنشور الأصلي
  /// @return الرد من AI أو رسالة خطأ
  static Future<String> getAIResponse({
    required String question,
    String? context,
  }) async {
    try {
      // التحقق من صحة الإعدادات
      final configError = AppSettings.validateAIConfig();
      if (configError != null) {
        return 'ai_bot_service_unavailable'.tr;
      }

      // التحقق من طول النص
      if (question.length > AppSettings.aiMaxCharactersPerRequest) {
        return 'ai_bot_question_too_long'.tr.replaceAll(
          '@max',
          '${AppSettings.aiMaxCharactersPerRequest}',
        );
      }

      if (question.trim().isEmpty) {
        return 'ai_bot_hello'.tr;
      }

      // بناء الرسائل للـ API
      final messages = <Map<String, String>>[];

      // رسالة النظام
      messages.add({
        'role': 'system',
        'content': '''أنت مساعد ذكي ومفيد على منصة تواصل اجتماعي.
- أجب بشكل موجز وواضح
- استخدم لغة ودية ومهذبة
- إذا سُئلت عن خبر أو معلومة، حاول التحقق منها وتقديم معلومات دقيقة
- إذا لم تكن متأكداً من معلومة، اذكر ذلك بوضوح
- لا تتجاوز 280 حرفاً في الرد''',
      });

      // إضافة السياق إن وُجد
      if (context != null && context.isNotEmpty) {
        messages.add({'role': 'system', 'content': 'سياق المنشور: $context'});
      }

      // السؤال من المستخدم
      messages.add({'role': 'user', 'content': question});

      // إرسال الطلب لـ OpenAI
      final response = await http
          .post(
            Uri.parse(_openAIUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppSettings.aiApiKey}',
            },
            body: jsonEncode({
              'model': AppSettings.aiModel,
              'messages': messages,
              'max_tokens': 150,
              'temperature': 0.7,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiReply = data['choices']?[0]?['message']?['content'] as String?;

        if (aiReply != null && aiReply.isNotEmpty) {
          return aiReply.trim();
        } else {
          return 'ai_bot_cannot_understand'.tr;
        }
      } else if (response.statusCode == 401) {
        return 'ai_bot_api_key_error'.tr;
      } else if (response.statusCode == 429) {
        return 'ai_bot_rate_limit'.tr;
      } else {
        return 'ai_bot_service_error'.tr;
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return 'ai_bot_no_internet'.tr;
      }
      return 'ai_bot_unexpected_error'.tr;
    }
  }

  /// إنشاء رد تلقائي على تعليق يحتوي منشن للبوت
  /// @param commentText نص التعليق الأصلي
  /// @param postContext سياق المنشور (اختياري)
  /// @return نص الرد من AI
  static Future<String> generateAutoReply({
    required String commentText,
    String? postContext,
    String? userId,
    String userType = 'free',
  }) async {
    // التحقق من الحصة اليومية (مع مفتاح احتياطي للضيوف)
    final userKey = _resolveUserKey(userId);
    final allowed = await _consumeQuota(userKey, userType: userType);
    if (!allowed) return 'ai_bot_daily_limit'.tr;

    // استخراج السؤال
    final question = extractQuestion(commentText);

    // الحصول على الرد من AI
    return await getAIResponse(question: question, context: postContext);
  }

  /// إنشاء رد باستخدام توكن البوت
  static Future<bool> createBotReply({
    required int commentId,
    required String replyText,
  }) async {
    try {
      // الحصول على التوكن
      final token = await _getBotAuthToken();
      if (token == null) {
        return false;
      }

      final commentEndpoint = configCfgP('comments_reply');
      final url = appConfig.endpoint(commentEndpoint);

      final requestBody = {
        'comment_id': commentId,
        'text': replyText,
        'image': '',
        'voice_note': '',
      };

      final response = await http
          .post(
            url,
            headers: _buildAuthHeaders(
              includeAuthToken: true,
              authToken: token,
            ),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return true;
        } else {
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من إمكانية المستخدم استخدام AI
  /// (يمكن توسيع هذه الدالة لاحقاً للتحقق من الحد اليومي)
  static Future<bool> canUserUseAI(
    String? userId, {
    String userType = 'free',
  }) async {
    final userKey = _resolveUserKey(userId);
    await _ensureUsageLoaded();
    return _canUseQuota(userKey, userType: userType);
  }

  /// محاولة استهلاك حصة اليوم الحالية. يعيد false إذا انتهت الحصة.
  static Future<bool> consumeQuota(
    String? userId, {
    String userType = 'free',
  }) {
    final userKey = _resolveUserKey(userId);
    return _consumeQuota(userKey, userType: userType);
  }

  static Future<void> _loadUsage() async {
    if (_usageLoaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_usagePrefsKey);
    if (raw == null || raw.isEmpty) {
      _usageLoaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _dailyUsage.clear();

        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final day = value['day'] as String?;
            final count = value['count'] as int?;
            if (day != null && count != null) {
              _dailyUsage[key] = _DailyUsage(day, count);
            }
          }
        });
      }
    } catch (_) {
      // تجاهل الأخطاء في القراءة
    }

    _usageLoaded = true;
  }

  static Future<void> _ensureUsageLoaded() async {
    if (_usageLoaded) return;
    await _loadUsage();
    _usageLoaded = true;
  }

  static Future<void> _persistUsage() async {
    _prefs ??= await SharedPreferences.getInstance();
    final map = <String, Map<String, dynamic>>{};
    _dailyUsage.forEach((key, usage) {
      map[key] = {'day': usage.dayKey, 'count': usage.count};
    });
    await _prefs!.setString(_usagePrefsKey, jsonEncode(map));
  }

  /// الحصول على معلومات حول البوت (للمساعدة)
  static String getBotInfo() {
    return '''
  ${'ai_bot_info_title'.tr.replaceAll('@username', AppSettings.aiBotUsername)}

  ${'ai_bot_info_can_help'.tr}
  ${'ai_bot_info_verify_news'.tr}
  ${'ai_bot_info_answer_questions'.tr}
  ${'ai_bot_info_provide_info'.tr}

  ${'ai_bot_info_usage'.tr}
  ${'ai_bot_info_example'.tr.replaceAll('@username', AppSettings.aiBotUsername)}
    '''
        .trim();
  }
}

class _DailyUsage {
  _DailyUsage(this.dayKey, this.count);
  String dayKey;
  int count;
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

String _resolveUserKey(String? userId) {
  if (userId != null && userId.isNotEmpty) return userId;
  return '_guest';
}

bool _canUseQuota(String userId, {required String userType}) {
  final limit = AppSettings.getMaxAIRequestsPerDay(userType);
  final dayKey = _todayKey();
  final usage = AICommentService._dailyUsage[userId];
  if (usage == null || usage.dayKey != dayKey) {
    return true;
  }
  return usage.count < limit;
}

Future<bool> _consumeQuota(String userId, {required String userType}) async {
  await AICommentService._ensureUsageLoaded();

  final limit = AppSettings.getMaxAIRequestsPerDay(userType);
  final dayKey = _todayKey();
  final usage = AICommentService._dailyUsage[userId];

  if (usage == null || usage.dayKey != dayKey) {
    AICommentService._dailyUsage[userId] = _DailyUsage(dayKey, 1);
    await AICommentService._persistUsage();
    return true;
  }

  if (usage.count >= limit) {
    return false;
  }

  usage.count += 1;
  await AICommentService._persistUsage();
  return true;
}