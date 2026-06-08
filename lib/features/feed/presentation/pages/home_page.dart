import 'dart:async';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
import 'package:snginepro/features/stories/application/bloc/stories_bloc.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import 'package:snginepro/features/feed/presentation/pages/create_story_page.dart';
import 'package:snginepro/features/feed/presentation/pages/story_viewer_page.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';
import 'package:snginepro/features/feed/presentation/widgets/promoted_post_widget.dart';
import 'package:snginepro/features/feed/presentation/pages/reels_page.dart';
import 'package:snginepro/features/reels/application/bloc/reels_bloc.dart';
import 'package:snginepro/features/search/presentation/pages/search_page.dart';
import 'package:snginepro/features/agora/presentation/pages/professional_live_stream_wrapper.dart';
import 'package:snginepro/features/messenger/presentation/pages/conversations_page.dart';
import 'package:snginepro/features/discover/data/services/homepage_widgets_api_service.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onScrollDirectionChanged});

  // true => scrolling down, false => scrolling up
  final ValueChanged<bool>? onScrollDirectionChanged;

  @override
  State<HomePage> createState() => HomePageState();
}

/// شريط الريلز في الصفحة الرئيسية
class _ReelsPreviewRail extends StatelessWidget {
  const _ReelsPreviewRail({
    required this.reels,
    required this.mediaResolver,
    required this.onOpenAll,
    required this.onOpenAt,
  });

  final List<Post> reels;
  final Uri Function(String) mediaResolver;
  final VoidCallback onOpenAll;
  final void Function(int) onOpenAt;

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = (m % 60).toString().padLeft(2, '0');
      final ss = s.toString().padLeft(2, '0');
      return '$h:$mm:$ss';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  // Priority: video.thumbnail → photos[0] → ogImage
  String _thumbFor(Post reel) {
    final vt = reel.video?.thumbnail ?? '';
    if (vt.isNotEmpty) return vt;

    if (reel.photos != null && reel.photos!.isNotEmpty) {
      final src = reel.photos!.first.source;
      if (src.isNotEmpty) return src;
    }

    final og = reel.ogImage ?? '';
    if (og.isNotEmpty) return og;

    return '';
  }

  // Returns a resolved URL. Skips mediaResolver for already-absolute URLs
  // to avoid double-base-URL bugs (e.g. https://host.com/https://host.com/…).
  String? _resolveMediaUrl(String raw) {
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return mediaResolver(raw).toString();
  }

  String? _resolveThumb(Post reel) => _resolveMediaUrl(_thumbFor(reel));

  String? _resolveVideoUrl(Post reel) {
    final bestSource = reel.video?.bestSourceUri()?.toString() ?? '';
    if (bestSource.isNotEmpty) return _resolveMediaUrl(bestSource);

    final original = reel.video?.originalSource ?? '';
    return _resolveMediaUrl(original);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.video, color: Colors.red, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'reels'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onOpenAll,
                child: Text(
                  'view_all'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final reel = reels[index];
              final thumbUrl = _resolveThumb(reel);
              final videoUrl = _resolveVideoUrl(reel);
              final durationText = reel.videoDurationSeconds != null
                  ? _formatDuration(reel.videoDurationSeconds!)
                  : null;

              return GestureDetector(
                onTap: () => onOpenAt(index),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Thumbnail
                      Positioned.fill(
                        child: _ReelThumbnail(
                          imageUrl: thumbUrl,
                          videoUrl: videoUrl,
                          isDark: isDark,
                        ),
                      ),
                      // Overlay gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Info
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Iconsax.play, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                if (durationText != null)
                                  Text(
                                    durationText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reel.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ReelThumbnail extends StatefulWidget {
  const _ReelThumbnail({
    required this.imageUrl,
    required this.videoUrl,
    required this.isDark,
  });

  final String? imageUrl;
  final String? videoUrl;
  final bool isDark;

  @override
  State<_ReelThumbnail> createState() => _ReelThumbnailState();
}

class _ReelThumbnailState extends State<_ReelThumbnail> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeFuture;
  bool _imageFailed = false;

  bool get _shouldUseVideoFallback =>
      _imageFailed || (widget.imageUrl == null || widget.imageUrl!.isEmpty);

  @override
  void initState() {
    super.initState();
    _setupVideoController();
  }

  @override
  void didUpdateWidget(covariant _ReelThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideoController();
      _setupVideoController();
    }
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFailed = false;
    }
  }

  void _setupVideoController() {
    final videoUrl = widget.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return;

    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    _initializeFuture = controller.initialize().then((_) async {
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.pause();
    }).catchError((_) {});
  }

  void _disposeVideoController() {
    final controller = _videoController;
    _videoController = null;
    _initializeFuture = null;
    controller?.dispose();
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldUseVideoFallback) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _ReelThumbPlaceholder(
          isDark: widget.isDark,
          showSpinner: true,
        ),
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageFailed = true;
              });
            }
          });
          return _buildVideoFallback();
        },
      );
    }

    return _buildVideoFallback();
  }

  Widget _buildVideoFallback() {
    final controller = _videoController;
    final initializeFuture = _initializeFuture;
    if (controller == null || initializeFuture == null) {
      return _ReelThumbPlaceholder(isDark: widget.isDark);
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return _ReelThumbPlaceholder(
            isDark: widget.isDark,
            showSpinner: true,
          );
        }

        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }
}

