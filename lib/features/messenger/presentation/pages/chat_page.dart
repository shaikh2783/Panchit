import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/services/messenger_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../services/global_call_service.dart';
import 'outgoing_call_screen.dart';
import 'all_media_page.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final UserPreview otherUser;

  const ChatPage({
    required this.conversationId,
    required this.otherUser,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // App-session cache of deleted message IDs, keyed by conversationId.
  static final Map<String, Set<int>> _deletedMsgCache = {};

  Set<int> get _deletedIds =>
      _deletedMsgCache.putIfAbsent(widget.conversationId, () => {});

  final _scrollController = ScrollController();
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0; // رقم الصفحة (0, 1, 2, 3...)
  List<MessageModel> _messages = [];
  final bool _isTyping = false; // سيتم ربطها لاحقاً بـ Socket
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  late MessengerApiService _apiService;
  late PostsApiService _postsService;
  late String _currentUserId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _apiService = MessengerApiService(context.read<ApiClient>());
    _postsService = PostsApiService(context.read<ApiClient>());

    // الحصول على user ID الحقيقي من AuthNotifier
    final authNotifier = context.read<AuthNotifier>();
    final userId = authNotifier.currentUser?['user_id'];
    _currentUserId = userId?.toString() ?? '0';

    _loadMessages();
    _scrollController.addListener(_onScroll);
    _startPolling(); // بدء polling للرسائل الجديدة
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // جلب المزيد عند الوصول للأعلى (لأن reverse: true)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final result = await _apiService.getMessages(
        conversationId: widget.conversationId,
        currentUserId: _currentUserId,
        offset: _page,
      );

      final messages = result['messages'] as List<dynamic>? ?? [];
      final hasMore = result['has_more'] as bool? ?? false;


      if (messages.isNotEmpty && messages.first is MessageModel) {
        final msgList = messages.cast<MessageModel>();
        if (_messages.isNotEmpty) {
        }

        setState(() {
          _hasMore = hasMore;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _startPolling() {
    // جلب الرسائل الجديدة كل 3 ثوانٍ
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkNewMessages();
    });
  }

  Future<void> _checkNewMessages() async {
    if (_messages.isEmpty) return;

    try {
      // استخدام last_message_id لجلب الرسائل الأحدث فقط
      final lastMessageId = _messages.first.messageId;

      final result = await _apiService.getMessages(
        conversationId: widget.conversationId,
        currentUserId: _currentUserId,
        offset: 0,
        lastMessageId: lastMessageId,
      );

      final messages = result['messages'] as List<dynamic>? ?? [];

      if (messages.isNotEmpty && messages.first is MessageModel) {
        final newMessages = List<MessageModel>.from(messages.reversed)
            .where((m) => !_deletedIds.contains(m.messageId))
            .toList();

        if (newMessages.isNotEmpty) {
          setState(() {
            // إضافة الرسائل الجديدة في البداية (لأن reverse: true)
            _messages.insertAll(0, newMessages);
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getMessages(
        conversationId: widget.conversationId,
        currentUserId: _currentUserId,
        offset: 0,
      );


      final hasMore = result['has_more'] as bool? ?? false;

      setState(() {
        // النتيجة تحتوي على 'messages' key فيه list من MessageModel
        final messages = result['messages'] as List<dynamic>? ?? [];

        if (messages.isNotEmpty) {
          if (messages.first is MessageModel) {
            // عكس الترتيب: الرسائل الأحدث أولاً (لتظهر في الأسفل مع reverse: true)
            _messages = List<MessageModel>.from(messages.reversed)
                .where((m) => !_deletedIds.contains(m.messageId))
                .toList();
            _page = 1; // الصفحة التالية ستكون 1
            _hasMore = hasMore;
          } else {
            // _messages = _getDummyMessages();
          }
        } else {
          // _messages = _getDummyMessages();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // _messages = _getDummyMessages();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch;
    // _pendingTextByTempId[tempId] = text.trim();

    final newMessage = MessageModel(
      messageId: tempId,
      conversationId: int.tryParse(widget.conversationId) ?? 0,
      userId: int.tryParse(_currentUserId) ?? 1,
      messageText: text,
      sentAt: DateTime.now(),
      isMe: true,
      isSeen: false,
      username: '',
      firstName: '',
      lastName: '',
    );

    setState(() {
      _messages.insert(0, newMessage); // الإضافة في البداية بسبب reverse: true
      _messageController.clear();
    });

    try {
      final sentMessage = await _apiService.sendMessage(
        conversationId: widget.conversationId,
        messageText: text,
        currentUserId: _currentUserId,
        otherUser: widget.otherUser.userId
      );

      // تحقق من البيانات المستلمة

      if (sentMessage?.userId.toString() != _currentUserId) {
      }
      if (sentMessage?.sentAt == null) {
      }


      // استبدال الرسالة المؤقتة بالرسالة الحقيقية من السيرفر
      // إجبار isMe: true لأن الرسالة مرسلة من المستخدم الحالي
      if (sentMessage != null) {
        final correctedMessage = sentMessage.copyWith(isMe: true);
        setState(() {
          final index = _messages.indexWhere((m) => m.messageId == tempId);
          if (index != -1) {
            _messages[index] = correctedMessage;
          }
        });
      }


    } catch (e) {
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // إظهار رسالة تحميل
      Get.snackbar(
        'uploading_image'.tr,
        'please_wait'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
        showProgressIndicator: true,
      );

      // الخطوة 1: رفع الصورة أولاً
      final uploadResult = await _postsService.uploadFile(
        File(pickedFile.path),
        type: FileUploadType.photo,
        onProgress: (sent, total) {
        },
      );

      if (uploadResult == null) {
        Get.snackbar(
          'error'.tr,
          'failed_to_upload_image'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }


      // الخطوة 2: إرسال رابط الصورة في الرسالة
      final sentMessage = await _apiService.sendImage(
        conversationId: widget.conversationId,
        imageSource: uploadResult.source, // الرابط النسبي من السيرفر
        currentUserId: _currentUserId,
      );

      Get.closeAllSnackbars();

      if (sentMessage != null) {
        final corrected = sentMessage.copyWith(isMe: true);

        setState(() {
          _messages.removeWhere((m) => m.messageId == corrected.messageId);
          _messages.insert(0, corrected);
        });

        Get.snackbar(
          'success'.tr,
          'image_sent_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_send_image'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.closeAllSnackbars();
      Get.snackbar(
        'error'.tr,
        'failed_to_send_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        _recordingPath =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordingPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        // عداد الوقت
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingDuration++);
        });

        Get.snackbar(
          'recording'.tr,
          'tap_to_stop'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'permission_required'.tr,
          'microphone_permission_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_start_recording'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      if (!_isRecording) return;

      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      setState(() => _isRecording = false);

      if (path == null || !File(path).existsSync()) {
        Get.snackbar(
          'error'.tr,
          'recording_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // إظهار رسالة رفع
      Get.snackbar(
        'uploading_voice'.tr,
        'please_wait'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
        showProgressIndicator: true,
      );

      // رفع الملف الصوتي
      final uploadResult = await _postsService.uploadFile(
        File(path),
        type: FileUploadType.audio,
        onProgress: (sent, total) {
        },
      );

      if (uploadResult == null) {
        Get.snackbar(
          'error'.tr,
          'failed_to_upload_voice'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }


      // إرسال الرسالة الصوتية
      final sentMessage = await _apiService.sendVoiceNote(
        conversationId: widget.conversationId,
        voiceSource: uploadResult.source,
        currentUserId: _currentUserId,
      );

      Get.closeAllSnackbars();

      if (sentMessage != null) {
        final corrected = sentMessage.copyWith(isMe: true);

        setState(() {
          _messages.removeWhere((m) => m.messageId == corrected.messageId);
          _messages.insert(0, corrected);
        });

        Get.snackbar(
          'success'.tr,
          'voice_sent_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_send_voice'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      // حذف الملف المؤقت
      try {
        await File(path).delete();
      } catch (e) {
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _recordingTimer?.cancel();
      Get.closeAllSnackbars();
      Get.snackbar(
        'error'.tr,
        'failed_to_send_voice'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleVoiceButtonPress() {
    if (_isRecording) {
      _stopAndSendRecording();
    } else {
      _startRecording();
    }
  }

  void _openConversationInfo() {
    Get.to(
      () => AllMediaPage(
        currentUserId: _currentUserId,
        conversationId: widget.conversationId,
      ),
    );
  }

  // === Call Methods ===

  Future<void> _startVideoCall() async {
    await _startCall('video');
  }

  Future<void> _startAudioCall() async {
    await _startCall('audio');
  }

  Future<void> _startCall(String callType) async {
    try {
      // Show loading
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 15),
                Text(
                  callType == 'video'
                      ? 'starting_video_call'.tr
                      : 'starting_audio_call'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get global call service
      final globalCallService = Get.find<GlobalCallService>();

      // Start the call
      await globalCallService.callManager.startCall(
        toUserId: widget.otherUser.userId,
        callType: callType,
      );

      Get.back(); // Close loading dialog

      if (!mounted) return;

      // Navigate to outgoing call screen (waiting for answer)
      Get.to(
        () => OutgoingCallScreen(
          callData: globalCallService.callManager.currentCall!,
          callManager: globalCallService.callManager,
          otherUser: widget.otherUser,
        ),
      );
    } catch (e) {
      Get.back(); // Close loading dialog

      String errorMessage = 'call_start_failed'.tr;

      // Parse error message
      final errorStr = e.toString();
      if (errorStr.contains('busy') || errorStr.contains('مشغول')) {
        errorMessage = 'user_busy_now'.tr;
      } else if (errorStr.contains('إرسال طلب صداقة') ||
          errorStr.contains('friend request')) {
        errorMessage = 'must_be_friends_to_call'.tr;
      } else if (errorStr.contains('not found')) {
        errorMessage = 'user_not_found'.tr;
      } else if (errorStr.contains('permission')) {
        errorMessage = callType == 'video'
            ? 'allow_microphone_camera'.tr
            : 'allow_microphone_only'.tr;
      } else if (errorStr.contains('offline')) {
        errorMessage = 'user_offline'.tr;
      }

      Get.snackbar(
        'cannot_start_call'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, theme, isDark),
        body: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                  : _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true, // مهم جداً: الرسائل تبدأ من الأسفل
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // مؤشر التحميل في الأعلى (آخر عنصر بسبب reverse)
                        if (index == _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final message = _messages[index];
                        return MessageBubble(
                          message: message,
                          showTimestamp: _shouldShowTimestamp(index),
                          onDelete: () => _deleteMessage(message),
                        );
                      },
                    ),
            ),
            // حقل الإدخال بتصميم عائم
            _buildInputArea(theme, isDark),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final ok = await _apiService.deleteMessage(
      messageId: message.messageId,
    );

    if (ok) {
      _deletedIds.add(message.messageId);
      setState(() {
        _messages.removeWhere(
          (m) => m.messageId == message.messageId,
        );
      });
    } else {
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_conversation'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      leadingWidth: 40,
      titleSpacing: 8,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left_2,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => Get.back(),
      ),
      title: InkWell(
        onTap: _openConversationInfo, // فتح الملف الشخصي
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  // Text(
                  //   _isTyping ? 'typing'.tr : 'online'.tr,
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: _isTyping ? Colors.green : Colors.grey,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.video, size: 22),
          onPressed: () => _startVideoCall(),
        ),
        IconButton(
          icon: const Icon(Iconsax.call, size: 22),
          onPressed: () => _startAudioCall(),
        ),
 
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: widget.otherUser.avatar != null
              ? CachedNetworkImageProvider(widget.otherUser.avatar!)
              : null,
          child: widget.otherUser.avatar == null
              ? Text(widget.otherUser.fullName[0].toUpperCase())
              : null,
        ),
        // if (!_isTyping) // حالة النشاط
          // Positioned(
          //   right: 0,
          //   bottom: 0,
          //   child: Container(
          //     width: 12,
          //     height: 12,
          //     decoration: BoxDecoration(
          //       color: Colors.green,
          //       shape: BoxShape.circle,
          //       border: Border.all(color: Colors.white, width: 2),
          //     ),
          //   ),
          // ),
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ChatInput(
        controller: _messageController,
        onSend: _sendMessage,
        onImageTap: _pickAndSendImage,
        onVoiceTap: _handleVoiceButtonPress,
        isRecording: _isRecording,
        recordingDuration: _recordingDuration,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message_2, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text('say_hello'.tr, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: const Icon(Iconsax.more, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: _confirmDeleteConversation,
          child: Row(
            children: [
              const Icon(Iconsax.trash, size: 20, color: Colors.red),
              const SizedBox(width: 10),
              Text('delete'.tr, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteConversation() async {
    await Future.delayed(Duration.zero); // wait for menu to close
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_conversation'.tr),
        content: Text('are_you_sure'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              Navigator.pop(ctx, true);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final ok = await _apiService.deleteConversation(
        conversationId: widget.conversationId,
      );

      Get.back(); // close loader

      if (ok) {
        Get.snackbar(
          'success'.tr,
          'conversation_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.back(result: true); // close chat page with success result
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_delete_conversation'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_conversation'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool _shouldShowTimestamp(int index) {
    if (index == _messages.length - 1) return true;
    final current = _messages[index].sentAt;
    final previous = _messages[index + 1].sentAt;
    return current.difference(previous).inMinutes.abs() > 15;
  }

  // List<MessageModel> _getDummyMessages() {
  //   return [
  //     MessageModel(
  //       messageId: 1,
  //       conversationId: 0,
  //       userId: widget.otherUser.userId,
  //       messageText: 'مرحباً! كيف حالك؟',
  //       sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
  //       isSeen: true,
  //       isMe: false,
  //       username: '',
  //       firstName: '',
  //       lastName: '',
  //     ),
  //     MessageModel(
  //       messageId: 2,
  //       conversationId: 0,
  //       userId: 1,
  //       messageText: 'أهلاً بك، أنا بخير والحمد لله',
  //       sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
  //       isSeen: true,
  //       isMe: true,
  //       username: '',
  //       firstName: '',
  //       lastName: '',
  //     ),
  //   ].reversed.toList();
  // }
}
