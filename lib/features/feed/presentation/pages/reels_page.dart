import 'dart:async';

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
import 'package:snginepro/features/feed/presentation/widgets/share_post_dialog.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_camera_entry.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_sound_screen.dart';
import 'package:snginepro/features/reels/presentation/widgets/use_sound_sheet.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_menu_bottom_sheet.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
import 'package:snginepro/features/friends/data/models/friendship_model.dart';
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';

typedef MediaPathResolver = Uri Function(String);
const Color _kReelAccent = Color(0xFFE1306C);
const Color _kReelBlack = Colors.black;
const Color _kReelSurface = Color(0xFF111113);
const double _kRightRailWidth = 82;
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key, this.initialIndex = 0});

  /// يبدأ من الريل المطلوب عند الفتح
  final int initialIndex;
  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late final PageController _pageController;
  late int _currentPage;
  final Set<int> _reportedViewIds = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsBloc>().add(LoadReelsEvent());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _handlePageChanged(
      int index,
      List<Post> reels,
      bool hasMore,
      bool isLoadingMore,
      ) {
    if (_currentPage != index) {
      setState(() {
        _currentPage = index;
      });
    }

    _maybeLoadMore(index, reels, hasMore, isLoadingMore);
  }

  /// Fire-and-forget view event (contract §6): reported once per reel per
  /// session, and any failure is swallowed — it must never affect the UI.
  Future<void> _reportReelView(Post post) async {
    if (!_reportedViewIds.add(post.id)) return;
    try {
      await context.read<ReelsManagementApiService>().recordView(post.id);
    } catch (_) {}
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
              actionLabel: 'try_again'.tr,
              onAction: () => context.read<ReelsBloc>().add(LoadReelsEvent(source: state.source)),
            ),
          );
        }

        if (state is! ReelsLoadedState || state.reels.isEmpty) {
          return  _DarkScaffold(
            child: _ReelsMessage(
              icon: Iconsax.video,
              message: 'no_reels_available'.tr,
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
                  onPageChanged: (index) => _handlePageChanged(
                    index,
                    reels,
                    hasMore,
                    isLoadingMore,
                  ),
                  itemBuilder: (context, i) => _ReelView(
                    key: ValueKey(reels[i].id),
                    post: reels[i],
                    mediaResolver: mediaResolver,
                    isActive: i == _currentPage,
                    onDwell: () => _reportReelView(reels[i]),
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
      backgroundColor: _kReelBlack,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          const _ReelsTopOverlay(),
        ],
      ),
    );
  }
}

class _ReelsTopOverlay extends StatelessWidget {
  const _ReelsTopOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.video_play,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'reels'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _TopCircleButton(
                icon: Iconsax.video_add,
                onTap: () async {
                  await showReelCameraEntry(context);
                  if (context.mounted) {
                    context.read<ReelsBloc>().add(RefreshReelsEvent());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            color: _kReelAccent,
            size: 24,
          ),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: _kReelSurface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kReelAccent.withOpacity(0.16),
                  border: Border.all(
                    color: _kReelAccent.withOpacity(0.28),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _kReelAccent,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.92),
                height: 1.45,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _kReelAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
    required this.isActive,
    required this.onDwell,
  });
  final Post post;
  final MediaPathResolver mediaResolver;
  final bool isActive;
  final VoidCallback onDwell;

  @override
  State<_ReelView> createState() => _ReelViewState();
}