class _ReelThumbPlaceholder extends StatelessWidget {
  const _ReelThumbPlaceholder({required this.isDark, this.showSpinner = false});

  final bool isDark;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A2E), const Color(0xFF1A1A1E)]
              : [const Color(0xFFD0D4DC), const Color(0xFFB8BCC6)],
        ),
      ),
      child: Center(
        child: showSpinner
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: (isDark ? Colors.white : Colors.grey[600])!
                      .withValues(alpha: 0.4),
                ),
              )
            : Icon(
                Icons.play_circle_outline_rounded,
                size: 36,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.3),
              ),
      ),
    );
  }
}

/// شريط اقتراحات الأصدقاء في الصفحة الرئيسية
class _SuggestedFriendsRail extends StatefulWidget {
  const _SuggestedFriendsRail({
    required this.people,
    required this.mediaResolver,
  });

  final List<SuggestedFriend> people;
  final Uri Function(String) mediaResolver;

  @override
  State<_SuggestedFriendsRail> createState() => _SuggestedFriendsRailState();
}

class _SuggestedFriendsRailState extends State<_SuggestedFriendsRail> {
  final Set<int> _pending = {};
  final Set<int> _added = {};

  /// Check if user was added to friends from profile page
  void _checkIfAdded(int userId) {
    // Mark as added without making API call
    // This syncs the state after returning from ProfilePage
    if (!_added.contains(userId)) {
      setState(() {
        _added.add(userId);
      });
    }
  }

