import 'package:equatable/equatable.dart';
import '../../data/models/group.dart';
/// Base class for all Groups events
abstract class GroupsEvent extends Equatable {
  const GroupsEvent();
  @override
  List<Object?> get props => [];
}
/// Load groups list
class LoadGroupsEvent extends GroupsEvent {
  final int page;
  final int limit;
  final int? category;
  final String? search;
  final String? privacy;
  final bool isRefresh;
  const LoadGroupsEvent({
    this.page = 1,
    this.limit = 20,
    this.category,
    this.search,
    this.privacy,
    this.isRefresh = false,
  });
  @override
  List<Object?> get props => [page, limit, category, search, privacy, isRefresh];
}
/// Load joined groups
class LoadJoinedGroupsEvent extends GroupsEvent {
  final int page;
  final int limit;
  final String? search;
  final bool isRefresh;
  const LoadJoinedGroupsEvent({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.isRefresh = true,
  });
  @override
  List<Object?> get props => [page, limit, search, isRefresh];
}
/// Load my groups (owned by user)
class LoadMyGroupsEvent extends GroupsEvent {
  final int page;
  final int limit;
  final String? search;
  final bool isRefresh;
  const LoadMyGroupsEvent({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.isRefresh = true,
  });
  @override
  List<Object?> get props => [page, limit, search, isRefresh];
}
/// Load more groups (pagination)
class LoadMoreGroupsEvent extends GroupsEvent {
  const LoadMoreGroupsEvent();
}
/// Refresh groups list
class RefreshGroupsEvent extends GroupsEvent {
  const RefreshGroupsEvent();
}
/// Search groups
class SearchGroupsEvent extends GroupsEvent {
  final String query;
  const SearchGroupsEvent(this.query);
  @override
  List<Object> get props => [query];
}
/// Filter groups by category
class FilterGroupsByCategoryEvent extends GroupsEvent {
  final int? categoryId;
  const FilterGroupsByCategoryEvent(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}
/// Filter groups by privacy
class FilterGroupsByPrivacyEvent extends GroupsEvent {
  final String? privacy;
  const FilterGroupsByPrivacyEvent(this.privacy);
  @override
  List<Object?> get props => [privacy];
}
/// Clear filters
class ClearGroupsFiltersEvent extends GroupsEvent {
  const ClearGroupsFiltersEvent();
}
/// Load specific group details
class LoadGroupDetailsEvent extends GroupsEvent {
  final int? groupId;
  final String? groupName;
  const LoadGroupDetailsEvent.byId(this.groupId) : groupName = null;
  const LoadGroupDetailsEvent.byName(this.groupName) : groupId = null;
  @override
  List<Object?> get props => [groupId, groupName];
}
/// Load group members
class LoadGroupMembersEvent extends GroupsEvent {
  final int groupId;
  final int page;
  final int limit;
  final String status;
  final bool isRefresh;
  const LoadGroupMembersEvent({
    required this.groupId,
    this.page = 1,
    this.limit = 20,
    this.status = 'approved',
    this.isRefresh = false,
  });
  @override
  List<Object> get props => [groupId, page, limit, status, isRefresh];
}
/// Load more group members
class LoadMoreGroupMembersEvent extends GroupsEvent {
  final int groupId;
  const LoadMoreGroupMembersEvent(this.groupId);
  @override
  List<Object> get props => [groupId];
}
/// Join group
class JoinGroupEvent extends GroupsEvent {
  final int groupId;
  const JoinGroupEvent(this.groupId);
  @override
  List<Object> get props => [groupId];
}
/// Leave group
class LeaveGroupEvent extends GroupsEvent {
  final int groupId;
  const LeaveGroupEvent(this.groupId);
  @override
  List<Object> get props => [groupId];
}
/// Accept member (admin only)
class AcceptMemberEvent extends GroupsEvent {
  final int groupId;
  final int userId;
  const AcceptMemberEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object> get props => [groupId, userId];
}
/// Reject member (admin only)
class RejectMemberEvent extends GroupsEvent {
  final int groupId;
  final int userId;
  const RejectMemberEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object> get props => [groupId, userId];
}
/// Remove member (admin only)
class RemoveMemberEvent extends GroupsEvent {
  final int groupId;
  final int userId;
  const RemoveMemberEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object> get props => [groupId, userId];
}
/// Make member admin (admin only)
class MakeMemberAdminEvent extends GroupsEvent {
  final int groupId;
  final int userId;
  const MakeMemberAdminEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object> get props => [groupId, userId];
}
/// Remove admin role (admin only)
class RemoveAdminRoleEvent extends GroupsEvent {
  final int groupId;
  final int userId;
  const RemoveAdminRoleEvent({
    required this.groupId,
    required this.userId,
  });
  @override
  List<Object> get props => [groupId, userId];
}
/// Load group categories
class LoadGroupCategoriesEvent extends GroupsEvent {
  const LoadGroupCategoriesEvent();
}
/// Create new group
class CreateGroupEvent extends GroupsEvent {
  final String name;
  final String title;
  final String description;
  final GroupPrivacy privacy;
  final int categoryId;
  final int? country;
  final String? picture;
  final String? cover;
  const CreateGroupEvent({
    required this.name,
    required this.title,
    required this.description,
    required this.privacy,
    required this.categoryId,
    this.country,
    this.picture,
    this.cover,
  });
  @override
  List<Object?> get props => [
        name,
        title,
        description,
        privacy,
        categoryId,
        country,
        picture,
        cover,
      ];
}
/// Update group
class UpdateGroupEvent extends GroupsEvent {
  final int groupId;
  final String? title;
  final String? description;
  final GroupPrivacy? privacy;
  final int? categoryId;
  final String? picture;
  final String? cover;
  final bool? publishEnabled;
  final bool? publishApprovalEnabled;
  final bool? monetizationEnabled;
  final double? monetizationMinPrice;
  final bool? chatboxEnabled;
  const UpdateGroupEvent({
    required this.groupId,
    this.title,
    this.description,
    this.privacy,
    this.categoryId,
    this.picture,
    this.cover,
    this.publishEnabled,
    this.publishApprovalEnabled,
    this.monetizationEnabled,
    this.monetizationMinPrice,
    this.chatboxEnabled,
  });
  @override
  List<Object?> get props => [
        groupId,
        title,
        description,
        privacy,
        categoryId,
        picture,
        cover,
        publishEnabled,
        publishApprovalEnabled,
        monetizationEnabled,
        monetizationMinPrice,
        chatboxEnabled,
      ];
}
/// Delete group
class DeleteGroupEvent extends GroupsEvent {
  final int groupId;
  const DeleteGroupEvent(this.groupId);
  @override
  List<Object> get props => [groupId];
}
/// Update current group details (for optimistic updates)
class UpdateCurrentGroupEvent extends GroupsEvent {
  final Group group;
  const UpdateCurrentGroupEvent(this.group);
  @override
  List<Object> get props => [group];
}