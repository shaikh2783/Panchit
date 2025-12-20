import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/profile/data/services/profile_api_service.dart';
import 'package:snginepro/features/profile/application/bloc/profile_posts_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
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
                Text('Error: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
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
        body: Center(child: Text('Profile not found')),
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
                    _buildPhotosTab(),
                    _buildVideosTab(),
                    _buildFriendsTab(),
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
                  _buildHeaderStat('posts'.tr, stats.posts),
                  _buildHeaderStat('photos'.tr, stats.photos),
                  _buildHeaderStat('friends'.tr, stats.friends),
                  _buildHeaderStat('followers'.tr, stats.followers),
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
      child: Row(
        children: [
          // زر إضافة صديق
          Expanded(child: _buildFriendButton(relationship)),
          const SizedBox(width: 8),
          // زر متابعة
          Expanded(child: _buildFollowButton(relationship)),
          const SizedBox(width: 8),
          _buildSecondaryButton(Iconsax.message, 'messages'.tr, () {
            /* open chat */
          }),
          const SizedBox(width: 8),
          _buildSecondaryButton(Iconsax.more, 'show_more'.tr, _showMoreOptions),
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
      icon: Icon(
        isFollowing ? Iconsax.user_tick : Iconsax.user_add,
        size: 18,
      ),
      label: Text(isFollowing ? 'follower'.tr : 'Tracking'),
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
            ListTile(
              leading: const Icon(Iconsax.danger),
              title:  Text('block'.tr),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Iconsax.flag),
              title:  Text('report'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportContentPage(
                      contentType: ReportContentType.user,
                      contentId: _profileData?.profile.id ?? widget.userId?.toString() ?? '',
                      contentAuthor: _profileData?.profile.fullName ?? _profileData?.profile.username ?? widget.username ?? 'User',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title:  Text('Share Profile'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
        tabs:  [
          Tab(icon: Icon(Iconsax.document_text), text: 'posts'.tr),
          Tab(icon: Icon(Iconsax.info_circle), text: 'about'.tr),
          Tab(icon: Icon(Iconsax.gallery), text: 'photos'.tr),
          Tab(icon: Icon(Iconsax.video_play), text: 'videos'.tr),
          Tab(icon: Icon(Iconsax.people), text: 'friends'.tr),
          Tab(icon: Icon(Iconsax.more_square), text: 'more'.tr),
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
                  Text('Error: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadPosts(profile.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final posts = state is ProfilePostsLoadedState ? state.posts : <Post>[];
        final hasMore = state is ProfilePostsLoadedState ? state.hasMore : false;
        final isLoadingMore = state is ProfilePostsLoadedState ? state.isLoadingMore : false;
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // تحقق من الوصول لنهاية القائمة
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              final remaining = scrollInfo.metrics.maxScrollExtent - scrollInfo.metrics.pixels;
              if (hasMore && !isLoadingMore) {
                context.read<ProfilePostsBloc>().add(LoadMoreUserPostsEvent());
              } else {
              }
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ProfilePostsBloc>().add(RefreshUserPostsEvent(profile.id));
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
                        Icon(Iconsax.document_1, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                          ReactToPostInProfileEvent(int.parse(postId), reaction),
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
            title: 'about'.tr,
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
            title: 'work'.tr,
            icon: Iconsax.briefcase,
            children: [
              if ((profile.work.title ?? '').isNotEmpty)
                _buildInfoRow(Iconsax.award, 'position'.tr, profile.work.title!),
              if ((profile.work.place ?? '').isNotEmpty)
                _buildInfoRow(Iconsax.building, 'company'.tr, profile.work.place!),
              if ((profile.work.website ?? '').isNotEmpty)
                _buildInfoRow(Iconsax.link, 'website'.tr, profile.work.website!),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (hasLocation) ...[
          _InfoCard(
            title: 'location'.tr,
            icon: Iconsax.location,
            children: [
              if ((profile.location.currentCity ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.location_tick,
                  'lives_in'.tr,
                  profile.location.currentCity!,
                ),
              if ((profile.location.hometown ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.home_2,
                  'from'.tr,
                  profile.location.hometown!,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (hasEducation) ...[
          _InfoCard(
            title: 'education'.tr,
            icon: Iconsax.book,
            children: [
              if ((profile.education.school ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.building_3,
                  'school'.tr,
                  profile.education.school!,
                ),
              if ((profile.education.major ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.teacher,
                  'major'.tr,
                  profile.education.major!,
                ),
              if ((profile.education.classYear ?? '').isNotEmpty)
                _buildInfoRow(
                  Iconsax.calendar_1,
                  'class_of'.tr,
                  profile.education.classYear!,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _InfoCard(
          title: 'details'.tr,
          icon: Iconsax.user,
          children: [
            if (profile.country != null)
              _buildInfoRow(Iconsax.global, 'country'.tr, profile.country!.name),
            if ((profile.gender).isNotEmpty)
              _buildInfoRow(
                Iconsax.user,
                'gender'.tr,
                profile.gender == 'male' ? 'Male' : 'Female',
              ),
            if ((profile.birthDate ?? '').isNotEmpty)
              _buildInfoRow(Iconsax.cake, 'birthday'.tr, profile.birthDate!),
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
  Widget _buildPhotosTab() =>
       Center(child: Text('photos_coming_soon'.tr));
  Widget _buildVideosTab() =>
       Center(child: Text('videos_coming_soon'.tr));
  Widget _buildFriendsTab() =>
       Center(child: Text('friends_coming_soon'.tr));
  Widget _buildMoreTab(UserProfile profile) {
    final socialLinks = _profileData!.socialLinks;
    final hasLinks = socialLinks.values.any((v) => (v ?? '').isNotEmpty);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasLinks)
          _InfoCard(
            title: 'social_links'.tr,
            icon: Iconsax.global,
            children: [
              if ((socialLinks['website'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'website'.tr,
                  Iconsax.language_circle,
                  socialLinks['website']!,
                ),
              if ((socialLinks['facebook'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'facebook'.tr,
                  Iconsax.facebook,
                  socialLinks['facebook']!,
                ),
              if ((socialLinks['x'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'x_twitter'.tr,
                  Iconsax.hashtag,
                  socialLinks['x']!,
                ),
              if ((socialLinks['instagram'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'instagram'.tr,
                  Iconsax.instagram,
                  socialLinks['instagram']!,
                ),
              if ((socialLinks['youtube'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'youtube'.tr,
                  Iconsax.video,
                  socialLinks['youtube']!,
                ),
              if ((socialLinks['linkedin'] ?? '').isNotEmpty)
                _buildSocialLink(
                  'linkedin'.tr,
                  Iconsax.briefcase,
                  socialLinks['linkedin']!,
                ),
            ],
          )
        else
           Center(child: Text('no_social_links'.tr)),
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
