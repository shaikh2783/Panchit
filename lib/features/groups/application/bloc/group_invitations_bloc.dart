import 'package:flutter_bloc/flutter_bloc.dart';
import 'group_invitations_events.dart';
import 'group_invitations_states.dart';
import '../../data/services/group_invitations_service.dart';
import '../../data/models/invitable_friend.dart';
import '../../data/models/sent_invitation.dart';
import '../../data/models/received_invitation.dart';
/// Bloc for managing group invitations
class GroupInvitationsBloc extends Bloc<GroupInvitationsEvent, GroupInvitationsState> {
  final GroupInvitationsService _invitationsService;
  // Internal state for pagination
  final Map<int, List<InvitableFriend>> _invitableFriendsCache = {};
  final Map<int, int> _invitableFriendsOffset = {};
  final Map<int, bool> _hasMoreInvitableFriends = {};
  final Map<int, List<SentInvitation>> _sentInvitationsCache = {};
  final Map<int, int> _sentInvitationsOffset = {};
  final Map<int, bool> _hasMoreSentInvitations = {};
  List<ReceivedInvitation> _receivedInvitationsCache = [];
  int _receivedInvitationsOffset = 0;
  bool _hasMoreReceivedInvitations = true;
  GroupInvitationsBloc(this._invitationsService) : super(const GroupInvitationsInitialState()) {
    on<LoadInvitableFriendsEvent>(_onLoadInvitableFriends);
    on<LoadMoreInvitableFriendsEvent>(_onLoadMoreInvitableFriends);
    on<InviteFriendEvent>(_onInviteFriend);
    on<LoadSentInvitationsEvent>(_onLoadSentInvitations);
    on<LoadMoreSentInvitationsEvent>(_onLoadMoreSentInvitations);
    on<CancelInvitationEvent>(_onCancelInvitation);
    on<LoadReceivedInvitationsEvent>(_onLoadReceivedInvitations);
    on<LoadMoreReceivedInvitationsEvent>(_onLoadMoreReceivedInvitations);
    on<AcceptInvitationEvent>(_onAcceptInvitation);
    on<DeclineInvitationEvent>(_onDeclineInvitation);
    on<RefreshInvitableFriendsEvent>(_onRefreshInvitableFriends);
    on<RefreshSentInvitationsEvent>(_onRefreshSentInvitations);
    on<RefreshReceivedInvitationsEvent>(_onRefreshReceivedInvitations);
  }
  /// Load invitable friends
  Future<void> _onLoadInvitableFriends(
    LoadInvitableFriendsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      // Check if we have cached data and not forcing refresh
      final cache = _invitableFriendsCache[event.groupId] ?? [];
      if (!event.isRefresh && cache.isNotEmpty && event.offset == 0) {
        // Use cached data instead of API call
        emit(InvitableFriendsLoadedState(
          friends: cache,
          groupId: event.groupId,
          hasMore: _hasMoreInvitableFriends[event.groupId] ?? false,
        ));
        return;
      }
      if (event.isRefresh) {
        _invitableFriendsCache[event.groupId] = [];
        _invitableFriendsOffset[event.groupId] = 0;
        _hasMoreInvitableFriends[event.groupId] = true;
      }
      if (cache.isEmpty) {
        emit(const InvitableFriendsLoadingState());
      }
      final friends = await _invitationsService.getInvitableFriends(
        groupId: event.groupId,
        offset: event.offset,
      );
      if (event.isRefresh) {
        _invitableFriendsCache[event.groupId] = friends;
      } else {
        _invitableFriendsCache[event.groupId] = [...cache, ...friends];
      }
      _invitableFriendsOffset[event.groupId] = event.offset + friends.length;
      _hasMoreInvitableFriends[event.groupId] = friends.length >= 20;
      final allFriends = _invitableFriendsCache[event.groupId] ?? [];
      if (allFriends.isEmpty) {
        emit(InvitableFriendsEmptyState(groupId: event.groupId));
      } else {
        emit(InvitableFriendsLoadedState(
          friends: allFriends,
          groupId: event.groupId,
          hasMore: _hasMoreInvitableFriends[event.groupId] ?? false,
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Failed to load friends',
        error: e,
      ));
    }
  }
  /// Load more invitable friends
  Future<void> _onLoadMoreInvitableFriends(
    LoadMoreInvitableFriendsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    final hasMore = _hasMoreInvitableFriends[event.groupId] ?? true;
    if (!hasMore) return;
    final offset = _invitableFriendsOffset[event.groupId] ?? 0;
    add(LoadInvitableFriendsEvent(
      groupId: event.groupId,
      offset: offset,
      isRefresh: false,
    ));
  }
  /// Invite a friend to group
  Future<void> _onInviteFriend(
    InviteFriendEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      emit(const GroupInvitationsLoadingState());
      final success = await _invitationsService.inviteFriend(
        groupId: event.groupId,
        userId: event.userId,
      );
      if (success) {
        // Don't remove from cache, just emit success state
        // UI will handle showing "Invited" status
        emit(InvitationSentState(
          groupId: event.groupId,
          userId: event.userId,
        ));
        // Keep the current list but emit it again to refresh UI
        final friends = _invitableFriendsCache[event.groupId] ?? [];
        if (friends.isEmpty) {
          emit(InvitableFriendsEmptyState(groupId: event.groupId));
        } else {
          emit(InvitableFriendsLoadedState(
            friends: friends,
            groupId: event.groupId,
            hasMore: _hasMoreInvitableFriends[event.groupId] ?? false,
          ));
        }
      } else {
        emit(const GroupInvitationsErrorState(
          message: 'Failed to send invitation',
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Error sending invitation',
        error: e,
      ));
    }
  }
  /// Load sent invitations
  Future<void> _onLoadSentInvitations(
    LoadSentInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      if (event.isRefresh) {
        _sentInvitationsCache[event.groupId] = [];
        _sentInvitationsOffset[event.groupId] = 0;
        _hasMoreSentInvitations[event.groupId] = true;
      }
      final cache = _sentInvitationsCache[event.groupId] ?? [];
      if (cache.isEmpty) {
        emit(const SentInvitationsLoadingState());
      }
      final invitations = await _invitationsService.getSentInvitations(
        groupId: event.groupId,
        offset: event.offset,
        limit: event.limit,
      );
      if (event.isRefresh) {
        _sentInvitationsCache[event.groupId] = invitations;
      } else {
        _sentInvitationsCache[event.groupId] = [...cache, ...invitations];
      }
      _sentInvitationsOffset[event.groupId] = event.offset + invitations.length;
      _hasMoreSentInvitations[event.groupId] = invitations.length >= event.limit;
      final allInvitations = _sentInvitationsCache[event.groupId] ?? [];
      if (allInvitations.isEmpty) {
        emit(SentInvitationsEmptyState(groupId: event.groupId));
      } else {
        emit(SentInvitationsLoadedState(
          invitations: allInvitations,
          groupId: event.groupId,
          hasMore: _hasMoreSentInvitations[event.groupId] ?? false,
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Failed to load sent invitations',
        error: e,
      ));
    }
  }
  /// Load more sent invitations
  Future<void> _onLoadMoreSentInvitations(
    LoadMoreSentInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    final hasMore = _hasMoreSentInvitations[event.groupId] ?? true;
    if (!hasMore) return;
    final offset = _sentInvitationsOffset[event.groupId] ?? 0;
    add(LoadSentInvitationsEvent(
      groupId: event.groupId,
      offset: offset,
      isRefresh: false,
    ));
  }
  /// Cancel invitation
  Future<void> _onCancelInvitation(
    CancelInvitationEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      emit(const GroupInvitationsLoadingState());
      final success = await _invitationsService.cancelInvitation(
        groupId: event.groupId,
        userId: event.userId,
      );
      if (success) {
        // Remove from sent invitations cache
        final invitations = _sentInvitationsCache[event.groupId] ?? [];
        invitations.removeWhere((inv) => inv.userId == event.userId.toString());
        _sentInvitationsCache[event.groupId] = invitations;
        emit(InvitationCancelledState(
          groupId: event.groupId,
          userId: event.userId,
        ));
        // Reload sent invitations
        add(RefreshSentInvitationsEvent(groupId: event.groupId));
      } else {
        emit(const GroupInvitationsErrorState(
          message: 'Failed to cancel invitation',
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Error cancelling invitation',
        error: e,
      ));
    }
  }
  /// Load received invitations
  Future<void> _onLoadReceivedInvitations(
    LoadReceivedInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      if (event.isRefresh) {
        _receivedInvitationsCache = [];
        _receivedInvitationsOffset = 0;
        _hasMoreReceivedInvitations = true;
      }
      if (_receivedInvitationsCache.isEmpty) {
        emit(const ReceivedInvitationsLoadingState());
      }
      final invitations = await _invitationsService.getReceivedInvitations(
        offset: event.offset,
        limit: event.limit,
      );
      if (event.isRefresh) {
        _receivedInvitationsCache = invitations;
      } else {
        _receivedInvitationsCache = [..._receivedInvitationsCache, ...invitations];
      }
      _receivedInvitationsOffset = event.offset + invitations.length;
      _hasMoreReceivedInvitations = invitations.length >= event.limit;
      if (_receivedInvitationsCache.isEmpty) {
        emit(const ReceivedInvitationsEmptyState());
      } else {
        emit(ReceivedInvitationsLoadedState(
          invitations: _receivedInvitationsCache,
          hasMore: _hasMoreReceivedInvitations,
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Failed to load received invitations',
        error: e,
      ));
    }
  }
  /// Load more received invitations
  Future<void> _onLoadMoreReceivedInvitations(
    LoadMoreReceivedInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    if (!_hasMoreReceivedInvitations) return;
    add(LoadReceivedInvitationsEvent(
      offset: _receivedInvitationsOffset,
      isRefresh: false,
    ));
  }
  /// Accept invitation
  Future<void> _onAcceptInvitation(
    AcceptInvitationEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      emit(const GroupInvitationsLoadingState());
      final success = await _invitationsService.acceptInvitation(
        groupId: event.groupId,
      );
      if (success) {
        // Remove from received invitations cache
        _receivedInvitationsCache.removeWhere(
          (inv) => inv.groupId == event.groupId.toString(),
        );
        emit(InvitationAcceptedState(groupId: event.groupId));
        // Reload received invitations
        add(const RefreshReceivedInvitationsEvent());
      } else {
        emit(const GroupInvitationsErrorState(
          message: 'Failed to accept invitation',
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Error accepting invitation',
        error: e,
      ));
    }
  }
  /// Decline invitation
  Future<void> _onDeclineInvitation(
    DeclineInvitationEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    try {
      emit(const GroupInvitationsLoadingState());
      final success = await _invitationsService.declineInvitation(
        groupId: event.groupId,
      );
      if (success) {
        // Remove from received invitations cache
        _receivedInvitationsCache.removeWhere(
          (inv) => inv.groupId == event.groupId.toString(),
        );
        emit(InvitationDeclinedState(groupId: event.groupId));
        // Reload received invitations
        add(const RefreshReceivedInvitationsEvent());
      } else {
        emit(const GroupInvitationsErrorState(
          message: 'Failed to decline invitation',
        ));
      }
    } catch (e) {
      emit(GroupInvitationsErrorState(
        message: 'Error declining invitation',
        error: e,
      ));
    }
  }
  /// Refresh handlers
  Future<void> _onRefreshInvitableFriends(
    RefreshInvitableFriendsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    add(LoadInvitableFriendsEvent(
      groupId: event.groupId,
      isRefresh: true,
    ));
  }
  Future<void> _onRefreshSentInvitations(
    RefreshSentInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    add(LoadSentInvitationsEvent(
      groupId: event.groupId,
      isRefresh: true,
    ));
  }
  Future<void> _onRefreshReceivedInvitations(
    RefreshReceivedInvitationsEvent event,
    Emitter<GroupInvitationsState> emit,
  ) async {
    add(const LoadReceivedInvitationsEvent(isRefresh: true));
  }
  /// Clear cache for a specific group
  void clearGroupCache(int groupId) {
    _invitableFriendsCache.remove(groupId);
    _invitableFriendsOffset.remove(groupId);
    _hasMoreInvitableFriends.remove(groupId);
    _sentInvitationsCache.remove(groupId);
    _sentInvitationsOffset.remove(groupId);
    _hasMoreSentInvitations.remove(groupId);
  }
  /// Clear all caches
  void clearAllCaches() {
    _invitableFriendsCache.clear();
    _invitableFriendsOffset.clear();
    _hasMoreInvitableFriends.clear();
    _sentInvitationsCache.clear();
    _sentInvitationsOffset.clear();
    _hasMoreSentInvitations.clear();
    _receivedInvitationsCache.clear();
    _receivedInvitationsOffset = 0;
    _hasMoreReceivedInvitations = true;
  }
}