  Future<void> _sendFriendRequest(SuggestedFriend person) async {
    if (_pending.contains(person.userId) || _added.contains(person.userId)) return;
    setState(() {
      _pending.add(person.userId);
    });

    try {
      final api = FriendsApiService(context.read<ApiClient>());
      final result = await api.sendFriendRequest(person.userId);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _added.add(person.userId);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              result.success ? Colors.green : Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pending.remove(person.userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter out friends that have been added
    final filteredPeople = widget.people.where((person) => !_added.contains(person.userId)).toList();
    
    // If all friends were added, don't show the rail
    if (filteredPeople.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.profile_2user,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'suggested_friends_section_title'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filteredPeople.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final person = filteredPeople[index];
              final picture = person.picture;
              final avatarUrl =
                  picture != null && picture.isNotEmpty ? widget.mediaResolver(picture).toString() : null;

              final isPending = _pending.contains(person.userId);
              final isAdded = _added.contains(person.userId);

              return Container(
                width: 170,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(username: person.username),
                          ),
                        );
                        // If friend request was sent in profile page, update local state
                        if (mounted && result == true) {
                          _checkIfAdded(person.userId);
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundImage:
                                avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            child: avatarUrl == null
                                ? Text(
                                    person.fullName.isNotEmpty
                                        ? person.fullName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          if (person.verified)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Iconsax.verify, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      person.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${person.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    if (person.mutualFriendsCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${person.mutualFriendsCount} mutual',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isPending || isAdded) ? null : () => _sendFriendRequest(person),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdded
                              ? Theme.of(context).colorScheme.surfaceVariant
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: isAdded
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isPending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isAdded ? 'friends'.tr : 'add_friend_button'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  VoidCallback? _refreshPromotedPost;
  double _lastScrollOffset = 0.0;
  
  // متغيرات الفلتر
  String _selectedType = 'discover';
  Future<List<SuggestedFriend>>? _suggestedFriendsFuture;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final remaining = max - current;

    // Detect scroll direction with a small threshold to avoid noise
    const threshold = 4.0;
    if ((current - _lastScrollOffset).abs() > threshold) {
      final isScrollingDown = current > _lastScrollOffset;
      // Avoid notifying when overscrolling at top
      if (current <= 0) {
        widget.onScrollDirectionChanged?.call(false);
      } else {
        widget.onScrollDirectionChanged?.call(isScrollingDown);
      }
      _lastScrollOffset = current;
    }

    if (remaining <= 200) {
      final postsBloc = context.read<PostsBloc>();
      final state = postsBloc.state;

      if (state is PostsLoadedState && state.hasMore && !state.isLoadingMore) {
        postsBloc.add(LoadMorePostsEvent(
          type: _selectedType,
          includeAds: _selectedType == 'competition' ? '0' : '1',
        ));
      }
    }
  }

  Future<List<SuggestedFriend>> _fetchSuggestedFriends() async {
    try {
      final api = HomepageWidgetsApiService(context.read<ApiClient>());
      final response = await api.getHomepageWidgets();

      if (response.success &&
          response.widgets?.suggestedFriends?.enabled == true) {
        return response.widgets!.suggestedFriends!.people;
      }
    } catch (e) {
    }

    return [];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _suggestedFriendsFuture = _fetchSuggestedFriends();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsBloc = context.read<PostsBloc>();
      if (postsBloc.state is PostsInitialState) {
        postsBloc.add(LoadPostsEvent());
        // 💰 تحميل منشور مدفوع عشوائي عند فتح الصفحة الرئيسية
        postsBloc.add(LoadPromotedPostEvent());
      }

      // 📖 تحميل القصص
      final storiesBloc = context.read<StoriesBloc>();
      if (storiesBloc.state is StoriesInitial) {
        storiesBloc.add(LoadStoriesEvent());
      }

      // 🎞️ تحميل الريلز للصفحة الرئيسية
      final reelsBloc = context.read<ReelsBloc>();
      if (reelsBloc.state is ReelsInitialState) {
        reelsBloc.add(LoadReelsEvent());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Method للـ scroll to top
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleRefresh() async {

    final postsBloc = context.read<PostsBloc>();
    postsBloc.add(RefreshPostsEvent(
      type: _selectedType,
      includeAds: _selectedType == 'competition' ? '0' : '1',
    ));

    // 📖 تحديث القصص
    final storiesBloc = context.read<StoriesBloc>();
    storiesBloc.add(RefreshStoriesEvent());

    // تحديث المنشور المدفوع أيضاً
    if (_refreshPromotedPost != null) {
      _refreshPromotedPost!();
    }

    // Wait for the refresh to complete
    await postsBloc.stream.firstWhere((state) => state is! PostsLoadingState);

  }

  void _openCreatePost() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreatePostPageModern()));
  }

  void _applyFilter(String type) {
    setState(() {
      _selectedType = type;
    });

    final postsBloc = context.read<PostsBloc>();
    postsBloc.add(LoadPostsEvent(
      type: type,
      includeAds: type == 'competition' ? '0' : '1',
    ));
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'loading_posts'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Card(
            elevation: isDark ? 8 : 4,
            shadowColor: isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8F9FA)],
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.red[700]!, Colors.red[800]!]
                            : [Colors.red[300]!, Colors.red[400]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'connection_error'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.blue[600]!, Colors.blue[700]!]
                            : [Colors.blue[500]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        'try_again'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.note_2,
                  size: 64,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'no_posts'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'be_first_to_post'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openCreatePost,
                icon: const Icon(Iconsax.edit, size: 20),
                label: Text(
                  'create_post'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final displayName =
        auth.currentUser?['user_fullname'] ??
        auth.currentUser?['user_firstname'] ??
        auth.currentUser?['user_name'] ??
        'My Account';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      body: BlocConsumer<PostsBloc, PostsState>(
        listener: (context, state) {
          // Handle any side effects here if needed
        },
        builder: (context, state) {
          if (state is PostsLoadingState) {
            return _buildLoadingState();
          }

          if (state is PostsErrorState) {
            return _buildErrorState(state.message, () {
              context.read<PostsBloc>().add(LoadPostsEvent());
            });
          }

          final posts = state is PostsLoadedState ? state.posts : <Post>[];
          final isLoadingMore = state is PostsLoadedState
              ? state.isLoadingMore
              : false;

          if (posts.isEmpty && state is PostsLoadedState) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHomeSliverAppBar(context, isDark, cs),
                  SliverToBoxAdapter(
                    child: _buildFilterBar(),
                  ),
                  SliverToBoxAdapter(
                    child: _ComposerCard(
                      displayName: displayName,
                      onTap: _openCreatePost,
                    ),
                  ),
                  SliverFillRemaining(child: _buildEmptyState()),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(), // منع scroll jump
              cacheExtent: 1000.0, // زيادة cache للـ widgets لتحسين السكرول
              slivers: [
                _buildHomeSliverAppBar(context, isDark, cs),
                SliverToBoxAdapter(
                  child: _buildFilterBar(),
                ),
                BlocBuilder<StoriesBloc, StoriesState>(
                  builder: (context, storiesState) {
                    // عرض القصص دائماً (مع زر الإضافة) إذا كانت في حالة StoriesLoaded
                    if (storiesState is StoriesLoaded) {
                      return SliverToBoxAdapter(
                        child: _StoriesRail(stories: storiesState.stories),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                SliverToBoxAdapter(
                  child: _ComposerCard(
                    displayName: displayName,
                    onTap: _openCreatePost,
                  ),
                ),
                // 💰 المنشور المدفوع الثابت في الأعلى
                SliverToBoxAdapter(
                  child: PromotedPostWidget(
                    onRefreshCallback: (refreshFunc) {
                      _refreshPromotedPost = refreshFunc;
                    },
                  ),
                ),
                // Posts with Ads as separate slivers
                ...() {
                  final List<Widget> slivers = [];
                  
                  for (int i = 0; i < posts.length; i++) {
                    // Add post
                    slivers.add(
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          key: ValueKey('post-${posts[i].id}'),
                          child: PostCard(
                            post: posts[i],
                            onReactionChanged: (postId, reaction) {
                              context.read<PostsBloc>().add(
                                ReactToPostEvent(int.parse(postId), reaction),
                              );
                            },
                          ),
                        ),
                      ),
                    );

                    // Insert reels rail after the third post (index 2) once
                    if (i == 2) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: BlocBuilder<ReelsBloc, ReelsState>(
                            builder: (context, reelsState) {
                              if (reelsState is ReelsLoadedState &&
                                  reelsState.reels.isNotEmpty) {
                                final mediaResolver =
                                    context.read<AppConfig>().mediaAsset;
                                final previewReels = reelsState.reels.length > 5
                                    ? reelsState.reels.sublist(0, 5)
                                    : reelsState.reels;
                                return _ReelsPreviewRail(
                                  reels: previewReels,
                                  mediaResolver: mediaResolver,
                                  onOpenAll: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ReelsPage(),
                                      ),
                                    );
                                  },
                                  onOpenAt: (startIndex) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReelsPage(initialIndex: startIndex),
                                      ),
                                    );
                                  },
                                );
                              }

                              if (reelsState is ReelsLoadingState) {
                                return const SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      );
                    }

                    // Insert suggested friends rail after the 7th post (index 6) once
                    if (i == 6) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: FutureBuilder<List<SuggestedFriend>>(
                            future: _suggestedFriendsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 230,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final people = snapshot.data ?? const [];
                              if (people.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final mediaResolver = context.read<AppConfig>().mediaAsset;
                              final limited = people.length > 10
                                  ? people.sublist(0, 10)
                                  : people;

                              return _SuggestedFriendsRail(
                                people: limited,
                                mediaResolver: mediaResolver,
                              );
                            },
                          ),
                        ),
                      );
                    }
                  }
                  
                  return slivers;
                }(),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: isLoadingMore
                          ? Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black26
                                            : Colors.grey.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'home_loading_more'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildHomeSliverAppBar(
    BuildContext context,
    bool isDark,
    ColorScheme cs,
  ) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      toolbarHeight: 64,
      floating: true,
      snap: true,
      pinned: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A).withValues(alpha: 0.98),
                    const Color(0xFF0A0A0A).withValues(alpha: 0.95),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.98),
                    const Color(0xFFF8F9FA).withValues(alpha: 0.95),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Image.asset('assets/app_icon.png',width: 40,height: 40),
          const SizedBox(width: 12),
          Image.asset('assets/ic_logo_txt.png',width: 120,height: 40)
        ],
      ),
      actions: [
        _AppBarAction(
          icon: Icons.search,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const SearchPage()));
          },
        ),
        _AppBarAction(
          icon: Iconsax.message,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ConversationsPage()),
            );
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    const filterOptions = [
      (label: 'Home',    value: 'discover',    icon: Icons.home_rounded),
      (label: 'competition',     value: 'competition', icon: Iconsax.cup),
      (label: 'Popular',     value: 'popular',     icon: Icons.trending_up_rounded),
      (label: 'For You',    value: 'newsfeed',    icon: Icons.explore_outlined),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1F) : const Color(0xFFECEFF4),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final opt = filterOptions[index];
          final isSelected = _selectedType == opt.value;

          return GestureDetector(
            onTap: () => _applyFilter(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : cs.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : cs.onSurface.withValues(alpha: 0.75)),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: isSelected ? 0.1 : 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [Colors.white, const Color(0xFFF5F5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.grey[700],
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoriesRail extends StatelessWidget {
  const _StoriesRail({required this.stories});

  final List<Story> stories;

  void _openStories(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerPage(stories: stories, initialStoryIndex: index),
      ),
    );
  }

  void _openCreateStory(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateStoryPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.surface, cs.surface.withValues(alpha: 0.95)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreateStoryCard(onTap: () => _openCreateStory(context));
          }
          final story = stories[index - 1];
          return _StoryCard(
            story: story,
            onTap: () => _openStories(context, index - 1),
          );
        },
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    final avatarUrl = auth.currentUser?['user_picture'];
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                if (avatarUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      mediaAsset(avatarUrl).toString(),
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Positioned.fill(child: Container(color: Colors.grey[300])),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: cs.primary,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 35,
                    color: cs.surface.withValues(alpha: 0.92),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'home_create_story'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    final firstItem = story.items.isNotEmpty ? story.items.first : null;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                if (firstItem != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: mediaAsset(firstItem.source).toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: story.authorAvatarUrl != null
                          ? CachedNetworkImageProvider(
                              mediaAsset(story.authorAvatarUrl!).toString(),
                            )
                          : null,
                      child: story.authorAvatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    story.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.1,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
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

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.displayName, required this.onTap});

  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Get.isDarkMode || Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF3A3A3A),
                                  const Color(0xFF2F2F2F),
                                ]
                              : [
                                  const Color(0xFFF5F5F5),
                                  const Color(0xFFEEEEEE),
                                ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'home_composer_placeholder'.trParams({
                          'name': displayName,
                        }),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ComposerAction(
                  icon: Icons.videocam_rounded,
                  color: const Color(0xFFF02849),
                  label: 'home_live'.tr,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalLiveStreamWrapper(),
                        settings: const RouteSettings(
                          name: '/professional-live-stream',
                        ),
                      ),
                    );
                  },
                ),
                _ComposerAction(
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFF45BD62),
                  label: 'home_photo'.tr,
                  onTap: onTap
                ),
                _ComposerAction(
                  icon: Icons.flag_rounded,
                  color: const Color(0xFF1877F2),
                  label: 'home_event'.tr,
                  onTap: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
                : [const Color(0xFFF8F9FA), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}
