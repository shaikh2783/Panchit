import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';

import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/presentation/widgets/video_reels_player.dart';
import 'package:snginepro/features/reels/application/bloc/reels_bloc.dart';
import 'package:snginepro/features/reels/data/services/reels_management_api_service.dart';
import 'package:snginepro/core/services/reactions_service.dart';
import 'package:snginepro/core/models/reaction_model.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/comments/presentation/pages/comments_bottom_sheet.dart';
import 'package:snginepro/features/feed/presentation/widgets/reaction_users_bottom_sheet.dart';
import 'package:snginepro/features/feed/presentation/pages/create_reel_page.dart';
import 'package:snginepro/features/feed/presentation/widgets/share_post_dialog.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_menu_bottom_sheet.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
import 'package:snginepro/features/friends/data/models/friendship_model.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';

typedef MediaPathResolver = Uri Function(String);

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});
  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsBloc>().add(LoadReelsEvent());
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    // Only update if page has actually changed
    if (_pageController.hasClients) {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    }
  }

  void _maybeLoadMore(int index, List<Post> reels, bool hasMore, bool isLoadingMore) {
    final nearEnd = reels.length - 2;
    if (index >= nearEnd && hasMore && !isLoadingMore) {
      context.read<ReelsBloc>().add(LoadMoreReelsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaResolver = context.read<AppConfig>().mediaAsset;

    return BlocBuilder<ReelsBloc, ReelsState>(
      builder: (context, state) {
        if (state is ReelsLoadingState) {
          return const _DarkScaffold(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ReelsErrorState) {
          return _DarkScaffold(
            child: _ReelsMessage(
              icon: Iconsax.warning_2,
              message: state.message,
              actionLabel: 'Try Again',
              onAction: () => context.read<ReelsBloc>().add(LoadReelsEvent(source: state.source)),
            ),
          );
        }

        if (state is! ReelsLoadedState || state.reels.isEmpty) {
          return const _DarkScaffold(
            child: _ReelsMessage(
              icon: Iconsax.video,
              message: 'No reels available right now.',
            ),
          );
        }

        final reels = state.reels;
        final hasMore = state.hasMore;
        final isLoadingMore = state.isLoadingMore;

        return _DarkScaffold(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  context.read<ReelsBloc>().add(RefreshReelsEvent(source: state.source));
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  onPageChanged: (i) => _maybeLoadMore(i, reels, hasMore, isLoadingMore),
                  itemBuilder: (context, i) => _ReelView(
                    key: ValueKey(reels[i].id),
                    post: reels[i],
                    mediaResolver: mediaResolver,
                  ),
                ),
              ),
              if (isLoadingMore)
                const Positioned(
                  left: 0, right: 0, bottom: 28,
                  child: Center(
                    child: SizedBox(
                      height: 26, width: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DarkScaffold extends StatelessWidget {
  const _DarkScaffold({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateReelPage(),
                ),
              ).then((result) {
                if (result == true) {
                  context.read<ReelsBloc>().add(RefreshReelsEvent());
                }
              });
            },
            icon: const Icon(
              Iconsax.video_add,
              color: Color(0xFFE1306C),
              size: 28,
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

class _ReelsMessage extends StatelessWidget {
  const _ReelsMessage({
    this.icon,
    required this.message,
    this.onAction,
    this.actionLabel,
  });
  final IconData? icon;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.withOpacity(0.1),
              Colors.grey.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    color: Colors.white, 
                    height: 1.5,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF0F0F0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReelView extends StatefulWidget {
  const _ReelView({
    super.key,
    required this.post,
    required this.mediaResolver,
  });
  final Post post;
  final MediaPathResolver mediaResolver;

  @override
  State<_ReelView> createState() => _ReelViewState();
}

class _ReelViewState extends State<_ReelView>
    with SingleTickerProviderStateMixin {
  bool _uiVisible = true;
  late final AnimationController _discCtrl;

  @override
  void initState() {
    super.initState();
    _discCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  void _toggleUI() => setState(() => _uiVisible = !_uiVisible);

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final mediaResolver = widget.mediaResolver;

    return GestureDetector(
      onTap: _toggleUI,
      onDoubleTap: () {
        // TODO: send like
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❤️ Liked'),
            duration: Duration(milliseconds: 600),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (p.video != null)
            VideoReelsPlayer(
              video: p.video!,
              mediaResolver: mediaResolver,
              autoplay: true,
              muted: false,
              loop: true,
              enableCaching: true,
            )
          else
            Container(color: Colors.black),

          // Cinematic gradient
          const _GlassGradients(),

          // Top glass bar
          if(false)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _uiVisible ? MediaQuery.of(context).padding.top + 8 : -72,
            left: 12,
            right: 12,
            child: const _TopGlassBar(),
          ),

          // Bottom: caption + profile pill + hashtags
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _uiVisible ? 1 : 0,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  0,
                  88,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                child: _CaptionAndOwner(post: p, mediaResolver: mediaResolver),
              ),
            ),
          ),

          // Right rail actions
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _uiVisible ? 1 : 0,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  0,
                  12,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                child: _ActionsRail(
                  post: p,
                  discController: _discCtrl,
                  mediaResolver: mediaResolver,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassGradients extends StatelessWidget {
  const _GlassGradients();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .18, .6, 1],
            colors: [
              Colors.black.withOpacity(.55),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(.75),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopGlassBar extends StatelessWidget {
  const _TopGlassBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.video_play, 
                  color: Colors.white, 
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reels',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _buildGlassButton(
                icon: Iconsax.search_normal_1,
                onTap: () {},
                tooltip: 'Search',
              ),
              const SizedBox(width: 8),
              _buildGlassButton(
                icon: Iconsax.setting_2,
                onTap: () {},
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionAndOwner extends StatefulWidget {
  const _CaptionAndOwner({required this.post, required this.mediaResolver});
  final Post post;
  final MediaPathResolver mediaResolver;

  @override
  State<_CaptionAndOwner> createState() => _CaptionAndOwnerState();
}

class _CaptionAndOwnerState extends State<_CaptionAndOwner> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _didLoadStatus = false;
  bool _isOwner = false;
  int? _authorId;
  FriendsApiService? _friendsService;

  @override
  void initState() {
    super.initState();
    _authorId = int.tryParse(widget.post.authorId ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // إعداد خدمة المتابعة وحساب ملكية الريل
    _friendsService ??= FriendsApiService(context.read<ApiClient>());
    _computeOwnership();

    if (!_didLoadStatus) {
      _didLoadStatus = true;
      _loadFollowStatus();
    }
  }

  void _computeOwnership() {
    final auth = context.read<AuthNotifier>();
    final currentUserId = int.tryParse(auth.currentUser?['user_id']?.toString() ?? '');
    final authorId = _authorId;
    final isOwnerNow = currentUserId != null && authorId != null && currentUserId == authorId;
    if (isOwnerNow != _isOwner) {
      setState(() => _isOwner = isOwnerNow);
    }
  }

  Future<void> _loadFollowStatus() async {
    if (_isOwner) return;
    final authorId = _authorId;
    final service = _friendsService;
    if (authorId == null || service == null) return;

    try {
      final data = await service.getUserRelationshipStatus(authorId);
      final statusString = (data?['friendship_status'] ?? data?['status'] ?? '').toString().toLowerCase();
      final isFollowing = data?['is_following'] == true || statusString == 'following' || statusString == 'friends';
      if (mounted) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (_) {
      // تجاهل الخطأ والاكتفاء بالقيمة الافتراضية
    }
  }

  Future<void> _toggleFollow() async {
    final authorId = _authorId;
    final service = _friendsService;
    if (authorId == null || service == null || _isOwner) return;
    if (_isLoadingFollow) return;

    setState(() => _isLoadingFollow = true);
    try {
      final result = _isFollowing
          ? await service.unfollowUser(authorId)
          : await service.followUser(authorId);

      if (!mounted) return;

      setState(() {
        final newStatus = result.newStatus;
        _isFollowing = newStatus == FriendshipStatus.following || newStatus == FriendshipStatus.friends;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('action_failed'.tr)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    }
  }

  void _goToProfile() {
    final authorId = _authorId;
    if (authorId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(userId: authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final avatar = (post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty)
        ? CachedNetworkImageProvider(widget.mediaResolver(post.authorAvatarUrl!).toString())
        : null;
    final canFollow = post.authorType == 'user' && !_isOwner && _authorId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced owner pill + follow
        InkWell(
          onTap: (widget.post.authorType == 'user' && _authorId != null)
              ? _goToProfile
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.transparent,
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Iconsax.user, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                    // مؤشر حالة الاتصال للمستخدمين فقط
                    if (post.authorType == 'user' && post.authorIsOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  post.authorName,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 12),
                if (canFollow)
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _isLoadingFollow ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.white : const Color(0xFFE1306C),
                        foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoadingFollow
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isFollowing ? 'following'.tr : 'Follow',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (post.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              post.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Enhanced music line
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.music, 
                  color: Colors.white70, 
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Original audio • ${post.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsRail extends StatefulWidget {
  const _ActionsRail({
    required this.post,
    required this.discController,
    required this.mediaResolver,
  });

  final Post post;
  final AnimationController discController;
  final MediaPathResolver mediaResolver;

  @override
  State<_ActionsRail> createState() => _ActionsRailState();
}

class _ActionsRailState extends State<_ActionsRail> {
  late Post _currentPost;
  late ReelsManagementApiService _reelsService;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reelsService = ReelsManagementApiService(context.read<ApiClient>());
  }

  void _showReactionsPicker() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // تحقق من الاتجاه RTL للحصول على الموضع المناسب
    final localizationController = Get.find<LocalizationController>();
    final isRTL = localizationController.isRTL;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                // في RTL: عرض على اليسار، في LTR: عرض على اليمين
                left: isRTL ? 16 : null, // في RTL نضعها على اليسار
                right: isRTL ? null : offset.dx, // في LTR نضعها على اليمين كالمعتاد
                bottom: MediaQuery.of(context).size.height - offset.dy,
                child: GestureDetector(
                  onTap: () {},
                  child: _ReactionPicker(
                    onSelected: (reaction) {
                      _handleSpecificReaction(reaction);
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _handleSpecificReaction(String reaction) async {
    try {
      final isCurrentlyReacting = _currentPost.myReaction == reaction;
      
      // Update UI immediately (Optimistic Update)
      setState(() {
        if (isCurrentlyReacting) {
          // إزالة التفاعل الحالي
          _currentPost = _currentPost.copyWithReaction(null);
        } else {
          // إضافة التفاعل الجديد
          _currentPost = _currentPost.copyWithReaction(reaction);
        }
      });
      
      // Send update to ReelsBloc
      context.read<ReelsBloc>().add(UpdateReelEvent(_currentPost));
      
      // API call - نرسل 'remove' إذا كان نفس التفاعل
      await _reelsService.reactToReel(
        reelId: _currentPost.id,
        reaction: isCurrentlyReacting ? 'remove' : reaction,
        isReacting: !isCurrentlyReacting,
      );
      
    } catch (e) {
      if (mounted) {
        // Restore previous state on failure
        setState(() {
          _currentPost = widget.post;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while adding reaction')),
        );
      }
    }
  }

  Future<void> _handleReaction() async {
    try {
      final isCurrentlyLiked = _currentPost.myReaction != null;
      
      // Update UI immediately (Optimistic Update)
      setState(() {
        if (isCurrentlyLiked) {
          // إزالة التفاعل الحالي
          _currentPost = _currentPost.copyWithReaction(null);
        } else {
          // إضافة تفاعل جديد
          _currentPost = _currentPost.copyWithReaction('like');
        }
      });
      
      // Send update to ReelsBloc
      context.read<ReelsBloc>().add(UpdateReelEvent(_currentPost));
      
      // API call - نرسل 'remove' إذا كان يريد إزالة التفاعل
      await _reelsService.reactToReel(
        reelId: _currentPost.id,
        reaction: isCurrentlyLiked ? 'remove' : 'like',
        isReacting: !isCurrentlyLiked,
      );
      
    } catch (e) {
      if (mounted) {
        // Restore previous state on failure
        setState(() {
          _currentPost = widget.post;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while adding reaction')),
        );
      }
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: _currentPost.id,
        commentsCount: _currentPost.commentsCount,
      ),
    );
  }

  void _showReactionUsers() {
    // استخدام reactionBreakdown الفعلي لحساب العدد الصحيح
    final reactionStats = Map<String, int>.from(_currentPost.reactionBreakdown);
    
    // إذا لم تكن هناك breakdown ولكن هناك تفاعلات، اعتبرها likes
    if (reactionStats.isEmpty && _currentPost.reactionsCount > 0) {
      reactionStats['like'] = _currentPost.reactionsCount;
    }
    
    showReactionUsersSheet(
      context: context,
      type: 'post',
      id: _currentPost.id,
      reactionStats: reactionStats,
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => SharePostDialog(
        post: _currentPost,
        onShareSuccess: () {
          // تحديث عدد المشاركات
          setState(() {
            _currentPost = _currentPost.copyWith(
              sharesCount: _currentPost.sharesCount + 1,
            );
          });
          // إرسال التحديث للـ Bloc
          context.read<ReelsBloc>().add(UpdateReelEvent(_currentPost));
        },
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PostMenuBottomSheet(
        post: _currentPost,
        onAction: _handlePostAction,
      ),
    );
  }

  Future<void> _handlePostAction(PostAction action) async {
    // معالجة الحذف
    if (action == PostAction.deletePost) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('confirm_delete'.tr),
          content: Text('delete_post_message'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel_button'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('delete_button'.tr),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        try {
          await _reelsService.manageReel(
            reelId: _currentPost.id,
            action: 'delete_post',
          );
          if (mounted) {
            context.read<ReelsBloc>().add(DeleteReelEvent(_currentPost.id));
            Navigator.pop(context); // Close the menu
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('reel_deleted_success'.tr)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('error_deleting_post'.tr)),
            );
          }
        }
      }
      return;
    }

    // معالجة باقي الأوامر
    try {
      await _reelsService.manageReel(
        reelId: _currentPost.id,
        action: action.value,
      );

      // تحديث الحالة حسب النوع
      setState(() {
        switch (action) {
          case PostAction.savePost:
            _currentPost = _currentPost.copyWith(isSaved: true);
            break;
          case PostAction.unsavePost:
            _currentPost = _currentPost.copyWith(isSaved: false);
            break;
          case PostAction.pinPost:
            _currentPost = _currentPost.copyWith(isPinned: true);
            break;
          case PostAction.unpinPost:
            _currentPost = _currentPost.copyWith(isPinned: false);
            break;
          case PostAction.hidePost:
            _currentPost = _currentPost.copyWith(isHidden: true);
            break;
          case PostAction.unhidePost:
            _currentPost = _currentPost.copyWith(isHidden: false);
            break;
          default:
            break;
        }
      });

      // تحديث Bloc
      context.read<ReelsBloc>().add(UpdateReelEvent(_currentPost));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('action_completed'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('action_failed'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReaction = _currentPost.myReaction != null;
    final reactionModel = hasReaction 
        ? ReactionsService.instance.getReactionByName(_currentPost.myReaction!)
        : null;

    Widget btn(IconData i, {String? label, Color? activeColor, bool active = false, VoidCallback? onTap, VoidCallback? onLongPress}) {
      final c = active ? (activeColor ?? Colors.red) : Colors.white;
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: const CircleBorder(),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: active 
                      ? [
                          (activeColor ?? Colors.red).withOpacity(0.3),
                          (activeColor ?? Colors.red).withOpacity(0.1),
                        ]
                      : [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.3),
                        ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active 
                      ? (activeColor ?? Colors.red).withOpacity(0.4)
                      : Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: active 
                        ? (activeColor ?? Colors.red).withOpacity(0.3)
                        : Colors.black.withOpacity(0.4),
                      blurRadius: active ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: reactionModel != null && active
                    ? _ReactionIcon(type: _currentPost.myReaction!, size: 28)
                    : Icon(i, color: c, size: 28),
              ),
              if (label != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _currentPost.reactionsCount > 0 ? _showReactionUsers : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    final avatar = (_currentPost.authorAvatarUrl != null &&
            _currentPost.authorAvatarUrl!.isNotEmpty)
        ? CachedNetworkImageProvider(
            widget.mediaResolver(_currentPost.authorAvatarUrl!).toString())
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          Iconsax.heart,
          label: _currentPost.reactionsCountFormatted,
          active: hasReaction,
          activeColor: reactionModel?.colorValue ?? Colors.red,
          onTap: _handleReaction,
          onLongPress: _showReactionsPicker,
        ),
        btn(Iconsax.message, label: _currentPost.commentsCountFormatted, onTap: _showComments),
        btn(Iconsax.send_2, label: _currentPost.sharesCountFormatted, onTap: _showShareDialog),
        btn(Iconsax.more, onTap: _showMenu),
        const SizedBox(height: 8),
        // spinning music disc
        RotationTransition(
          turns: widget.discController,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.2),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.2),
                backgroundImage: avatar,
                child: avatar == null
                    ? Icon(
                        Iconsax.music,
                        color: Colors.white.withOpacity(0.9),
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reaction Picker Widget for Reels
class _ReactionPicker extends StatefulWidget {
  const _ReactionPicker({required this.onSelected});

  final Function(String) onSelected;

  @override
  State<_ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<_ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final reactions = ReactionsService.instance.getReactions();
    for (int i = 0; i < reactions.length; i++) {
      final delay = i * 0.08;
      
      _scaleAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              delay + 0.3,
              curve: Curves.elasticOut,
            ),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              delay + 0.3,
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = ReactionsService.instance.getReactions();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < reactions.length; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimations[i],
                    child: ScaleTransition(
                      scale: _scaleAnimations[i],
                      child: _ReactionButton(
                        reaction: reactions[i],
                        onTap: () => widget.onSelected(reactions[i].reaction),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Reaction Button Widget
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.reaction,
    required this.onTap,
  });

  final ReactionModel reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CachedNetworkImage(
          imageUrl: reaction.imageUrl,
          width: 28,
          height: 28,
          placeholder: (context, url) => SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: reaction.colorValue,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            Iconsax.happyemoji,
            size: 28,
            color: reaction.colorValue,
          ),
        ),
      ),
    );
  }
}

/// Reaction Icon Widget
class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({required this.type, this.size = 18});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reaction = ReactionsService.instance.getReactionByName(type);
    
    if (reaction != null) {
      return CachedNetworkImage(
        imageUrl: reaction.imageUrl,
        width: size,
        height: size,
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: reaction.colorValue,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Iconsax.happyemoji,
          size: size,
          color: reaction.colorValue,
        ),
      );
    }
    
    return SizedBox(width: size, height: size);
  }
}
