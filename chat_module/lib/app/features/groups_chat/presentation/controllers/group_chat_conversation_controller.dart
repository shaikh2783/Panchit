import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../../settings.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../data/api/api_exception.dart';
import '../../../chat/data/models/chat_reaction_types_response.dart';
import '../../data/models/groups_chat_models.dart';
import '../../data/services/groups_chat_service.dart';
import '../../utils/groups_chat_logger.dart';
import 'groups_chat_controller.dart';

const int _groupChatMessagesPageSize = 20;
const Set<String> _audioFileExtensions = <String>{
  'mp3',
  'm4a',
  'aac',
  'wav',
  'ogg',
  'oga',
  'flac',
  'opus',
  'amr',
  '3gp',
};

class GroupChatConversationController extends GetxController {
  GroupChatConversationController(
    this._groupsChatService,
    this._preferences,
    GroupsChatGroupModel initialGroup,
  ) : group = initialGroup.obs;

  final GroupsChatService _groupsChatService;
  final ChatAppPreferences _preferences;
  final Rx<GroupsChatGroupModel> group;
  final ImagePicker _imagePicker = ImagePicker();
  AudioRecorder? _audioRecorder;

  final inputController = TextEditingController();
  final scrollController = ScrollController();
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSending = false.obs;
  final isRecordingVoice = false.obs;
  final isGroupDeleted = false.obs;
  final errorMessage = ''.obs;
  final messages = <GroupsChatMessageModel>[].obs;
  final reactionTypes = <ChatReactionTypeModel>[].obs;
  final Set<int> _loadedMessageIds = <int>{};
  bool _hasMore = false;
  bool _isPolling = false;
  bool _initialScrollCompleted = false;
  int _lastEventCursor = 0;
  Timer? _pollingTimer;

  int get currentUserId => _preferences.getUserId() ?? 0;
  bool get canSendMessages => group.value.canSendMessages;
  bool get isCurrentUserMutedByAdmin => group.value.isCurrentMemberMutedByAdmin;
  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    GroupsChatLogger.log(
      'conversation_controller',
      'onInit groupId=${group.value.groupId} name="${group.value.name}" canSend=$canSendMessages',
    );
    unawaited(_loadReactionTypes());
    load();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    final recorder = _audioRecorder;
    if (recorder != null) {
      unawaited(recorder.dispose());
    }
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> load({bool reset = true}) async {
    GroupsChatLogger.log(
      'conversation_controller',
      'load reset=$reset groupId=${group.value.groupId}',
    );
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      isLoadingMore.value = false;
      errorMessage.value = '';
      messages.clear();
      _loadedMessageIds.clear();
      _hasMore = false;
      _initialScrollCompleted = false;
      _lastEventCursor = 0;
      return;
    }

    if (reset) {
      _initialScrollCompleted = false;
      isLoading.value = true;
      errorMessage.value = '';
      messages.clear();
      _loadedMessageIds.clear();
      _hasMore = false;
      _lastEventCursor = 0;
    } else {
      if (isLoading.value ||
          isLoadingMore.value ||
          !_hasMore ||
          messages.isEmpty) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final response = await _groupsChatService.fetchMessages(
        groupId: group.value.groupId,
        limit: _groupChatMessagesPageSize,
        beforeMessageId: reset ? null : messages.first.messageId,
      );
      _hasMore = response.hasMore;
      final freshItems = response.messages.where((message) {
        return _loadedMessageIds.add(message.messageId);
      }).toList();

      if (reset) {
        messages.assignAll(freshItems);
        _scrollToBottomSoon(reason: 'initial_load');
      } else if (freshItems.isNotEmpty) {
        final previousPixels = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final previousMaxExtent = scrollController.hasClients
            ? scrollController.position.maxScrollExtent
            : 0.0;
        messages.insertAll(0, freshItems);
        _restoreScrollOffsetAfterPrepend(
          previousPixels: previousPixels,
          previousMaxExtent: previousMaxExtent,
        );
      } else {
        _hasMore = false;
      }
      GroupsChatLogger.log(
        'conversation_controller',
        'load success reset=$reset fresh=${freshItems.length} total=${messages.length} hasMore=$_hasMore',
      );
      unawaited(_markLatestRead());
      if (reset) {
        _startPolling();
      }
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.load', error);
      if (reset) {
        errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
          error.toString(),
        );
      }
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() {
    if (isLoading.value ||
        isLoadingMore.value ||
        !_initialScrollCompleted ||
        !_hasMore ||
        messages.isEmpty) {
      return Future<void>.value();
    }
    return load(reset: false);
  }

