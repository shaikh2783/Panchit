import 'package:equatable/equatable.dart';
import '../../data/models/invitable_friend.dart';
import '../../data/models/sent_invitation.dart';
import '../../data/models/received_invitation.dart';
/// Base state for group invitations
abstract class GroupInvitationsState extends Equatable {
  const GroupInvitationsState();
  @override
  List<Object?> get props => [];
}
/// Initial state
class GroupInvitationsInitialState extends GroupInvitationsState {
  const GroupInvitationsInitialState();
}
/// Loading states
class GroupInvitationsLoadingState extends GroupInvitationsState {
  const GroupInvitationsLoadingState();
}
class InvitableFriendsLoadingState extends GroupInvitationsState {
  const InvitableFriendsLoadingState();
}
class SentInvitationsLoadingState extends GroupInvitationsState {
  const SentInvitationsLoadingState();
}
class ReceivedInvitationsLoadingState extends GroupInvitationsState {
  const ReceivedInvitationsLoadingState();
}
/// Success states
class InvitableFriendsLoadedState extends GroupInvitationsState {
  final List<InvitableFriend> friends;
  final int groupId;
  final bool hasMore;
  const InvitableFriendsLoadedState({
    required this.friends,
    required this.groupId,
    this.hasMore = true,
  });
  @override
  List<Object?> get props => [friends, groupId, hasMore];
}
class SentInvitationsLoadedState extends GroupInvitationsState {
  final List<SentInvitation> invitations;
  final int groupId;
  final bool hasMore;
  const SentInvitationsLoadedState({
    required this.invitations,
    required this.groupId,
    this.hasMore = true,
  });
  @override
  List<Object?> get props => [invitations, groupId, hasMore];
}
class ReceivedInvitationsLoadedState extends GroupInvitationsState {
  final List<ReceivedInvitation> invitations;
  final bool hasMore;
  const ReceivedInvitationsLoadedState({
    required this.invitations,
    this.hasMore = true,
  });
  @override
  List<Object?> get props => [invitations, hasMore];
}
/// Action success states
class InvitationSentState extends GroupInvitationsState {
  final int groupId;
  final int userId;
  final String message;
  const InvitationSentState({
    required this.groupId,
    required this.userId,
    this.message = 'Invitation sent successfully',
  });
  @override
  List<Object?> get props => [groupId, userId, message];
}
class InvitationCancelledState extends GroupInvitationsState {
  final int groupId;
  final int userId;
  final String message;
  const InvitationCancelledState({
    required this.groupId,
    required this.userId,
    this.message = 'Invitation cancelled successfully',
  });
  @override
  List<Object?> get props => [groupId, userId, message];
}
class InvitationAcceptedState extends GroupInvitationsState {
  final int groupId;
  final String message;
  const InvitationAcceptedState({
    required this.groupId,
    this.message = 'You have joined the group successfully',
  });
  @override
  List<Object?> get props => [groupId, message];
}
class InvitationDeclinedState extends GroupInvitationsState {
  final int groupId;
  final String message;
  const InvitationDeclinedState({
    required this.groupId,
    this.message = 'Invitation declined successfully',
  });
  @override
  List<Object?> get props => [groupId, message];
}
/// Error state
class GroupInvitationsErrorState extends GroupInvitationsState {
  final String message;
  final dynamic error;
  const GroupInvitationsErrorState({
    required this.message,
    this.error,
  });
  @override
  List<Object?> get props => [message, error];
}
/// Empty states
class InvitableFriendsEmptyState extends GroupInvitationsState {
  final int groupId;
  const InvitableFriendsEmptyState({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
class SentInvitationsEmptyState extends GroupInvitationsState {
  final int groupId;
  const SentInvitationsEmptyState({required this.groupId});
  @override
  List<Object?> get props => [groupId];
}
class ReceivedInvitationsEmptyState extends GroupInvitationsState {
  const ReceivedInvitationsEmptyState();
}
