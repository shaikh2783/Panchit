import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/timeline_launcher.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../settings/data/services/blocked_users_service.dart';
import '../../data/models/chat_backgrounds_response.dart';
import '../../data/models/chat_report_models.dart';
import '../../data/models/chat_shared_content.dart';
import '../../data/services/chat_service.dart';
import 'chat_conversation_controller.dart';
import '../pages/shared_media_viewer_page.dart';

class ConversationDetailsController extends GetxController {
  ConversationDetailsController({
    required ChatService chatService,
    required this.conversationId,
    required this.titleText,
    required this.avatar,
    required this.targetUserId,
    required this.nodeId,
    required this.nodeType,
    required this.nodeLink,
    required this.isDirectConversation,
    required this.initialIsPinned,
    required this.initialIsMuted,
    required this.initialBlockedByMe,
    required this.initialBlockedByRecipient,
    this.chatControllerTag,
  }) : _chatService = chatService;

  final ChatService _chatService;
  final int conversationId;
  final String titleText;
  final String avatar;
  final int targetUserId;
  final int nodeId;
  final String nodeType;
  final String nodeLink;
  final bool isDirectConversation;
  final bool initialIsPinned;
  final bool initialIsMuted;
  final bool initialBlockedByMe;
  final bool initialBlockedByRecipient;
  final String? chatControllerTag;
  final isPinned = false.obs;
  final isMuted = false.obs;
  final isBlockedByMe = false.obs;
  final isBlockedByRecipient = false.obs;
  final isLoadingBackgrounds = false.obs;
  final isSavingBackground = false.obs;
  final isBlockingUser = false.obs;
  final isLoadingReportCategories = false.obs;
  final isSubmittingReport = false.obs;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isDeleting = false.obs;
  final errorMessage = ''.obs;
  final selectedType = 'all'.obs;
  final items = <ChatSharedItemModel>[].obs;
  final counts = const ChatSharedCountsModel(
    images: 0,
    videos: 0,
    audio: 0,
    files: 0,
    links: 0,
  ).obs;
  final availableBackgrounds = <ChatBackgroundModel>[].obs;
  final conversationBackground = Rxn<ChatBackgroundModel>();

  int? _nextOffset;
  bool _hasMore = false;
  final Set<int> _loadedIds = <int>{};

  List<ChatSharedItemModel> get visibleItems {
    final type = selectedType.value;
    if (type == 'all') {
      return items;
    }
    return items.where((item) => item.type == type).toList();
  }

  Future<void> selectType(String type) async {
    if (selectedType.value == type) {
      return;
    }
    selectedType.value = type;
    await _loadUntilSelectedTypeIsVisible();
  }

