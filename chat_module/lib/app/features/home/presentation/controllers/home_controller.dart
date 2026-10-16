import 'dart:async';

import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../chat/data/models/chat_conversations_response.dart';
import '../../../chat/data/services/chat_cache_store.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../groups_chat/presentation/controllers/groups_chat_controller.dart';

class HomeController extends GetxController {
  HomeController(this._chatService, this._preferences, this._chatCacheStore);

  final ChatService _chatService;
  final ChatAppPreferences _preferences;
  final ChatCacheStore _chatCacheStore;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final currentTabIndex = 0.obs;
  final isCreatingConversation = false.obs;
  final backendReady = false.obs;
  final backendMessage = ''.obs;
  final searchErrorMessage = ''.obs;
  final searchQuery = ''.obs;
  final conversations = <ChatConversationModel>[].obs;
  final remoteSearchResults = <ChatConversationModel>[].obs;
  final Set<String> _loadedConversationIds = <String>{};
  final Set<String> _remoteSearchConversationIds = <String>{};
  int? _nextOffset;
  int? _lastRequestedOffset;
  int? _searchNextOffset;
  int? _searchLastRequestedOffset;
  bool _hasMore = false;
  bool _searchHasMore = false;
  int _searchRequestGeneration = 0;
  Timer? _searchDebounce;
  Timer? _conversationsRefreshTimer;

  bool get hasMore => isSearchActive ? _searchHasMore : _hasMore;
  bool get isSearchActive => searchQuery.value.trim().isNotEmpty;

