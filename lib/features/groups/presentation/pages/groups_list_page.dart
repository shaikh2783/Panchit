import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../application/bloc/groups_bloc.dart';
import '../../application/bloc/groups_events.dart';
import '../../application/bloc/groups_states.dart';
import '../../data/models/group.dart';
import 'group_page.dart';
import 'create_group_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
/// Types of groups lists
enum GroupsListType {
  joined,  // Joined groups
  owned,   // Owned groups
}
/// Page for listing all groups
class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});
  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}
class _GroupsListPageState extends State<GroupsListPage> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  @override
  bool get wantKeepAlive => true; // Keep state
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    // Load data after UI build to ensure no duplication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGroupsByTab();
      }
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_isBottom) {
      context.read<GroupsBloc>().add(const LoadMoreGroupsEvent());
    }
  }
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
  void _onTabChanged() {
    if (mounted) {
      _loadGroupsByTab();
    }
  }
  void _loadGroupsByTab() {
    // Use separate APIs for joined and owned groups
    if (_tabController.index == 0) {
      // Load joined groups using separate API
      context.read<GroupsBloc>().add(LoadJoinedGroupsEvent(
        page: 1,
        limit: 20,
        search: _searchController.text,
        isRefresh: true,
      ));
    } else {
      // Load my groups using separate API
      context.read<GroupsBloc>().add(LoadMyGroupsEvent(
        page: 1,
        limit: 20,
        search: _searchController.text,
        isRefresh: true,
      ));
    }
  }
  /// Show leave confirmation
  void _showLeaveConfirmation(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave'),
        content: Text(
          'Are you sure you want to leave "${group.groupTitle}" group?\n\nYou will need to request to join again if you want to return.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GroupsBloc>().add(LeaveGroupEvent(group.groupId));
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required with AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Groups'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Iconsax.people),
              text: 'Joined Groups',
            ),
            Tab(
              icon: Icon(Iconsax.user),
              text: 'My Groups',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () {
              Get.to(() => const CreateGroupPage());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              onChanged: (query) {
                // Use new events to search by selected tab
                if (_tabController.index == 0) {
                  // Search in joined groups
                  context.read<GroupsBloc>().add(LoadJoinedGroupsEvent(
                    page: 1,
                    limit: 20,
                    search: query,
                    isRefresh: true,
                  ));
                } else {
                  // Search in my groups
                  context.read<GroupsBloc>().add(LoadMyGroupsEvent(
                    page: 1,
                    limit: 20,
                    search: query,
                    isRefresh: true,
                  ));
                }
              },
            ),
          ),
          // TabBarView for groups
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Joined groups tab
                _buildGroupsList(GroupsListType.joined),
                // My groups tab
                _buildGroupsList(GroupsListType.owned),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGroupsList(GroupsListType type) {
    return BlocBuilder<GroupsBloc, GroupsState>(
      buildWhen: (previous, current) {
        // Build view only when Groups List states change
        return current is GroupsLoadingState ||
               current is GroupsErrorState ||
               current is GroupsEmptyState ||
               current is GroupsLoadedState ||
               current is GroupsLoadingMoreState;
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        if (state is GroupsLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GroupsErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Occurred',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadGroupsByTab(),
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        if (state is GroupsEmptyState) {
          final emptyMessage = type == GroupsListType.joined 
              ? 'No groups joined yet'
              : 'No groups created yet';
          final emptyDescription = type == GroupsListType.joined 
              ? 'Search for groups to join'
              : 'Start by creating a new group';
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == GroupsListType.joined ? Iconsax.people : Iconsax.user,
                  size: 64,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  emptyDescription,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (state is GroupsLoadedState) {
          // Use groups directly from API instead of local filtering
          final groups = state.groups;
          if (groups.isEmpty) {
            // If no groups found, show empty message
            final emptyMessage = type == GroupsListType.joined 
                ? 'No groups joined yet'
                : 'No groups created yet';
            final emptyDescription = type == GroupsListType.joined 
                ? 'Search for groups to join'
                : 'Start by creating a new group';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == GroupsListType.joined ? Iconsax.people : Iconsax.user,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptyDescription,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadGroupsByTab(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groups.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= groups.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final group = groups[index];
                return _GroupListItem(
                  group: group,
                  listType: type,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupPage.withGroup(group: group),
                      ),
                    );
                  },
                  onLeave: (group.isCurrentUserMember && type != GroupsListType.owned) 
                    ? () => _showLeaveConfirmation(context, group)
                    : null,
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
/// Group item in the list
class _GroupListItem extends StatelessWidget {
  final Group group;
  final GroupsListType listType;
  final VoidCallback onTap;
  final VoidCallback? onLeave;
  const _GroupListItem({
    required this.group,
    required this.listType,
    required this.onTap,
    this.onLeave,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.blue.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: group.groupPicture?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          group.groupPicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _GroupPlaceholder(),
                        ),
                      )
                    : _GroupPlaceholder(),
              ),
              const SizedBox(width: 16),
              // Group information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.groupTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Show membership or admin badge
                        if (listType == GroupsListType.owned)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (group.isCurrentUserAdmin)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (group.isCurrentUserMember)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Member',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (group.groupDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.groupDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Group statistics
                    Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.membersCountText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          group.groupPrivacy == GroupPrivacy.public
                              ? Iconsax.global
                              : Iconsax.lock,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.privacyDisplayText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Leave button for joined groups (not owned)
              if (listType != GroupsListType.owned && group.isCurrentUserMember) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onLeave ?? () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Iconsax.logout,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
              // Navigation arrow
              Icon(
                Iconsax.arrow_right_3,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Placeholder for group image
class _GroupPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Iconsax.people,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}