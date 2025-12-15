import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/pages/application/bloc/page_posts_bloc.dart';
import 'package:snginepro/features/pages/presentation/pages/page_settings_page.dart';
import 'package:snginepro/features/pages/presentation/pages/invite_friends_to_page_page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_admins_page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_verification_request_page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_update_pictures_page.dart';
import 'package:snginepro/features/agora/presentation/pages/professional_live_stream_wrapper.dart';
class PageProfilePage extends StatefulWidget {
  // Constructor للاستخدام مع PageModel كامل (الاستخدام الحالي)
  const PageProfilePage({super.key, required this.page}) : pageId = null;
  // Constructor للاستخدام مع pageId فقط (للإشعارات وما شابه)
  const PageProfilePage.fromId({super.key, required int pageId})
    : page = null,
      pageId = pageId;
  final PageModel? page;
  final int? pageId;
  @override
  State<PageProfilePage> createState() => _PageProfilePageState();
}
class _PageProfilePageState extends State<PageProfilePage>
    with SingleTickerProviderStateMixin {
  // Page info
  PageModel? _currentPage; // تغيير إلى nullable
  bool _isLoadingPageInfo = false;
  // Tabs
  late TabController _tabController;
  static const int _idxTimeline = 0;
  @override
  void initState() {
    super.initState();
    // إذا تم تمرير PageModel كامل، استخدمه
    if (widget.page != null) {
      _currentPage = widget.page;
    }
    // وإلا، سيكون null وسنجلب البيانات من pageId
    _tabController = TabController(length: 6, vsync: this);
    _loadPageInfo();
    if (_currentPage != null) {
      _loadInitialPosts();
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  // ---------- Data ----------
  Future<void> _loadPageInfo() async {
    if (_isLoadingPageInfo) return;
    setState(() => _isLoadingPageInfo = true);
    try {
      final repo = context.read<PagesRepository>();
      // تحديد pageId بناءً على المصدر
      int pageId;
      if (widget.page != null) {
        pageId = widget.page!.id;
      } else if (widget.pageId != null) {
        pageId = widget.pageId!;
      } else {
        throw Exception('لا يوجد page أو pageId');
      }
      final updated = await repo.fetchPageInfo(pageId: pageId);
      setState(() {
        _currentPage = updated;
        _isLoadingPageInfo = false;
      });
      // جلب المنشورات بعد تحميل بيانات الصفحة
      _loadInitialPosts();
    } catch (e) {
      setState(() => _isLoadingPageInfo = false);
    }
  }
  Future<void> _loadInitialPosts() async {
    if (_currentPage == null)
      return; // لا نستطيع تحميل المنشورات بدون بيانات الصفحة
    context.read<PagePostsBloc>().add(
      LoadPagePostsEvent(_currentPage!.id.toString()),
    );
  }
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadPageInfo(),
      // _loadInitialPosts() سيتم استدعاؤها تلقائياً من _loadPageInfo()
    ]);
  }
  void _openCreatePost() {
    if (_currentPage == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CreatePostPageModern(
              handle: 'page',
              handleId: _currentPage!.id,
              handleName: _currentPage!.title,
            ),
          ),
        )
        .then((_) {
          // إعادة تحميل منشورات الصفحة بعد إنشاء منشور جديد
          _loadInitialPosts();
        });
  }
  void _handleReactionChanged(String postId, String reaction) async {
    // تحديث التفاعل في PagePostsBloc
    context.read<PagePostsBloc>().add(
      ReactToPostInPageEvent(int.parse(postId), reaction),
    );
    // تحديث التفاعل في PostsBloc العام إذا كان موجوداً
    context.read<PostsBloc>().add(
      ReactToPostEvent(int.parse(postId), reaction),
    );
  }
  Future<void> _toggleLikePage() async {
    if (_currentPage == null) return;
    final currentLikeStatus = _currentPage!.iLike;
    final pageId = _currentPage!.id;
    // تحديث UI فوراً
    setState(() {
      _currentPage = PageModel(
        id: _currentPage!.id,
        name: _currentPage!.name,
        title: _currentPage!.title,
        description: _currentPage!.description,
        picture: _currentPage!.picture,
        cover: _currentPage!.cover,
        category: _currentPage!.category,
        likes: currentLikeStatus
            ? _currentPage!.likes - 1
            : _currentPage!.likes + 1,
        verified: _currentPage!.verified,
        boosted: _currentPage!.boosted,
        iAdmin: _currentPage!.iAdmin,
        iLike: !currentLikeStatus,
        website: _currentPage!.website,
        company: _currentPage!.company,
        phone: _currentPage!.phone,
        location: _currentPage!.location,
        country: _currentPage!.country,
        language: _currentPage!.language,
        actionText: _currentPage!.actionText,
        actionUrl: _currentPage!.actionUrl,
        actionColor: _currentPage!.actionColor,
        facebook: _currentPage!.facebook,
        twitter: _currentPage!.twitter,
        youtube: _currentPage!.youtube,
        instagram: _currentPage!.instagram,
        linkedin: _currentPage!.linkedin,
        vkontakte: _currentPage!.vkontakte,
      );
    });
    try {
      final repo = context.read<PagesRepository>();
      await repo.toggleLikePage(pageId, currentLikeStatus);
    } catch (e) {
      // إذا فشل، إرجاع الحالة السابقة
      setState(() {
        _currentPage = PageModel(
          id: _currentPage!.id,
          name: _currentPage!.name,
          title: _currentPage!.title,
          description: _currentPage!.description,
          picture: _currentPage!.picture,
          cover: _currentPage!.cover,
          category: _currentPage!.category,
          likes: currentLikeStatus
              ? _currentPage!.likes + 1
              : _currentPage!.likes - 1,
          verified: _currentPage!.verified,
          boosted: _currentPage!.boosted,
          iAdmin: _currentPage!.iAdmin,
          iLike: currentLikeStatus,
          website: _currentPage!.website,
          company: _currentPage!.company,
          phone: _currentPage!.phone,
          location: _currentPage!.location,
          country: _currentPage!.country,
          language: _currentPage!.language,
          actionText: _currentPage!.actionText,
          actionUrl: _currentPage!.actionUrl,
          actionColor: _currentPage!.actionColor,
          facebook: _currentPage!.facebook,
          twitter: _currentPage!.twitter,
          youtube: _currentPage!.youtube,
          instagram: _currentPage!.instagram,
          linkedin: _currentPage!.linkedin,
          vkontakte: _currentPage!.vkontakte,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${currentLikeStatus ? 'unlike' : 'like'} page',
          ),
        ),
      );
    }
  }
  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    // إذا لم يتم تحميل بيانات الصفحة بعد، أظهر loading
    if (_currentPage == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      floatingActionButton:
          _currentPage!.iAdmin && _tabController.index == _idxTimeline
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
              expandedHeight: 400, // زيادة الارتفاع ليتضمن الإحصائيات
              pinned: true, // جعل زر الرجوع واسم الصفحة ثابتين
              floating: false,
              snap: false,
              elevation: 0,
              stretch: true,
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              title: Text(
                _currentPage!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Camera button (only for page admin)
                if (_currentPage!.iAdmin)
                  IconButton(
                    icon: const Icon(Iconsax.camera),
                    tooltip: 'Update Pictures',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PageUpdatePicturesPage(page: _currentPage!),
                        ),
                      );
                      if (result == true && mounted) {
                        // Refresh page info after updating pictures
                        _loadPageInfo();
                      }
                    },
                  ),
                // Edit button (only for page admin)
                if (_currentPage!.iAdmin)
                  IconButton(
                    icon: const Icon(Iconsax.setting_2),
                    tooltip: 'Page Settings',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PageSettingsPage(page: _currentPage!),
                        ),
                      );
                      if (result == true && mounted) {
                        // Refresh page info after edit
                        _loadPageInfo();
                      }
                    },
                  ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateToLiveStream(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
              flexibleSpace: FlexibleSpaceBar(
                background: BlocBuilder<PagePostsBloc, PagePostsState>(
                  builder: (context, state) {
                    final postsCount = state is PagePostsLoadedState
                        ? state.posts.length
                        : 0;
                    return _HeaderWithStats(
                      page: _currentPage!,
                      mediaAsset: mediaAsset,
                      onCreatePost: _openCreatePost,
                      onLikePressed: _toggleLikePage,
                      postsCount: postsCount,
                    );
                  },
                ),
              ),
            ),
            // Admin Action Buttons (before tabs)
            if (_currentPage != null && _currentPage!.iAdmin)
              SliverToBoxAdapter(
                child: _AdminActionsBar(
                  page: _currentPage!,
                  onInviteFriends: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InviteFriendsToPagePage(page: _currentPage!),
                      ),
                    );
                  },
                  onManageAdmins: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PageAdminsPage(page: _currentPage!),
                      ),
                    );
                  },
                  onRequestVerification: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PageVerificationRequestPage(page: _currentPage!),
                      ),
                    );
                    // Reload page info if verification was submitted
                    if (result == true) {
                      _loadPageInfo();
                    }
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
              BlocBuilder<PagePostsBloc, PagePostsState>(
                builder: (context, state) {
                  final posts = state is PagePostsLoadedState
                      ? state.posts
                      : <Post>[];
                  final isLoading = state is PagePostsLoadingState;
                  final hasMore = state is PagePostsLoadedState
                      ? state.hasMore
                      : false;
                  final isLoadingMore = state is PagePostsLoadedState
                      ? state.isLoadingMore
                      : false;
                  final error = state is PagePostsErrorState
                      ? state.message
                      : null;
                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      // تحقق من الوصول لنهاية القائمة
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        final remaining =
                            scrollInfo.metrics.maxScrollExtent -
                            scrollInfo.metrics.pixels;
                        if (hasMore && !isLoadingMore) {
                          context.read<PagePostsBloc>().add(
                            LoadMorePagePostsEvent(),
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
                        if (_currentPage != null) {
                          context.read<PagePostsBloc>().add(
                            RefreshPagePostsEvent(_currentPage!.id.toString()),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              _AboutTab(page: _currentPage!),
              _PhotosTab(
                posts: [],
                mediaAsset: mediaAsset,
                onRefresh: () async {
                  if (_currentPage != null) {
                    context.read<PagePostsBloc>().add(
                      RefreshPagePostsEvent(_currentPage!.id.toString()),
                    );
                  }
                },
              ), // Simplified for now
              _VideosTab(
                posts: [],
                mediaAsset: mediaAsset,
                onRefresh: () async {
                  if (_currentPage != null) {
                    context.read<PagePostsBloc>().add(
                      RefreshPagePostsEvent(_currentPage!.id.toString()),
                    );
                  }
                },
              ), // Simplified for now
              const _ReviewsTab(), // TODO: wire real reviews API when ready
              const _EventsTab(), // TODO: wire real events API when ready
            ],
          ),
        ),
      ),
    );
  }
  void _navigateToLiveStream(BuildContext context) {
    if (_currentPage == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfessionalLiveStreamWrapper(
          node: 'page',
          nodeId: _currentPage!.id,
        ),
        settings: const RouteSettings(name: '/professional-live-stream'),
      ),
    );
  }
}
// ===================== Header with Stats =====================
class _HeaderWithStats extends StatelessWidget {
  const _HeaderWithStats({
    required this.page,
    required this.mediaAsset,
    required this.onCreatePost,
    required this.onLikePressed,
    required this.postsCount,
  });
  final PageModel page;
  final Uri Function(String) mediaAsset;
  final VoidCallback onCreatePost;
  final VoidCallback onLikePressed;
  final int postsCount;
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
  @override
  Widget build(BuildContext context) {
    final hasCover = page.cover.isNotEmpty;
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
                      imageUrl: mediaAsset(page.cover).toString(),
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
              // page avatar + name + badges
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
                        child: page.picture.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: mediaAsset(page.picture).toString(),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Iconsax.gallery,
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
                                  page.title,
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
                              if (page.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Iconsax.verify,
                                    color: Colors.lightBlueAccent,
                                    size: 22,
                                  ),
                                ),
                              if (page.boosted)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Iconsax.star,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '@${page.name}',
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
                    icon: Iconsax.like_1,
                    label: 'Likes',
                    value: _fmt(page.likes),
                  ),
                  const _VSeparator(),
                  _Stat(
                    icon: Iconsax.document,
                    label: 'Posts',
                    value: _fmt(postsCount),
                  ),
                  const Spacer(),
                ],
              ),
              // Buttons Row (if any)
              if ((page.actionText.isNotEmpty && page.actionUrl.isNotEmpty) || !page.iAdmin) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Action Button (if available)
                    if (page.actionText.isNotEmpty && page.actionUrl.isNotEmpty)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _getActionButtonGradient(page.actionColor),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getActionButtonColor(
                                  page.actionColor,
                                ).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                // TODO: Launch URL
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        page.actionText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Iconsax.arrow_right_3,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Spacing between buttons
                    if ((page.actionText.isNotEmpty && page.actionUrl.isNotEmpty) && !page.iAdmin)
                      const SizedBox(width: 12),
                    // Like Button (only for non-admins)
                    if (!page.iAdmin)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onLikePressed,
                          icon: Icon(page.iLike ? Iconsax.heart_add : Iconsax.heart),
                          label: Text(page.iLike ? 'Liked' : 'Like'),
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
  Color _getActionButtonColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'light':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
  LinearGradient _getActionButtonGradient(String colorName) {
    final color = _getActionButtonColor(colorName);
    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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
        tabs: const [
          Tab(icon: Icon(Iconsax.activity), text: 'Timeline'),
          Tab(icon: Icon(Iconsax.info_circle), text: 'About'),
          Tab(icon: Icon(Iconsax.image), text: 'Photos'),
          Tab(icon: Icon(Iconsax.video), text: 'Videos'),
          Tab(icon: Icon(Iconsax.star), text: 'Reviews'),
          Tab(icon: Icon(Iconsax.calendar), text: 'Events'),
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
            '$value $label',
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
  final void Function(String postId, String reaction) onReactionChanged;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && posts.isEmpty) {
      return _ErrorState(message: error!, onRetry: onRetry);
    }
    if (posts.isEmpty) {
      return const _EmptyState(
        icon: Iconsax.document,
        title: 'No posts yet',
        subtitle: 'Posts published by this page will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        // إزالة controller منفصل لجعل التمرير موحد
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: posts.length + (isLoadingMore && hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = posts[index];
          return PostCard(
            key: ValueKey('post-${post.id}'),
            post: post,
            onReactionChanged: onReactionChanged,
            onPostUpdated: (updatedPost) {
              // تحديث المنشور في PagePostsBloc
              context.read<PagePostsBloc>().add(
                UpdatePostInPageEvent(updatedPost),
              );
              // تحديث المنشور في PostsBloc العام إذا كان موجوداً
              context.read<PostsBloc>().add(UpdatePostEvent(updatedPost));
            },
            onPostDeleted: (postId) {
              // حذف المنشور من PagePostsBloc
              context.read<PagePostsBloc>().add(
                DeletePostFromPageEvent(int.parse(postId)),
              );
              // حذف المنشور من PostsBloc العام إذا كان موجوداً
              context.read<PostsBloc>().add(DeletePostEvent(int.parse(postId)));
            },
          );
        },
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
    final photos = posts
        .where((p) => p.hasPhotos)
        .expand((p) => p.photos!)
        .toList();
    if (photos.isEmpty) {
      return const _EmptyState(
        icon: Iconsax.image,
        title: 'No photos',
        subtitle: 'Photos posted by this page will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: photos.length,
        itemBuilder: (_, i) {
          final src = mediaAsset(photos[i].source).toString();
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: src, fit: BoxFit.cover),
          );
        },
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
    final vids = posts.where((p) => p.isVideoPost && p.video != null).toList();
    if (vids.isEmpty) {
      return const _EmptyState(
        icon: Iconsax.video,
        title: 'No videos',
        subtitle: 'Videos posted by this page will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 10,
        ),
        itemCount: vids.length,
        itemBuilder: (_, i) {
          final thumb = vids[i]
              .video!
              .thumbnail; // if your model has it; falls back to first photo
          final fallbackPhoto = (vids[i].photos?.isNotEmpty ?? false)
              ? vids[i].photos!.first.source
              : null;
          final img = thumb.isNotEmpty ? thumb : (fallbackPhoto ?? '');
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: img.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: mediaAsset(img).toString(),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                ),
              ),
              const Positioned.fill(
                child: Center(
                  child: Icon(Iconsax.play, size: 36, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
// -- Reviews (placeholder)
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();
  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Iconsax.star,
      title: 'No reviews yet',
      subtitle: 'When users leave reviews, you\'ll see them here.',
    );
  }
}
// -- Events (placeholder)
class _EventsTab extends StatelessWidget {
  const _EventsTab();
  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Iconsax.calendar,
      title: 'No events',
      subtitle: 'Events created by this page will appear here.',
    );
  }
}
// ===================== About Tab =====================
class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.page});
  final PageModel page;
  @override
  Widget build(BuildContext context) {
    final hasDescription = page.description.isNotEmpty;
    final hasWebsite = page.website.isNotEmpty;
    final hasCompany = page.company.isNotEmpty;
    final hasPhone = page.phone.isNotEmpty;
    final hasLocation = page.location.isNotEmpty;
    final hasActionButton =
        page.actionText.isNotEmpty && page.actionUrl.isNotEmpty;
    final hasSocialLinks =
        page.facebook.isNotEmpty ||
        page.twitter.isNotEmpty ||
        page.youtube.isNotEmpty ||
        page.instagram.isNotEmpty ||
        page.linkedin.isNotEmpty ||
        page.vkontakte.isNotEmpty;
    final hasAnyInfo =
        hasDescription ||
        hasWebsite ||
        hasCompany ||
        hasPhone ||
        hasLocation ||
        hasActionButton ||
        hasSocialLinks;
    if (!hasAnyInfo) {
      return const _EmptyState(
        icon: Iconsax.info_circle,
        title: 'No information',
        subtitle: 'Page information will appear here when available.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        if (hasDescription) ...[
          _InfoSection(
            title: 'About',
            children: [
              _InfoItem(
                icon: Iconsax.document_text,
                label: 'Description',
                value: page.description,
                isMultiline: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Contact Information
        if (hasWebsite || hasCompany || hasPhone || hasLocation) ...[
          _InfoSection(
            title: 'Contact Information',
            children: [
              if (hasCompany)
                _InfoItem(
                  icon: Iconsax.building,
                  label: 'Company',
                  value: page.company,
                ),
              if (hasWebsite)
                _InfoItem(
                  icon: Iconsax.global,
                  label: 'Website',
                  value: page.website,
                  isLink: true,
                ),
              if (hasPhone)
                _InfoItem(
                  icon: Iconsax.call,
                  label: 'Phone',
                  value: page.phone,
                  isLink: true,
                  linkPrefix: 'tel:',
                ),
              if (hasLocation)
                _InfoItem(
                  icon: Iconsax.location,
                  label: 'Location',
                  value: page.location,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Action Button
        if (hasActionButton) ...[
          _InfoSection(
            title: 'Call to Action',
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _getActionButtonGradient(page.actionColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getActionButtonColor(
                        page.actionColor,
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Open URL
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        page.actionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Iconsax.arrow_right_3,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Social Links
        if (hasSocialLinks) ...[
          _InfoSection(
            title: 'Social Media',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (page.facebook.isNotEmpty)
                    _SocialButton(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      url: page.facebook,
                    ),
                  if (page.twitter.isNotEmpty)
                    _SocialButton(
                      icon:
                          Icons.flutter_dash, // Using as Twitter/X placeholder
                      label: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      url: page.twitter,
                    ),
                  if (page.youtube.isNotEmpty)
                    _SocialButton(
                      icon: Icons.play_circle_fill,
                      label: 'YouTube',
                      color: const Color(0xFFFF0000),
                      url: page.youtube,
                    ),
                  if (page.instagram.isNotEmpty)
                    _SocialButton(
                      icon: Icons.camera_alt,
                      label: 'Instagram',
                      color: const Color(0xFFE4405F),
                      url: page.instagram,
                    ),
                  if (page.linkedin.isNotEmpty)
                    _SocialButton(
                      icon: Icons.business,
                      label: 'LinkedIn',
                      color: const Color(0xFF0A66C2),
                      url: page.linkedin,
                    ),
                  if (page.vkontakte.isNotEmpty)
                    _SocialButton(
                      icon: Icons.people,
                      label: 'VK',
                      color: const Color(0xFF0077FF),
                      url: page.vkontakte,
                    ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
  Color _getActionButtonColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'light':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
  LinearGradient _getActionButtonGradient(String colorName) {
    final color = _getActionButtonColor(colorName);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
    this.isLink = false,
    this.linkPrefix = '',
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;
  final bool isLink;
  final String linkPrefix;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLink)
                  InkWell(
                    onTap: () {
                      // TODO: Launch URL with linkPrefix + value
                    },
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                    maxLines: isMultiline ? null : 1,
                    overflow: isMultiline ? null : TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String url;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // TODO: Launch social URL
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ===================== Shared UI =====================
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: onSurf),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurf),
            ),
          ],
        ),
      ),
    );
  }
}
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.info_circle, size: 56, color: onSurf),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
// ==================== Admin Actions Bar ====================
class _AdminActionsBar extends StatelessWidget {
  const _AdminActionsBar({
    required this.page,
    required this.onInviteFriends,
    required this.onManageAdmins,
    required this.onRequestVerification,
  });
  final PageModel page;
  final VoidCallback onInviteFriends;
  final VoidCallback onManageAdmins;
  final VoidCallback onRequestVerification;
  @override
  Widget build(BuildContext context) {
    // عرض زر التوثيق فقط إذا لم تكن الصفحة موثقة
    final showVerificationButton = !page.verified;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Invite Friends Button
              Expanded(
                child: _ActionButton(
                  icon: Iconsax.user_add,
                  label: 'Invite Friends',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  onTap: onInviteFriends,
                ),
              ),
              const SizedBox(width: 12),
              // Manage Admins Button
              Expanded(
                child: _ActionButton(
                  icon: Icons.admin_panel_settings,
                  label: 'Manage Admins',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  onTap: onManageAdmins,
                ),
              ),
            ],
          ),
          // Request Verification Button (only if not verified)
          // TODO: إخفاء الزر إذا كان هناك طلب pending
          // يحتاج Backend أن يضيف verification_status في PageModel
          // الحالات المتوقعة: null (no request), "pending", "approved", "rejected"
          if (showVerificationButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                icon: Icons.verified,
                label: 'Request Verification',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
                onTap: onRequestVerification,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
