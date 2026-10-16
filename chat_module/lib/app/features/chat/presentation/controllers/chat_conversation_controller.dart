import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../../settings.dart';
import '../../../../core/utils/audio_cache_warmer.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/utils/chat_trace_logger.dart';
import '../../../../core/utils/video_cache_warmer.dart';
import '../../data/models/chat_backgrounds_response.dart';
import '../../data/models/chat_conversation_details.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/models/chat_reaction_types_response.dart';
import '../../data/models/chat_stickers_response.dart';
import '../../data/services/chat_cache_store.dart';
import '../../data/services/chat_service.dart';
import '../../../home/presentation/controllers/home_controller.dart';

enum ChatPermissionType { photos, videos, microphone, location }

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

class ChatPermissionException implements Exception {
  const ChatPermissionException({
    required this.type,
    required this.title,
    required this.message,
    this.canOpenSettings = false,
  });

  final ChatPermissionType type;
  final String title;
  final String message;
  final bool canOpenSettings;

  @override
  String toString() => message;
}

class ChatConversationController extends GetxController {
  ChatConversationController(
    this._chatService,
    this._preferences,
    this._chatCacheStore,
    this.initialConversation,
  );

  final ChatService _chatService;
  final ChatAppPreferences _preferences;
  final ChatCacheStore _chatCacheStore;
  final ChatConversationModel initialConversation;
  final ImagePicker _imagePicker = ImagePicker();
  AudioRecorder? _audioRecorder;

  final isLoading = true.obs;
  final isSending = false.obs;
  final isRecordingVoice = false.obs;
  final errorMessage = ''.obs;
  final title = ''.obs;
  final avatarUrl = ''.obs;
  final isGroupConversation = false.obs;
  final recipientUserId = 0.obs;
  final nodeId = 0.obs;
  final nodeType = ''.obs;
  final nodeLink = ''.obs;
  final statusLabel = ''.obs;
  final statusIsActive = false.obs;
  final seenNameList = ''.obs;
  final isPinned = false.obs;
  final isMuted = false.obs;
  final isUpdatingBackground = false.obs;
  final isLoadingStickers = false.obs;
  final isRecipientBlocked = false.obs;
  final isBlockedByRecipient = false.obs;
  final canSendMessages = true.obs;
  final messages = <ChatMessageModel>[].obs;
  final reactionTypes = <ChatReactionTypeModel>[].obs;
  final conversationBackground = Rxn<ChatBackgroundModel>();
  final selectedReplyMessage = Rxn<ChatMessageModel>();
  final selectedEditingMessage = Rxn<ChatMessageModel>();
  final stickerPacks = <ChatStickerPackSummaryModel>[].obs;
  final stickers = <ChatStickerModel>[].obs;
  final selectedStickerPack = ''.obs;

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  int _conversationId = 0;
  int? _nextOffset;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isPolling = false;
  bool _ignoreScrollPagination = false;
  bool _canTriggerLoadMore = true;
  int _lastEventCursor = 0;
  bool _isPollingCursorPrimed = false;
  int _lastSeenMessageId = 0;
  int _lastMarkedSeenMessageId = 0;
  bool _isRefreshingReadStatus = false;
  Timer? _pollingTimer;
  Timer? _cacheWriteDebounce;
  DateTime? _lastScrollTraceAt;

  int get conversationId => _conversationId;

  bool isNearBottom({double threshold = 180}) {
    return _isNearBottom(threshold: threshold);
  }

  void scrollToBottom({String reason = 'manual'}) {
    _scrollToBottom(reason: reason);
  }