  List<ChatConversationModel> get visibleConversations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return conversations;
    }

    final localMatches = conversations.where((conversation) {
      return _matchesSearchQuery(conversation, query);
    });
    final remoteMatches = remoteSearchResults.where((conversation) {
      return _matchesSearchQuery(conversation, query);
    });

    final merged = <String, ChatConversationModel>{};
    for (final conversation in [...localMatches, ...remoteMatches]) {
      if (conversation.id.isEmpty) {
        continue;
      }
      merged[conversation.id] = conversation;
    }
    return _sortConversations(merged.values.toList());
  }

  void selectTab(int index) {
    currentTabIndex.value = index;
    if (index == 4) {
      _ensureGroupsTabLoaded();
    }
  }

  void _ensureGroupsTabLoaded() {
    if (!Get.isRegistered<GroupsChatController>()) {
      return;
    }
    final groupsController = Get.find<GroupsChatController>();
    final shouldRefresh =
        !groupsController.hasLoadedOnce || groupsController.groups.isEmpty;
    unawaited(
      groupsController.ensureLoaded(
        forceRefresh: shouldRefresh,
        reason: 'tab_select',
      ),
    );
  }

  void updateSearchQuery(String value) {
    final normalized = value.trim();
    if (searchQuery.value == normalized) {
      return;
    }
    _searchRequestGeneration++;
    searchQuery.value = normalized;
    _searchDebounce?.cancel();

    // A changed query owns a completely new pagination stream. Clear the
    // previous stream immediately (rather than waiting for the debounce) so
    // the UI cannot request an old cursor while the new search is pending.
    isSearching.value = false;
    isLoadingMore.value = false;
    searchErrorMessage.value = '';
    remoteSearchResults.clear();
    _remoteSearchConversationIds.clear();
    _searchNextOffset = null;
    _searchLastRequestedOffset = null;
    _searchHasMore = false;

    if (normalized.isEmpty) {
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_loadRemoteSearch(reset: true));
    });
  }

  void clearSearchQuery() {
    if (searchQuery.value.isEmpty) {
      return;
    }
    _searchRequestGeneration++;
    _searchDebounce?.cancel();
    searchQuery.value = '';
    isSearching.value = false;
    isLoadingMore.value = false;
    searchErrorMessage.value = '';
    remoteSearchResults.clear();
    _remoteSearchConversationIds.clear();
    _searchNextOffset = null;
    _searchLastRequestedOffset = null;
    _searchHasMore = false;
  }

  @override
  void onInit() {
    super.onInit();
    _startConversationsRefreshPolling();
  }

  @override
  void onClose() {
    _searchRequestGeneration++;
    _searchDebounce?.cancel();
    _conversationsRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> load({bool reset = true, bool ignoreSearch = false}) async {
    if (!_preferences.hasActiveSession()) {
      _searchRequestGeneration++;
      isLoading.value = false;
      isLoadingMore.value = false;
      isSearching.value = false;
      backendReady.value = false;
      backendMessage.value = '';
      searchErrorMessage.value = '';
      conversations.clear();
      remoteSearchResults.clear();
      _loadedConversationIds.clear();
      _remoteSearchConversationIds.clear();
      _nextOffset = null;
      _lastRequestedOffset = null;
      _searchNextOffset = null;
      _searchLastRequestedOffset = null;
      _hasMore = false;
      _searchHasMore = false;
      return;
    }

    if (!ignoreSearch && isSearchActive) {
      if (reset) {
        await _loadRemoteSearch(reset: true);
      } else {
        await _loadRemoteSearch(reset: false);
      }
      return;
    }

    if (reset) {
      backendMessage.value = '';
      _nextOffset = null;
      _lastRequestedOffset = null;
      _hasMore = false;
      final restoredFromCache = await _restoreCachedConversations();
      if (!restoredFromCache) {
        conversations.clear();
        _loadedConversationIds.clear();
      }
      isLoading.value = !restoredFromCache;
    } else {
      if (isLoading.value ||
          isLoadingMore.value ||
          !_hasMore ||
          _nextOffset == null ||
          _lastRequestedOffset == _nextOffset) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final requestedOffset = reset ? 0 : _nextOffset!;
      _lastRequestedOffset = requestedOffset;
      final result = await _chatService.fetchConversations(
        offset: requestedOffset,
      );
      _nextOffset = result.nextOffset;
      _hasMore = result.hasMore;
      final freshItems = reset
          ? result.conversations
                .where((conversation) => conversation.id.isNotEmpty)
                .toList()
          : result.conversations.where((conversation) {
              return conversation.id.isNotEmpty &&
                  _loadedConversationIds.add(conversation.id);
            }).toList();

      backendReady.value =
          result.implemented && !result.scaffoldOnly && result.hasConversations;
      backendMessage.value = result.message;
      if (reset) {
        _loadedConversationIds
          ..clear()
          ..addAll(
            freshItems
                .map((conversation) => conversation.id)
                .where((id) => id.isNotEmpty),
          );
        conversations.assignAll(_sortConversations(freshItems));
      } else if (freshItems.isNotEmpty) {
        conversations.assignAll(
          _sortConversations([...conversations, ...freshItems]),
        );
      } else {
        _hasMore = false;
      }
      await _persistCachedConversations(result);
    } catch (error) {
      if (reset) {
        if (conversations.isEmpty) {
          backendReady.value = false;
          backendMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
            error.toString(),
          );
          _loadedConversationIds.clear();
        }
      } else {
        // A transient failure must not permanently lock this offset. Keeping
        // it as the last requested value would make every retry return early.
        _lastRequestedOffset = null;
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

  Future<void> refreshConversationsSilently() async {
    if (!_preferences.hasActiveSession() ||
        isLoading.value ||
        isLoadingMore.value ||
        isSearching.value ||
        isSearchActive ||
        isCreatingConversation.value ||
        currentTabIndex.value != 0) {
      return;
    }

    try {
      final result = await _chatService.fetchConversations(offset: 0);
      final freshItems = result.conversations
          .where((conversation) => conversation.id.isNotEmpty)
          .toList();
      final mergedItems = _mergeRefreshedConversations(
        current: conversations,
        refreshed: freshItems,
      );

      _loadedConversationIds
        ..clear()
        ..addAll(
          mergedItems
              .map((conversation) => conversation.id)
              .where((id) => id.isNotEmpty),
        );

      conversations.assignAll(_sortConversations(mergedItems));
      backendReady.value =
          result.implemented && !result.scaffoldOnly && result.hasConversations;
      backendMessage.value = result.message;
      _nextOffset = result.nextOffset;
      _lastRequestedOffset = null;
      _hasMore = result.hasMore;
      await _persistCachedConversations(result);
    } catch (_) {
      // Keep the existing list visible if a silent refresh fails.
    }
  }

  Future<ChatConversationModel?> startConversation({
    required int recipientId,
    required String message,
  }) async {
    isCreatingConversation.value = true;
    try {
      final result = await _chatService.sendMessage(
        recipients: [recipientId],
        message: message,
      );
      currentTabIndex.value = 0;
      await load(ignoreSearch: true);
      final createdConversationId = result.conversationId.toString();
      for (final conversation in conversations) {
        if (conversation.id == createdConversationId) {
          return conversation;
        }
      }
      if (result.conversationId != 0) {
        return ChatConversationModel(
          id: createdConversationId,
          title: '',
          preview: result.lastMessage?.previewText ?? message,
          timeLabel: result.lastMessage?.timeLabel ?? '',
          avatarUrl: '',
          isOnline: false,
          isTyping: false,
          unreadCount: 0,
          isSeen: true,
          isPinned: false,
          isMuted: false,
          targetUserId: recipientId,
        );
      }
      return null;
    } finally {
      isCreatingConversation.value = false;
    }
  }

  void removeConversationById(int conversationId) {
    final id = conversationId.toString();
    conversations.removeWhere((conversation) => conversation.id == id);
    backendReady.value = conversations.isNotEmpty;
  }

  void updateConversationPreferences({
    required int conversationId,
    bool? isPinned,
    bool? isMuted,
  }) {
    final index = conversations.indexWhere(
      (conversation) => conversation.id == conversationId.toString(),
    );
    if (index == -1) {
      return;
    }
    conversations[index] = conversations[index].copyWith(
      isPinned: isPinned,
      isMuted: isMuted,
    );
    conversations.assignAll(_sortConversations(conversations.toList()));
  }

  Future<void> togglePinnedConversation({required int conversationId}) async {
    final index = conversations.indexWhere(
      (conversation) => conversation.id == conversationId.toString(),
    );
    if (index == -1) {
      return;
    }

    final conversation = conversations[index];
    final preferences = conversation.isPinned
        ? await _chatService.unpinConversation(conversationId: conversationId)
        : await _chatService.pinConversation(conversationId: conversationId);

    updateConversationPreferences(
      conversationId: conversationId,
      isPinned: preferences.isPinned,
      isMuted: preferences.isMuted,
    );
  }

  Future<void> deleteConversation({required int conversationId}) async {
    await _chatService.deleteConversation(conversationId: conversationId);
    removeConversationById(conversationId);
  }

  List<ChatConversationModel> _sortConversations(
    List<ChatConversationModel> source,
  ) {
    final items = [...source];
    items.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return 0;
    });
    return items;
  }

  Future<void> _loadRemoteSearch({required bool reset}) async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      isSearching.value = false;
      searchErrorMessage.value = '';
      remoteSearchResults.clear();
      _remoteSearchConversationIds.clear();
      _searchNextOffset = null;
      _searchLastRequestedOffset = null;
      _searchHasMore = false;
      return;
    }

    final requestGeneration = reset
        ? ++_searchRequestGeneration
        : _searchRequestGeneration;

    if (reset) {
      isSearching.value = true;
      // A reset can supersede an in-flight load-more request for the same
      // query. Its stale finally block is generation-guarded, so release the
      // shared loading-more state here to avoid leaving pagination locked.
      isLoadingMore.value = false;
      searchErrorMessage.value = '';
      _searchNextOffset = null;
      _searchLastRequestedOffset = null;
      _searchHasMore = false;
      _remoteSearchConversationIds.clear();
      remoteSearchResults.clear();
    } else {
      if (isLoading.value ||
          isLoadingMore.value ||
          !_searchHasMore ||
          _searchNextOffset == null ||
          _searchLastRequestedOffset == _searchNextOffset) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final requestedOffset = reset ? 0 : _searchNextOffset!;
      _searchLastRequestedOffset = requestedOffset;
      final result = await _chatService.fetchConversations(
        offset: requestedOffset,
        query: query,
      );

      if (!_isCurrentSearchRequest(requestGeneration, query)) {
        return;
      }

      _searchNextOffset = result.nextOffset;
      _searchHasMore = result.hasMore;
      final freshItems = result.conversations.where((conversation) {
        return conversation.id.isNotEmpty &&
            _remoteSearchConversationIds.add(conversation.id);
      }).toList();

      if (reset) {
        remoteSearchResults.assignAll(_sortConversations(freshItems));
      } else if (freshItems.isNotEmpty) {
        remoteSearchResults.assignAll(
          _sortConversations([...remoteSearchResults, ...freshItems]),
        );
      } else {
        _searchHasMore = false;
      }
    } catch (error) {
      if (!_isCurrentSearchRequest(requestGeneration, query)) {
        return;
      }
      if (reset) {
        searchErrorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
          error.toString(),
        );
        remoteSearchResults.clear();
        _remoteSearchConversationIds.clear();
        _searchNextOffset = null;
        _searchLastRequestedOffset = null;
        _searchHasMore = false;
      } else {
        // Preserve the existing results and pagination cursor, but release
        // the failed offset so scrolling (or an explicit retry) can request it
        // again.
        _searchLastRequestedOffset = null;
      }
    } finally {
      if (_isCurrentSearchRequest(requestGeneration, query)) {
        if (reset) {
          isSearching.value = false;
        } else {
          isLoadingMore.value = false;
        }
      }
    }
  }

  bool _isCurrentSearchRequest(int generation, String query) {
    return generation == _searchRequestGeneration &&
        query == searchQuery.value.trim();
  }

  bool _matchesSearchQuery(ChatConversationModel conversation, String query) {
    final title = conversation.title.toLowerCase();
    final preview = conversation.preview.toLowerCase();
    return title.contains(query) || preview.contains(query);
  }

  Future<bool> _restoreCachedConversations() async {
    final userId = _preferences.getUserId();
    if ((userId ?? 0) <= 0) {
      return false;
    }
    final cached = await _chatCacheStore.readConversations(userId: userId!);
    if (cached == null || cached.conversations.isEmpty) {
      return false;
    }

    _loadedConversationIds
      ..clear()
      ..addAll(
        cached.conversations
            .map((conversation) => conversation.id)
            .where((id) => id.isNotEmpty),
      );
    conversations.assignAll(_sortConversations(cached.conversations));
    backendReady.value =
        cached.implemented && !cached.scaffoldOnly && cached.hasConversations;
    backendMessage.value = cached.message;
    _nextOffset = cached.nextOffset;
    _lastRequestedOffset = null;
    _hasMore = cached.hasMore;
    return true;
  }

  Future<void> _persistCachedConversations(
    ChatConversationsResponse response,
  ) async {
    final userId = _preferences.getUserId();
    if ((userId ?? 0) <= 0) {
      return;
    }
    final cachePayload = ChatConversationsResponse(
      implemented: response.implemented,
      scaffoldOnly: response.scaffoldOnly,
      message: response.message,
      endpoint: response.endpoint,
      conversations: conversations.toList(growable: false),
      count: conversations.length,
      offset: 0,
      nextOffset: _nextOffset,
      hasMore: _hasMore,
    );
    await _chatCacheStore.writeConversations(
      userId: userId!,
      response: cachePayload,
    );
  }

  List<ChatConversationModel> _mergeRefreshedConversations({
    required List<ChatConversationModel> current,
    required List<ChatConversationModel> refreshed,
  }) {
    if (current.isEmpty) {
      return refreshed;
    }

    final merged = <String, ChatConversationModel>{};
    for (final conversation in refreshed) {
      merged[conversation.id] = conversation;
    }
    for (final conversation in current) {
      merged.putIfAbsent(conversation.id, () => conversation);
    }
    return merged.values.toList(growable: false);
  }

  void _startConversationsRefreshPolling() {
    _conversationsRefreshTimer?.cancel();
    _conversationsRefreshTimer = Timer.periodic(chatPollingInterval, (_) {
      unawaited(refreshConversationsSilently());
    });
  }
}
