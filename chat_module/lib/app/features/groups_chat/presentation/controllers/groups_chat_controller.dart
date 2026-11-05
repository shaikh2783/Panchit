import 'dart:async';

import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../data/models/groups_chat_models.dart';
import '../../data/services/groups_chat_service.dart';
import '../../utils/groups_chat_logger.dart';

class GroupsChatController extends GetxController {
  GroupsChatController(this._groupsChatService, this._preferences);

  final GroupsChatService _groupsChatService;
  final ChatAppPreferences _preferences;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isCreatingGroup = false.obs;
  final isLoadingInvitations = false.obs;
  final errorMessage = ''.obs;
  final invitationsError = ''.obs;
  final groups = <GroupsChatGroupModel>[].obs;
  final pendingInvitations = <GroupsChatInvitationModel>[].obs;
  final pendingInvitationsCount = 0.obs;
  final adminJoinRequestCounts = <int, int>{}.obs;
  final Set<int> _loadedGroupIds = <int>{};
  int? _nextOffset;
  int? _lastRequestedOffset;
  bool _hasMore = false;
  bool _hasLoadedOnce = false;
  bool _isResetLoading = false;
  bool _isLoadingPendingInvitations = false;
  bool _isRefreshingSilently = false;
  bool _isRefreshingJoinRequestCounts = false;
  Timer? _groupsRefreshTimer;

  bool get hasMore => _hasMore;
  bool get hasLoadedOnce => _hasLoadedOnce;
  int get unreadMessagesCount =>
      groups.fold<int>(0, (total, group) => total + group.unreadCount);
  int get pendingJoinRequestsCount => adminJoinRequestCounts.values.fold<int>(
    0,
    (total, count) => total + count,
  );
  int get navbarBadgeCount =>
      unreadMessagesCount +
      pendingInvitationsCount.value +
      pendingJoinRequestsCount;

  int joinRequestsCountFor(int groupId) {
    return adminJoinRequestCounts[groupId] ?? 0;
  }

  void setJoinRequestsCountFor(int groupId, int count) {
    if (groupId <= 0) {
      return;
    }
    if (count <= 0) {
      adminJoinRequestCounts.remove(groupId);
      return;
    }
    adminJoinRequestCounts[groupId] = count;
  }

