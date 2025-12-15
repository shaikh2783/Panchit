import 'package:equatable/equatable.dart';
import '../../data/models/group.dart';
/// Base class for all Groups states
abstract class GroupsState extends Equatable {
  const GroupsState();
  @override
  List<Object?> get props => [];
}
/// Initial state
class GroupsInitialState extends GroupsState {
  const GroupsInitialState();
}
/// Loading states
class GroupsLoadingState extends GroupsState {
  const GroupsLoadingState();
}
class GroupsLoadingMoreState extends GroupsState {
  final List<Group> currentGroups;
  const GroupsLoadingMoreState(this.currentGroups);
  @override
  List<Object> get props => [currentGroups];
}
class GroupDetailsLoadingState extends GroupsState {
  const GroupDetailsLoadingState();
}
class GroupMembersLoadingState extends GroupsState {
  const GroupMembersLoadingState();
}
class GroupMembersLoadingMoreState extends GroupsState {
  final List<GroupMember> currentMembers;
  const GroupMembersLoadingMoreState(this.currentMembers);
  @override
  List<Object> get props => [currentMembers];
}
/// Loaded states
class GroupsLoadedState extends GroupsState {
  final List<Group> groups;
  final Pagination pagination;
  final bool hasMore;
  final bool isLoadingMore;
  final String? searchQuery;
  final int? categoryFilter;
  final String? privacyFilter;
  const GroupsLoadedState({
    required this.groups,
    required this.pagination,
    required this.hasMore,
    this.isLoadingMore = false,
    this.searchQuery,
    this.categoryFilter,
    this.privacyFilter,
  });
  GroupsLoadedState copyWith({
    List<Group>? groups,
    Pagination? pagination,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    int? categoryFilter,
    String? privacyFilter,
  }) {
    return GroupsLoadedState(
      groups: groups ?? this.groups,
      pagination: pagination ?? this.pagination,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      privacyFilter: privacyFilter ?? this.privacyFilter,
    );
  }
  @override
  List<Object?> get props => [
        groups,
        pagination,
        hasMore,
        isLoadingMore,
        searchQuery,
        categoryFilter,
        privacyFilter,
      ];
}
class GroupDetailsLoadedState extends GroupsState {
  final Group group;
  const GroupDetailsLoadedState(this.group);
  @override
  List<Object> get props => [group];
}
class GroupMembersLoadedState extends GroupsState {
  final int groupId;
  final List<GroupMember> members;
  final Pagination pagination;
  final bool hasMore;
  final bool isLoadingMore;
  final String status;
  const GroupMembersLoadedState({
    required this.groupId,
    required this.members,
    required this.pagination,
    required this.hasMore,
    this.isLoadingMore = false,
    this.status = 'approved',
  });
  GroupMembersLoadedState copyWith({
    int? groupId,
    List<GroupMember>? members,
    Pagination? pagination,
    bool? hasMore,
    bool? isLoadingMore,
    String? status,
  }) {
    return GroupMembersLoadedState(
      groupId: groupId ?? this.groupId,
      members: members ?? this.members,
      pagination: pagination ?? this.pagination,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      status: status ?? this.status,
    );
  }
  @override
  List<Object?> get props => [
        groupId,
        members,
        pagination,
        hasMore,
        isLoadingMore,
        status,
      ];
}
class GroupCategoriesLoadedState extends GroupsState {
  final List<GroupCategory> categories;
  const GroupCategoriesLoadedState(this.categories);
  @override
  List<Object> get props => [categories];
}
/// Action states
class GroupJoiningState extends GroupsState {
  final int groupId;
  const GroupJoiningState(this.groupId);
  @override
  List<Object> get props => [groupId];
}
class GroupLeavingState extends GroupsState {
  final int groupId;
  const GroupLeavingState(this.groupId);
  @override
  List<Object> get props => [groupId];
}
class GroupCreatingState extends GroupsState {
  const GroupCreatingState();
}
class GroupUpdatingState extends GroupsState {
  final int groupId;
  const GroupUpdatingState(this.groupId);
  @override
  List<Object> get props => [groupId];
}
class GroupDeletingState extends GroupsState {
  final int groupId;
  const GroupDeletingState(this.groupId);
  @override
  List<Object> get props => [groupId];
}
class MemberActionState extends GroupsState {
  final int groupId;
  final int userId;
  final String action;
  const MemberActionState({
    required this.groupId,
    required this.userId,
    required this.action,
  });
  @override
  List<Object> get props => [groupId, userId, action];
}
/// Success states
class GroupJoinedSuccessState extends GroupsState {
  final int groupId;
  final String message;
  const GroupJoinedSuccessState({
    required this.groupId,
    required this.message,
  });
  @override
  List<Object> get props => [groupId, message];
}
class GroupLeftSuccessState extends GroupsState {
  final int groupId;
  final String message;
  const GroupLeftSuccessState({
    required this.groupId,
    required this.message,
  });
  @override
  List<Object> get props => [groupId, message];
}
class GroupCreatedSuccessState extends GroupsState {
  final Group group;
  final String message;
  const GroupCreatedSuccessState({
    required this.group,
    required this.message,
  });
  @override
  List<Object> get props => [group, message];
}
class GroupUpdatedSuccessState extends GroupsState {
  final Group group;
  final String message;
  const GroupUpdatedSuccessState({
    required this.group,
    required this.message,
  });
  @override
  List<Object> get props => [group, message];
}
class GroupDeletedSuccessState extends GroupsState {
  final int groupId;
  final String message;
  const GroupDeletedSuccessState({
    required this.groupId,
    required this.message,
  });
  @override
  List<Object> get props => [groupId, message];
}
class MemberActionSuccessState extends GroupsState {
  final int groupId;
  final int userId;
  final String action;
  final String message;
  const MemberActionSuccessState({
    required this.groupId,
    required this.userId,
    required this.action,
    required this.message,
  });
  @override
  List<Object> get props => [groupId, userId, action, message];
}
/// Error states
class GroupsErrorState extends GroupsState {
  final String message;
  final String? errorCode;
  const GroupsErrorState({
    required this.message,
    this.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode];
}
class GroupDetailsErrorState extends GroupsState {
  final String message;
  final String? errorCode;
  const GroupDetailsErrorState({
    required this.message,
    this.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode];
}
class GroupMembersErrorState extends GroupsState {
  final String message;
  final String? errorCode;
  const GroupMembersErrorState({
    required this.message,
    this.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode];
}
class GroupActionErrorState extends GroupsState {
  final String message;
  final String? errorCode;
  final String action;
  const GroupActionErrorState({
    required this.message,
    required this.action,
    this.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode, action];
}
/// Empty states
class GroupsEmptyState extends GroupsState {
  final String message;
  const GroupsEmptyState({this.message = 'لا توجد مجموعات'});
  @override
  List<Object> get props => [message];
}
class GroupMembersEmptyState extends GroupsState {
  final String message;
  const GroupMembersEmptyState({this.message = 'لا يوجد أعضاء'});
  @override
  List<Object> get props => [message];
}
class GroupCategoriesEmptyState extends GroupsState {
  final String message;
  const GroupCategoriesEmptyState({this.message = 'لا توجد فئات'});
  @override
  List<Object> get props => [message];
}