import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';
import '../../application/bloc/group_posts_bloc.dart';
import '../../data/models/group.dart';
import '../../data/models/group_membership.dart';
import '../../data/models/group_privacy.dart';
import '../../data/services/groups_api_service.dart';
import '../../data/repositories/groups_repository.dart';
import 'group_pending_requests_page.dart';
import 'edit_group_page.dart';
import 'group_members_page.dart';
import 'group_invite_friends_page.dart';

/// صفحة بروفايل المجموعة - بنفس تصميم صفحة الـ Page
/// تستقبل فقط groupId وتجلب جميع البيانات داخليًا
class GroupProfilePage extends StatefulWidget {
  const GroupProfilePage({super.key, required this.groupId});

  final int groupId;

  @override
  State<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends State<GroupProfilePage>
    with SingleTickerProviderStateMixin {
  // Group info
  Group? _currentGroup;
  bool _isLoadingGroupInfo = false;
  String? _errorMessage;
  bool _isLeavingGroup = false;

  // Tabs
  late TabController _tabController;
  static const int _idxTimeline = 0;

  // Repository
  late GroupsRepository _repository;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);

    // تهيئة Repository
    final apiClient = context.read<ApiClient>();
    _repository = GroupsRepository(GroupsApiService(apiClient));

    // جلب بيانات المجموعة
    _loadGroupInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------- Data ----------
  Future<void> _loadGroupInfo() async {
    if (_isLoadingGroupInfo) return;

    setState(() => _isLoadingGroupInfo = true);

    try {
      final groupDetails = await _repository.getGroupDetails(widget.groupId);

      if (mounted) {
        setState(() {
          _currentGroup = groupDetails;
          _isLoadingGroupInfo = false;
        });

        // جلب المنشورات بعد تحميل بيانات المجموعة
        if (groupDetails != null) {

          _loadInitialPosts();
        } else {

        }
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _isLoadingGroupInfo = false;
          // استخراج رسالة الخطأ من ApiException
          if (e.toString().contains('403')) {
            _errorMessage = 'هذه مجموعة سرية';
          } else if (e.toString().contains('404')) {
            _errorMessage = 'المجموعة غير موجودة';
          } else if (e.toString().contains('401')) {
            _errorMessage = 'يجب تسجيل الدخول أولاً';
          } else {
            _errorMessage = 'حدث خطأ في تحميل المجموعة';
          }
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadGroupInfo(),
      // _loadInitialPosts() سيتم استدعاؤها تلقائياً من _loadGroupInfo()
    ]);
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cancel_group_request_title'.tr),
        content: Text('cancel_group_request_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLeavingGroup = true);

    try {
      final success = await _repository.leaveGroup(_currentGroup!.groupId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('group_request_cancelled_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // العودة مع تحديث
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('group_request_cancel_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_occurred_with_message'.trParams({'error': e.toString()})), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLeavingGroup = false);
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_currentGroup == null) return;
    context.read<GroupPostsBloc>().add(
      LoadGroupPostsEvent(_currentGroup!.groupId.toString()),
    );
  }

  void _openCreatePost() {
    if (_currentGroup == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CreatePostPageModern(
              handle: 'group',
              handleId: _currentGroup!.groupId,
              handleName: _currentGroup!.groupTitle,
            ),
          ),
        )
        .then((_) {
          // إعادة تحميل منشورات المجموعة بعد إنشاء منشور جديد
          _loadInitialPosts();
        });
  }

  void _handleReactionChanged(String postId, String reaction) async {
    // تحديث التفاعل في GroupPostsBloc
    context.read<GroupPostsBloc>().add(
      ReactToPostInGroupEvent(int.parse(postId), reaction),
    );

    // تحديث التفاعل في PostsBloc العام إذا كان موجوداً
    context.read<PostsBloc>().add(
      ReactToPostEvent(int.parse(postId), reaction),
    );
  }

  Future<void> _toggleJoinGroup() async {
    if (_currentGroup == null) return;

    final membership = _currentGroup!.membership;
    final isJoined = membership?.isMember ?? false;
    final groupId = _currentGroup!.groupId;

    try {
      if (isJoined) {
        final success = await _repository.leaveGroup(groupId);
        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم مغادرة المجموعة')));
          await _loadGroupInfo();
        }
      } else {
        final success = await _repository.joinGroup(groupId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب الانضمام')),
          );
          await _loadGroupInfo();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    // Loading state
    if (_isLoadingGroupInfo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Error state - المجموعة غير موجودة أو خطأ في الوصول
    if (_currentGroup == null) {
      final isSecretGroup = _errorMessage?.contains('سرية') ?? false;
      final isNotFound = _errorMessage?.contains('غير موجودة') ?? false;

      return Scaffold(
        appBar: AppBar(title: Text('error'.tr)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSecretGroup
                      ? Iconsax.lock_1
                      : isNotFound
                      ? Iconsax.search_status
                      : Iconsax.info_circle,
                  size: 64,
                  color: isSecretGroup ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'group_not_available'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isSecretGroup
                      ? 'group_secret_no_access'.tr
                      : isNotFound
                      ? 'group_may_be_deleted'.tr
                      : 'group_no_access_permission'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.arrow_left),
                  label: Text('back_button'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // التحقق من حالة العضوية
    final membership = _currentGroup!.membership;
    final isPending = membership?.status == MembershipStatus.pending;
    final isNotMember =
        membership == null || membership.status == MembershipStatus.notMember;
    final isClosed = _currentGroup!.groupPrivacy == GroupPrivacy.closed;
    final isSecret = _currentGroup!.groupPrivacy == GroupPrivacy.secret;

    // استثناء المشرف من القيود (isAdmin يشمل المالك والمشرفين)
    final isAdmin = membership?.isAdmin ?? false;

    // حالة غير منضم - يجب الانضمام أولاً لرؤية المحتوى
    // (إلا إذا كان مشرف/مالك)
    if (isNotMember && (isClosed || isSecret) && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(_currentGroup!.groupTitle)),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // صورة المجموعة
                    if (_currentGroup!.groupPicture != null)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              _currentGroup!.groupPicture!,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: const Icon(Iconsax.people, size: 48),
                      ),
                    const SizedBox(height: 24),
                    Icon(
                      isSecret ? Iconsax.lock_1 : Iconsax.lock,
                      size: 64,
                      color: isSecret ? Colors.deepOrange : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentGroup!.groupTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSecret ? 'group_secret'.tr : 'group_closed'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSecret
                          ? 'group_member_to_see_secret'.tr
                          : 'group_member_to_see_posts'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    // معلومات المجموعة الأساسية فقط
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupMembersPage(
                                    group: _currentGroup!,
                                    isAdmin: _currentGroup!.membership?.isAdmin ?? false,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _InfoRow(
                                icon: Iconsax.people,
                                label: 'group_members'.tr,
                                value: '${_currentGroup!.groupMembers}',
                              ),
                            ),
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: isSecret ? Iconsax.lock_1 : Iconsax.lock,
                            label: 'group_privacy'.tr,
                            value: isSecret ? 'group_privacy_secret'.tr : 'group_privacy_closed'.tr,
                          ),
                          if (_currentGroup!.groupDescription != null) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Iconsax.document_text,
                              label: 'group_description'.tr,
                              value:
                                  _currentGroup!.groupDescription!.length > 50
                                  ? '${_currentGroup!.groupDescription!.substring(0, 50)}...'
                                  : _currentGroup!.groupDescription!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // زر الانضمام
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleJoinGroup,
                        icon: const Icon(Iconsax.user_add),
                        label: Text(
                          isSecret ? 'group_request_join'.tr : 'group_join'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.arrow_left),
                      label: Text('back_button'.tr),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // حالة الطلب المعلق - لا يمكن رؤية المحتوى
    // (إلا إذا كان مشرف/مالك)
    if (isPending && (isClosed || isSecret) && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(_currentGroup!.groupTitle)),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // صورة المجموعة
                    if (_currentGroup!.groupPicture != null)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              _currentGroup!.groupPicture!,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: const Icon(Iconsax.people, size: 48),
                      ),
                    const SizedBox(height: 24),
                    const Icon(Iconsax.clock, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'group_request_pending'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSecret
                          ? 'group_request_sent_secret'.tr
                          : 'group_request_sent'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    // معلومات المجموعة الأساسية فقط
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Iconsax.people,
                            label: 'group_members'.tr,
                            value: '${_currentGroup!.groupMembers}',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: isSecret ? Iconsax.lock_1 : Iconsax.lock,
                            label: 'group_privacy'.tr,
                            value: isSecret ? 'group_privacy_secret'.tr : 'group_privacy_closed'.tr,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // أزرار الإجراءات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // زر إلغاء الطلب
                        ElevatedButton.icon(
                          onPressed: _isLeavingGroup ? null : _leaveGroup,
                          icon: _isLeavingGroup
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Iconsax.close_circle),
                          label: Text('group_cancel_request'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // زر العودة
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Iconsax.arrow_left),
                          label: Text('back_button'.tr),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton:
          (_currentGroup!.membership?.isAdmin ?? false) &&
              _tabController.index == _idxTimeline
          ? FloatingActionButton(
              onPressed: _openCreatePost,
              child: const Icon(Iconsax.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              stretch: true,
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              title: Text(
                _currentGroup!.groupTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Settings button (only for group admin)
                if (_currentGroup!.membership?.isAdmin ?? false)
                  IconButton(
                    icon: const Icon(Iconsax.setting_2),
                    tooltip: 'group_settings'.tr,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditGroupPage(group: _currentGroup!),
                        ),
                      );

                      // إذا تم الحذف، العودة للصفحة السابقة
                      if (result == 'deleted') {
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      } else if (result == true) {
                        // إذا تم التحديث، إعادة تحميل البيانات
                        _loadGroupInfo();
                      }
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: BlocBuilder<GroupPostsBloc, GroupPostsState>(
                  builder: (context, state) {
                    final postsCount = state is GroupPostsLoadedState
                        ? state.posts.length
                        : 0;
                    return _HeaderWithStats(
                      group: _currentGroup!,
                      mediaAsset: mediaAsset,
                      onCreatePost: _openCreatePost,
                      onJoinPressed: _toggleJoinGroup,
                      postsCount: postsCount,
                    );
                  },
                ),
              ),
            ),
            // Admin Action Buttons (before tabs)
            if (_currentGroup!.membership?.isAdmin ?? false)
              SliverToBoxAdapter(
                child: _AdminActionsBar(
                  group: _currentGroup!,
                  onInviteMembers: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupInviteFriendsPage(
                          group: _currentGroup!,
                        ),
                      ),
                    );
                  },
                  onManageMembers: () {
                    // TODO: Navigate to manage members
                  },
                  onPendingRequests: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupPendingRequestsPage(group: _currentGroup!),
                      ),
                    );
                  },
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(tabController: _tabController),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              BlocBuilder<GroupPostsBloc, GroupPostsState>(
                builder: (context, state) {
                  final posts = state is GroupPostsLoadedState
                      ? state.posts
                      : <Post>[];
                  final isLoading = state is GroupPostsLoadingState;
                  final hasMore = state is GroupPostsLoadedState
                      ? state.hasMore
                      : false;
                  final isLoadingMore = state is GroupPostsLoadedState
                      ? state.isLoadingMore
                      : false;
                  final error = state is GroupPostsErrorState
                      ? state.message
                      : null;

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        final remaining =
                            scrollInfo.metrics.maxScrollExtent -
                            scrollInfo.metrics.pixels;

                        if (hasMore && !isLoadingMore) {

                          context.read<GroupPostsBloc>().add(
                            LoadMoreGroupPostsEvent(),
                          );
                        } else {

                        }
                      }
                      return false;
                    },
                    child: _TimelineTab(
                      posts: posts,
                      isLoading: isLoading,
                      isLoadingMore: isLoadingMore,
                      hasMore: hasMore,
                      error: error,
                      onRetry: _loadInitialPosts,
                      onReactionChanged: _handleReactionChanged,
                      onRefresh: () async {
                        if (_currentGroup != null) {
                          context.read<GroupPostsBloc>().add(
                            RefreshGroupPostsEvent(
                              _currentGroup!.groupId.toString(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              _AboutTab(group: _currentGroup!),
              _MembersTab(group: _currentGroup!),
              _PhotosTab(
                posts: [],
                mediaAsset: mediaAsset,
                onRefresh: _onRefresh,
              ),
              _VideosTab(
                posts: [],
                mediaAsset: mediaAsset,
                onRefresh: _onRefresh,
              ),
              _EventsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Header with Stats =====================
class _HeaderWithStats extends StatelessWidget {
  const _HeaderWithStats({
    required this.group,
    required this.mediaAsset,
    required this.onCreatePost,
    required this.onJoinPressed,
    required this.postsCount,
  });

  final Group group;
  final Uri Function(String) mediaAsset;
  final VoidCallback onCreatePost;
  final VoidCallback onJoinPressed;
  final int postsCount;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = group.groupCover != null && group.groupCover!.isNotEmpty;
    return Column(
      children: [
        // Header Image Section
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasCover
                  ? CachedNetworkImage(
                      imageUrl: mediaAsset(group.groupCover!).toString(),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

              // top gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // group avatar + name + badges
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: group.groupPicture != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: mediaAsset(
                                    group.groupPicture!,
                                  ).toString(),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Iconsax.people,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        runSpacing: 6,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.groupTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  _getPrivacyIcon(group.groupPrivacy),
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '@${group.groupName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats Section
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              // Stats Row
              Row(
                children: [
                  _Stat(
                    icon: Iconsax.people,
                    label: 'group_members_label'.tr,
                    value: _fmt(group.groupMembers),
                  ),
                  const _VSeparator(),
                  _Stat(
                    icon: Iconsax.document,
                    label: 'group_posts_label'.tr,
                    value: _fmt(postsCount),
                  ),
                  const _VSeparator(),
                  _Stat(
                    icon: Iconsax.tag,
                    label: group.category.categoryName,
                    value: '',
                  ),
                  const Spacer(),
                ],
              ),

              // Buttons Row
              if (!(group.membership?.isAdmin ?? false)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildJoinButton(
                        context,
                        group.membership,
                        onJoinPressed,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPrivacyIcon(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return Iconsax.global;
      case GroupPrivacy.closed:
        return Iconsax.lock;
      case GroupPrivacy.secret:
        return Iconsax.eye_slash;
    }
  }

  Widget _buildJoinButton(
    BuildContext context,
    GroupMembership? membership,
    VoidCallback onPressed,
  ) {
    if (membership == null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Iconsax.add),
        label: Text('group_join'.tr),
      );
    }

    if (membership.isPending) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Iconsax.clock),
        label: Text('group_pending_review'.tr),
      );
    } else if (membership.isMember) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Iconsax.logout),
        label: Text('group_leave'.tr),
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
      );
    } else {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Iconsax.add),
        label: Text('group_join'.tr),
      );
    }
  }
}

// ===================== Admin Actions Bar =====================
class _AdminActionsBar extends StatelessWidget {
  const _AdminActionsBar({
    required this.group,
    required this.onInviteMembers,
    required this.onManageMembers,
    required this.onPendingRequests,
  });

  final Group group;
  final VoidCallback onInviteMembers;
  final VoidCallback onManageMembers;
  final VoidCallback onPendingRequests;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onInviteMembers,
              icon: const Icon(Iconsax.user_add, size: 18),
              label: Text('group_invite_button'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupMembersPage(
                      group: group,
                      isAdmin: group.membership?.isAdmin ?? false,
                    ),
                  ),
                );
              },
              icon: const Icon(Iconsax.people, size: 18),
              label: Text('group_members_button'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPendingRequests,
              icon: const Icon(Iconsax.notification, size: 18),
              label: Text('group_requests_button'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Tabs Header Delegate =====================
class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabsHeaderDelegate({required this.tabController});
  final TabController tabController;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(icon: const Icon(Iconsax.activity), text: 'group_tab_posts'.tr),
          Tab(icon: const Icon(Iconsax.info_circle), text: 'group_tab_about'.tr),
          Tab(icon: const Icon(Iconsax.people), text: 'group_tab_members'.tr),
          Tab(icon: const Icon(Iconsax.image), text: 'group_tab_photos'.tr),
          Tab(icon: const Icon(Iconsax.video), text: 'group_tab_videos'.tr),
          Tab(icon: const Icon(Iconsax.calendar), text: 'group_tab_events'.tr),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface.withOpacity(0.75);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: onSurf),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value.isEmpty ? label : '$value $label',
            style: TextStyle(color: onSurf, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VSeparator extends StatelessWidget {
  const _VSeparator();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).dividerColor.withOpacity(0.6),
    );
  }
}

// ===================== Tabs =====================

// -- Timeline
class _TimelineTab extends StatelessWidget {
  const _TimelineTab({
    required this.posts,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.onRetry,
    required this.onReactionChanged,
    required this.onRefresh,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;
  final Function(String, String) onReactionChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.close_circle, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('retry_button'.tr),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.document, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'group_no_posts'.tr,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: posts.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            // مؤشر التحميل في النهاية
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return PostCard(
            post: posts[index],
            onReactionChanged: onReactionChanged,
          );
        },
      ),
    );
  }
}

