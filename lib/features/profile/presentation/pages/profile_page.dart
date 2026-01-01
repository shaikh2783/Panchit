import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/profile/data/services/profile_api_service.dart';
import 'package:snginepro/features/profile/application/bloc/profile_posts_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/friends/data/services/user_relationships_service.dart';
import 'package:snginepro/features/friends/data/models/subscription.dart';
import 'package:snginepro/features/photos/data/services/user_photos_service.dart';
import 'package:snginepro/features/photos/data/models/user_photo.dart';
import 'package:snginepro/features/photos/data/models/user_album.dart';
import 'package:snginepro/features/photos/presentation/pages/user_photos_page.dart';
import 'package:snginepro/features/photos/presentation/pages/user_albums_page.dart';
import 'package:snginepro/features/blocking/data/services/blocking_service.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/models/profile_completion_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../reports/presentation/pages/report_content_page.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../friends/presentation/widgets/add_friend_button.dart';
import '../../../friends/data/models/friendship_model.dart';
import '../../../friends/data/services/friends_api_service.dart';
import '../widgets/profile_completion_card.dart';
import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  final String? username;
  final int? userId;

  const ProfilePage({super.key, this.username, this.userId})
    : assert(
        username != null || userId != null,
        'Either username or userId must be provided',
      );

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late ProfileApiService _profileService;
  UserProfileResponse? _profileData;
  ProfileCompletionData? _completionData;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username ||
        oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      _profileService = ProfileApiService(apiClient);

      final profile = widget.username != null
          ? await _profileService.getProfileByUsername(widget.username!)
          : await _profileService.getProfileById(widget.userId!);

      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });

      // Check blocked status (skip self)
      try {
        final userIdInt = int.tryParse(profile.profile.id) ?? 0;
        if (userIdInt > 0 && !profile.relationship.isSelf) {
          final apiClient2 = context.read<ApiClient>();
          final blockingService = BlockingService(apiClient2);
          final isBlocked = await blockingService.checkUserBlocked(
            userId: userIdInt,
          );
          if (mounted) setState(() => _isBlocked = isBlocked);
        }
      } catch (_) {
        // ignore errors silently
      }

      if (profile.relationship.isSelf) {
        _loadProfileCompletion();
      }

      _loadPosts(profile.profile.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileCompletion() async {
    try {
      final response = await _profileService.getProfileCompletion();
      if (!mounted) return;
      setState(() {
        _completionData = response.data;
      });
    } catch (e) {
      // Handle error silently for profile completion
    }
  }

  Future<void> _loadPosts(String userId) async {
    context.read<ProfilePostsBloc>().add(LoadUserPostsEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                Text('${'error'.tr}: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: Text('profile_retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_profileData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('profile_not_found'.tr)),
      );
    }

    final profile = _profileData!.profile;
    final stats = _profileData!.stats;
    final relationship = _profileData!.relationship;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(profile, relationship, stats),
            ),
            actions: relationship.isSelf
                ? [
                    IconButton(
                      icon: const Icon(Iconsax.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileEditPage(profile: profile),
                          ),
                        );
                        if (result == true && mounted) _loadProfile();
                      },
                    ),
                  ]
                : null,
          ),
        ],
        body: Column(
          children: [
            if (!relationship.isSelf) _buildActionButtons(relationship),
            _buildTabBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(),
                    _buildAboutTab(profile),
                    _buildPhotosTab(stats),
                    _buildVideosTab(),
                    _buildFriendsTab(stats),
                    _buildMoreTab(profile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(
    UserProfile profile,
    ProfileRelationship relationship,
    ProfileStats stats,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (profile.cover != null)
          CachedNetworkImage(
            imageUrl: profile.cover!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[300]),
            errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
          )
        else
          Container(color: Colors.grey[300]),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: CachedNetworkImageProvider(
                            profile.picture,
                          ),
                        ),
                        if (profile.isOnline == true)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Iconsax.verify,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                            if (profile.isSubscribed)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Iconsax.star_1,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${profile.username}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat('Posts', stats.posts),
                  _buildHeaderStat('Photos', stats.photos),
                  _buildHeaderStat('Friends', stats.friends),
                  _buildHeaderStat('Followers', stats.followers),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, int count) {
    return Column(
      children: [
        Text(
          _formatNumber(count),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  // Actions
  Widget _buildActionButtons(ProfileRelationship relationship) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // الصف الأول: زر إضافة صديق + زر متابعة
          Row(
            children: [
              Expanded(child: _buildFriendButton(relationship)),
              const SizedBox(width: 10),
              Expanded(child: _buildFollowButton(relationship)),
            ],
          ),
          const SizedBox(height: 10),
          // الصف الثاني: زر الرسالة + زر المزيد
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.message,
                  label: 'send_message'.tr,
                  onPressed: () {
                    /* open chat */
                  },
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.more,
                  label: 'more_options'.tr,
                  onPressed: _showMoreOptions,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton(ProfileRelationship relationship) {
    // Convert ProfileRelationship to FriendshipStatus for friend system
    FriendshipStatus friendshipStatus;
    if (relationship.isFriend) {
      friendshipStatus = FriendshipStatus.friends;
    } else if (relationship.hasPendingRequest) {
      friendshipStatus = FriendshipStatus.requested;
    } else if (relationship.canCancelRequest) {
      friendshipStatus = FriendshipStatus.pending;
    } else {
      friendshipStatus = FriendshipStatus.none;
    }

    return AddFriendButton(
      userId: widget.userId ?? 0,
      initialStatus: friendshipStatus,
      size: AddFriendButtonSize.medium,
      style: AddFriendButtonStyle.filled,
      onStatusChanged: (newStatus) {
        // Reload profile to get updated relationship status
        _loadProfile();
      },
    );
  }

  Widget _buildFollowButton(ProfileRelationship relationship) {
    final isFollowing = relationship.isFollowing;

    return ElevatedButton.icon(
      onPressed: () => _handleFollowAction(isFollowing),
      icon: Icon(isFollowing ? Iconsax.user_tick : Iconsax.user_add, size: 18),
      label: Text(isFollowing ? 'متابع' : 'متابعة'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
        foregroundColor: isFollowing ? Colors.black87 : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleFollowAction(bool isCurrentlyFollowing) async {
    if (_profileData == null) return;

    final userId = int.parse(_profileData!.profile.id);
    final apiClient = context.read<ApiClient>();
    final friendsService = FriendsApiService(apiClient);

    FriendActionResult result;
    if (isCurrentlyFollowing) {
      result = await friendsService.unfollowUser(userId);
    } else {
      result = await friendsService.followUser(userId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (result.success) {
        // إعادة تحميل البيانات لتحديث الحالة
        _loadProfile();
      }
    }
  }

  Widget _buildSecondaryButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Icon(icon, size: 20),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!(_profileData?.relationship.isSelf ?? true))
              ListTile(
                leading: Icon(
                  _isBlocked ? Iconsax.user_minus : Iconsax.danger,
                  color: _isBlocked ? Colors.orange : Colors.red,
                ),
                title: Text(
                  _isBlocked
                      ? 'profile_unblock_user'.tr
                      : 'profile_block_user'.tr,
                ),
                subtitle: Text(
                  _isBlocked
                      ? 'Allow this user to interact with you'
                      : 'Prevent this user from interacting with you',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleBlockUser();
                },
              ),
            ListTile(
              leading: const Icon(Iconsax.flag),
              title: Text('report'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportContentPage(
                      contentType: ReportContentType.user,
                      contentId:
                          _profileData?.profile.id ??
                          widget.userId?.toString() ??
                          '',
                      contentAuthor:
                          _profileData?.profile.fullName ??
                          _profileData?.profile.username ??
                          widget.username ??
                          'User',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title: Text('share'.tr),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBlockUser() async {
    if (_profileData == null) return;
    final isSelf = _profileData!.relationship.isSelf;
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot block yourself'.tr)),
      );
      return;
    }

    final userId = int.tryParse(_profileData!.profile.id) ?? 0;
    if (userId <= 0) return;

    final apiClient = context.read<ApiClient>();
    final service = BlockingService(apiClient);

    try {
      if (_isBlocked) {
        final resp = await service.unblockUser(userId: userId);
        final ok =
            (resp['status']?.toString() == 'success') ||
            (resp['message']?.toString().toLowerCase().contains('unblocked') ??
                false);
        if (ok) {
          setState(() => _isBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message']?.toString() ?? 'User unblocked successfully',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message']?.toString() ?? 'profile_unblock_failed'.tr,
              ),
            ),
          );
        }
      } else {
        final resp = await service.blockUser(userId: userId);
        final ok =
            (resp['status']?.toString() == 'success') ||
            (resp['message']?.toString().toLowerCase().contains('blocked') ??
                false);
        if (ok) {
          setState(() => _isBlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message']?.toString() ?? 'User blocked successfully',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message']?.toString() ?? 'profile_block_failed'.tr,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${'error'.tr}: $e')));
    }
  }

  // Tabs
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          Tab(
            icon: const Icon(Iconsax.document_text),
            text: 'profile_tab_posts'.tr,
          ),
          Tab(
            icon: const Icon(Iconsax.info_circle),
            text: 'profile_tab_about'.tr,
          ),
          Tab(icon: const Icon(Iconsax.gallery), text: 'profile_tab_photos'.tr),
          Tab(
            icon: const Icon(Iconsax.video_play),
            text: 'profile_tab_videos'.tr,
          ),
          Tab(icon: const Icon(Iconsax.people), text: 'profile_tab_friends'.tr),
          Tab(
            icon: const Icon(Iconsax.more_square),
            text: 'profile_tab_more'.tr,
          ),
        ],
      ),
    );
  }

  // Posts
  Widget _buildPostsTab() {
    final profile = _profileData!.profile;
    final relationship = _profileData!.relationship;

    return BlocBuilder<ProfilePostsBloc, ProfilePostsState>(
      builder: (context, state) {
        if (state is ProfilePostsLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProfilePostsErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('${'error'.tr}: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadPosts(profile.id),
                    child: Text('retry_button'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final posts = state is ProfilePostsLoadedState ? state.posts : <Post>[];
        final hasMore = state is ProfilePostsLoadedState
            ? state.hasMore
            : false;
        final isLoadingMore = state is ProfilePostsLoadedState
            ? state.isLoadingMore
            : false;

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // تحقق من الوصول لنهاية القائمة
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              final remaining =
                  scrollInfo.metrics.maxScrollExtent -
                  scrollInfo.metrics.pixels;

              if (hasMore && !isLoadingMore) {

                context.read<ProfilePostsBloc>().add(LoadMoreUserPostsEvent());
              } else {

              }
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ProfilePostsBloc>().add(
                RefreshUserPostsEvent(profile.id),
              );
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (relationship.isSelf &&
                    _completionData != null &&
                    !_completionData!.isComplete)
                  ProfileCompletionCard(
                    completionData: _completionData!,
                    profile: profile,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileEditPage(profile: profile),
                        ),
                      );
                      if (result == true && mounted) _loadProfile();
                    },
                  ),
                if (posts.isEmpty && !isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.document_1,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...posts.map((p) {
                    return PostCard(
                      key: ValueKey('profile-post-${p.id}'),
                      post: p,
                      onReactionChanged: (postId, reaction) {

                        // تحديث التفاعل في ProfilePostsBloc فقط (لتجنب الطلبات المكررة)
                        context.read<ProfilePostsBloc>().add(
                          ReactToPostInProfileEvent(
                            int.parse(postId),
                            reaction,
                          ),
                        );
                      },
                      onPostUpdated: (updatedPost) {
                        // تحديث المنشور في ProfilePostsBloc فقط
                        context.read<ProfilePostsBloc>().add(
                          UpdatePostInProfileEvent(updatedPost),
                        );
                      },
                      onPostDeleted: (postId) {
                        // حذف المنشور من ProfilePostsBloc فقط
                        context.read<ProfilePostsBloc>().add(
                          DeletePostFromProfileEvent(int.parse(postId)),
                        );
                      },
                    );
                  }).toList(),

                  // Loading indicator for pagination
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // About
  Widget _buildAboutTab(UserProfile profile) {
    final hasWork =
        (profile.work.title?.isNotEmpty ?? false) ||
        (profile.work.place?.isNotEmpty ?? false) ||
        (profile.work.website?.isNotEmpty ?? false);

    final hasLocation =
        (profile.location.currentCity?.isNotEmpty ?? false) ||
        (profile.location.hometown?.isNotEmpty ?? false);

    final hasEducation =
        (profile.education.school?.isNotEmpty ?? false) ||
        (profile.education.major?.isNotEmpty ?? false) ||
        (profile.education.classYear?.isNotEmpty ?? false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if ((profile.about ?? '').isNotEmpty) ...[
          _InfoCard(
            title: 'profile_about_title'.tr,
            icon: Iconsax.info_circle,
            children: [
              Text(
                profile.about!,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (hasWork) ...[
          _InfoCard(
            title: 'profile_work_title'.tr,
            icon: Iconsax.briefcase,
            children: [
              if ((profile.work.title ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.award,
                  'profile_position'.tr,
                  profile.work.title!,
                ),
              if ((profile.work.place ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.building,
                  'profile_company'.tr,
                  profile.work.place!,
                ),
              if ((profile.work.website ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.link,
                  'profile_website'.tr,
                  profile.work.website!,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (hasLocation) ...[
          _InfoCard(
            title: 'profile_location_title'.tr,
            icon: Iconsax.location,
            children: [
              if ((profile.location.currentCity ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.location_tick,
                  'profile_current_city'.tr,
                  profile.location.currentCity!,
                ),
              if ((profile.location.hometown ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.home_2,
                  'profile_hometown'.tr,
                  profile.location.hometown!,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (hasEducation) ...[
          _InfoCard(
            title: 'profile_education_title'.tr,
            icon: Iconsax.book,
            children: [
              if ((profile.education.school ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.building_3,
                  'profile_school'.tr,
                  profile.education.school!,
                ),
              if ((profile.education.major ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.teacher,
                  'profile_major'.tr,
                  profile.education.major!,
                ),
              if ((profile.education.classYear ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.calendar_1,
                  'profile_class_year'.tr,
                  profile.education.classYear!,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _InfoCard(
          title: 'profile_details_title'.tr,
          icon: Iconsax.user,
          children: [
            if (profile.country != null)
              _buildInfoRow(
                Iconsax.global,
                'profile_country'.tr,
                profile.country!.name,
              ),
            if ((profile.gender).isNotEmpty)
              _buildInfoRow(
                Iconsax.user,
                'profile_gender'.tr,
                profile.gender == 'male'
                    ? 'profile_gender_male'.tr
                    : 'profile_gender_female'.tr,
              ),
            if ((profile.birthDate ?? '').isNotEmpty)
              _buildInfoRow(
                Iconsax.cake,
                'profile_birthday'.tr,
                profile.birthDate!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _InfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // السطر الأول (Position:, Company:, Lives in:)
                Text(
                  "$label:",
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 2),

                // السطر الثاني (القيمة العربية)
                Text(
                  value,
                  textDirection: TextDirection.rtl, // ✅ القيمة عربية
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration:
                        TextDecoration.none, // ✅ يمنع أي خط أصفر أو أزرق
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Other tabs
  Widget _buildPhotosTab(ProfileStats stats) {
    final items = [
      _FriendMenuItem(
        title: 'profile_photos'.tr,
        icon: Iconsax.gallery,
        count: stats.photos,
      ),
      _FriendMenuItem(
        title: 'profile_albums_menu'.tr,
        icon: Iconsax.folder_2,
        count: 0,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = items[index];
        return _FriendMenuTile(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  final profileUsername =
                      widget.username ?? _profileData?.profile.username;
                  if (index == 0) {
                    return UserPhotosPage(username: profileUsername);
                  } else {
                    return UserAlbumsPage(username: profileUsername);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideosTab() =>
      Center(child: Text('profile_videos_coming_soon'.tr));
  Widget _buildFriendsTab(ProfileStats stats) {
    return _FriendsRelationshipsTab(userId: widget.userId, stats: stats);
  }

  Widget _buildMoreTab(UserProfile profile) {
    final socialLinks = _profileData!.socialLinks;
    final hasLinks = socialLinks.values.any((v) => (v ?? '').isNotEmpty);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasLinks)
          _InfoCard(
            title: 'Social Links',
            icon: Iconsax.global,
            children: [
              if ((socialLinks['website'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'Website',
                  Iconsax.language_circle,
                  socialLinks['website']!,
                ),
              if ((socialLinks['facebook'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'Facebook',
                  Iconsax.facebook,
                  socialLinks['facebook']!,
                ),
              if ((socialLinks['x'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'X (Twitter)',
                  Iconsax.hashtag,
                  socialLinks['x']!,
                ),
              if ((socialLinks['instagram'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'Instagram',
                  Iconsax.instagram,
                  socialLinks['instagram']!,
                ),
              if ((socialLinks['youtube'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'YouTube',
                  Iconsax.video,
                  socialLinks['youtube']!,
                ),
              if ((socialLinks['linkedin'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'LinkedIn',
                  Iconsax.briefcase,
                  socialLinks['linkedin']!,
                ),
            ],
          )
        else
          Center(child: Text('profile_no_social_links'.tr)),
      ],
    );
  }

  Widget _buildSocialLink(String name, IconData icon, String url) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Iconsax.export_3, size: 20),
      onTap: () {
        // TODO: launch URL
      },
    );
  }
}

class _FriendMenuItem {
  final String title;
  final IconData icon;
  final int? count;

  const _FriendMenuItem({required this.title, required this.icon, this.count});
}

class _FriendMenuTile extends StatelessWidget {
  const _FriendMenuTile({required this.item, required this.onTap});

  final _FriendMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.count!.toString(),
                    style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else
                Icon(Iconsax.arrow_right_3, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsRelationshipsTab extends StatelessWidget {
  final int? userId;
  final ProfileStats stats;

  const _FriendsRelationshipsTab({required this.userId, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FriendMenuItem(
        title: 'profile_friends_menu'.tr,
        icon: Iconsax.profile_2user,
        count: stats.friends,
      ),
      _FriendMenuItem(
        title: 'profile_followers_menu'.tr,
        icon: Iconsax.user_tick,
        count: stats.followers,
      ),
      _FriendMenuItem(
        title: 'profile_followings_menu'.tr,
        icon: Iconsax.user_add,
        count: stats.followings,
      ),
      _FriendMenuItem(
        title: 'profile_subscriptions_menu'.tr,
        icon: Iconsax.star,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FriendMenuTile(
          item: item,
          onTap: () {
            // Navigate to respective page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  switch (index) {
                    case 0:
                      return _FriendsListPage(userId: userId);
                    case 1:
                      return _FollowersListPage(userId: userId);
                    case 2:
                      return _FollowingsListPage(userId: userId);
                    case 3:
                      return _SubscriptionsListPage(userId: userId);
                    default:
                      return const SizedBox();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Separate pages for each list type
class _FriendsListPage extends StatelessWidget {
  final int? userId;

  const _FriendsListPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserRelationshipsService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('profile_friends_menu'.tr)),
      body: _FriendsListView(userId: userId, service: service),
    );
  }
}

class _FollowersListPage extends StatelessWidget {
  final int? userId;

  const _FollowersListPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserRelationshipsService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('profile_followers_menu'.tr)),
      body: _FollowersListView(userId: userId, service: service),
    );
  }
}

class _FollowingsListPage extends StatelessWidget {
  final int? userId;

  const _FollowingsListPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserRelationshipsService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('profile_followings_menu'.tr)),
      body: _FollowingsListView(userId: userId, service: service),
    );
  }
}

class _SubscriptionsListPage extends StatelessWidget {
  final int? userId;

  const _SubscriptionsListPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserRelationshipsService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('profile_subscriptions_menu'.tr)),
      body: _SubscriptionsListView(userId: userId, service: service),
    );
  }
}

class _FriendsListView extends StatefulWidget {
  final int? userId;
  final UserRelationshipsService service;

  const _FriendsListView({required this.userId, required this.service});

  @override
  State<_FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<_FriendsListView> {
  List<dynamic> _friends = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFriends();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadMoreFriends();
      }
    }
  }

  Future<void> _loadFriends() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFriends(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _friends = result['friends'] as List<dynamic>;
          _currentPage = 1;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_friends'.tr)),
        );
      }
    }
  }

  Future<void> _loadMoreFriends() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFriends(
        userId: widget.userId,
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _friends.addAll(result['friends'] as List<dynamic>);
          _currentPage++;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_friends'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_friends.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'profile_no_friends'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _friends.length + (_hasMore && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _friends.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final friend = _friends[index];
          return _UserListTile(user: friend);
        },
      ),
    );
  }
}

class _FollowersListView extends StatefulWidget {
  final int? userId;
  final UserRelationshipsService service;

  const _FollowersListView({required this.userId, required this.service});

  @override
  State<_FollowersListView> createState() => _FollowersListViewState();
}

class _FollowersListViewState extends State<_FollowersListView> {
  List<dynamic> _followers = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFollowers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadMoreFollowers();
      }
    }
  }

  Future<void> _loadFollowers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFollowers(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _followers = result['followers'] as List<dynamic>;
          _currentPage = 1;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_followers'.tr)),
        );
      }
    }
  }

  Future<void> _loadMoreFollowers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFollowers(
        userId: widget.userId,
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _followers.addAll(result['followers'] as List<dynamic>);
          _currentPage++;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_followers'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_followers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.user_tick, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'profile_no_followers'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _followers.length + (_hasMore && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _followers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final follower = _followers[index];
          return _UserListTile(user: follower);
        },
      ),
    );
  }
}

class _FollowingsListView extends StatefulWidget {
  final int? userId;
  final UserRelationshipsService service;

  const _FollowingsListView({required this.userId, required this.service});

  @override
  State<_FollowingsListView> createState() => _FollowingsListViewState();
}

class _FollowingsListViewState extends State<_FollowingsListView> {
  List<dynamic> _followings = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFollowings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadMoreFollowings();
      }
    }
  }

  Future<void> _loadFollowings() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFollowings(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _followings = result['followings'] as List<dynamic>;
          _currentPage = 1;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_followings'.tr)),
        );
      }
    }
  }

  Future<void> _loadMoreFollowings() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getFollowings(
        userId: widget.userId,
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _followings.addAll(result['followings'] as List<dynamic>);
          _currentPage++;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_followings'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_followings.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.user_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'profile_not_following'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowings,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _followings.length + (_hasMore && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _followings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final following = _followings[index];
          return _UserListTile(user: following);
        },
      ),
    );
  }
}

class _SubscriptionsListView extends StatefulWidget {
  final int? userId;
  final UserRelationshipsService service;

  const _SubscriptionsListView({required this.userId, required this.service});

  @override
  State<_SubscriptionsListView> createState() => _SubscriptionsListViewState();
}

class _SubscriptionsListViewState extends State<_SubscriptionsListView> {
  List<Subscription> _subscriptions = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadMoreSubscriptions();
      }
    }
  }

  Future<void> _loadSubscriptions() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getSubscriptions(
        userId: widget.userId,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _subscriptions = result['subscriptions'] as List<Subscription>;
          _currentPage = 1;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_subscriptions'.tr)),
        );
      }
    }
  }

  Future<void> _loadMoreSubscriptions() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getSubscriptions(
        userId: widget.userId,
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _subscriptions.addAll(result['subscriptions'] as List<Subscription>);
          _currentPage++;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _hasMore = pagination['has_more'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_error_loading_subscriptions'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subscriptions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.star, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'profile_no_subscriptions'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _subscriptions.length + (_hasMore && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _subscriptions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final subscription = _subscriptions[index];
          return _SubscriptionListTile(subscription: subscription);
        },
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final dynamic user; // Follower or similar

  const _UserListTile({required this.user});

  String get _name => (user.name ?? '') as String;
  String get _picture => (user.userPicture ?? '') as String;
  bool get _isOnline => (user.isOnline ?? false) as bool;
  bool get _isVerified => (user.isVerified ?? false) as bool;
  int get _mutualFriends => (user.mutualFriendsCount ?? 0) as int;
  int? get _userId => user.userId as int?;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: _picture.isNotEmpty
                ? CachedNetworkImageProvider(_picture)
                : null,
            child: _picture.isEmpty ? const Icon(Iconsax.user) : null,
          ),
          if (_isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(_name),
          if (_isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Iconsax.verify, color: Colors.blue, size: 16),
            ),
        ],
      ),
      subtitle: Text(
        'profile_mutual_friends'.trParams({'count': _mutualFriends.toString()}),
      ),
      trailing: const Icon(Iconsax.arrow_right_3),
      onTap: () {
        if (_userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: _userId),
            ),
          );
        }
      },
    );
  }
}

class _SubscriptionListTile extends StatelessWidget {
  final Subscription subscription;

  const _SubscriptionListTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final picture = subscription.displayPicture;
    final name = subscription.displayName;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: picture != null
            ? CachedNetworkImageProvider(picture)
            : null,
        child: picture == null
            ? Icon(
                subscription.nodeType == 'profile'
                    ? Iconsax.user
                    : subscription.nodeType == 'page'
                    ? Iconsax.folder
                    : Iconsax.people,
              )
            : null,
      ),
      title: Text(name),
      subtitle: Text(
        subscription.nodeType == 'profile'
            ? 'profile_subscription_type_profile'.tr
            : subscription.nodeType == 'page'
            ? 'profile_subscription_type_page'.tr
            : 'profile_subscription_type_group'.tr,
      ),
      trailing: const Icon(Iconsax.arrow_right_3),
      onTap: () {
        // Handle subscription tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${subscription.nodeType}: $name')),
        );
      },
    );
  }
}

// ==================== Photos & Albums Pages ====================

// Photos and Albums pages are extracted into dedicated files under
// features/photos/presentation/pages for better maintainability.

class _UserPhotosGrid extends StatefulWidget {
  final UserPhotosService service;

  const _UserPhotosGrid({required this.service});

  @override
  State<_UserPhotosGrid> createState() => _UserPhotosGridState();
}

class _UserPhotosGridState extends State<_UserPhotosGrid> {
  List<UserPhoto> _photos = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getUserPhotos(
        page: _currentPage,
        limit: 20,
      );

      final newPhotos = result['photos'] as List<UserPhoto>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        _photos.addAll(newPhotos);
        _hasMore = pagination['has_more'] == true;
        final total = pagination['total'];
        if (total != null) {
          _totalCount = int.tryParse(total.toString()) ?? _totalCount;
        }
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading photos: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return Center(child: Text('profile_no_photos'.tr));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.photo,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'Showing ${_photos.length}${_totalCount > 0 ? ' of $_totalCount' : ''} photos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount:
                _photos.length +
                (_isLoading ? 1 : 0) +
                ((_hasMore && !_isLoading) ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator item
              if (index == _photos.length && _isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Load more item
              if (index == _photos.length + (_isLoading ? 1 : 0) &&
                  _hasMore &&
                  !_isLoading) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _loadPhotos,
                      icon: const Icon(Icons.expand_more),
                      label: Text('profile_load_more'.tr),
                    ),
                  ),
                );
              }

              final photo = _photos[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PhotoViewerPage(
                          photos: _photos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: photo.source,
                          child: CachedNetworkImage(
                            imageUrl: photo.source,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        if (photo.isBlurred)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.blur_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserAlbumsGrid extends StatefulWidget {
  final UserPhotosService service;

  const _UserAlbumsGrid({required this.service});

  @override
  State<_UserAlbumsGrid> createState() => _UserAlbumsGridState();
}

class _UserAlbumsGridState extends State<_UserAlbumsGrid> {
  List<UserAlbum> _albums = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAlbums();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadAlbums();
    }
  }

  Future<void> _loadAlbums() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getUserAlbums(
        page: _currentPage,
        limit: 20,
      );

      final newAlbums = result['albums'] as List<UserAlbum>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        _albums.addAll(newAlbums);
        _hasMore = pagination['has_more'] == true;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading albums: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_albums.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_albums.isEmpty) {
      return Center(child: Text('profile_no_albums'.tr));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _albums.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _albums.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final album = _albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _AlbumPhotosPage(album: album),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: album.cover != null
                      ? CachedNetworkImage(
                          imageUrl: album.cover!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Iconsax.folder_2, size: 48),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${album.photosCount} photos',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumPhotosPage extends StatelessWidget {
  final UserAlbum album;

  const _AlbumPhotosPage({required this.album});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserPhotosService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text(album.title)),
      body: _AlbumPhotosGrid(albumId: album.albumId, service: service),
    );
  }
}