  Future<void> sendTextMessage() async {
    final text = inputController.text.trim();
    GroupsChatLogger.log(
      'conversation_controller',
      'sendTextMessage groupId=${group.value.groupId} length=${text.length} canSend=$canSendMessages sending=${isSending.value}',
    );
    if (text.isEmpty || isSending.value || !canSendMessages) {
      return;
    }

    isSending.value = true;
    errorMessage.value = '';
    try {
      final sentMessage = await _groupsChatService.sendMessage(
        groupId: group.value.groupId,
        message: text,
      );
      inputController.clear();
      if (_loadedMessageIds.add(sentMessage.messageId)) {
        messages.add(sentMessage);
      }
      GroupsChatLogger.log(
        'conversation_controller',
        'sendTextMessage success messageId=${sentMessage.messageId} total=${messages.length}',
      );
      _scrollToBottomSoon();
      unawaited(_markLatestRead());
      if (Get.isRegistered<GroupsChatController>()) {
        unawaited(Get.find<GroupsChatController>().load());
      }
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.sendTextMessage', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendPhoto() async {
    _ensureCanSendMessage();
    if (isSending.value) {
      return;
    }

    await _ensureMediaPermission(forVideo: false);
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      final photoSource = await _groupsChatService.uploadPhoto(
        bytes: await pickedFile.readAsBytes(),
        filename: _filenameForPickedMedia(pickedFile, fallbackExtension: 'jpg'),
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        photo: photoSource,
      );
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.pickAndSendPhoto', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendVideo() async {
    _ensureCanSendMessage();
    if (isSending.value) {
      return;
    }

    await _ensureMediaPermission(forVideo: true);
    final pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      final videoSource = await _groupsChatService.uploadVideo(
        bytes: await pickedFile.readAsBytes(),
        filename: _filenameForPickedMedia(pickedFile, fallbackExtension: 'mp4'),
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        video: videoSource,
      );
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.pickAndSendVideo', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendFile() {
    return _pickAndSendPickedFile(
      traceName: 'pickAndSendFile',
      allowedExtensions: const [
        ..._audioFileExtensions,
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'rtf',
        'csv',
        'zip',
        'rar',
        '7z',
        'json',
        'xml',
      ],
    );
  }

  Future<void> pickAndSendAudio() {
    return _pickAndSendPickedFile(
      traceName: 'pickAndSendAudio',
      forceAudio: true,
      allowedExtensions: const [..._audioFileExtensions],
    );
  }

  Future<void> _pickAndSendPickedFile({
    required String traceName,
    required List<String> allowedExtensions,
    bool forceAudio = false,
  }) async {
    _ensureCanSendMessage();
    if (isSending.value) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final filename = pickedFile.name.trim();
    if (filename.isEmpty) {
      throw Exception(
        _localizedMessage(
          arabic: 'الملف المحدد لا يحتوي على اسم صالح',
          english: 'The selected file is missing a valid name',
        ),
      );
    }

    Uint8List? bytes = pickedFile.bytes;
    final path = pickedFile.path?.trim() ?? '';
    if ((bytes == null || bytes.isEmpty) && path.isNotEmpty) {
      bytes = await File(path).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      throw Exception(
        _localizedMessage(
          arabic: 'تعذر قراءة الملف المحدد',
          english: 'Unable to read the selected file',
        ),
      );
    }

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      if (forceAudio || _isAudioPlatformFile(pickedFile)) {
        final voiceNoteSource = await _groupsChatService.uploadVoiceNote(
          bytes: bytes,
          filename: filename,
        );
        await _sendAttachmentMessage(
          message: pendingText.isEmpty ? null : pendingText,
          voiceNote: voiceNoteSource,
        );
      } else {
        final fileAttachment = await _groupsChatService.uploadFile(
          bytes: bytes,
          filename: filename,
        );
        await _sendAttachmentMessage(
          message: pendingText.isEmpty ? null : pendingText,
          file: fileAttachment,
        );
      }
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.$traceName', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> toggleVoiceRecording() async {
    _ensureCanSendMessage();
    if (isSending.value) {
      return;
    }

    if (isRecordingVoice.value) {
      await _stopAndSendVoiceRecording();
      return;
    }

    await _ensureMicrophonePermission();
    final recorder = _audioRecorder ??= AudioRecorder();
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/group-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      isRecordingVoice.value = true;
    } on MissingPluginException {
      throw Exception(
        _localizedMessage(
          arabic: 'تسجيل الصوت غير متاح في هذا الإصدار',
          english: 'Voice recording plugin is not available in this build',
        ),
      );
    }
  }