  Future<void> _loadUntilSelectedTypeIsVisible() async {
    if (selectedType.value == 'all' || visibleItems.isNotEmpty) {
      return;
    }
    while (_hasMore && visibleItems.isEmpty) {
      final previousOffset = _nextOffset;
      await loadMore();
      if (_nextOffset == previousOffset) {
        break;
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    isPinned.value = initialIsPinned;
    isMuted.value = initialIsMuted;
    isBlockedByMe.value = initialBlockedByMe;
    isBlockedByRecipient.value = initialBlockedByRecipient;
    load();
    unawaited(loadConversationBackground());
  }

  Future<void> load({bool reset = true}) async {
    if (conversationId == 0) {
      isLoading.value = false;
      return;
    }

    if (reset) {
      isLoading.value = true;
      errorMessage.value = '';
      items.clear();
      _loadedIds.clear();
      _nextOffset = null;
      _hasMore = false;
    } else {
      if (isLoading.value || isLoadingMore.value || !_hasMore) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final response = await _chatService.fetchSharedContent(
        conversationId: conversationId,
        offset: reset ? 0 : _nextOffset,
      );
      counts.value = response.counts;
      _nextOffset = response.nextOffset;
      _hasMore = response.hasMore;
      final freshItems = response.items.where((item) {
        return _loadedIds.add(item.id);
      }).toList();
      if (reset) {
        items.assignAll(freshItems);
      } else if (freshItems.isNotEmpty) {
        items.addAll(freshItems);
      } else {
        _hasMore = false;
      }
    } catch (error) {
      if (reset) {
        errorMessage.value = error.toString();
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
    return load(reset: false);
  }

  Future<void> openSharedItem(ChatSharedItemModel item) async {
    final context = Get.context ?? Get.overlayContext;
    if (item.isPost) {
      if (context == null) {
        return;
      }
      await TimelineLauncher.openPost(context, postId: item.postId);
      return;
    }
    if (item.isReel) {
      if (context == null) {
        return;
      }
      await TimelineLauncher.openReel(
        context,
        postId: item.postId > 0 ? item.postId : null,
        reelId: item.reelId > 0 ? item.reelId : null,
      );
      return;
    }
    final target = item.bestUrl;
    if (target.isEmpty) {
      return;
    }

    if (item.isImage || item.isVideo || item.isAudio) {
      await Get.to<void>(
        () => SharedMediaViewerPage(
          item: item,
          title: titleText.isEmpty
              ? AppTranslations.chatInfoSharedMedia.tr
              : titleText,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(target);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool get canOpenTimelineTarget {
    final normalizedNodeType = nodeType.trim().toLowerCase();
    if (normalizedNodeType == 'user') {
      return targetUserId > 0;
    }
    if (normalizedNodeType == 'event' ||
        normalizedNodeType == 'group' ||
        normalizedNodeType == 'page') {
      return nodeId > 0 || nodeLink.trim().isNotEmpty;
    }
    return isDirectConversation && targetUserId > 0;
  }

  Future<void> openTimelineTarget() async {
    final context = Get.context ?? Get.overlayContext;
    if (context == null) {
      return;
    }
    final normalizedNodeType = nodeType.trim().toLowerCase();
    if (normalizedNodeType == 'event' ||
        normalizedNodeType == 'group' ||
        normalizedNodeType == 'page') {
      await TimelineLauncher.openNode(
        context,
        nodeType: normalizedNodeType,
        nodeId: nodeId > 0 ? nodeId : null,
        nodeLink: nodeLink,
      );
      return;
    }

    final resolvedUserId = targetUserId > 0 ? targetUserId : nodeId;
    if (resolvedUserId <= 0) {
      return;
    }
    await TimelineLauncher.openUser(context, userId: resolvedUserId);
  }

  Future<bool> deleteConversation() async {
    if (conversationId == 0 || isDeleting.value) {
      return false;
    }
    isDeleting.value = true;
    try {
      await _chatService.deleteConversation(conversationId: conversationId);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> setPinned(bool value) async {
    errorMessage.value = '';
    try {
      final preferences = value
          ? await _chatService.pinConversation(conversationId: conversationId)
          : await _chatService.unpinConversation(
              conversationId: conversationId,
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
          ? await _chatService.muteConversation(conversationId: conversationId)
          : await _chatService.unmuteConversation(
              conversationId: conversationId,
            );
      isMuted.value = preferences.isMuted;
      _syncHomePreferences();
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> loadBackgroundOptions({bool force = false}) async {
    if (isLoadingBackgrounds.value) {
      return;
    }
    if (!force && availableBackgrounds.isNotEmpty) {
      return;
    }
    isLoadingBackgrounds.value = true;
    try {
      final response = await _chatService.fetchChatBackgrounds();
      final ordered = response.items.isNotEmpty
          ? response.items
          : <ChatBackgroundModel>[
              ...response.colors,
              ...response.presets,
              ...response.images,
            ];
      availableBackgrounds.assignAll(ordered);
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isLoadingBackgrounds.value = false;
    }
  }

  Future<void> loadConversationBackground() async {
    if (conversationId == 0) {
      conversationBackground.value = null;
      return;
    }
    try {
      final response = await _chatService.fetchConversationBackground(
        conversationId: conversationId,
      );
      conversationBackground.value = response.background;
    } catch (_) {
      conversationBackground.value = null;
    }
  }

  Future<void> applyConversationBackground(
    ChatBackgroundModel? background,
  ) async {
    if (conversationId == 0 || isSavingBackground.value) {
      return;
    }

    isSavingBackground.value = true;
    errorMessage.value = '';
    try {
      final response = await _chatService.saveConversationBackground(
        conversationId: conversationId,
        backgroundId: background != null && background.id != 0
            ? background.id
            : null,
        type: background != null && background.id == 0 ? background.type : null,
        value: background != null && background.id == 0
            ? background.value
            : null,
        preview: background != null && background.id == 0
            ? background.preview
            : null,
        reset: background == null,
      );
      final appliedBackground = background == null
          ? null
          : response.background ?? background;
      conversationBackground.value = appliedBackground;
      _syncChatBackground(appliedBackground);
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSavingBackground.value = false;
    }
  }

  List<ChatBackgroundModel> get colorBackgrounds =>
      availableBackgrounds.where((item) => item.isColor).toList();

  List<ChatBackgroundModel> get gradientBackgrounds =>
      _gradientBackgroundOptions;

  List<ChatBackgroundModel> get imageBackgrounds => availableBackgrounds
      .where((item) => !item.isColor && !item.isGradient)
      .toList();

  String get backgroundSummary {
    final selected = resolvedConversationBackground;
    if (selected == null) {
      return 'Default background';
    }
    if (selected.title.trim().isNotEmpty) {
      return selected.title;
    }
    if (selected.isColor) {
      return 'Custom color';
    }
    return 'Selected background';
  }

  Future<String> toggleBlockCurrentUser() async {
    if (!isDirectConversation || targetUserId <= 0 || isBlockingUser.value) {
      return '';
    }

    isBlockingUser.value = true;
    errorMessage.value = '';
    try {
      final service = Get.find<BlockedUsersService>();
      if (isBlockedByMe.value) {
        final message = await service.unblockUser(userId: targetUserId);
        isBlockedByMe.value = false;
        _syncChatRelationship();
        return message;
      }
      final message = await service.blockUser(userId: targetUserId);
      isBlockedByMe.value = true;
      _syncChatRelationship();
      return message;
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isBlockingUser.value = false;
    }
  }

  Future<List<ChatReportCategoryModel>> fetchReportCategories() async {
    if (!isDirectConversation || targetUserId <= 0) {
      return const <ChatReportCategoryModel>[];
    }
    isLoadingReportCategories.value = true;
    errorMessage.value = '';
    try {
      final response = await _chatService.fetchUserReportCategories();
      return response.items;
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isLoadingReportCategories.value = false;
    }
  }

  Future<String> reportCurrentUser({
    required int categoryId,
    String? reason,
  }) async {
    if (!isDirectConversation ||
        targetUserId <= 0 ||
        isSubmittingReport.value) {
      return '';
    }

    isSubmittingReport.value = true;
    errorMessage.value = '';
    try {
      return await _chatService.reportUser(
        userId: targetUserId,
        categoryId: categoryId,
        reason: reason,
      );
    } catch (error) {
      errorMessage.value = error.toString();
      rethrow;
    } finally {
      isSubmittingReport.value = false;
    }
  }

  ChatBackgroundModel? get resolvedConversationBackground {
    final current = conversationBackground.value;
    if (current == null) {
      return null;
    }
    for (final item in <ChatBackgroundModel>[
      ...availableBackgrounds,
      ...gradientBackgrounds,
    ]) {
      if (item.id == current.id &&
          item.type == current.type &&
          item.value == current.value) {
        return item;
      }
    }
    return current;
  }

  void _syncHomePreferences() {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }
    Get.find<HomeController>().updateConversationPreferences(
      conversationId: conversationId,
      isPinned: isPinned.value,
      isMuted: isMuted.value,
    );
  }

  void _syncChatBackground(ChatBackgroundModel? background) {
    final tag = chatControllerTag;
    if (tag == null ||
        !Get.isRegistered<ChatConversationController>(tag: tag)) {
      return;
    }
    Get.find<ChatConversationController>(
      tag: tag,
    ).setConversationBackgroundLocally(background);
  }

  void _syncChatRelationship() {
    final tag = chatControllerTag;
    if (tag == null ||
        !Get.isRegistered<ChatConversationController>(tag: tag)) {
      return;
    }
    Get.find<ChatConversationController>(tag: tag).setRelationshipLocally(
      blockedByMe: isBlockedByMe.value,
      blockedMe: isBlockedByRecipient.value,
      canSend: !isBlockedByMe.value && !isBlockedByRecipient.value,
    );
  }

  String labelForType(String type) {
    switch (type) {
      case 'image':
        return AppTranslations.chatInfoImages.tr;
      case 'video':
        return AppTranslations.chatInfoVideos.tr;
      case 'audio':
        return AppTranslations.chatInfoAudio.tr;
      case 'file':
        return AppTranslations.chatInfoFiles.tr;
      case 'link':
        return AppTranslations.chatInfoLinks.tr;
      default:
        return AppTranslations.chatInfoAll.tr;
    }
  }
}

final List<ChatBackgroundModel> _gradientBackgroundOptions =
    <ChatBackgroundModel>[
      const ChatBackgroundModel(
        id: 0,
        title: 'Blue Horizon',
        type: 'gradient',
        value: '#3063F7|#6ED0FF',
        preview: '#3063F7|#6ED0FF',
        isActive: true,
        sortOrder: 1000,
        createdAt: '',
        updatedAt: '',
      ),
      const ChatBackgroundModel(
        id: 0,
        title: 'Rose Sunset',
        type: 'gradient',
        value: '#FB7185|#FDBA74',
        preview: '#FB7185|#FDBA74',
        isActive: true,
        sortOrder: 1001,
        createdAt: '',
        updatedAt: '',
      ),
      const ChatBackgroundModel(
        id: 0,
        title: 'Emerald Night',
        type: 'gradient',
        value: '#0F766E|#111827',
        preview: '#0F766E|#111827',
        isActive: true,
        sortOrder: 1002,
        createdAt: '',
        updatedAt: '',
      ),
      const ChatBackgroundModel(
        id: 0,
        title: 'Royal Velvet',
        type: 'gradient',
        value: '#7C3AED|#EC4899',
        preview: '#7C3AED|#EC4899',
        isActive: true,
        sortOrder: 1003,
        createdAt: '',
        updatedAt: '',
      ),
      const ChatBackgroundModel(
        id: 0,
        title: 'Graphite Glow',
        type: 'gradient',
        value: '#111827|#475569',
        preview: '#111827|#475569',
        isActive: true,
        sortOrder: 1004,
        createdAt: '',
        updatedAt: '',
      ),
    ];
