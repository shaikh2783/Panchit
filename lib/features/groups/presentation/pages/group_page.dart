import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/groups/application/bloc/groups_bloc.dart';
import 'package:snginepro/features/groups/application/bloc/groups_events.dart';
import 'package:snginepro/features/groups/application/bloc/groups_states.dart';
import 'package:snginepro/features/agora/presentation/pages/professional_live_stream_wrapper.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import '../../data/models/group.dart';
import '../widgets/group_header_widget.dart';
import '../widgets/group_members_widget.dart';
import '../widgets/group_actions_widget.dart';
import '../widgets/group_info_widget.dart';
import '../widgets/group_posts_widget.dart';
import 'invite_friends_page.dart';
/// Exclusive design for the individual group page
class GroupPage extends StatefulWidget {
  final int? groupId;
  final String? groupName;
  final Group? group; // For direct passing
  const GroupPage.byId({
    super.key,
    required this.groupId,
  }) : groupName = null, group = null;
  const GroupPage.byName({
    super.key, 
    required this.groupName,
  }) : groupId = null, group = null;
  const GroupPage.withGroup({
    super.key,
    required this.group,
  }) : groupId = null, groupName = null;
  @override
  State<GroupPage> createState() => _GroupPageState();
}
class _GroupPageState extends State<GroupPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isHeaderCollapsed = false;
  Group? _currentGroup; // Store current group data
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Load group data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    final isCollapsed = _scrollController.hasClients && 
                       _scrollController.offset > 200;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }
  void _loadGroupData() {
    if (widget.group != null) {
      // If the group is passed directly, store it locally and call setState
      setState(() {
        _currentGroup = widget.group;
      });
    } else if (widget.groupId != null) {
      // Load by ID
      context.read<GroupsBloc>().add(LoadGroupDetailsEvent.byId(widget.groupId!));
    } else if (widget.groupName != null) {
      // Load by Name
      context.read<GroupsBloc>().add(LoadGroupDetailsEvent.byName(widget.groupName!));
    }
  }
  /// Build floating action button for creating posts
  Widget? _buildCreatePostFAB() {
    if (_currentGroup == null) return null;
    // Check posting permissions
    if (_canCreatePost(_currentGroup!)) {
      return FloatingActionButton(
        onPressed: () => _navigateToCreatePost(_currentGroup!),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      );
    }
    // Show info FAB if user can't post
    return _buildInfoFAB(_currentGroup!);
  }
  /// Build info FAB when user can't create posts
  Widget? _buildInfoFAB(Group group) {
    IconData icon = Iconsax.info_circle;
    if (!group.groupPublishEnabled) {
      icon = Iconsax.close_circle;
    } else if (!(group.membership?.isMember ?? false)) {
      icon = Iconsax.user_add;
    }
    return FloatingActionButton(
      onPressed: () => _showPostingInfoDialog(group),
      backgroundColor: Colors.grey,
      child: Icon(icon, color: Colors.white),
    );
  }
  /// Show dialog explaining why user can't post
  void _showPostingInfoDialog(Group group) {
    String title = '';
    String message = '';
    if (!group.groupPublishEnabled) {
      title = 'النشر معطل';
      message = 'إدارة المجموعة قامت بتعطيل إنشاء منشورات جديدة في هذه المجموعة.';
    } else if (!(group.membership?.isMember ?? false)) {
      title = 'انضم للمجموعة';
      message = 'يجب أن تكون عضواً في المجموعة لتتمكن من إنشاء منشورات.\n\nانضم الآن للمشاركة!';
    }
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: (group.membership?.isMember ?? false) ? 'حسناً' : 'انضم الآن',
      textCancel: 'إلغاء',
      onConfirm: () {
        Get.back();
        if (!(group.membership?.isMember ?? false)) {
          // Trigger join group action
          context.read<GroupsBloc>().add(JoinGroupEvent(group.groupId));
        }
      },
    );
  }
  /// Check if user can create post in this group
  bool _canCreatePost(Group group) {
    // If publishing is disabled in group
    if (!group.groupPublishEnabled) return false;
    // Must be a member to post in any group
    if (!(group.membership?.isMember ?? false)) return false;
    return true;
  }
  /// Navigate to create post page
  void _navigateToCreatePost(Group group) {
    // Show info if approval is required
    if (group.groupPublishApprovalEnabled) {
      Get.defaultDialog(
        title: 'تنبيه',
        middleText: 'منشوراتك في هذه المجموعة تحتاج إلى موافقة الأدمن قبل النشر',
        textConfirm: 'فهمت، أريد المتابعة',
        textCancel: 'إلغاء',
        onConfirm: () {
          Get.back();
          _proceedToCreatePost(group);
        },
      );
    } else {
      _proceedToCreatePost(group);
    }
  }
  /// Actually navigate to create post
  void _proceedToCreatePost(Group group) {
    Get.to(() => CreatePostPageModern(
      handle: 'group',
      handleId: group.groupId,
      handleName: group.groupTitle,
    ));
  }
  @override
  Widget build(BuildContext context) {
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    return Scaffold(
      floatingActionButton: _buildCreatePostFAB(),
      body: BlocConsumer<GroupsBloc, GroupsState>(
        listener: (context, state) {
          if (state is GroupJoinedSuccessState || state is GroupLeftSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state is GroupJoinedSuccessState 
                    ? state.message 
                    : (state as GroupLeftSuccessState).message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is GroupActionErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          // If we have locally stored Group data, display it directly
          if (_currentGroup != null) {
            return _GroupContent(
              group: _currentGroup!,
              tabController: _tabController,
              scrollController: _scrollController,
              isHeaderCollapsed: _isHeaderCollapsed,
              mediaAsset: mediaAsset.toString(),
              onRefresh: () => _loadGroupData(),
            );
          }
          // Loading states
          if (state is GroupDetailsLoadingState) {
            return const _LoadingView();
          }
          // Error states
          if (state is GroupDetailsErrorState) {
            return _ErrorView(
              message: state.message,
              onRetry: _loadGroupData,
            );
          }
          // Success states with group data
          if (state is GroupDetailsLoadedState) {
            _currentGroup = state.group; // Store group data
            return _GroupContent(
              group: state.group,
              tabController: _tabController,
              scrollController: _scrollController,
              isHeaderCollapsed: _isHeaderCollapsed,
              mediaAsset: mediaAsset.toString(),
              onRefresh: () => _loadGroupData(),
            );
          }
          // Handle member loading states - if we have group data, continue showing it
          if (state is GroupMembersLoadedState || 
              state is GroupMembersLoadingState ||
              state is GroupMembersLoadingMoreState) {
            if (_currentGroup != null) {
              return _GroupContent(
                group: _currentGroup!,
                tabController: _tabController,
                scrollController: _scrollController,
                isHeaderCollapsed: _isHeaderCollapsed,
                mediaAsset: mediaAsset.toString(),
                onRefresh: () => _loadGroupData(),
              );
            }
            // If no group data stored, show loading
            return const _LoadingView();
          }
          // Initial state - check if we have group data passed directly
          if (state is GroupsInitialState || state is GroupsLoadedState) {
            // If group was passed directly, we can show it immediately
            if (_currentGroup != null) {
              return _GroupContent(
                group: _currentGroup!,
                tabController: _tabController,
                scrollController: _scrollController,
                isHeaderCollapsed: _isHeaderCollapsed,
                mediaAsset: mediaAsset.toString(),
                onRefresh: () => _loadGroupData(),
              );
            }
            return const _LoadingView();
          }
          // Fallback
          if (_currentGroup != null) {
            return _GroupContent(
              group: _currentGroup!,
              tabController: _tabController,
              scrollController: _scrollController,
              isHeaderCollapsed: _isHeaderCollapsed,
              mediaAsset: mediaAsset.toString(),
              onRefresh: () => _loadGroupData(),
            );
          }
          return const _LoadingView();
        },
      ),
    );
  }
}
class _GroupContent extends StatelessWidget {
  final Group group;
  final TabController tabController;
  final ScrollController scrollController;
  final bool isHeaderCollapsed;
  final String mediaAsset;
  final VoidCallback onRefresh;
  const _GroupContent({
    required this.group,
    required this.tabController,
    required this.scrollController,
    required this.isHeaderCollapsed,
    required this.mediaAsset,
    required this.onRefresh,
  });
  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // AppBar with Live Stream Button
          SliverAppBar(
            expandedHeight: 0,
            pinned: false,
            floating: false,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(group.groupTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              // Live Stream Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _navigateToLiveStream(context, group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFE74C3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'بث مباشر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Group Header
          SliverToBoxAdapter(
            child: GroupHeaderWidget(
              group: group,
              mediaAsset: mediaAsset,
              isCollapsed: isHeaderCollapsed,
              onJoinPressed: () => _handleJoin(context),
              onLeavePressed: () => _handleLeave(context),
              onSharePressed: () => _handleShare(context),
              onMorePressed: () => _handleMore(context),
            ),
          ),
          // Group Info Card
          SliverToBoxAdapter(
            child: _GroupInfoCard(group: group),
          ),
          // Action Buttons
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: GroupActionsWidget(
                group: group,
                onJoinPressed: () => _handleJoin(context),
                onLeavePressed: () => _handleLeave(context),
                onSharePressed: () => _handleShare(context),
                onInvitePressed: () => _navigateToInviteFriends(context, group),
              ),
            ),
          ),
          // Tab Bar
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
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
                    text: 'Members',
                  ),
                  Tab(
                    icon: Icon(Iconsax.document_text),
                    text: 'Posts',
                  ),
                  Tab(
                    icon: Icon(Iconsax.info_circle),
                    text: 'About',
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: tabController,
        children: [
          // Members Tab
          GroupMembersWidget(
            group: group,
            mediaAsset: mediaAsset,
          ),
          // Posts Tab
          GroupPostsWidget(group: group),
          // Info Tab
          GroupInfoWidget(
            group: group,
            mediaAsset: mediaAsset,
          ),
        ],
      ),
    );
  }
  void _handleJoin(BuildContext context) {
    context.read<GroupsBloc>().add(JoinGroupEvent(group.groupId));
  }
  void _handleLeave(BuildContext context) {
    context.read<GroupsBloc>().add(LeaveGroupEvent(group.groupId));
  }
  void _handleShare(BuildContext context) {
    // Implement group sharing
    Get.snackbar(
      'Share',
      'Group link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  void _navigateToInviteFriends(BuildContext context, Group group) {
    Get.to(() => InviteFriendsPage(
          groupId: group.groupId,
          groupTitle: group.groupTitle,
        ));
  }
  void _handleMore(BuildContext context) {
    // Show more options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              leading: const Icon(Iconsax.share),
              title: const Text('Share Group'),
              onTap: () {
                Get.back();
                _handleShare(context);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.notification),
              title: const Text('Notification Settings'),
              onTap: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
  void _navigateToLiveStream(BuildContext context, Group group) {
    Get.to(() => ProfessionalLiveStreamWrapper(
      node: 'group',
      nodeId: group.groupId,
    ));
  }
}
/// Loading screen
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
/// Widget to display group information card
class _GroupInfoCard extends StatelessWidget {
  final Group group;
  const _GroupInfoCard({required this.group});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGroupPrivacyIcon(group.groupPrivacy),
                size: 20,
                color: _getGroupPrivacyColor(group.groupPrivacy),
              ),
              const SizedBox(width: 8),
              Text(
                _getGroupPrivacyText(group.groupPrivacy),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getGroupPrivacyColor(group.groupPrivacy),
                ),
              ),
              const Spacer(),
              if (group.membership?.isMember ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'عضو',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Iconsax.people,
                text: group.membersCountText,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              if (group.groupPublishEnabled)
                _buildInfoChip(
                  icon: Iconsax.edit_2,
                  text: 'النشر مفتوح',
                  color: Colors.green,
                )
              else
                _buildInfoChip(
                  icon: Iconsax.close_circle,
                  text: 'النشر مغلق',
                  color: Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }
  /// Build small info chip
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  /// Get group privacy icon
  IconData _getGroupPrivacyIcon(GroupPrivacy? privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return Iconsax.global;
      case GroupPrivacy.closed:
        return Iconsax.lock;
      case GroupPrivacy.secret:
        return Iconsax.eye_slash;
      default:
        return Iconsax.info_circle;
    }
  }
  /// Get group privacy color
  Color _getGroupPrivacyColor(GroupPrivacy? privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return Colors.green;
      case GroupPrivacy.closed:
        return Colors.orange;
      case GroupPrivacy.secret:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  /// Get group privacy text
  String _getGroupPrivacyText(GroupPrivacy? privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return 'مجموعة عامة';
      case GroupPrivacy.closed:
        return 'مجموعة مغلقة';
      case GroupPrivacy.secret:
        return 'مجموعة سرية';
      default:
        return 'غير محدد';
    }
  }
}