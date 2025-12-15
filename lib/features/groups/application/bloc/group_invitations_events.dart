import 'package:equatable/equatable.dart';
/// Base event for group invitations
abstract class GroupInvitationsEvent extends Equatable {
  const GroupInvitationsEvent();
  @override
  List<Object?> get props => [];
}
/// Load invitable friends for a group
class LoadInvitableFriendsEvent extends GroupInvitationsEvent {
  final int groupId;
  final int offset;
  final bool isRefresh;
  const LoadInvitableFriendsEvent({
    required this.groupId,
    this.offset = 0,
    this.isRefresh = false,
  });
  @override
  List<Object?> get props => [groupId, offset, isRefresh];
}
/// Load more invitable friends
class LoadMoreInvitableFriendsEvent extends GroupInvitationsEvent {
  final int groupId;
  const LoadMoreInvitableFriendsEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Invite a friend to group
class InviteFriendEvent extends GroupInvitationsEvent {
  final int groupId;
  final int userId;
  const InviteFriendEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object?> get props => [groupId, userId];
}
/// Load sent invitations for a group
class LoadSentInvitationsEvent extends GroupInvitationsEvent {
  final int groupId;
  final int offset;
  final int limit;
  final bool isRefresh;
  const LoadSentInvitationsEvent({
    required this.groupId,
    this.offset = 0,
    this.limit = 20,
    this.isRefresh = false,
  });
  @override
  List<Object?> get props => [groupId, offset, limit, isRefresh];
}
/// Load more sent invitations
class LoadMoreSentInvitationsEvent extends GroupInvitationsEvent {
  final int groupId;
  const LoadMoreSentInvitationsEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Cancel an invitation
class CancelInvitationEvent extends GroupInvitationsEvent {
  final int groupId;
  final int userId;
  const CancelInvitationEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object?> get props => [groupId, userId];
}
/// Load received invitations for current user
class LoadReceivedInvitationsEvent extends GroupInvitationsEvent {
  final int offset;
  final int limit;
  final bool isRefresh;
  const LoadReceivedInvitationsEvent({
    this.offset = 0,
    this.limit = 20,
    this.isRefresh = false,
  });
  @override
  List<Object?> get props => [offset, limit, isRefresh];
}
/// Load more received invitations
class LoadMoreReceivedInvitationsEvent extends GroupInvitationsEvent {
  const LoadMoreReceivedInvitationsEvent();
}
/// Accept a group invitation
class AcceptInvitationEvent extends GroupInvitationsEvent {
  final int groupId;
  const AcceptInvitationEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Decline a group invitation
class DeclineInvitationEvent extends GroupInvitationsEvent {
  final int groupId;
  const DeclineInvitationEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Refresh invitable friends
class RefreshInvitableFriendsEvent extends GroupInvitationsEvent {
  final int groupId;
  const RefreshInvitableFriendsEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Refresh sent invitations
class RefreshSentInvitationsEvent extends GroupInvitationsEvent {
  final int groupId;
  const RefreshSentInvitationsEvent({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
/// Refresh received invitations
class RefreshReceivedInvitationsEvent extends GroupInvitationsEvent {
  const RefreshReceivedInvitationsEvent();
}