  Future<void> _stopAndSendVoiceRecording() async {
    isSending.value = true;
    errorMessage.value = '';

    try {
      final recorder = _audioRecorder;
      if (recorder == null) {
        throw Exception(
          _localizedMessage(
            arabic: 'مسجل الصوت غير جاهز',
            english: 'Voice recorder is not initialized',
          ),
        );
      }

      final recordedPath = await recorder.stop();
      isRecordingVoice.value = false;
      if (recordedPath == null || recordedPath.trim().isEmpty) {
        throw Exception(
          _localizedMessage(
            arabic: 'فشل تسجيل الرسالة الصوتية',
            english: 'Voice note recording failed',
          ),
        );
      }

      final pendingText = inputController.text.trim();
      final file = File(recordedPath);
      final voiceNoteSource = await _groupsChatService.uploadVoiceNote(
        bytes: await file.readAsBytes(),
        filename: recordedPath.split(Platform.pathSeparator).last,
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        voiceNote: voiceNoteSource,
      );
    } on MissingPluginException {
      isRecordingVoice.value = false;
      throw Exception(
        _localizedMessage(
          arabic: 'تسجيل الصوت غير متاح في هذا الإصدار',
          english: 'Voice recording plugin is not available in this build',
        ),
      );
    } catch (error) {
      isRecordingVoice.value = false;
      GroupsChatLogger.error(
        'conversation_controller.stopAndSendVoiceRecording',
        error,
      );
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _sendAttachmentMessage({
    String? message,
    String? photo,
    String? video,
    String? voiceNote,
    Map<String, dynamic>? file,
  }) async {
    _ensureCanSendMessage();
    final sentMessage = await _groupsChatService.sendMessage(
      groupId: group.value.groupId,
      message: message,
      photo: photo,
      video: video,
      voiceNote: voiceNote,
      file: file,
    );
    inputController.clear();
    if (_loadedMessageIds.add(sentMessage.messageId)) {
      messages.add(sentMessage);
    }
    GroupsChatLogger.log(
      'conversation_controller',
      'sendAttachment success messageId=${sentMessage.messageId} type=${sentMessage.messageType} total=${messages.length}',
    );
    _scrollToBottomSoon(reason: 'attachment_sent');
    unawaited(_markLatestRead());
    if (Get.isRegistered<GroupsChatController>()) {
      unawaited(Get.find<GroupsChatController>().load());
    }
  }

  Future<void> deleteMessage(GroupsChatMessageModel message) async {
    if (message.messageId <= 0) {
      return;
    }

    errorMessage.value = '';
    try {
      await _groupsChatService.deleteMessage(messageId: message.messageId);
      _loadedMessageIds.remove(message.messageId);
      messages.removeWhere((item) => item.messageId == message.messageId);
      messages.refresh();
      if (Get.isRegistered<GroupsChatController>()) {
        unawaited(Get.find<GroupsChatController>().load());
      }
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.deleteMessage', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    }
  }

  Future<void> reactToMessage(
    GroupsChatMessageModel message, {
    required String reaction,
  }) async {
    if (message.messageId <= 0 || reaction.trim().isEmpty) {
      return;
    }

    errorMessage.value = '';
    final shouldUnreact = message.iReact && message.myReactionType == reaction;

    try {
      await _groupsChatService.reactToMessage(
        messageId: message.messageId,
        reaction: reaction,
        shouldReact: !shouldUnreact,
      );
      _updateMessageReactionState(
        message.messageId,
        reaction: reaction,
        shouldReact: !shouldUnreact,
      );
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.reactToMessage', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    }
  }

  Future<GroupsChatReactionAuthorsResponse> fetchReactionAuthors(
    GroupsChatMessageModel message, {
    String reactionType = 'all',
    int? offset,
  }) {
    return _groupsChatService.fetchReactionAuthors(
      messageId: message.messageId,
      reactionType: reactionType,
      offset: offset,
    );
  }

  Future<void> muteMessageSender(GroupsChatMessageModel message) async {
    if (message.senderId <= 0 || isOwnMessage(message)) {
      return;
    }

    errorMessage.value = '';
    try {
      await _groupsChatService.muteMember(
        groupId: group.value.groupId,
        userId: message.senderId,
      );
    } catch (error) {
      GroupsChatLogger.error(
        'conversation_controller.muteMessageSender',
        error,
      );
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    }
  }

  Future<void> unmuteMessageSender(GroupsChatMessageModel message) async {
    if (message.senderId <= 0 || isOwnMessage(message)) {
      return;
    }

    errorMessage.value = '';
    try {
      await _groupsChatService.unmuteMember(
        groupId: group.value.groupId,
        userId: message.senderId,
      );
    } catch (error) {
      GroupsChatLogger.error(
        'conversation_controller.unmuteMessageSender',
        error,
      );
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    }
  }

  Future<GroupsChatMemberModel?> fetchMessageSenderMember(
    GroupsChatMessageModel message,
  ) async {
    if (message.senderId <= 0 || isOwnMessage(message)) {
      return null;
    }

    try {
      return await _groupsChatService.fetchMember(
        groupId: group.value.groupId,
        userId: message.senderId,
      );
    } catch (error) {
      GroupsChatLogger.error(
        'conversation_controller.fetchMessageSenderMember',
        error,
      );
      return null;
    }
  }

  bool _isAudioPlatformFile(PlatformFile file) {
    final extension =
        (file.extension?.trim().toLowerCase() ??
                _extensionFromFilename(file.name))
            .trim();
    return _audioFileExtensions.contains(extension);
  }

  String _extensionFromFilename(String filename) {
    final trimmedName = filename.trim().toLowerCase();
    final dotIndex = trimmedName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == trimmedName.length - 1) {
      return '';
    }
    return trimmedName.substring(dotIndex + 1);
  }

  String _filenameForPickedMedia(
    XFile file, {
    required String fallbackExtension,
  }) {
    final rawName = file.name.trim();
    if (_extensionFromFilename(rawName).isNotEmpty) {
      return rawName;
    }

    final pathName = _basenameFromPath(file.path);
    if (_extensionFromFilename(pathName).isNotEmpty) {
      return pathName;
    }

    final cleanExtension = fallbackExtension.replaceAll('.', '').trim();
    final baseName = rawName.isNotEmpty
        ? rawName
        : 'group-media-${DateTime.now().millisecondsSinceEpoch}';
    return cleanExtension.isEmpty ? baseName : '$baseName.$cleanExtension';
  }

  String _basenameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    final slashIndex = normalized.lastIndexOf('/');
    if (slashIndex < 0) {
      return normalized;
    }
    return normalized.substring(slashIndex + 1);
  }

  Future<void> _ensureMediaPermission({required bool forVideo}) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        return;
      }
      throw Exception(
        _mediaPermissionMessage(
          forVideo: forVideo,
          permanentlyDenied: status.isPermanentlyDenied || status.isRestricted,
        ),
      );
    }