class _ReelViewState extends State<_ReelView>
    with SingleTickerProviderStateMixin {
  bool _uiVisible = true;
  final GlobalKey<_ActionsRailState> _actionsKey = GlobalKey<_ActionsRailState>();
  late final AnimationController _discCtrl;
  Timer? _dwellTimer;
  bool _showDoubleTapHeart = false;
  Timer? _heartTimer;

  @override
  void initState() {
    super.initState();
    _discCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
    if (widget.isActive) _startDwellTimer();
  }

  @override
  void didUpdateWidget(covariant _ReelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startDwellTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _dwellTimer?.cancel();
    }
  }

  // View counts only after ~3s of dwell, so fast flicks don't report.
  void _startDwellTimer() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(seconds: 3), widget.onDwell);
  }
  void _handleDoubleTap() {
    _actionsKey.currentState?.triggerReactionToggle();

    setState(() {
      _showDoubleTapHeart = true;
    });

    _heartTimer?.cancel();
    _heartTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _showDoubleTapHeart = false;
      });
    });
  }
  @override
  void dispose() {
    _dwellTimer?.cancel();
    _heartTimer?.cancel();
    _discCtrl.dispose();
    super.dispose();
  }

  void _toggleUI() => setState(() => _uiVisible = !_uiVisible);

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final mediaResolver = widget.mediaResolver;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleUI,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (p.video != null)
            VideoReelsPlayer(
              video: p.video!,
              mediaResolver: mediaResolver,
              autoplay: widget.isActive,
              muted: false,
              loop: true,
              enableCaching: true,
            )
          else
            Container(color: Colors.black),

          const _GlassGradients(),

          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showDoubleTapHeart ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: AnimatedScale(
                scale: _showDoubleTapHeart ? 1 : 0.65,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: const Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 108,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // IgnorePointer so hidden overlays don't keep receiving taps.
          IgnorePointer(
            ignoring: !_uiVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _uiVisible ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    _kRightRailWidth + 14,
                    22 + bottomInset,
                  ),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    offset: _uiVisible ? Offset.zero : const Offset(0, 0.08),
                    child: _CaptionAndOwner(
                      post: p,
                      mediaResolver: mediaResolver,
                    ),
                  ),
                ),
              ),
            ),
          ),

          IgnorePointer(
            ignoring: !_uiVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _uiVisible ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    12,
                    22 + bottomInset,
                  ),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    offset: _uiVisible ? Offset.zero : const Offset(0, 0.08),
                    child: _ActionsRail(
                      key: _actionsKey,
                      post: p,
                      discController: _discCtrl,
                      mediaResolver: mediaResolver,
                    ),
                  ),
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
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.20, 0.58, 1],
                  colors: [
                    Colors.black.withOpacity(0.58),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.86),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  stops: const [0, 0.22, 0.55],
                  colors: [
                    Colors.black.withOpacity(0.22),
                    Colors.transparent,
                    Colors.transparent,
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
    final avatar = post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty
        ? CachedNetworkImageProvider(
      widget.mediaResolver(post.authorAvatarUrl!).toString(),
    )
        : null;

    final canFollow = post.authorType == 'user' && !_isOwner && _authorId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAuthorRow(
          post: post,
          avatar: avatar,
          canFollow: canFollow,
        ),
        if (post.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCaption(post.text),
        ],
        const SizedBox(height: 10),
        _buildSoundPill(post),
      ],
    );
  }

  Widget _buildAuthorRow({
    required Post post,
    required ImageProvider? avatar,
    required bool canFollow,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: post.authorType == 'user' && _authorId != null ? _goToProfile : null,
          customBorder: const CircleBorder(),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1.6,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? const Icon(
                    Iconsax.user,
                    color: Colors.white,
                    size: 18,
                  )
                      : null,
                ),
              ),
              if (post.authorType == 'user' && post.authorIsOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: InkWell(
            onTap: post.authorType == 'user' && _authorId != null ? _goToProfile : null,
            child: Text(
              post.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (canFollow) ...[
          const SizedBox(width: 10),
          _buildFollowButton(),
        ],
      ],
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: _isLoadingFollow ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _isFollowing ? Colors.white : _kReelAccent,
          disabledBackgroundColor: Colors.white24,
          foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoadingFollow
            ? SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _isFollowing ? Colors.black87 : Colors.white,
          ),
        )
            : Text(
          _isFollowing ? 'following'.tr : 'follow'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(String text) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withOpacity(0.96),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        shadows: const [
          Shadow(
            color: Colors.black87,
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundPill(Post post) {
    final soundText = post.soundTitle ??
        'original_audio_by'.trParams({'name': post.authorName});

    return GestureDetector(
      onTap: post.soundUrl != null ? () => showUseSoundSheet(context, post) : null,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Iconsax.music,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                soundText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (post.soundUrl != null) ...[
              const SizedBox(width: 6),
              Icon(
                Iconsax.arrow_right_3,
                color: Colors.white.withOpacity(0.62),
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionsRail extends StatefulWidget {
  const _ActionsRail({
    super.key,
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
    _reelsService = context.read<ReelsManagementApiService>();
  }

  @override
  void didUpdateWidget(covariant _ActionsRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      // Keep local state in sync when parent provides an updated post
      _currentPost = widget.post;
    }
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
          SnackBar(content: Text('reaction_failed'.tr)),
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
          SnackBar(content: Text('reaction_failed'.tr)),
        );
      }
    }
  }

  // Exposed for parent (e.g., double-tap on the video) to trigger the same flow
  Future<void> triggerReactionToggle() => _handleReaction();

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
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

      if (!mounted) return;

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

    // The disc shows the reel's own thumbnail (like the sound artwork on
    // the sound screen), not the author avatar.
    final thumbnailPath = _currentPost.video?.thumbnail.trim();
    final thumbnailUrl =
    thumbnailPath != null && thumbnailPath.isNotEmpty
        ? widget.mediaResolver(thumbnailPath).toString()
        : null;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReelRailButton(
            icon: Iconsax.heart,
            label: _currentPost.reactionsCountFormatted,
            active: hasReaction,
            activeColor: reactionModel?.colorValue ?? Colors.red,
            reactionType: _currentPost.myReaction,
            onTap: _handleReaction,
            onLongPress: _showReactionsPicker,
            onLabelTap:
            _currentPost.reactionsCount > 0 ? _showReactionUsers : null,
          ),
          _ReelRailButton(
            icon: Iconsax.message,
            label: _currentPost.commentsCountFormatted,
            onTap: _showComments,
          ),
          _ReelRailButton(
            icon: Iconsax.send_2,
            label: _currentPost.sharesCountFormatted,
            onTap: _showShareDialog,
          ),
          _ReelRailButton(
            icon: Iconsax.more,
            onTap: _showMenu,
          ),
          const SizedBox(height: 10),
          _MusicDisc(
            imageUrl: thumbnailUrl,
            controller: widget.discController,
            onTap: _currentPost.soundUrl != null ? _openSoundScreen : null,
          ),
        ],
      ),
    );
  }

  void _openSoundScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelSoundScreen(
        sourcePost: _currentPost,
        mediaResolver: widget.mediaResolver,
      ),
    ));
  }
  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

}
class _ReelRailButton extends StatelessWidget {
  const _ReelRailButton({
    required this.icon,
    this.label,
    this.active = false,
    this.activeColor,
    this.reactionType,
    this.onTap,
    this.onLongPress,
    this.onLabelTap,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final Color? activeColor;
  final String? reactionType;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? Colors.red) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active
                      ? color.withOpacity(0.18)
                      : Colors.black.withOpacity(0.30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? color.withOpacity(0.38)
                        : Colors.white.withOpacity(0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: active && reactionType != null
                      ? _ReactionIcon(type: reactionType!, size: 27)
                      : Icon(
                    icon,
                    color: color,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap: onLabelTap,
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rotating sound disc at the bottom of the action rail, showing the reel's
/// video thumbnail as artwork. Tappable only when the reel has a reusable
/// sound (opens [ReelSoundScreen]).
class _MusicDisc extends StatelessWidget {
  const _MusicDisc({
    required this.imageUrl,
    required this.controller,
    this.onTap,
  });

  final String? imageUrl;
  final AnimationController controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RotationTransition(
        turns: controller,
        child: Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE1306C),
                Color(0xFF8B5CF6),
                Color(0xFF111111),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl == null
                ? _buildFallback()
                : CachedNetworkImage(
              imageUrl: imageUrl!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => _buildFallback(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(
        Iconsax.music,
        color: Colors.white,
        size: 17,
      ),
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
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _kReelSurface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