// -- About
class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        if (group.groupDescription != null) ...[
          _SectionTitle(title: 'group_description_section'.tr, icon: Iconsax.document_text),
          const SizedBox(height: 8),
          _InfoCard(
            isDark: isDark,
            child: Text(
              group.groupDescription!,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Group Info
        _SectionTitle(title: 'group_information_section'.tr, icon: Iconsax.info_circle),
        const SizedBox(height: 8),
        _InfoCard(
          isDark: isDark,
          child: Column(
            children: [
              _InfoRow(
                icon: Iconsax.global,
                label: 'group_privacy'.tr,
                value: group.groupPrivacy.displayName,
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Iconsax.people,
                label: 'group_members'.tr,
                value: '${group.groupMembers} ${'group_member_unit'.tr}',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Iconsax.tag,
                label: 'group_category'.tr,
                value: group.category.categoryName,
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Iconsax.calendar,
                label: 'group_creation_date'.tr,
                value: group.groupDate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Admin Info
        _SectionTitle(title: 'group_admin_section'.tr, icon: Iconsax.user),
        const SizedBox(height: 8),
        _InfoCard(
          isDark: isDark,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: group.admin.picture.isNotEmpty
                  ? CachedNetworkImageProvider(
                      context
                          .read<AppConfig>()
                          .mediaAsset(group.admin.picture)
                          .toString(),
                    )
                  : null,
              child: group.admin.picture.isEmpty
                  ? const Icon(Iconsax.user)
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    group.admin.fullname,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (group.admin.verified)
                  const Icon(
                    Iconsax.verify,
                    size: 18,
                    color: Colors.lightBlueAccent,
                  ),
              ],
            ),
            subtitle: Text('@${group.admin.username}'),
          ),
        ),
      ],
    );
  }
}

// -- Members
class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.people, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'coming_soon'.tr,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '${group.groupMembers} ${'group_member_unit'.tr}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// -- Photos
class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.posts,
    required this.mediaAsset,
    required this.onRefresh,
  });

  final List<Post> posts;
  final Uri Function(String) mediaAsset;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.image, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'group_no_photos'.tr,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// -- Videos
class _VideosTab extends StatelessWidget {
  const _VideosTab({
    required this.posts,
    required this.mediaAsset,
    required this.onRefresh,
  });

  final List<Post> posts;
  final Uri Function(String) mediaAsset;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'group_no_videos'.tr,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// -- Events
class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.calendar, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'group_no_events'.tr,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ===================== Widgets Helper =====================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