class _AlbumPhotosGrid extends StatefulWidget {
  final String albumId;
  final UserPhotosService service;

  const _AlbumPhotosGrid({required this.albumId, required this.service});

  @override
  State<_AlbumPhotosGrid> createState() => _AlbumPhotosGridState();
}

class _AlbumPhotosGridState extends State<_AlbumPhotosGrid> {
  List<UserPhoto> _photos = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.service.getAlbumPhotos(
        albumId: widget.albumId,
        page: _currentPage,
        limit: 20,
      );

      final newPhotos = result['photos'] as List<UserPhoto>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        _photos.addAll(newPhotos);
        _hasMore = pagination['has_more'] == true;
        final total = pagination['total'];
        if (total != null) {
          _totalCount = int.tryParse(total.toString()) ?? _totalCount;
        }
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading photos: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return const Center(child: Text('No photos in this album'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.photo_album,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'Showing ${_photos.length}${_totalCount > 0 ? ' of $_totalCount' : ''} photos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount:
                _photos.length +
                (_isLoading ? 1 : 0) +
                ((_hasMore && !_isLoading) ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator item
              if (index == _photos.length && _isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Load more item
              if (index == _photos.length + (_isLoading ? 1 : 0) &&
                  _hasMore &&
                  !_isLoading) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _loadPhotos,
                      icon: const Icon(Icons.expand_more),
                      label: Text('profile_load_more'.tr),
                    ),
                  ),
                );
              }

              final photo = _photos[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PhotoViewerPage(
                          photos: _photos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: photo.source,
                          child: CachedNetworkImage(
                            imageUrl: photo.source,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        if (photo.isBlurred)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.blur_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoViewerPage extends StatefulWidget {
  final List<UserPhoto> photos;
  final int initialIndex;

  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final PageController _controller;
  late int _currentIndex;
  bool _uiVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => setState(() => _uiVisible = !_uiVisible),
                child: Center(
                  child: Hero(
                    tag: photo.source,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: photo.source,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top controls
          AnimatedOpacity(
            opacity: _uiVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          // Blur indicator
          if (photos[_currentIndex].isBlurred)
            Positioned(
              bottom: 24,
              right: 24,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.blur_on, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'profile_blurred'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