  @override
  void onInit() {
    super.onInit();
    title.value = initialConversation.title;
    avatarUrl.value = initialConversation.avatarUrl;
    _conversationId = int.tryParse(initialConversation.id) ?? 0;
    unawaited(
      ChatTraceLogger.resetSession(
        'conversation:${initialConversation.id}:${initialConversation.targetUserId}',
      ),
    );
    unawaited(
      ChatTraceLogger.log(
        'controller',
        'onInit initialConversationId=${initialConversation.id} targetUserId=${initialConversation.targetUserId}',
      ),
    );
    scrollController.addListener(_handleScroll);
    unawaited(_loadReactionTypes());
    _applyInitialRelationship();
    loadConversation();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _cacheWriteDebounce?.cancel();
    scrollController.removeListener(_handleScroll);
    final recorder = _audioRecorder;
    if (recorder != null) {
      unawaited(recorder.dispose());
    }
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadConversation() async {
    if (_conversationId == 0) {
      recipientUserId.value = initialConversation.targetUserId;
      isGroupConversation.value = false;
      statusLabel.value = '';
      statusIsActive.value = false;
      if (recipientUserId.value == 0) {
        isLoading.value = false;
        return;
      }
    }

    isLoading.value = true;
    errorMessage.value = '';
    final restoredFromCache = await _restoreCachedConversation();
    if (restoredFromCache) {
      isLoading.value = false;
      if (_conversationId != 0) {
        unawaited(refreshReadStatus(reason: 'cache_restore'));
      }
    }

    try {
      final details = await _chatService.fetchConversation(
        conversationId: _conversationId == 0 ? null : _conversationId,
        userId: _conversationId == 0 ? recipientUserId.value : null,
      );
      _applyConversation(details);
      _scheduleConversationCacheWrite();
      unawaited(
        ChatTraceLogger.log(
          'conversation',
          'loaded conversationId=$_conversationId messages=${messages.length} first=${_minLoadedMessageId()} last=${_maxLoadedMessageId()} hasMore=$_hasMore nextOffset=$_nextOffset',
        ),
      );
      if (_conversationId != 0) {
        unawaited(loadConversationBackground());
        unawaited(refreshReadStatus(reason: 'load'));
        unawaited(_markVisibleMessagesSeen());
      }
      _scrollToBottom();
      _startPolling();
    } catch (error) {
      if (!restoredFromCache) {
        errorMessage.value = error.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshConversation() async {
    if (_conversationId == 0) {
      return;
    }

    try {
      _ignoreScrollPagination = true;
      final response = await _chatService.fetchMessages(
        conversationId: _conversationId,
      );
      _applyMessagesResponse(response, replace: true);
      _scheduleConversationCacheWrite();
      await loadConversationBackground();
      _scrollToBottom();
      unawaited(_markVisibleMessagesSeen());
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      _releaseScrollPaginationLock();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _nextOffset == null ||
        _conversationId == 0) {
      return;
    }

    _isLoadingMore = true;
    final previousPixels = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    final previousMaxExtent = scrollController.hasClients
        ? scrollController.position.maxScrollExtent
        : 0.0;

    try {
      _canTriggerLoadMore = false;
      unawaited(
        ChatTraceLogger.log(
          'pagination',
          'loadMore:start offset=$_nextOffset previousPixels=${previousPixels.toStringAsFixed(1)} previousMaxExtent=${previousMaxExtent.toStringAsFixed(1)} count=${messages.length} first=${_minLoadedMessageId()} last=${_maxLoadedMessageId()}',
        ),
      );
      final response = await _chatService.fetchMessages(
        conversationId: _conversationId,
        offset: _nextOffset,
      );
      _applyMessagesResponse(response, replace: false);
      unawaited(
        ChatTraceLogger.log(
          'pagination',
          'loadMore:done nextOffset=$_nextOffset hasMore=$_hasMore count=${messages.length} first=${_minLoadedMessageId()} last=${_maxLoadedMessageId()}',
        ),
      );
      _restoreScrollOffsetAfterPrepend(
        previousPixels: previousPixels,
        previousMaxExtent: previousMaxExtent,
      );
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> sendCurrentMessage() async {
    _ensureCanSendMessage();
    final text = inputController.text.trim();
    if (text.isEmpty || isSending.value) {
      return;
    }

    isSending.value = true;
    errorMessage.value = '';
    final replyToMessage = selectedReplyMessage.value;
    final editingMessage = selectedEditingMessage.value;
    inputController.clear();

    try {
      if (editingMessage != null) {
        final updated = await _chatService.editMessage(
          messageId: editingMessage.id,
          message: text,
        );
        final index = messages.indexWhere(
          (item) => item.id == editingMessage.id,
        );
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            text: updated.text,
            editableText: updated.editableText,
          );
          messages.refresh();
          _scheduleConversationCacheWrite();
        }
        clearEditSelection();
        return;
      }
      final result = await _chatService.sendMessage(
        conversationId: _conversationId == 0 ? null : _conversationId,
        recipients: _conversationId == 0 && recipientUserId.value != 0
            ? <int>[recipientUserId.value]
            : null,
        message: text,
        replyToMessageId: replyToMessage?.id,
      );
      if (result.conversationId != 0) {
        _conversationId = result.conversationId;
      }
      _advanceEventCursorFromSendResult(result);
      if (result.lastMessage != null) {
        messages.assignAll(
          _dedupeMessages(<ChatMessageModel>[...messages, result.lastMessage!]),
        );
        _scheduleConversationCacheWrite();
      } else {
        await _loadLatestMessages(forceScroll: true);
      }
      clearReplySelection();
      _scrollToBottom();
    } catch (error) {
      inputController.text = text;
      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendPhoto() async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    await _ensurePhotoPermission();

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
      final bytes = await pickedFile.readAsBytes();
      final photoSource = await _chatService.uploadPhoto(
        bytes: bytes,
        filename: pickedFile.name,
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        photo: photoSource,
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendVideo() async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    await _ensureVideoPermission();

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
      final bytes = await pickedFile.readAsBytes();
      final videoSource = await _chatService.uploadVideo(
        bytes: bytes,
        filename: pickedFile.name,
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        video: videoSource,
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendFile() async {
    await _pickAndSendFile(
      type: FileType.custom,
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

  Future<void> _pickAndSendFile({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: type,
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
      throw Exception('The selected file is missing a valid name');
    }

    Uint8List? bytes = pickedFile.bytes;
    final path = pickedFile.path?.trim() ?? '';
    if ((bytes == null || bytes.isEmpty) && path.isNotEmpty) {
      bytes = await File(path).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to read the selected file');
    }

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      if (_isAudioPlatformFile(pickedFile)) {
        final voiceNoteSource = await _chatService.uploadVoiceNote(
          bytes: bytes,
          filename: filename,
        );
        await _sendAttachmentMessage(
          message: pendingText.isEmpty ? null : pendingText,
          voiceNote: voiceNoteSource,
        );
      } else {
        final fileAttachment = await _chatService.uploadFile(
          bytes: bytes,
          filename: filename,
        );
        await _sendAttachmentMessage(
          message: pendingText.isEmpty ? null : pendingText,
          file: fileAttachment.toRequestPayload(),
        );
      }
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendCurrentLocation() async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ChatPermissionException(
        type: ChatPermissionType.location,
        title: _isArabicLocale
            ? 'خدمة الموقع متوقفة'
            : 'Location services disabled',
        message: AppTranslations.chatLocationServiceDisabled.tr,
      );
    }

    await _ensureLocationPermission();

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        location: <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'name': AppTranslations.chatCurrentLocation.tr,
        },
      );
    } on LocationServiceDisabledException {
      errorMessage.value = AppTranslations.chatLocationServiceDisabled.tr;
      rethrow;
    } catch (error) {
      final fallbackError = Exception(
        AppTranslations.chatLocationFetchFailed.tr,
      );
      errorMessage.value = fallbackError.toString();
      throw fallbackError;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendContact({
    required String displayName,
    required String phoneNumber,
    String? phoneLabel,
  }) async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    final trimmedName = displayName.trim();
    final trimmedPhone = phoneNumber.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
      return;
    }

    final pendingText = inputController.text.trim();
    isSending.value = true;
    errorMessage.value = '';

    try {
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        contact: <String, dynamic>{
          'display_name': trimmedName,
          'phone_number': trimmedPhone,
          if ((phoneLabel?.trim().isNotEmpty ?? false))
            'phone_label': phoneLabel!.trim(),
        },
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> toggleVoiceRecording() async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
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
        '${tempDir.path}/voice-note-${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
    } on MissingPluginException {
      throw Exception('Voice recording plugin is not available in this build');
    }
    isRecordingVoice.value = true;
  }

  Future<void> _stopAndSendVoiceRecording() async {
    isSending.value = true;
    errorMessage.value = '';

    try {
      final recorder = _audioRecorder;
      if (recorder == null) {
        throw Exception('Voice recorder is not initialized');
      }
      final recordedPath = await recorder.stop();
      isRecordingVoice.value = false;
      if (recordedPath == null || recordedPath.trim().isEmpty) {
        throw Exception('Voice note recording failed');
      }

      final pendingText = inputController.text.trim();
      final file = File(recordedPath);
      final bytes = await file.readAsBytes();
      final filename = recordedPath.split(Platform.pathSeparator).last;
      final voiceNoteSource = await _chatService.uploadVoiceNote(
        bytes: bytes,
        filename: filename,
      );
      await _sendAttachmentMessage(
        message: pendingText.isEmpty ? null : pendingText,
        voiceNote: voiceNoteSource,
      );
    } on MissingPluginException {
      isRecordingVoice.value = false;
      throw Exception('Voice recording plugin is not available in this build');
    } catch (error) {
      isRecordingVoice.value = false;
      errorMessage.value = error.toString();
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
    Map<String, dynamic>? location,
    Map<String, dynamic>? contact,
    int? stickerId,
    String? sticker,
  }) async {
    _ensureCanSendMessage();
    final result = await _chatService.sendMessage(
      conversationId: _conversationId == 0 ? null : _conversationId,
      recipients: _conversationId == 0 && recipientUserId.value != 0
          ? <int>[recipientUserId.value]
          : null,
      message: message,
      photo: photo,
      video: video,
      voiceNote: voiceNote,
      file: file,
      location: location,
      contact: contact,
      stickerId: stickerId,
      sticker: sticker,
      replyToMessageId: selectedReplyMessage.value?.id,
    );
    if (result.conversationId != 0) {
      _conversationId = result.conversationId;
    }
    _advanceEventCursorFromSendResult(result);
    final resolvedLastMessage = _resolveOutgoingAttachmentMessage(
      result.lastMessage,
      stickerId: stickerId,
      stickerUrl: sticker,
    );
    inputController.clear();
    if (resolvedLastMessage != null) {
      messages.assignAll(
        _dedupeMessages(<ChatMessageModel>[...messages, resolvedLastMessage]),
      );
      _scheduleConversationCacheWrite();
    } else {
      await _loadLatestMessages(forceScroll: true);
    }
    clearReplySelection();
    _scrollToBottom();
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

  void selectReplyMessage(ChatMessageModel message) {
    if (message.id == 0) {
      return;
    }
    clearEditSelection(clearInput: false);
    selectedReplyMessage.value = message;
  }

  void clearReplySelection() {
    selectedReplyMessage.value = null;
  }

  void beginEditMessage(ChatMessageModel message) {
    if (message.id == 0) {
      return;
    }
    clearReplySelection();
    selectedEditingMessage.value = message;
    inputController
      ..text = message.editableText
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: message.editableText.length),
      );
  }

  void clearEditSelection({bool clearInput = false}) {
    selectedEditingMessage.value = null;
    if (clearInput) {
      inputController.clear();
    }
  }

  Future<void> loadStickerCatalog({bool force = false}) async {
    if (isLoadingStickers.value) {
      return;
    }
    if (!force && stickerPacks.isNotEmpty && stickers.isNotEmpty) {
      return;
    }

    isLoadingStickers.value = true;
    errorMessage.value = '';
    try {
      final packsResponse = await _chatService.fetchStickerPacks();
      final stickersResponse = await _chatService.fetchStickers();
      stickerPacks.assignAll(packsResponse.items);
      final stickersByKey = <String, ChatStickerModel>{};
      void addSticker(ChatStickerModel sticker) {
        final key = sticker.id > 0
            ? 'id:${sticker.id}'
            : 'asset:${sticker.packKey}:${sticker.resolvedImage}:${sticker.title}';
        if (key.trim().isEmpty || key == 'asset:::') {
          return;
        }
        stickersByKey.putIfAbsent(key, () => sticker);
      }

      for (final sticker in stickersResponse.items) {
        addSticker(sticker);
      }
      for (final pack in packsResponse.items) {
        for (final sticker in pack.items) {
          addSticker(sticker);
        }
      }
      stickers.assignAll(stickersByKey.values);
      final selectedPack = selectedStickerPack.value.trim();
      final hasSelectedPack = stickerPacks.any(
        (pack) => pack.selectionKey == selectedPack,
      );
      if (selectedPack.isEmpty || !hasSelectedPack) {
        selectedStickerPack.value = stickerPacks.isNotEmpty
            ? stickerPacks.first.selectionKey
            : 'all';
      }
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isLoadingStickers.value = false;
    }
  }

  List<ChatStickerModel> get visibleStickers {
    final selectedPack = selectedStickerPack.value.trim();
    if (selectedPack.isEmpty || selectedPack == 'all') {
      return stickers;
    }
    return stickers.where((item) => item.matchesPack(selectedPack)).toList();
  }

  Future<void> sendSticker(ChatStickerModel sticker) async {
    _ensureCanSendMessage();
    if (isSending.value ||
        (_conversationId == 0 && recipientUserId.value == 0)) {
      return;
    }

    isSending.value = true;
    errorMessage.value = '';
    try {
      final stickerUrl = sticker.resolvedImage;
      if (sticker.id <= 0 && stickerUrl.isEmpty) {
        throw Exception(AppTranslations.chatStickerEmpty.tr);
      }
      await _sendAttachmentMessage(
        stickerId: sticker.id > 0 ? sticker.id : null,
        sticker: stickerUrl.isEmpty ? null : stickerUrl,
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> reactToMessage(
    ChatMessageModel message, {
    required String reaction,
  }) async {
    if (message.id == 0 || reaction.trim().isEmpty) {
      return;
    }

    errorMessage.value = '';
    final shouldUnreact = message.iReact && message.myReactionType == reaction;

    try {
      await _chatService.reactToMessage(
        messageId: message.id,
        reaction: reaction,
        shouldReact: !shouldUnreact,
      );
      _updateMessageReactionState(
        message,
        reaction: reaction,
        shouldReact: !shouldUnreact,
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> deleteMessage(ChatMessageModel message) async {
    if (message.id == 0) {
      return;
    }

    errorMessage.value = '';

    try {
      await _chatService.deleteMessage(messageId: message.id);
      messages.removeWhere((item) => item.id == message.id);
      if (selectedReplyMessage.value?.id == message.id) {
        clearReplySelection();
      }
      if (selectedEditingMessage.value?.id == message.id) {
        clearEditSelection(clearInput: true);
      }
      messages.refresh();
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> editMessage({
    required ChatMessageModel message,
    required String text,
  }) async {
    if (message.id == 0 || text.trim().isEmpty) {
      return;
    }
    errorMessage.value = '';
    try {
      final updated = await _chatService.editMessage(
        messageId: message.id,
        message: text,
      );
      final index = messages.indexWhere((item) => item.id == message.id);
      if (index == -1) {
        return;
      }
      messages[index] = messages[index].copyWith(
        text: updated.text,
        editableText: updated.editableText,
      );
      messages.refresh();
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> _loadReactionTypes() async {
    try {
      final response = await _chatService.fetchReactionTypes();
      if (response.types.isEmpty) {
        reactionTypes.assignAll(_fallbackReactionTypes);
        return;
      }
      reactionTypes.assignAll(response.types);
    } catch (_) {
      reactionTypes.assignAll(_fallbackReactionTypes);
    }
  }

  Future<void> _ensurePhotoPermission() async {
    await _ensureMediaPermission(forVideo: false);
  }

  Future<void> _ensureVideoPermission() async {
    await _ensureMediaPermission(forVideo: true);
  }

  Future<void> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return;
    }
    throw ChatPermissionException(
      type: ChatPermissionType.microphone,
      title: _isArabicLocale
          ? 'صلاحية الميكروفون مطلوبة'
          : 'Microphone permission required',
      message: status.isPermanentlyDenied
          ? (_isArabicLocale
                ? 'تم رفض صلاحية الميكروفون نهائياً. افتح إعدادات التطبيق وفعّل الميكروفون للمتابعة.'
                : 'Microphone permission was permanently denied. Open app settings and enable microphone access to continue.')
          : (_isArabicLocale
                ? 'يجب السماح بالوصول إلى الميكروفون لتسجيل الرسائل الصوتية.'
                : 'Microphone access is required to record voice messages.'),
      canOpenSettings: status.isPermanentlyDenied,
    );
  }

  Future<void> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return;
    }

    final permanentlyDenied = permission == LocationPermission.deniedForever;
    throw ChatPermissionException(
      type: ChatPermissionType.location,
      title: _isArabicLocale
          ? 'صلاحية الموقع مطلوبة'
          : 'Location permission required',
      message: permanentlyDenied
          ? (_isArabicLocale
                ? 'تم رفض صلاحية الموقع نهائياً. افتح إعدادات التطبيق وفعّل الموقع للمتابعة.'
                : 'Location permission was permanently denied. Open app settings and enable location access to continue.')
          : AppTranslations.chatLocationPermissionDenied.tr,
      canOpenSettings: permanentlyDenied,
    );
  }

  Future<void> _ensureMediaPermission({required bool forVideo}) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        return;
      }
      throw ChatPermissionException(
        type: forVideo ? ChatPermissionType.videos : ChatPermissionType.photos,
        title: _isArabicLocale
            ? (forVideo ? 'صلاحية الفيديوهات مطلوبة' : 'صلاحية الصور مطلوبة')
            : (forVideo
                  ? 'Video permission required'
                  : 'Photo permission required'),
        message: status.isPermanentlyDenied
            ? (_isArabicLocale
                  ? 'تم رفض صلاحية معرض الصور نهائياً. افتح إعدادات التطبيق وفعّل الوصول للصور والفيديوهات للمتابعة.'
                  : 'Photo library permission was permanently denied. Open app settings and enable access to photos and videos to continue.')
            : (_isArabicLocale
                  ? 'يجب السماح بالوصول إلى معرض الصور لإرسال الوسائط.'
                  : 'Photo library access is required to send media.'),
        canOpenSettings: status.isPermanentlyDenied || status.isRestricted,
      );
    }

    if (Platform.isAndroid) {
      final primaryPermission = forVideo
          ? Permission.videos
          : Permission.photos;
      final permissions = <Permission>[primaryPermission, Permission.storage];
      var canOpenSettings = false;

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
        canOpenSettings =
            canOpenSettings ||
            requestedStatus.isPermanentlyDenied ||
            requestedStatus.isRestricted;
      }

      throw ChatPermissionException(
        type: forVideo ? ChatPermissionType.videos : ChatPermissionType.photos,
        title: _isArabicLocale
            ? (forVideo ? 'صلاحية الفيديوهات مطلوبة' : 'صلاحية الصور مطلوبة')
            : (forVideo
                  ? 'Video permission required'
                  : 'Photo permission required'),
        message: canOpenSettings
            ? (_isArabicLocale
                  ? 'تم رفض صلاحية الوسائط نهائياً. افتح إعدادات التطبيق وفعّل الوصول للصور أو الفيديوهات للمتابعة.'
                  : 'Media permission was permanently denied. Open app settings and enable access to photos or videos to continue.')
            : (_isArabicLocale
                  ? 'يجب السماح بالوصول إلى الصور أو الفيديوهات لإرسال الوسائط.'
                  : 'Access to photos or videos is required to send media.'),
        canOpenSettings: canOpenSettings,
      );
    }

    throw ChatPermissionException(
      type: forVideo ? ChatPermissionType.videos : ChatPermissionType.photos,
      title: _isArabicLocale
          ? 'صلاحية الوسائط مطلوبة'
          : 'Media permission required',
      message: _isArabicLocale
          ? 'يجب السماح بالوصول إلى الوسائط لإرسال الملفات.'
          : 'Media access is required to send files.',
    );
  }

  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  bool get _isArabicLocale =>
      (Get.locale?.languageCode.toLowerCase() ?? '') == 'ar';

  bool isMyMessage(ChatMessageModel message) {
    return message.userId != 0 &&
        message.userId == (_preferences.getUserId() ?? 0);
  }

  void _applyConversation(
    ChatConversationDetailsModel details, {
    bool applyPresence = true,
  }) {
    final resolvedConversationId = details.conversationId != 0
        ? details.conversationId
        : details.resolvedConversationId;
    if (resolvedConversationId != 0) {
      _conversationId = resolvedConversationId;
    }
    title.value = details.title.isEmpty
        ? initialConversation.title
        : details.title;
    avatarUrl.value = details.avatarUrl.isEmpty
        ? initialConversation.avatarUrl
        : details.avatarUrl;
    isGroupConversation.value = details.isGroupConversation;
    recipientUserId.value = details.userId != 0
        ? details.userId
        : (recipientUserId.value != 0
              ? recipientUserId.value
              : initialConversation.targetUserId);
    nodeId.value = details.nodeId;
    nodeType.value = details.nodeType;
    nodeLink.value = details.link;
    _hasMore = details.hasMore;
    _nextOffset = details.hasMore ? 1 : null;
    isPinned.value = details.isPinned;
    isMuted.value = details.isMuted;
    _applyRelationship(
      isBlocked: details.isBlocked,
      blockedByMe: details.blockedByMe,
      blockedMe: details.blockedMe,
      canSend: details.canSendMessages,
    );
    messages.assignAll(details.messages);
    _prefetchRecentMedia();
    _lastEventCursor = 0;
    _isPollingCursorPrimed = details.messages.isEmpty;
    _applyReadStatus(
      details.readStatus,
      typingNameList: details.typingNameList,
      fallbackSeenNameList: details.seenNameList,
      fallbackIsOnline: details.isOnline,
      fallbackLastSeenAt: details.lastSeenAt,
      fallbackLastSeenAgo: details.lastSeenAgo,
      applyPresence: applyPresence,
    );
  }

  void _ensureCanSendMessage() {
    if (canSendMessages.value) {
      return;
    }
    final message = isBlockedByRecipient.value
        ? AppTranslations.chatBlockedByRecipientBanner.tr
        : AppTranslations.chatBlockedUserCannotMessage.tr;
    errorMessage.value = message;
    throw Exception(message);
  }

  void _applyInitialRelationship() {
    if (initialConversation.targetUserId <= 0) {
      isRecipientBlocked.value = false;
      isBlockedByRecipient.value = false;
      canSendMessages.value = true;
      return;
    }
    isRecipientBlocked.value = initialConversation.blockedByMe;
    isBlockedByRecipient.value = initialConversation.blockedMe;
    canSendMessages.value = initialConversation.canSendMessages;
  }

  void _applyRelationship({
    required bool isBlocked,
    required bool blockedByMe,
    required bool blockedMe,
    required bool canSend,
  }) {
    isRecipientBlocked.value = isBlocked || blockedByMe;
    isBlockedByRecipient.value = blockedMe;
    canSendMessages.value = canSend;
  }

  void _applyMessagesResponse(
    ChatMessagesResponse response, {
    required bool replace,
  }) {
    _hasMore = response.hasMore;
    _nextOffset = response.nextOffset;
    final merged = replace
        ? response.messages
        : <ChatMessageModel>[...response.messages, ...messages];
    messages.assignAll(_dedupeMessages(merged));
    _prefetchRecentMedia();
    _scheduleConversationCacheWrite();
    _applyReadStatus(
      response.readStatus,
      typingNameList: response.typingNameList,
      fallbackSeenNameList: response.seenNameList,
      fallbackIsOnline: response.userIsOnline,
      fallbackLastSeenAt: response.userLastSeen,
      fallbackLastSeenAgo: response.userLastSeenAgo,
    );
  }

  Future<void> _loadLatestMessages({bool forceScroll = false}) async {
    if (_conversationId == 0) {
      await loadConversation();
      return;
    }
    if (_isPolling) {
      return;
    }

    _isPolling = true;
    try {
      final newestLoadedMessageId = _maxLoadedMessageId();
      final oldestLoadedMessageId = _minLoadedMessageId();
      final wasPollingCursorPrimed = _isPollingCursorPrimed;
      final wasNearBottomBeforeFetch = _isNearBottom(threshold: 260);
      final shouldAutoScroll = forceScroll || wasNearBottomBeforeFetch;
      unawaited(
        ChatTraceLogger.log(
          'polling',
          'changes:start cursor=$_lastEventCursor primed=$_isPollingCursorPrimed forceScroll=$forceScroll nearBottomBefore=$wasNearBottomBeforeFetch shouldAutoScroll=$shouldAutoScroll count=${messages.length} first=$oldestLoadedMessageId last=$newestLoadedMessageId',
        ),
      );
      final response = await _chatService.fetchMessageChanges(
        conversationId: _conversationId,
        afterEventId: _lastEventCursor == 0 ? null : _lastEventCursor,
      );
      if (response.nextCursor > _lastEventCursor) {
        _lastEventCursor = response.nextCursor;
      } else {
        unawaited(
          ChatTraceLogger.log(
            'polling',
            'cursorNotAdvanced responseNext=${response.nextCursor} current=$_lastEventCursor',
          ),
        );
      }

      var incomingNewMessages = response.newMessages
          .where((message) => message.id > newestLoadedMessageId)
          .toList();
      final hasOnlyStaleNewMessages =
          response.newMessages.isNotEmpty && incomingNewMessages.isEmpty;
      if (!_isPollingCursorPrimed && messages.isNotEmpty) {
        final reachedCurrentWindow = response.newMessages.any(
          (message) => message.id >= oldestLoadedMessageId,
        );
        if (incomingNewMessages.isNotEmpty ||
            reachedCurrentWindow ||
            !response.hasMore) {
          _isPollingCursorPrimed = true;
        }
      }
      unawaited(
        ChatTraceLogger.log(
          'polling',
          'changes:done nextCursor=${response.nextCursor} primed=$_isPollingCursorPrimed newRaw=${response.newMessages.length} newAccepted=${incomingNewMessages.length} staleNew=${response.newMessages.length - incomingNewMessages.length} updated=${response.updatedMessages.length} deleted=${response.deletedMessageIds.length} count=${messages.length}',
        ),
      );

      if (response.background != null) {
        conversationBackground.value = response.background;
      }
      if (response.readStatus != null) {
        _applyReadStatus(response.readStatus!, applyPresence: false);
      }

      if (response.deletedMessageIds.isNotEmpty) {
        if (selectedReplyMessage.value != null &&
            response.deletedMessageIds.contains(
              selectedReplyMessage.value!.id,
            )) {
          clearReplySelection();
        }
        if (selectedEditingMessage.value != null &&
            response.deletedMessageIds.contains(
              selectedEditingMessage.value!.id,
            )) {
          clearEditSelection(clearInput: true);
        }
        messages.removeWhere(
          (message) => response.deletedMessageIds.contains(message.id),
        );
        _scheduleConversationCacheWrite();
      }
      if (response.updatedMessages.isNotEmpty) {
        for (final updated in response.updatedMessages) {
          final index = messages.indexWhere((item) => item.id == updated.id);
          if (index != -1) {
            messages[index] = _mergeMessages(messages[index], updated);
          }
        }
      }
      if (incomingNewMessages.isNotEmpty) {
        messages.assignAll(
          _dedupeMessages(<ChatMessageModel>[
            ...messages,
            ...incomingNewMessages,
          ]),
        );
        _prefetchRecentMedia();
        _scheduleConversationCacheWrite();
        unawaited(_markVisibleMessagesSeen());
      } else if (response.updatedMessages.isNotEmpty ||
          response.deletedMessageIds.isNotEmpty) {
        messages.refresh();
        _scheduleConversationCacheWrite();
      } else if (forceScroll ||
          !wasPollingCursorPrimed ||
          hasOnlyStaleNewMessages) {
        final fallbackResponse = await _chatService.fetchMessages(
          conversationId: _conversationId,
          lastMessageId: newestLoadedMessageId == 0
              ? null
              : newestLoadedMessageId,
        );
        final fallbackNewMessages = fallbackResponse.messages
            .where((message) => message.id > newestLoadedMessageId)
            .toList();

        if (fallbackNewMessages.isNotEmpty) {
          unawaited(
            ChatTraceLogger.log(
              'polling',
              'fallbackLatest accepted=${fallbackNewMessages.length} newestBefore=$newestLoadedMessageId newestFallback=${fallbackNewMessages.map((message) => message.id).join(',')}',
            ),
          );
          messages.assignAll(
            _dedupeMessages(<ChatMessageModel>[
              ...messages,
              ...fallbackNewMessages,
            ]),
          );
          _prefetchRecentMedia();
          _scheduleConversationCacheWrite();
          _applyReadStatus(
            fallbackResponse.readStatus,
            typingNameList: fallbackResponse.typingNameList,
            fallbackSeenNameList: fallbackResponse.seenNameList,
            fallbackIsOnline: fallbackResponse.userIsOnline,
            fallbackLastSeenAt: fallbackResponse.userLastSeen,
            fallbackLastSeenAgo: fallbackResponse.userLastSeenAgo,
          );
          unawaited(_markVisibleMessagesSeen());
          incomingNewMessages = fallbackNewMessages;
        }
      }

      unawaited(refreshReadStatus(reason: 'polling'));

      if (shouldAutoScroll && incomingNewMessages.isNotEmpty) {
        _scrollToBottom(reason: 'incoming_messages');
      } else if (incomingNewMessages.isNotEmpty) {
        unawaited(
          ChatTraceLogger.log(
            'polling',
            'changes:keepOffset newAccepted=${incomingNewMessages.length} nearBottomBefore=$wasNearBottomBeforeFetch forceScroll=$forceScroll',
          ),
        );
      }
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      _isPolling = false;
    }
  }

  void _advanceEventCursorFromSendResult(ChatSendMessageResult result) {
    final nextCursor = result.nextCursor;
    final eventId = result.eventId;
    final candidateCursor = nextCursor > 0 ? nextCursor : eventId;
    if (candidateCursor <= 0 || candidateCursor <= _lastEventCursor) {
      unawaited(
        ChatTraceLogger.log(
          'polling',
          'sendCursorIgnored eventId=$eventId nextCursor=$nextCursor current=$_lastEventCursor',
        ),
      );
      return;
    }

    final previousCursor = _lastEventCursor;
    _lastEventCursor = candidateCursor;
    _isPollingCursorPrimed = true;
    unawaited(
      ChatTraceLogger.log(
        'polling',
        'sendCursorAdvanced previous=$previousCursor eventId=$eventId nextCursor=$nextCursor current=$_lastEventCursor',
      ),
    );
  }

  List<ChatMessageModel> _dedupeMessages(List<ChatMessageModel> source) {
    final byId = <int, ChatMessageModel>{};
    for (final message in source) {
      final existing = byId[message.id];
      byId[message.id] = existing == null
          ? message
          : _mergeMessages(existing, message);
    }
    final sorted = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }

  ChatMessageModel? _resolveOutgoingAttachmentMessage(
    ChatMessageModel? message, {
    int? stickerId,
    String? stickerUrl,
  }) {
    if (message == null) {
      return null;
    }
    final trimmedStickerUrl = stickerUrl?.trim() ?? '';
    if ((stickerId == null || stickerId == 0) && trimmedStickerUrl.isEmpty) {
      return message;
    }
    if (message.hasSticker) {
      return message;
    }

    final stickerModel = stickers.firstWhereOrNull(
      (item) =>
          (stickerId != null && item.id == stickerId) ||
          (trimmedStickerUrl.isNotEmpty &&
              item.resolvedImage == trimmedStickerUrl),
    );

    return message.copyWith(
      stickerId: stickerId ?? stickerModel?.id ?? message.stickerId,
      stickerUrl: trimmedStickerUrl.isNotEmpty
          ? trimmedStickerUrl
          : stickerModel?.resolvedImage,
      stickerPreviewUrl: stickerModel?.preview,
      stickerPackName: stickerModel?.packSlug.isNotEmpty == true
          ? stickerModel!.packSlug
          : stickerModel?.packName,
      stickerTitle: stickerModel?.displayTitle,
    );
  }

  void _prefetchRecentMedia() {
    final recentVideoUrls = messages.reversed
        .where((message) => message.hasVideo)
        .map((message) => message.videoUrl)
        .toList(growable: false);
    final recentAudioUrls = messages.reversed
        .where((message) => message.hasVoiceNote)
        .map((message) => message.voiceNoteUrl)
        .toList(growable: false);

    if (recentVideoUrls.isNotEmpty) {
      unawaited(VideoCacheWarmer.warmMany(recentVideoUrls, limit: 3));
    }
    if (recentAudioUrls.isNotEmpty) {
      unawaited(AudioCacheWarmer.warmMany(recentAudioUrls, limit: 4));
    }
  }

  ChatMessageModel _mergeMessages(
    ChatMessageModel current,
    ChatMessageModel incoming,
  ) {
    final shouldPreserveSticker = current.hasSticker && !incoming.hasSticker;
    final shouldPreserveImage = current.hasImage && !incoming.hasImage;
    final shouldPreserveVideo = current.hasVideo && !incoming.hasVideo;
    final shouldPreserveVoiceNote =
        current.hasVoiceNote && !incoming.hasVoiceNote;
    final shouldPreserveFile =
        current.hasFileAttachment && !incoming.hasFileAttachment;
    final shouldPreserveProduct = current.hasProduct && !incoming.hasProduct;
    final shouldPreserveSharedItem =
        current.hasSharedItem && !incoming.hasSharedItem;
    final shouldPreserveStoryAction =
        current.hasStoryAction && !incoming.hasStoryAction;
    final shouldPreserveLocation = current.hasLocation && !incoming.hasLocation;
    final shouldPreserveContact = current.hasContact && !incoming.hasContact;
    final shouldPreserveReply =
        current.replyToMessageId != 0 && incoming.replyToMessageId == 0;
    final shouldPreserveForwarded =
        current.forwardedFromMessageId != 0 &&
        incoming.forwardedFromMessageId == 0;

    return incoming.copyWith(
      text: incoming.hasText ? incoming.text : current.text,
      imageUrl: shouldPreserveImage ? current.imageUrl : incoming.imageUrl,
      videoUrl: shouldPreserveVideo ? current.videoUrl : incoming.videoUrl,
      voiceNoteUrl: shouldPreserveVoiceNote
          ? current.voiceNoteUrl
          : incoming.voiceNoteUrl,
      fileAttachment: shouldPreserveFile
          ? current.fileAttachment
          : incoming.fileAttachment,
      location: shouldPreserveLocation ? current.location : incoming.location,
      contact: shouldPreserveContact ? current.contact : incoming.contact,
      stickerId: shouldPreserveSticker ? current.stickerId : incoming.stickerId,
      stickerUrl: shouldPreserveSticker
          ? current.stickerUrl
          : incoming.stickerUrl,
      stickerPreviewUrl: shouldPreserveSticker
          ? current.stickerPreviewUrl
          : incoming.stickerPreviewUrl,
      stickerPackName: shouldPreserveSticker
          ? current.stickerPackName
          : incoming.stickerPackName,
      stickerTitle: shouldPreserveSticker
          ? current.stickerTitle
          : incoming.stickerTitle,
      productPostId: shouldPreserveProduct
          ? current.productPostId
          : incoming.productPostId,
      messageType: _resolveMessageType(current, incoming),
      postId: shouldPreserveSharedItem ? current.postId : incoming.postId,
      reelId: shouldPreserveSharedItem ? current.reelId : incoming.reelId,
      sharedItem: shouldPreserveSharedItem
          ? current.sharedItem
          : incoming.sharedItem,
      storyAction: shouldPreserveStoryAction
          ? current.storyAction
          : incoming.storyAction,
      replyToMessageId: shouldPreserveReply
          ? current.replyToMessageId
          : incoming.replyToMessageId,
      replyToMessage: shouldPreserveReply
          ? current.replyToMessage
          : incoming.replyToMessage,
      forwardedFromMessageId: shouldPreserveForwarded
          ? current.forwardedFromMessageId
          : incoming.forwardedFromMessageId,
      forwardedFromMessage: shouldPreserveForwarded
          ? current.forwardedFromMessage
          : incoming.forwardedFromMessage,
      storyId: shouldPreserveStoryAction ? current.storyId : incoming.storyId,
      storyMediaId: shouldPreserveStoryAction
          ? current.storyMediaId
          : incoming.storyMediaId,
      storyReaction: shouldPreserveStoryAction
          ? current.storyReaction
          : incoming.storyReaction,
      productName: shouldPreserveProduct
          ? current.productName
          : incoming.productName,
      productPrice: shouldPreserveProduct
          ? current.productPrice
          : incoming.productPrice,
      productDescription: shouldPreserveProduct
          ? current.productDescription
          : incoming.productDescription,
      productImageUrl: shouldPreserveProduct
          ? current.productImageUrl
          : incoming.productImageUrl,
      productActionUrl: shouldPreserveProduct
          ? current.productActionUrl
          : incoming.productActionUrl,
    );
  }

  String _resolveMessageType(
    ChatMessageModel current,
    ChatMessageModel incoming,
  ) {
    if (incoming.messageType.trim().isNotEmpty) {
      return incoming.messageType;
    }
    return current.messageType;
  }

  Future<bool> _restoreCachedConversation() async {
    final userId = _preferences.getUserId();
    if ((userId ?? 0) <= 0) {
      return false;
    }

    final cached = await _chatCacheStore.readConversation(
      userId: userId!,
      cacheKey: _conversationCacheKey(
        conversationId: _conversationId,
        targetUserId: recipientUserId.value != 0
            ? recipientUserId.value
            : initialConversation.targetUserId,
      ),
    );
    if (cached == null) {
      return false;
    }

    _applyConversation(cached, applyPresence: false);
    statusLabel.value = '';
    statusIsActive.value = false;
    return true;
  }

  void _scheduleConversationCacheWrite() {
    _cacheWriteDebounce?.cancel();
    _cacheWriteDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persistConversationCache());
    });
  }

  Future<void> _persistConversationCache() async {
    final userId = _preferences.getUserId();
    if ((userId ?? 0) <= 0) {
      return;
    }

    final details = ChatConversationDetailsModel(
      conversationId: _conversationId,
      requestedUserId: recipientUserId.value,
      resolvedConversationId: _conversationId,
      openTokenUsed: false,
      title: title.value,
      avatarUrl: avatarUrl.value,
      userId: recipientUserId.value,
      nodeId: nodeId.value,
      nodeType: nodeType.value,
      link: nodeLink.value,
      isGroupConversation: isGroupConversation.value,
      isOnline: false,
      lastSeenAt: '',
      lastSeenAgo: '',
      typingNameList: '',
      seenNameList: seenNameList.value,
      hasMore: _hasMore,
      messagesCount: messages.length,
      isPinned: isPinned.value,
      isMuted: isMuted.value,
      isBlocked: isRecipientBlocked.value,
      blockedByMe: isRecipientBlocked.value,
      blockedMe: isBlockedByRecipient.value,
      canSendMessages: canSendMessages.value,
      readStatus: ChatReadStatusModel(
        conversationId: _conversationId,
        viewerSeen: false,
        seenNameList: seenNameList.value,
        lastSeenMessageId: _lastSeenMessageId,
        lastMessageId: _maxLoadedMessageId(),
        lastMessageUserId: 0,
        userIsOnline: false,
        userLastSeen: '',
        userLastSeenAgo: '',
        hasUserPresenceSignal: false,
        isBlocked: isRecipientBlocked.value,
        blockedByMe: isRecipientBlocked.value,
        blockedMe: isBlockedByRecipient.value,
        canSendMessages: canSendMessages.value,
      ),
      messages: messages.toList(growable: false),
    );

    final cacheKeys = <String>{
      _conversationCacheKey(
        conversationId: _conversationId,
        targetUserId: recipientUserId.value,
      ),
      _conversationCacheKey(
        conversationId: 0,
        targetUserId: initialConversation.targetUserId,
      ),
    }.where((value) => value.trim().isNotEmpty);

    for (final cacheKey in cacheKeys) {
      await _chatCacheStore.writeConversation(
        userId: userId!,
        cacheKey: cacheKey,
        details: details,
      );
    }
  }

  String _conversationCacheKey({
    required int conversationId,
    required int targetUserId,
  }) {
    if (conversationId > 0) {
      return 'conversation_$conversationId';
    }
    if (targetUserId > 0) {
      return 'target_$targetUserId';
    }
    return '';
  }

  Future<void> setPinned(bool value) async {
    if (_conversationId == 0) {
      return;
    }
    errorMessage.value = '';
    try {
      final preferences = value
          ? await _chatService.pinConversation(conversationId: _conversationId)
          : await _chatService.unpinConversation(
              conversationId: _conversationId,
            );
      isPinned.value = preferences.isPinned;
      _syncHomePreferences();
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> setMuted(bool value) async {
    errorMessage.value = '';
    try {
      final preferences = value
          ? await _chatService.muteConversation(
              conversationId: _conversationId == 0 ? null : _conversationId,
              targetUserId: _conversationId == 0 ? recipientUserId.value : null,
            )
          : await _chatService.unmuteConversation(
              conversationId: _conversationId == 0 ? null : _conversationId,
              targetUserId: _conversationId == 0 ? recipientUserId.value : null,
            );
      isMuted.value = preferences.isMuted;
      if (_conversationId == 0 && preferences.conversationId != 0) {
        _conversationId = preferences.conversationId;
      }
      _syncHomePreferences();
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> loadConversationBackground() async {
    if (_conversationId == 0) {
      conversationBackground.value = null;
      return;
    }
    try {
      final response = await _chatService.fetchConversationBackground(
        conversationId: _conversationId,
      );
      conversationBackground.value = response.background;
    } catch (_) {
      conversationBackground.value = null;
    }
  }

  Future<void> applyConversationBackground(
    ChatBackgroundModel? background,
  ) async {
    if (_conversationId == 0 || isUpdatingBackground.value) {
      return;
    }

    isUpdatingBackground.value = true;
    errorMessage.value = '';
    try {
      final response = await _chatService.saveConversationBackground(
        conversationId: _conversationId,
        backgroundId: background?.id != 0 ? background?.id : null,
        type: background != null && background.id == 0 ? background.type : null,
        value: background != null && background.id == 0
            ? background.value
            : null,
        preview: background != null && background.id == 0
            ? background.preview
            : null,
        reset: background == null,
      );
      conversationBackground.value = background == null
          ? null
          : response.background ?? background;
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isUpdatingBackground.value = false;
    }
  }

  void setConversationBackgroundLocally(ChatBackgroundModel? background) {
    conversationBackground.value = background;
  }

  void setRelationshipLocally({
    required bool blockedByMe,
    required bool blockedMe,
    required bool canSend,
  }) {
    _applyRelationship(
      isBlocked: blockedByMe,
      blockedByMe: blockedByMe,
      blockedMe: blockedMe,
      canSend: canSend,
    );
  }

  void _syncHomePreferences() {
    if (!Get.isRegistered<HomeController>() || _conversationId == 0) {
      return;
    }
    Get.find<HomeController>().updateConversationPreferences(
      conversationId: _conversationId,
      isPinned: isPinned.value,
      isMuted: isMuted.value,
    );
  }

  void _updateMessageReactionState(
    ChatMessageModel sourceMessage, {
    required String reaction,
    required bool shouldReact,
  }) {
    final index = messages.indexWhere((item) => item.id == sourceMessage.id);
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

    String resolvedTopReactionType = '';
    var resolvedTopCount = -1;
    for (final entry in nextCounts.entries) {
      if (entry.value > resolvedTopCount) {
        resolvedTopCount = entry.value;
        resolvedTopReactionType = entry.key;
      }
    }

    var totalCount = 0;
    for (final count in nextCounts.values) {
      totalCount += count;
    }

    messages[index] = current.copyWith(
      reactionCounts: nextCounts,
      reactionsTotalCount: totalCount,
      iReact: shouldReact,
      myReactionType: shouldReact ? reaction : '',
      topReactionType: resolvedTopReactionType,
    );
    messages.refresh();
  }

  void _updateStatus({
    required bool isOnline,
    required String typingNameList,
    required String lastSeenAgo,
  }) {
    statusIsActive.value = isOnline || typingNameList.trim().isNotEmpty;
    statusLabel.value = _buildStatusLabel(
      isOnline: isOnline,
      typingNameList: typingNameList,
      lastSeenAgo: lastSeenAgo,
    );
  }

  void _applyReadStatus(
    ChatReadStatusModel readStatus, {
    String typingNameList = '',
    String? fallbackSeenNameList,
    bool? fallbackIsOnline,
    String? fallbackLastSeenAt,
    String? fallbackLastSeenAgo,
    bool applyPresence = true,
  }) {
    _applyRelationship(
      isBlocked: readStatus.isBlocked,
      blockedByMe: readStatus.blockedByMe,
      blockedMe: readStatus.blockedMe,
      canSend: readStatus.canSendMessages,
    );
    final resolvedSeenNameList = readStatus.seenNameList.trim().isNotEmpty
        ? readStatus.seenNameList
        : (fallbackSeenNameList ?? '');
    seenNameList.value = resolvedSeenNameList;
    _lastSeenMessageId = readStatus.lastSeenMessageId;

    final hasPresenceFallback =
        fallbackIsOnline == true ||
        (fallbackLastSeenAt?.trim().isNotEmpty ?? false) ||
        (fallbackLastSeenAgo?.trim().isNotEmpty ?? false);
    final resolvedTypingNameList = typingNameList.trim();
    final hasPresenceSignal =
        applyPresence &&
        (readStatus.hasUserPresenceSignal || hasPresenceFallback);
    if (resolvedTypingNameList.isNotEmpty) {
      _updateStatus(
        isOnline: false,
        typingNameList: resolvedTypingNameList,
        lastSeenAgo: '',
      );
    } else if (hasPresenceSignal) {
      final resolvedIsOnline = readStatus.hasUserPresenceSignal
          ? readStatus.userIsOnline
          : (fallbackIsOnline ?? false);
      final resolvedLastSeenAgo = readStatus.userLastSeenAgo.trim().isNotEmpty
          ? readStatus.userLastSeenAgo.trim()
          : ((fallbackLastSeenAgo?.trim().isNotEmpty ?? false)
                ? fallbackLastSeenAgo!.trim()
                : '');
      _updateStatus(
        isOnline: resolvedIsOnline,
        typingNameList: '',
        lastSeenAgo: resolvedIsOnline ? '' : resolvedLastSeenAgo,
      );
    } else if (applyPresence) {
      statusLabel.value = '';
      statusIsActive.value = false;
    }
    unawaited(
      ChatTraceLogger.log(
        'status',
        'applied direct=$applyPresence presence=${readStatus.hasUserPresenceSignal} fallback=$hasPresenceFallback typing=$resolvedTypingNameList label=${statusLabel.value}',
      ),
    );
  }

  int? readReceiptMessageIdFor(ChatMessageModel message) {
    if (!isMyMessage(message) || _lastSeenMessageId <= 0) {
      return null;
    }

    var latestSeenOutgoingId = 0;
    for (final item in messages) {
      if (isMyMessage(item) &&
          item.id > latestSeenOutgoingId &&
          item.id <= _lastSeenMessageId) {
        latestSeenOutgoingId = item.id;
      }
    }

    if (latestSeenOutgoingId == 0 || latestSeenOutgoingId != message.id) {
      return null;
    }

    return latestSeenOutgoingId;
  }

  String? readReceiptLabelFor(ChatMessageModel message) {
    if (readReceiptMessageIdFor(message) == null) {
      return null;
    }

    final names = seenNameList.value.trim();
    if (names.isNotEmpty) {
      return '${AppTranslations.chatSeen.tr} • $names';
    }
    return AppTranslations.chatSeen.tr;
  }

  Future<void> refreshReadStatus({String reason = 'manual'}) async {
    if (_conversationId == 0 || _isRefreshingReadStatus) {
      return;
    }

    _isRefreshingReadStatus = true;
    try {
      final response = await _chatService.fetchConversationStatus(
        conversationId: _conversationId,
      );
      _applyReadStatus(response.readStatus);
      unawaited(
        ChatTraceLogger.log(
          'status',
          'refreshed reason=$reason conversationId=$_conversationId label=${statusLabel.value}',
        ),
      );
    } catch (error) {
      unawaited(
        ChatTraceLogger.log(
          'status',
          'refreshFailed reason=$reason conversationId=$_conversationId error=$error',
        ),
      );
    } finally {
      _isRefreshingReadStatus = false;
    }
  }

  String _buildStatusLabel({
    required bool isOnline,
    required String typingNameList,
    required String lastSeenAgo,
  }) {
    if (typingNameList.trim().isNotEmpty) {
      return '${typingNameList.trim()} ${AppTranslations.homeStatusTyping.tr}';
    }
    if (isOnline) {
      return AppTranslations.chatOnlineNow.tr;
    }
    if (lastSeenAgo.trim().isNotEmpty) {
      return lastSeenAgo.trim();
    }
    return '';
  }

  Future<void> _markVisibleMessagesSeen() async {
    if (_conversationId == 0 || messages.isEmpty) {
      return;
    }

    final ids =
        messages
            .where(
              (message) =>
                  !isMyMessage(message) &&
                  message.id > 0 &&
                  message.id > _lastMarkedSeenMessageId,
            )
            .map((message) => message.id)
            .toList()
          ..sort();

    if (ids.isEmpty) {
      return;
    }

    try {
      await _chatService.markConversationSeen(ids: ids);
      _lastMarkedSeenMessageId = ids.last;
    } catch (_) {}
  }

  void _handleScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    if (scrollController.position.pixels > 220) {
      _canTriggerLoadMore = true;
    }

    if (_ignoreScrollPagination ||
        !_canTriggerLoadMore ||
        scrollController.position.maxScrollExtent <= 0 ||
        scrollController.position.userScrollDirection !=
            ScrollDirection.forward) {
      return;
    }

    if (scrollController.position.pixels <= 120) {
      final now = DateTime.now();
      if (_lastScrollTraceAt == null ||
          now.difference(_lastScrollTraceAt!).inMilliseconds >= 200) {
        _lastScrollTraceAt = now;
        unawaited(
          ChatTraceLogger.log(
            'scroll',
            'triggerLoadMore pixels=${scrollController.position.pixels.toStringAsFixed(1)} maxExtent=${scrollController.position.maxScrollExtent.toStringAsFixed(1)} count=${messages.length}',
          ),
        );
      }
      unawaited(loadMoreMessages());
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (!chatPollingEnabled) {
      return;
    }

    if (!isClosed && !isLoading.value && !isSending.value && !_isLoadingMore) {
      unawaited(_loadLatestMessages());
    }

    _pollingTimer = Timer.periodic(chatPollingInterval, (_) {
      if (isClosed || isLoading.value || isSending.value || _isLoadingMore) {
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

  int _minLoadedMessageId() {
    if (messages.isEmpty) {
      return 0;
    }
    var minId = messages.first.id;
    for (final message in messages.skip(1)) {
      if (message.id < minId) {
        minId = message.id;
      }
    }
    return minId;
  }

  int _maxLoadedMessageId() {
    if (messages.isEmpty) {
      return 0;
    }
    var maxId = messages.first.id;
    for (final message in messages.skip(1)) {
      if (message.id > maxId) {
        maxId = message.id;
      }
    }
    return maxId;
  }

  void _restoreScrollOffsetAfterPrepend({
    required double previousPixels,
    required double previousMaxExtent,
  }) {
    _ignoreScrollPagination = true;
    void restoreOffset() {
      if (!scrollController.hasClients) {
        _releaseScrollPaginationLock();
        return;
      }

      final currentMaxExtent = scrollController.position.maxScrollExtent;
      final targetOffset =
          previousPixels + (currentMaxExtent - previousMaxExtent);
      scrollController.jumpTo(targetOffset.clamp(0.0, currentMaxExtent));
      unawaited(
        ChatTraceLogger.log(
          'scroll',
          'restoreAfterPrepend previousPixels=${previousPixels.toStringAsFixed(1)} previousMaxExtent=${previousMaxExtent.toStringAsFixed(1)} currentMaxExtent=${currentMaxExtent.toStringAsFixed(1)} target=${targetOffset.toStringAsFixed(1)} actual=${scrollController.offset.toStringAsFixed(1)}',
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      restoreOffset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        restoreOffset();
        _releaseScrollPaginationLock();
      });
    });
  }

  void _scrollToBottom({String reason = 'internal'}) {
    _ignoreScrollPagination = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        unawaited(
          ChatTraceLogger.log(
            'scroll',
            'scrollToBottom skipped reason=$reason noClients=true',
          ),
        );
        _releaseScrollPaginationLock();
        return;
      }
      final target = scrollController.position.maxScrollExtent;
      final current = scrollController.offset;
      final viewport = scrollController.position.viewportDimension;
      final distance = target - current;
      unawaited(
        ChatTraceLogger.log(
          'scroll',
          'scrollToBottom reason=$reason current=${current.toStringAsFixed(1)} target=${target.toStringAsFixed(1)} distance=${distance.toStringAsFixed(1)} viewport=${viewport.toStringAsFixed(1)} count=${messages.length}',
        ),
      );
      if (distance.abs() <= 1) {
        _releaseScrollPaginationLock();
        return;
      }
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      _releaseScrollPaginationLock();
    });
  }

  void _releaseScrollPaginationLock() {
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!isClosed) {
        _ignoreScrollPagination = false;
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