  @override
  void onInit() {
    super.onInit();
    GroupsChatLogger.log(
      'groups_controller',
      'onInit hasActiveSession=${_preferences.hasActiveSession()}',
    );
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      return;
    }
    load();
  }

  @override
  void onClose() {
    _groupsRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> ensureLoaded({
    bool forceRefresh = false,
    String reason = 'ensureLoaded',
  }) async {
    GroupsChatLogger.log(
      'groups_controller',
      'ensureLoaded reason=$reason force=$forceRefresh loaded=$_hasLoadedOnce total=${groups.length} loading=${isLoading.value} loadingMore=${isLoadingMore.value}',
    );
    if (isLoading.value || isLoadingMore.value) {
      return;
    }
    _startPolling();
    if (_hasLoadedOnce && !forceRefresh) {
      unawaited(loadPendingInvitations(showSpinner: false));
      unawaited(refreshJoinRequestCounts());
      return;
    }
    await load();
  }

  Future<void> load({bool reset = true}) async {
    GroupsChatLogger.log('groups_controller', 'load reset=$reset');
    if (reset && _isResetLoading) {
      GroupsChatLogger.log(
        'groups_controller',
        'load skipped reset already running total=${groups.length}',
      );
      return;
    }

    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      isLoadingMore.value = false;
      _isResetLoading = false;
      errorMessage.value = '';
      invitationsError.value = '';
      groups.clear();
      pendingInvitations.clear();
      pendingInvitationsCount.value = 0;
      adminJoinRequestCounts.clear();
      _loadedGroupIds.clear();
      _nextOffset = null;
      _lastRequestedOffset = null;
      _hasMore = false;
      _hasLoadedOnce = false;
      _groupsRefreshTimer?.cancel();
      return;
    }
    _startPolling();

    if (reset) {
      _isResetLoading = true;
      isLoading.value = groups.isEmpty;
      errorMessage.value = '';
      _nextOffset = null;
      _lastRequestedOffset = null;
      _hasMore = false;
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
      final response = await _groupsChatService.fetchGroups(
        offset: requestedOffset,
      );
      _nextOffset = response.nextOffset;
      _hasMore = response.hasMore;
      final freshItems = reset
          ? response.items
          : response.items.where((item) {
              return _loadedGroupIds.add(item.groupId);
            }).toList();
      if (reset) {
        _loadedGroupIds
          ..clear()
          ..addAll(freshItems.map((item) => item.groupId));
        groups.assignAll(freshItems);
      } else {
        if (freshItems.isNotEmpty) {
          groups.addAll(freshItems);
        } else {
          _hasMore = false;
        }
      }
      _hasLoadedOnce = true;
      if (reset) {
        unawaited(loadPendingInvitations(showSpinner: false));
        unawaited(refreshJoinRequestCounts());
      }
      GroupsChatLogger.log(
        'groups_controller',
        'load success reset=$reset fresh=${freshItems.length} total=${groups.length} hasMore=$_hasMore next=$_nextOffset',
      );
      for (final group in groups) {
        GroupsChatLogger.log(
          'groups_controller',
          'group id=${group.groupId} name="${group.name}" members=${group.memberCount} unread=${group.unreadCount} lastMessage=${group.lastMessage?.messageId ?? '-'}',
        );
      }
    } catch (error) {
      GroupsChatLogger.error('groups_controller.load', error);
      if (reset) {
        if (groups.isEmpty) {
          errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
            error.toString(),
          );
          _loadedGroupIds.clear();
        }
      } else {
        // Release the failed cursor so loadMore can retry this page.
        _lastRequestedOffset = null;
      }
    } finally {
      if (reset) {
        _isResetLoading = false;
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() {
    if (isLoading.value ||
        isLoadingMore.value ||
        !_hasMore ||
        _nextOffset == null ||
        _lastRequestedOffset == _nextOffset) {
      return Future<void>.value();
    }
    return load(reset: false);
  }

  Future<void> refreshSilently() async {
    if (!_preferences.hasActiveSession() ||
        isLoading.value ||
        isLoadingMore.value ||
        isCreatingGroup.value ||
        _isRefreshingSilently) {
      return;
    }

    _isRefreshingSilently = true;
    try {
      final response = await _groupsChatService.fetchGroups(offset: 0);
      final hadMoreLoaded = groups.length > response.items.length;
      final refreshedIds = response.items.map((group) => group.groupId).toSet();
      _mergeRefreshedGroups(response.items, replaceAll: !response.hasMore);
      if (response.hasMore) {
        await _removeDeletedGroupsMissingFromRefresh(refreshedIds);
      }
      if (!hadMoreLoaded) {
        _nextOffset = response.nextOffset;
        _hasMore = response.hasMore;
      } else {
        _hasMore = _hasMore || response.hasMore;
      }
      _hasLoadedOnce = true;
      await Future.wait([
        loadPendingInvitations(showSpinner: false),
        refreshJoinRequestCounts(),
      ]);
    } catch (error, stackTrace) {
      GroupsChatLogger.error(
        'groups_controller.refreshSilently',
        error,
        stackTrace,
      );
    } finally {
      _isRefreshingSilently = false;
    }
  }

  Future<void> loadPendingInvitations({bool showSpinner = true}) async {
    if (!_preferences.hasActiveSession()) {
      pendingInvitations.clear();
      pendingInvitationsCount.value = 0;
      invitationsError.value = '';
      isLoadingInvitations.value = false;
      return;
    }
    if (_isLoadingPendingInvitations) {
      return;
    }

    _isLoadingPendingInvitations = true;
    if (showSpinner) {
      isLoadingInvitations.value = true;
      invitationsError.value = '';
    }

    try {
      final response = await _groupsChatService.fetchPendingInvitations();
      pendingInvitations.assignAll(response.items);
      pendingInvitationsCount.value = response.count > response.items.length
          ? response.count
          : response.items.length;
      invitationsError.value = '';
    } catch (error, stackTrace) {
      invitationsError.value = error.toString();
      GroupsChatLogger.error(
        'groups_controller.loadPendingInvitations',
        error,
        stackTrace,
      );
    } finally {
      _isLoadingPendingInvitations = false;
      isLoadingInvitations.value = false;
    }
  }

  Future<void> refreshJoinRequestCounts() async {
    if (!_preferences.hasActiveSession()) {
      adminJoinRequestCounts.clear();
      return;
    }
    if (_isRefreshingJoinRequestCounts) {
      return;
    }

    final manageableGroups = groups
        .where((group) => group.canManageMembers)
        .toList(growable: false);
    if (manageableGroups.isEmpty) {
      adminJoinRequestCounts.clear();
      return;
    }

    _isRefreshingJoinRequestCounts = true;
    try {
      final entries = await Future.wait(
        manageableGroups.map((group) async {
          try {
            final response = await _groupsChatService.fetchJoinRequests(
              groupId: group.groupId,
            );
            final count = response.count > response.items.length
                ? response.count
                : response.items.length;
            return MapEntry(group.groupId, count);
          } catch (error, stackTrace) {
            GroupsChatLogger.error(
              'groups_controller.joinRequests groupId=${group.groupId}',
              error,
              stackTrace,
            );
            return MapEntry(
              group.groupId,
              adminJoinRequestCounts[group.groupId] ?? 0,
            );
          }
        }),
      );
      adminJoinRequestCounts.assignAll({
        for (final entry in entries)
          if (entry.value > 0) entry.key: entry.value,
      });
    } finally {
      _isRefreshingJoinRequestCounts = false;
    }
  }

  Future<GroupsChatInvitationActionResult> respondInvitation({
    required GroupsChatInvitationModel invitation,
    required bool accept,
  }) async {
    final result = accept
        ? await _groupsChatService.acceptInvitation(
            invitationId: invitation.invitationId,
          )
        : await _groupsChatService.rejectInvitation(
            invitationId: invitation.invitationId,
          );
    pendingInvitations.removeWhere(
      (item) => item.invitationId == invitation.invitationId,
    );
    pendingInvitationsCount.value = pendingInvitationsCount.value > 0
        ? pendingInvitationsCount.value - 1
        : pendingInvitations.length;
    if (accept && result.group != null) {
      upsertGroup(result.group!);
    } else if (accept) {
      unawaited(load());
    }
    return result;
  }

  Future<GroupsChatGroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    GroupsChatLogger.log(
      'groups_controller',
      'createGroup name="${name.trim()}"',
    );
    isCreatingGroup.value = true;
    errorMessage.value = '';
    try {
      final group = await _groupsChatService.createGroup(
        name: name,
        description: description,
      );
      groups.removeWhere((item) => item.groupId == group.groupId);
      groups.insert(0, group);
      _loadedGroupIds.add(group.groupId);
      _hasLoadedOnce = true;
      GroupsChatLogger.log(
        'groups_controller',
        'createGroup success groupId=${group.groupId} total=${groups.length}',
      );
      return group;
    } catch (error) {
      GroupsChatLogger.error('groups_controller.createGroup', error);
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isCreatingGroup.value = false;
    }
  }

  void upsertGroup(GroupsChatGroupModel group) {
    final index = groups.indexWhere((item) => item.groupId == group.groupId);
    if (index == -1) {
      groups.insert(0, group);
      _loadedGroupIds.add(group.groupId);
    } else {
      groups[index] = group;
    }
    _hasLoadedOnce = true;
    unawaited(refreshJoinRequestCounts());
  }

  void removeGroup(int groupId) {
    groups.removeWhere((item) => item.groupId == groupId);
    _loadedGroupIds.remove(groupId);
    adminJoinRequestCounts.remove(groupId);
  }

  Future<void> _removeDeletedGroupsMissingFromRefresh(
    Set<int> refreshedIds,
  ) async {
    final candidates = groups
        .where((group) => !refreshedIds.contains(group.groupId))
        .toList(growable: false);
    if (candidates.isEmpty) {
      return;
    }

    await Future.wait(
      candidates.map((group) async {
        try {
          await _groupsChatService.fetchGroupDetails(groupId: group.groupId);
        } on ApiException catch (error) {
          final message = error.message.toLowerCase();
          if (error.statusCode == 404 || message.contains('group not found')) {
            removeGroup(group.groupId);
          }
        } catch (_) {
          // Keep the local group on transient failures.
        }
      }),
    );
  }

  void _mergeRefreshedGroups(
    List<GroupsChatGroupModel> refreshed, {
    bool replaceAll = false,
  }) {
    if (replaceAll) {
      _loadedGroupIds
        ..clear()
        ..addAll(refreshed.map((group) => group.groupId));
      groups.assignAll(refreshed);
      return;
    }
    if (refreshed.isEmpty && groups.isNotEmpty) {
      return;
    }
    final merged = <int, GroupsChatGroupModel>{};
    for (final group in refreshed) {
      merged[group.groupId] = group;
    }
    for (final group in groups) {
      merged.putIfAbsent(group.groupId, () => group);
    }
    _loadedGroupIds
      ..clear()
      ..addAll(merged.keys);
    groups.assignAll(merged.values.toList(growable: false));
  }

  void _startPolling() {
    if (!_preferences.hasActiveSession()) {
      _groupsRefreshTimer?.cancel();
      _groupsRefreshTimer = null;
      return;
    }
    if (_groupsRefreshTimer != null) {
      return;
    }
    _groupsRefreshTimer = Timer.periodic(chatPollingInterval, (_) {
      unawaited(refreshSilently());
    });
  }
}
