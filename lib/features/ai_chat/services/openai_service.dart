import 'package:dart_openai/dart_openai.dart';
import '../models/chat_message_model.dart';
import '../../../App_Settings.dart';

/// خدمة OpenAI للدردشة مع الذكاء الاصطناعي
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  bool _initialized = false;

  /// تهيئة الخدمة بـ API Key
  void initialize(String apiKey) {
    if (_initialized) return;

    OpenAI.apiKey = apiKey;
    _initialized = true;
  }

  /// التحقق من تهيئة الخدمة
  bool get isInitialized => _initialized;

  /// إرسال رسالة والحصول على رد من GPT
  Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> conversationHistory,
    String? model, // يُستخدم AppSettings.aiModel إذا كان null
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    // استخدام النموذج من الإعدادات إذا لم يتم تحديده
    final selectedModel = model ?? AppSettings.aiModel;
    if (!_initialized) {
      throw Exception(
        'OpenAI service is not initialized. Call initialize() first.',
      );
    }

    try {
      // تحويل تاريخ المحادثة إلى تنسيق OpenAI
      final List<OpenAIChatCompletionChoiceMessageModel> messages = [
        // رسالة النظام
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'أنت مساعد ذكي ومفيد. رد على الأسئلة بنفس لغة السؤال بطريقة واضحة ومختصرة.',
            ),
          ],
        ),
        // إضافة تاريخ المحادثة
        ...conversationHistory.map((msg) {
          return OpenAIChatCompletionChoiceMessageModel(
            role: msg.role == MessageRole.user
                ? OpenAIChatMessageRole.user
                : OpenAIChatMessageRole.assistant,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                msg.content,
              ),
            ],
          );
        }).toList(),
        // الرسالة الحالية
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
          ],
        ),
      ];

      // إرسال الطلب
      final completion = await OpenAI.instance.chat.create(
        model: selectedModel,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      // استخراج الرد
      final response =
          completion.choices.first.message.content?.first.text ?? '';

      if (response.isEmpty) {
        throw Exception('Received empty response from OpenAI');
      }

      return response;
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// إرسال رسالة مع stream للحصول على رد تدريجي
  Stream<String> sendMessageStream({
    required String message,
    required List<ChatMessageModel> conversationHistory,
    String? model, // يُستخدم AppSettings.aiModel إذا كان null
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async* {
    // استخدام النموذج من الإعدادات إذا لم يتم تحديده
    final selectedModel = model ?? AppSettings.aiModel;
    if (!_initialized) {
      throw Exception(
        'OpenAI service is not initialized. Call initialize() first.',
      );
    }

    try {
      // تحويل تاريخ المحادثة إلى تنسيق OpenAI
      final List<OpenAIChatCompletionChoiceMessageModel> messages = [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'أنت مساعد ذكي ومفيد. رد على الأسئلة بنفس لغة السؤال بطريقة واضحة ومختصرة.',
            ),
          ],
        ),
        ...conversationHistory.map((msg) {
          return OpenAIChatCompletionChoiceMessageModel(
            role: msg.role == MessageRole.user
                ? OpenAIChatMessageRole.user
                : OpenAIChatMessageRole.assistant,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                msg.content,
              ),
            ],
          );
        }).toList(),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
          ],
        ),
      ];

      // إرسال الطلب مع streaming
      final stream = OpenAI.instance.chat.createStream(
        model: selectedModel,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      await for (final event in stream) {
        final content = event.choices.first.delta.content?.first;
        if (content != null && content.text != null) {
          yield content.text!;
        }
      }
    } catch (e) {
      throw Exception('Failed to send message stream: ${e.toString()}');
    }
  }

  /// الحصول على قائمة النماذج المتاحة
  Future<List<String>> getAvailableModels() async {
    if (!_initialized) {
      throw Exception('OpenAI service is not initialized');
    }

    try {
      final models = await OpenAI.instance.model.list();
      return models.map((model) => model.id).toList();
    } catch (e) {
      throw Exception('Failed to fetch models: ${e.toString()}');
    }
  }
}
