import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/groups/data/models/group_exceptions.dart';
import 'package:get/get.dart';
import 'groups_events.dart';
import 'groups_states.dart';
import '../../domain/groups_repository.dart';
import '../../data/models/group.dart';
import '../../presentation/pages/group_page.dart';
/// Groups Bloc for managing all group-related state
class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GroupsRepository _groupsRepository;
  // Internal state for pagination
  int _currentPage = 1;
  bool _hasMore = true;
  final List<Group> _currentGroups = [];
  String? _currentSearch;
  int? _currentCategoryFilter;
  String? _currentPrivacyFilter;
  // Members state
  int _currentMembersPage = 1;
  bool _hasMoreMembers = true;
  final List<GroupMember> _currentMembers = [];
  GroupsBloc(this._groupsRepository) : super(const GroupsInitialState()) {
    on<LoadGroupsEvent>(_onLoadGroups);
    on<LoadJoinedGroupsEvent>(_onLoadJoinedGroups);
    on<LoadMyGroupsEvent>(_onLoadMyGroups);
    on<LoadMoreGroupsEvent>(_onLoadMoreGroups);
    on<RefreshGroupsEvent>(_onRefreshGroups);
    on<SearchGroupsEvent>(_onSearchGroups);
    on<FilterGroupsByCategoryEvent>(_onFilterByCategory);
    on<FilterGroupsByPrivacyEvent>(_onFilterByPrivacy);
    on<ClearGroupsFiltersEvent>(_onClearFilters);
    on<LoadGroupDetailsEvent>(_onLoadGroupDetails);
    on<LoadGroupMembersEvent>(_onLoadGroupMembers);
    on<LoadMoreGroupMembersEvent>(_onLoadMoreGroupMembers);
    on<JoinGroupEvent>(_onJoinGroup);
    on<LeaveGroupEvent>(_onLeaveGroup);
    on<AcceptMemberEvent>(_onAcceptMember);
    on<RejectMemberEvent>(_onRejectMember);
    on<RemoveMemberEvent>(_onRemoveMember);
    on<MakeMemberAdminEvent>(_onMakeMemberAdmin);
    on<RemoveAdminRoleEvent>(_onRemoveAdminRole);
    on<LoadGroupCategoriesEvent>(_onLoadGroupCategories);
    on<CreateGroupEvent>(_onCreateGroup);
    on<UpdateGroupEvent>(_onUpdateGroup);
    on<DeleteGroupEvent>(_onDeleteGroup);
    on<UpdateCurrentGroupEvent>(_onUpdateCurrentGroup);
  }
  /// Load groups list
  Future<void> _onLoadGroups(LoadGroupsEvent event, Emitter<GroupsState> emit) async {
    try {
      if (event.isRefresh) {
        _resetPagination();
      }
      // Set filters
      _currentSearch = event.search;
      _currentCategoryFilter = event.category;
      _currentPrivacyFilter = event.privacy;
      if (_currentGroups.isEmpty) {
        emit(const GroupsLoadingState());
      }
      final response = await _groupsRepository.getGroups(
        page: event.page,
        limit: event.limit,
        category: event.category,
        search: event.search,
        privacy: event.privacy,
      );
      if (event.isRefresh) {
        _currentGroups.clear();
      }
      _currentGroups.addAll(response.groups);
      // فحص التكرار وإزالة المجموعات المكررة
      final uniqueGroups = <int, Group>{};
      for (final group in _currentGroups) {
        uniqueGroups[group.groupId] = group;
      }
      _currentGroups.clear();
      _currentGroups.addAll(uniqueGroups.values);
      _currentPage = response.pagination.page;
      _hasMore = response.pagination.hasMore;
      if (_currentGroups.isEmpty) {
        emit(const GroupsEmptyState());
      } else {
        emit(GroupsLoadedState(
          groups: List.from(_currentGroups),
          pagination: response.pagination,
          hasMore: _hasMore,
          searchQuery: _currentSearch,
          categoryFilter: _currentCategoryFilter,
          privacyFilter: _currentPrivacyFilter,
        ));
      }
    } catch (e) {
      emit(GroupsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load joined groups
  Future<void> _onLoadJoinedGroups(LoadJoinedGroupsEvent event, Emitter<GroupsState> emit) async {
    try {
      if (event.isRefresh) {
        _resetPagination();
      }
      // Set filters
      _currentSearch = event.search;
      _currentCategoryFilter = null; // No category filter for joined groups
      _currentPrivacyFilter = null;  // No privacy filter for joined groups
      if (_currentGroups.isEmpty) {
        emit(const GroupsLoadingState());
      }
      final response = await _groupsRepository.getJoinedGroups(
        page: event.page,
        limit: event.limit,
        search: event.search,
      );
      if (event.isRefresh) {
        _currentGroups.clear();
      }
      _currentGroups.addAll(response.groups);
      // فحص التكرار وإزالة المجموعات المكررة
      final uniqueGroups = <int, Group>{};
      for (final group in _currentGroups) {
        uniqueGroups[group.groupId] = group;
      }
      _currentGroups.clear();
      _currentGroups.addAll(uniqueGroups.values);
      _currentPage = response.pagination.page;
      _hasMore = response.pagination.hasMore;
      if (_currentGroups.isEmpty) {
        emit(const GroupsEmptyState());
      } else {
        emit(GroupsLoadedState(
          groups: List.from(_currentGroups),
          pagination: response.pagination,
          hasMore: _hasMore,
          searchQuery: _currentSearch,
          categoryFilter: _currentCategoryFilter,
          privacyFilter: _currentPrivacyFilter,
        ));
      }
    } catch (e) {
      emit(GroupsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load my groups (owned by user)
  Future<void> _onLoadMyGroups(LoadMyGroupsEvent event, Emitter<GroupsState> emit) async {
    try {
      if (event.isRefresh) {
        _resetPagination();
      }
      // Set filters
      _currentSearch = event.search;
      _currentCategoryFilter = null; // No category filter for my groups
      _currentPrivacyFilter = null;  // No privacy filter for my groups
      if (_currentGroups.isEmpty) {
        emit(const GroupsLoadingState());
      }
      final response = await _groupsRepository.getMyGroups(
        page: event.page,
        limit: event.limit,
        search: event.search,
      );
      if (event.isRefresh) {
        _currentGroups.clear();
      }
      _currentGroups.addAll(response.groups);
      // فحص التكرار وإزالة المجموعات المكررة
      final uniqueGroups = <int, Group>{};
      for (final group in _currentGroups) {
        uniqueGroups[group.groupId] = group;
      }
      _currentGroups.clear();
      _currentGroups.addAll(uniqueGroups.values);
      _currentPage = response.pagination.page;
      _hasMore = response.pagination.hasMore;
      if (_currentGroups.isEmpty) {
        emit(const GroupsEmptyState());
      } else {
        emit(GroupsLoadedState(
          groups: List.from(_currentGroups),
          pagination: response.pagination,
          hasMore: _hasMore,
          searchQuery: _currentSearch,
          categoryFilter: _currentCategoryFilter,
          privacyFilter: _currentPrivacyFilter,
        ));
      }
    } catch (e) {
      emit(GroupsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load more groups (pagination)
  Future<void> _onLoadMoreGroups(LoadMoreGroupsEvent event, Emitter<GroupsState> emit) async {
    if (!_hasMore || state is GroupsLoadingMoreState) return;
    try {
      emit(GroupsLoadingMoreState(List.from(_currentGroups)));
      final response = await _groupsRepository.getGroups(
        page: _currentPage + 1,
        limit: 20,
        category: _currentCategoryFilter,
        search: _currentSearch,
        privacy: _currentPrivacyFilter,
      );
      _currentGroups.addAll(response.groups);
      // فحص التكرار وإزالة المجموعات المكررة في التحميل الإضافي
      final uniqueGroups = <int, Group>{};
      for (final group in _currentGroups) {
        uniqueGroups[group.groupId] = group;
      }
      _currentGroups.clear();
      _currentGroups.addAll(uniqueGroups.values);
      _currentPage = response.pagination.page;
      _hasMore = response.pagination.hasMore;
      emit(GroupsLoadedState(
        groups: List.from(_currentGroups),
        pagination: response.pagination,
        hasMore: _hasMore,
        searchQuery: _currentSearch,
        categoryFilter: _currentCategoryFilter,
        privacyFilter: _currentPrivacyFilter,
      ));
    } catch (e) {
      emit(GroupsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Refresh groups list
  Future<void> _onRefreshGroups(RefreshGroupsEvent event, Emitter<GroupsState> emit) async {
    // مسح البيانات فوراً من الواجهة
    _resetPagination();
    emit(const GroupsLoadingState());
    add(LoadGroupsEvent(
      isRefresh: true,
      search: _currentSearch,
      category: _currentCategoryFilter,
      privacy: _currentPrivacyFilter,
    ));
  }
  /// Search groups
  Future<void> _onSearchGroups(SearchGroupsEvent event, Emitter<GroupsState> emit) async {
    _resetPagination();
    add(LoadGroupsEvent(
      search: event.query.isEmpty ? null : event.query,
      category: _currentCategoryFilter,
      privacy: _currentPrivacyFilter,
      isRefresh: true,
    ));
  }
  /// Filter by category
  Future<void> _onFilterByCategory(FilterGroupsByCategoryEvent event, Emitter<GroupsState> emit) async {
    _resetPagination();
    add(LoadGroupsEvent(
      search: _currentSearch,
      category: event.categoryId,
      privacy: _currentPrivacyFilter,
      isRefresh: true,
    ));
  }
  /// Filter by privacy
  Future<void> _onFilterByPrivacy(FilterGroupsByPrivacyEvent event, Emitter<GroupsState> emit) async {
    _resetPagination();
    add(LoadGroupsEvent(
      search: _currentSearch,
      category: _currentCategoryFilter,
      privacy: event.privacy,
      isRefresh: true,
    ));
  }
  /// Clear filters
  Future<void> _onClearFilters(ClearGroupsFiltersEvent event, Emitter<GroupsState> emit) async {
    _resetPagination();
    add(const LoadGroupsEvent(isRefresh: true));
  }
  /// Load group details
  Future<void> _onLoadGroupDetails(LoadGroupDetailsEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(const GroupDetailsLoadingState());
      Group group;
      if (event.groupId != null) {
        group = await _groupsRepository.getGroupById(event.groupId!);
      } else if (event.groupName != null) {
        group = await _groupsRepository.getGroupByName(event.groupName!);
      } else {
        throw Exception('Either group ID or name is required');
      }
      emit(GroupDetailsLoadedState(group));
    } catch (e) {
      emit(GroupDetailsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load group members
  Future<void> _onLoadGroupMembers(LoadGroupMembersEvent event, Emitter<GroupsState> emit) async {
    try {
      if (event.isRefresh) {
        _resetMembersPagination();
      }
      if (_currentMembers.isEmpty) {
        emit(const GroupMembersLoadingState());
      }
      final response = await _groupsRepository.getGroupMembers(
        event.groupId,
        page: event.page,
        limit: event.limit,
        status: event.status,
      );
      if (event.isRefresh) {
        _currentMembers.clear();
      }
      _currentMembers.addAll(response.members);
      _currentMembersPage = response.pagination.page;
      _hasMoreMembers = response.pagination.hasMore;
      if (_currentMembers.isEmpty) {
        emit(const GroupMembersEmptyState());
      } else {
        emit(GroupMembersLoadedState(
          groupId: event.groupId,
          members: List.from(_currentMembers),
          pagination: response.pagination,
          hasMore: _hasMoreMembers,
          status: event.status,
        ));
      }
    } catch (e) {
      emit(GroupMembersErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load more group members
  Future<void> _onLoadMoreGroupMembers(LoadMoreGroupMembersEvent event, Emitter<GroupsState> emit) async {
    if (!_hasMoreMembers || state is GroupMembersLoadingMoreState) return;
    try {
      emit(GroupMembersLoadingMoreState(List.from(_currentMembers)));
      final response = await _groupsRepository.getGroupMembers(
        event.groupId,
        page: _currentMembersPage + 1,
        limit: 20,
      );
      _currentMembers.addAll(response.members);
      _currentMembersPage = response.pagination.page;
      _hasMoreMembers = response.pagination.hasMore;
      emit(GroupMembersLoadedState(
        groupId: event.groupId,
        members: List.from(_currentMembers),
        pagination: response.pagination,
        hasMore: _hasMoreMembers,
      ));
    } catch (e) {
      emit(GroupMembersErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Join group
  Future<void> _onJoinGroup(JoinGroupEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(GroupJoiningState(event.groupId));
      await _groupsRepository.joinGroup(event.groupId);
      emit(GroupJoinedSuccessState(
        groupId: event.groupId,
        message: 'تم الانضمام للمجموعة بنجاح',
      ));
      // Refresh group details if currently loaded
      if (state is GroupDetailsLoadedState) {
        add(LoadGroupDetailsEvent.byId(event.groupId));
      }
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'join',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Leave group
  Future<void> _onLeaveGroup(LeaveGroupEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(GroupLeavingState(event.groupId));
      await _groupsRepository.leaveGroup(event.groupId);
      emit(GroupLeftSuccessState(
        groupId: event.groupId,
        message: 'تم مغادرة المجموعة بنجاح',
      ));
      // Refresh group details if currently loaded
      if (state is GroupDetailsLoadedState) {
        add(LoadGroupDetailsEvent.byId(event.groupId));
      }
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'leave',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Accept member
  Future<void> _onAcceptMember(AcceptMemberEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(MemberActionState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'accept',
      ));
      await _groupsRepository.acceptMember(event.groupId, event.userId);
      emit(MemberActionSuccessState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'accept',
        message: 'تم قبول العضو بنجاح',
      ));
      // Refresh members list
      add(LoadGroupMembersEvent(groupId: event.groupId, isRefresh: true));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'accept_member',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Reject member
  Future<void> _onRejectMember(RejectMemberEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(MemberActionState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'reject',
      ));
      await _groupsRepository.rejectMember(event.groupId, event.userId);
      emit(MemberActionSuccessState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'reject',
        message: 'تم رفض العضو بنجاح',
      ));
      // Refresh members list
      add(LoadGroupMembersEvent(groupId: event.groupId, isRefresh: true));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'reject_member',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Remove member
  Future<void> _onRemoveMember(RemoveMemberEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(MemberActionState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'remove',
      ));
      await _groupsRepository.removeMember(event.groupId, event.userId);
      emit(MemberActionSuccessState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'remove',
        message: 'تم إزالة العضو بنجاح',
      ));
      // Refresh members list
      add(LoadGroupMembersEvent(groupId: event.groupId, isRefresh: true));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'remove_member',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Make member admin
  Future<void> _onMakeMemberAdmin(MakeMemberAdminEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(MemberActionState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'make_admin',
      ));
      await _groupsRepository.makeMemberAdmin(event.groupId, event.userId);
      emit(MemberActionSuccessState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'make_admin',
        message: 'تم تعيين العضو كمشرف بنجاح',
      ));
      // Refresh members list
      add(LoadGroupMembersEvent(groupId: event.groupId, isRefresh: true));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'make_admin',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Remove admin role
  Future<void> _onRemoveAdminRole(RemoveAdminRoleEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(MemberActionState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'remove_admin',
      ));
      await _groupsRepository.removeAdminRole(event.groupId, event.userId);
      emit(MemberActionSuccessState(
        groupId: event.groupId,
        userId: event.userId,
        action: 'remove_admin',
        message: 'تم إزالة صلاحية الإشراف بنجاح',
      ));
      // Refresh members list
      add(LoadGroupMembersEvent(groupId: event.groupId, isRefresh: true));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'remove_admin',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Load group categories
  Future<void> _onLoadGroupCategories(LoadGroupCategoriesEvent event, Emitter<GroupsState> emit) async {
    try {
      final categories = await _groupsRepository.getGroupCategories();
      if (categories.isEmpty) {
        emit(const GroupCategoriesEmptyState());
      } else {
        emit(GroupCategoriesLoadedState(categories));
      }
    } catch (e) {
      emit(GroupsErrorState(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Create group
  Future<void> _onCreateGroup(CreateGroupEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(const GroupCreatingState());
      final groupData = await _groupsRepository.createGroup(
        name: event.name,
        title: event.title,
        description: event.description,
        privacy: event.privacy.value,
        category: event.categoryId,
        country: event.country ?? 1, // Default country ID
      );
      // Extract group ID from response
      final groupId = groupData['group_id'] as int;
      // Fetch complete group data using the ID
      final completeGroup = await _groupsRepository.getGroupById(groupId);
      emit(GroupCreatedSuccessState(
        group: completeGroup,
        message: 'تم إنشاء المجموعة بنجاح',
      ));
      // Refresh groups list
      add(const RefreshGroupsEvent());
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'create',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Update group
  Future<void> _onUpdateGroup(UpdateGroupEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(GroupUpdatingState(event.groupId));
      await _groupsRepository.updateGroup(
        groupId: event.groupId,
        title: event.title,
        description: event.description,
        privacy: event.privacy?.value,
        category: event.categoryId,
      );
      // Fetch complete updated group data using the ID
      final updatedGroup = await _groupsRepository.getGroupById(event.groupId);
      emit(GroupUpdatedSuccessState(
        group: updatedGroup,
        message: 'تم تحديث المجموعة بنجاح',
      ));
      // Update current group details
      emit(GroupDetailsLoadedState(updatedGroup));
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'update',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Delete group
  Future<void> _onDeleteGroup(DeleteGroupEvent event, Emitter<GroupsState> emit) async {
    try {
      emit(GroupDeletingState(event.groupId));
      await _groupsRepository.deleteGroup(event.groupId);
      emit(GroupDeletedSuccessState(
        groupId: event.groupId,
        message: 'تم حذف المجموعة بنجاح',
      ));
      // Refresh groups list
      add(const RefreshGroupsEvent());
    } catch (e) {
      emit(GroupActionErrorState(
        message: _getErrorMessage(e),
        action: 'delete',
        errorCode: _getErrorCode(e),
      ));
    }
  }
  /// Update current group (for optimistic updates)
  Future<void> _onUpdateCurrentGroup(UpdateCurrentGroupEvent event, Emitter<GroupsState> emit) async {
    emit(GroupDetailsLoadedState(event.group));
  }
  /// Reset pagination
  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _currentGroups.clear();
  }
  /// Reset members pagination
  void _resetMembersPagination() {
    _currentMembersPage = 1;
    _hasMoreMembers = true;
    _currentMembers.clear();
  }
  /// Helper method: Navigate to group by ID only (useful for notifications)
  static void navigateToGroupById(int groupId) {
    Get.to(() => GroupPage.byId(groupId: groupId));
  }
  /// Helper method: Create group and navigate by ID
  static Future<void> createGroupAndNavigate({
    required String name,
    required String title, 
    required String description,
    required GroupPrivacy privacy,
    required int categoryId,
  }) async {
    // This would be called from UI
    // Get.find<GroupsBloc>().add(CreateGroupEvent(...));
    // Navigation is handled in the BlocListener
  }
  /// Get error message from exception
  String _getErrorMessage(dynamic error) {
    if (error is GroupException) {
      return error.message;
    }
    return 'حدث خطأ غير متوقع';
  }
  /// Get error code from exception
  String? _getErrorCode(dynamic error) {
    if (error is GroupException) {
      return error.code.toString();
    }
    return null;
  }
}