    if (Platform.isAndroid) {
      final primaryPermission = forVideo
          ? Permission.videos
          : Permission.photos;
      final permissions = <Permission>[primaryPermission, Permission.storage];
      var permanentlyDenied = false;

      for (final permission in permissions) {
        final currentStatus = await permission.status;
        if (currentStatus.isGranted || currentStatus.isLimited) {
          return;
        }
      }

      for (final permission in permissions) {
        final requestedStatus = await permission.request();
        if (requestedStatus.isGranted || requestedStatus.isLimited) {
          return;
        }
        permanentlyDenied =
            permanentlyDenied ||
            requestedStatus.isPermanentlyDenied ||
            requestedStatus.isRestricted;
      }

      throw Exception(
        _mediaPermissionMessage(
          forVideo: forVideo,
          permanentlyDenied: permanentlyDenied,
        ),
      );
    }
  }

  Future<void> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return;
    }
    throw Exception(
      status.isPermanentlyDenied
          ? _localizedMessage(
              arabic:
                  'تم رفض صلاحية الميكروفون نهائياً. افتح إعدادات التطبيق وفعّل الميكروفون للمتابعة.',
              english:
                  'Microphone permission was permanently denied. Open app settings and enable microphone access to continue.',
            )
          : _localizedMessage(
              arabic:
                  'يجب السماح بالوصول إلى الميكروفون لتسجيل الرسائل الصوتية.',
              english:
                  'Microphone access is required to record voice messages.',
            ),
    );
  }

  void _ensureCanSendMessage() {
    if (canSendMessages) {
      return;
    }
    throw Exception(
      _localizedMessage(
        arabic: 'المراسلة في هذه المجموعة متاحة للإدارة فقط حالياً.',
        english: 'Only admins can send messages in this group right now.',
      ),
    );
  }

  String _mediaPermissionMessage({
    required bool forVideo,
    required bool permanentlyDenied,
  }) {
    if (permanentlyDenied) {
      return _localizedMessage(
        arabic:
            'تم رفض صلاحية الوسائط نهائياً. افتح إعدادات التطبيق وفعّل الوصول للصور أو الفيديوهات للمتابعة.',
        english:
            'Media permission was permanently denied. Open app settings and enable access to photos or videos to continue.',
      );
    }
    return _localizedMessage(
      arabic: forVideo
          ? 'يجب السماح بالوصول إلى الفيديوهات لإرسال فيديو.'
          : 'يجب السماح بالوصول إلى الصور لإرسال صورة.',
      english: forVideo
          ? 'Video access is required to send videos.'
          : 'Photo access is required to send photos.',
    );
  }

  String _localizedMessage({required String arabic, required String english}) {
    return (Get.locale?.languageCode.toLowerCase() ?? '') == 'ar'
        ? arabic
        : english;
  }

  bool isOwnMessage(GroupsChatMessageModel message) {
    return currentUserId > 0 && message.senderId == currentUserId;
  }

  void updateGroup(GroupsChatGroupModel updatedGroup) {
    if (updatedGroup.groupId != group.value.groupId) {
      return;
    }
    group.value = updatedGroup;
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().upsertGroup(updatedGroup);
    }
  }

  Future<void> _loadReactionTypes() async {
    try {
      final response = await _groupsChatService.fetchReactionTypes();
      if (response.types.isEmpty) {
        reactionTypes.assignAll(_fallbackReactionTypes);
        return;
      }
      reactionTypes.assignAll(response.types);
    } catch (_) {
      reactionTypes.assignAll(_fallbackReactionTypes);
    }
  }

  Future<void> _markLatestRead() async {
    if (messages.isEmpty) {
      return;
    }
    try {
      GroupsChatLogger.log(
        'conversation_controller',
        'markLatestRead groupId=${group.value.groupId} messageId=${messages.last.messageId}',
      );
      await _groupsChatService.markGroupRead(
        groupId: group.value.groupId,
        lastMessageId: messages.last.messageId,
      );
      if (Get.isRegistered<GroupsChatController>()) {
        final groupsController = Get.find<GroupsChatController>();
        final readGroup = group.value.copyWith(unreadCount: 0);
        group.value = readGroup;
        groupsController.upsertGroup(readGroup);
        unawaited(groupsController.refreshSilently());
      }
    } catch (error) {
      GroupsChatLogger.error('conversation_controller.markLatestRead', error);
      // Read receipts should not interrupt opening or sending messages.
    }
  }

  Future<void> _loadLatestMessages({bool forceScroll = false}) async {
    if (_isPolling ||
        !_preferences.hasActiveSession() ||
        isLoading.value ||
        isLoadingMore.value ||
        isSending.value) {
      return;
    }

    _isPolling = true;
    try {
      final latestMessageId = messages.isEmpty ? null : messages.last.messageId;
      final wasNearBottom = _isNearBottom(threshold: 260);
      GroupsChatLogger.log(
        'conversation_controller',
        'poll latest groupId=${group.value.groupId} after=${latestMessageId ?? '-'} nearBottom=$wasNearBottom',
      );
      final groupDetailsFuture = _refreshGroupDetailsFromPolling();
      final eventsFuture = _groupsChatService.fetchEvents(
        groupId: group.value.groupId,
        afterEventId: _lastEventCursor == 0 ? null : _lastEventCursor,
        limit: 100,
      );
      final loadedMessageIds = messages
          .map((message) => message.messageId)
          .where((id) => id > 0)
          .toSet()
          .take(100)
          .toList(growable: false);
      final snapshotFuture = loadedMessageIds.isEmpty
          ? Future<GroupsChatMessagesResponse?>.value()
          : _groupsChatService
                .fetchMessages(
                  groupId: group.value.groupId,
                  limit: loadedMessageIds.length,
                  messageIds: loadedMessageIds,
                )
                .then<GroupsChatMessagesResponse?>((response) => response);
      final response = await _groupsChatService.fetchMessages(
        groupId: group.value.groupId,
        limit: _groupChatMessagesPageSize,
        afterMessageId: latestMessageId,
      );
      final eventsResponse = await eventsFuture;
      final snapshotResponse = await snapshotFuture;
      await groupDetailsFuture;
      final eventsChanged = await _applyGroupEvents(eventsResponse);
      final snapshotChanged = _mergeMessageSnapshots(
        snapshotResponse?.messages ?? const <GroupsChatMessageModel>[],
      );
      final freshItems = response.messages.where((message) {
        return _loadedMessageIds.add(message.messageId);
      }).toList();

      if (freshItems.isEmpty && !eventsChanged && !snapshotChanged) {
        return;
      }

      if (freshItems.isNotEmpty) {
        messages.addAll(freshItems);
        GroupsChatLogger.log(
          'conversation_controller',
          'poll success fresh=${freshItems.length} total=${messages.length}',
        );
        if (forceScroll || wasNearBottom) {
          _scrollToBottomSoon(reason: 'incoming_messages');
        }
        unawaited(_markLatestRead());
      }
      if (Get.isRegistered<GroupsChatController>()) {
        unawaited(Get.find<GroupsChatController>().load());
      }
    } catch (error) {
      if (_isGroupDeletedError(error)) {
        _handleGroupDeleted();
        return;
      }
      GroupsChatLogger.error('conversation_controller.poll', error);
    } finally {
      _isPolling = false;
    }
  }

  Future<bool> _applyGroupEvents(GroupsChatEventsResponse response) async {
    if (response.nextCursor > _lastEventCursor) {
      _lastEventCursor = response.nextCursor;
    }

    var changedAny = false;
    final events = [...response.items]
      ..sort((a, b) => a.eventId.compareTo(b.eventId));
    for (final event in events) {
      if (_eventShouldRefreshGroupDetails(event)) {
        await _refreshGroupDetailsFromPolling(reason: event.actionType);
        changedAny = true;
        continue;
      }

      if (event.actionType == 'reaction_updated') {
        if (_applyReactionEvent(event)) {
          changedAny = true;
        }
        continue;
      }

      if (event.actionType != 'message_deleted') {
        continue;
      }

      final messageId =
          event.messageId ?? int.tryParse(event.data['message_id'].toString());
      if (messageId == null || messageId <= 0) {
        continue;
      }

      final before = messages.length;
      messages.removeWhere((message) => message.messageId == messageId);
      _loadedMessageIds.remove(messageId);
      if (messages.length != before) {
        changedAny = true;
      }
    }

    if (changedAny) {
      _forceMessagesRebuild();
      GroupsChatLogger.log(
        'conversation_controller',
        'events applied total=${messages.length} cursor=$_lastEventCursor',
      );
    }
    return changedAny;
  }

  bool _eventShouldRefreshGroupDetails(GroupsChatEventModel event) {
    if (event.groupId != group.value.groupId) {
      return false;
    }

    if (event.actionType == 'permissions_updated' ||
        event.actionType == 'join_link_updated') {
      return true;
    }

    const memberStateEvents = <String>{
      'admin_permissions_updated',
      'admin_added',
      'admin_removed',
      'member_muted',
      'member_unmuted',
      'member_removed',
      'member_banned',
      'member_left',
      'ownership_transferred',
    };
    if (!memberStateEvents.contains(event.actionType)) {
      return false;
    }

    return event.targetUserId != null && event.targetUserId == currentUserId;
  }

  bool _applyReactionEvent(GroupsChatEventModel event) {
    final messageId =
        event.messageId ?? int.tryParse(event.data['message_id'].toString());
    if (messageId == null || messageId <= 0) {
      return false;
    }

    final index = messages.indexWhere((item) => item.messageId == messageId);
    if (index == -1) {
      return false;
    }

    final state = event.data['reaction_state'];
    if (state is! Map) {
      return false;
    }
    final stateMap = Map<String, dynamic>.from(state);
    final counts = _normalizeReactionCounts(stateMap['reactions']);
    final totalCount = _reactionTotalCount(
      counts,
      fallback: int.tryParse(
        stateMap['reactions_total_count']?.toString() ?? '',
      ),
    );
    final current = messages[index];
    final actorIsCurrentUser =
        event.performedBy != null && event.performedBy == currentUserId;
    final action = event.data['action']?.toString() ?? '';
    final reaction = event.data['reaction']?.toString().trim() ?? '';

    messages[index] = current.copyWith(
      reactionCounts: counts,
      reactionsTotalCount: totalCount,
      topReactionType: _topReactionType(counts),
      iReact: actorIsCurrentUser ? action == 'react' : current.iReact,
      myReactionType: actorIsCurrentUser
          ? (action == 'react' ? reaction : '')
          : current.myReactionType,
    );
    GroupsChatLogger.log(
      'conversation_controller',
      'reaction event applied messageId=$messageId total=$totalCount counts=$counts actor=${event.performedBy ?? '-'} currentUser=$currentUserId',
    );
    return true;
  }

  bool _mergeMessageSnapshots(List<GroupsChatMessageModel> snapshots) {
    if (snapshots.isEmpty || messages.isEmpty) {
      return false;
    }

    var changedAny = false;
    for (final snapshot in snapshots) {
      final index = messages.indexWhere(
        (message) => message.messageId == snapshot.messageId,
      );
      if (index == -1) {
        continue;
      }

      final current = messages[index];
      if (!_messageSnapshotChanged(current, snapshot)) {
        continue;
      }

      messages[index] = snapshot;
      changedAny = true;
      GroupsChatLogger.log(
        'conversation_controller',
        'message snapshot merged messageId=${snapshot.messageId} reactions=${snapshot.reactionsTotalCount} mine=${snapshot.myReactionType}',
      );
    }

    if (changedAny) {
      _forceMessagesRebuild();
    }
    return changedAny;
  }

  bool _messageSnapshotChanged(
    GroupsChatMessageModel current,
    GroupsChatMessageModel snapshot,
  ) {
    if (current.reactionsTotalCount != snapshot.reactionsTotalCount ||
        current.iReact != snapshot.iReact ||
        current.myReactionType != snapshot.myReactionType ||
        current.topReactionType != snapshot.topReactionType ||
        current.readByCount != snapshot.readByCount) {
      return true;
    }
    return !_reactionCountsEqual(
      current.reactionCounts,
      snapshot.reactionCounts,
    );
  }

  bool _reactionCountsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  void _updateMessageReactionState(
    int messageId, {
    required String reaction,
    required bool shouldReact,
  }) {
    final index = messages.indexWhere((item) => item.messageId == messageId);
    if (index == -1) {
      return;
    }

    final current = messages[index];
    final nextCounts = Map<String, int>.from(current.reactionCounts);
    final previousReaction = current.myReactionType.trim();

    if (previousReaction.isNotEmpty) {
      nextCounts[previousReaction] = ((nextCounts[previousReaction] ?? 0) - 1)
          .clamp(0, 1 << 30);
    }

    if (shouldReact) {
      nextCounts[reaction] = (nextCounts[reaction] ?? 0) + 1;
    }

    nextCounts.removeWhere((_, value) => value <= 0);

    messages[index] = current.copyWith(
      reactionCounts: nextCounts,
      reactionsTotalCount: _reactionTotalCount(nextCounts),
      iReact: shouldReact,
      myReactionType: shouldReact ? reaction : '',
      topReactionType: _topReactionType(nextCounts),
    );
    _forceMessagesRebuild();
  }

  void _forceMessagesRebuild() {
    messages.assignAll(List<GroupsChatMessageModel>.of(messages));
  }

  Map<String, int> _normalizeReactionCounts(dynamic raw) {
    if (raw is! Map) {
      return <String, int>{};
    }
    final counts = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString().trim() ?? '';
      final value = int.tryParse(entry.value?.toString() ?? '') ?? 0;
      if (key.isNotEmpty && value > 0) {
        counts[key] = value;
      }
    }
    return counts;
  }

  int _reactionTotalCount(Map<String, int> counts, {int? fallback}) {
    if (fallback != null && fallback >= 0) {
      return fallback;
    }
    var total = 0;
    for (final count in counts.values) {
      total += count;
    }
    return total;
  }

  String _topReactionType(Map<String, int> counts) {
    var topType = '';
    var topCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        topCount = entry.value;
        topType = entry.key;
      }
    }
    return topType;
  }

  Future<void> _refreshGroupDetailsFromPolling({String reason = 'poll'}) async {
    try {
      final previousPermission = group.value.messagePermission;
      final previousCanSend = canSendMessages;
      final updatedGroup = await _groupsChatService.fetchGroupDetails(
        groupId: group.value.groupId,
      );
      updateGroup(updatedGroup);
      final nextCanSend = canSendMessages;
      if (previousPermission != updatedGroup.messagePermission ||
          previousCanSend != nextCanSend) {
        GroupsChatLogger.log(
          'conversation_controller',
          'group details refreshed reason=$reason groupId=${group.value.groupId} permission=$previousPermission->${updatedGroup.messagePermission} canSend=$previousCanSend->$nextCanSend',
        );
      } else if (reason != 'poll') {
        GroupsChatLogger.log(
          'conversation_controller',
          'group details refreshed reason=$reason groupId=${group.value.groupId} no visible permission delta',
        );
      }
    } catch (error) {
      if (_isGroupDeletedError(error)) {
        _handleGroupDeleted();
        return;
      }
      GroupsChatLogger.error('conversation_controller.pollGroupDetails', error);
    }
  }

  bool _isGroupDeletedError(Object error) {
    if (error is! ApiException) {
      return false;
    }
    final message = error.message.toLowerCase();
    return error.statusCode == 404 || message.contains('group not found');
  }

  void _handleGroupDeleted() {
    if (isGroupDeleted.value) {
      return;
    }
    GroupsChatLogger.log(
      'conversation_controller',
      'group deleted groupId=${group.value.groupId}',
    );
    isGroupDeleted.value = true;
    _pollingTimer?.cancel();
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().removeGroup(group.value.groupId);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (!chatPollingEnabled) {
      GroupsChatLogger.log(
        'conversation_controller',
        'polling disabled groupId=${group.value.groupId}',
      );
      return;
    }

    GroupsChatLogger.log(
      'conversation_controller',
      'polling start groupId=${group.value.groupId} interval=${chatPollingInterval.inSeconds}s',
    );
    if (!isClosed && !isLoading.value && !isSending.value) {
      unawaited(_loadLatestMessages());
    }
    _pollingTimer = Timer.periodic(chatPollingInterval, (_) {
      if (isClosed ||
          isLoading.value ||
          isLoadingMore.value ||
          isSending.value) {
        return;
      }
      unawaited(_loadLatestMessages());
    });
  }

  bool _isNearBottom({double threshold = 180}) {
    if (!scrollController.hasClients) {
      return true;
    }
    return scrollController.position.maxScrollExtent -
            scrollController.offset <=
        threshold;
  }

  void _restoreScrollOffsetAfterPrepend({
    required double previousPixels,
    required double previousMaxExtent,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }
      final newMaxExtent = scrollController.position.maxScrollExtent;
      final delta = newMaxExtent - previousMaxExtent;
      scrollController.jumpTo(previousPixels + delta);
    });
  }

  void _scrollToBottomSoon({String reason = 'internal', int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        if (attempt < 4) {
          Future<void>.delayed(
            const Duration(milliseconds: 60),
            () => _scrollToBottomSoon(reason: reason, attempt: attempt + 1),
          );
        }
        return;
      }
      final target = scrollController.position.maxScrollExtent;
      final current = scrollController.offset;
      _initialScrollCompleted = true;
      GroupsChatLogger.log(
        'conversation_controller',
        'scrollToBottom reason=$reason attempt=$attempt current=${current.toStringAsFixed(1)} target=${target.toStringAsFixed(1)} count=${messages.length}',
      );
      if ((target - current).abs() <= 1) {
        return;
      }
      scrollController.jumpTo(target);
      if (attempt < 2) {
        Future<void>.delayed(
          const Duration(milliseconds: 120),
          () => _scrollToBottomSoon(reason: reason, attempt: attempt + 1),
        );
      }
    });
  }
}

const List<ChatReactionTypeModel> _fallbackReactionTypes =
    <ChatReactionTypeModel>[
      ChatReactionTypeModel(
        key: 'like',
        label: 'Like',
        emoji: '👍',
        iconUrl: '',
        order: 1,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'love',
        label: 'Love',
        emoji: '❤️',
        iconUrl: '',
        order: 2,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'haha',
        label: 'Haha',
        emoji: '😂',
        iconUrl: '',
        order: 3,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'yay',
        label: 'Yay',
        emoji: '🎉',
        iconUrl: '',
        order: 4,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'wow',
        label: 'Wow',
        emoji: '😮',
        iconUrl: '',
        order: 5,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'sad',
        label: 'Sad',
        emoji: '😢',
        iconUrl: '',
        order: 6,
        enabled: true,
      ),
      ChatReactionTypeModel(
        key: 'angry',
        label: 'Angry',
        emoji: '😡',
        iconUrl: '',
        order: 7,
        enabled: true,
      ),
    ];
