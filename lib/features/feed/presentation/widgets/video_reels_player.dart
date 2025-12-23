import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/core/services/video_precache_service.dart';

typedef MediaPathResolver = Uri Function(String);

/// Professional Reels Video Player with caching and smart aspect ratio
class VideoReelsPlayer extends StatefulWidget {
  const VideoReelsPlayer({
    super.key,
    required this.video,
    required this.mediaResolver,
    this.autoplay = true,
    this.muted = false,
    this.loop = true,
    this.enableCaching = true,
  });

  final PostVideo video;
  final MediaPathResolver mediaResolver;
  final bool autoplay;
  final bool muted;
  final bool loop;
  final bool enableCaching;

  @override
  State<VideoReelsPlayer> createState() => _VideoReelsPlayerState();
}

class _VideoReelsPlayerState extends State<VideoReelsPlayer>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  
  // Global player coordination to ensure only one plays at a time
  static final Set<_VideoReelsPlayerState> _allPlayers = <_VideoReelsPlayerState>{};
  static _VideoReelsPlayerState? _currentActivePlayer;
  
  // Memory management: Limit maximum concurrent players
  static const int _maxConcurrentPlayers = 3;
  static final List<_VideoReelsPlayerState> _recentPlayers = [];

  CachedVideoPlayerPlus? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isVisible = false;
  bool _isPaused = true; // Start as paused, will auto-play when visible

  // Animation for loading indicator
  late AnimationController _loadingAnimationController;
  late Animation<double> _rotationAnimation;

  // Debouncing for visibility changes
  Timer? _visibilityDebouncer;
  bool _lastVisibilityState = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addObserver(this);
    _registerPlayer();
    
    // Pre-cache الفيديو الحالي في الخلفية
    if (widget.enableCaching) {
      _precacheCurrentVideo();
    }
    
    _initializeVideo();
  }

  /// حفظ الفيديو الحالي مسبقاً في الخلفية
  void _precacheCurrentVideo() {
    try {
      final videoUrl = _getBestQualityUrl();
      VideoPrecacheService().precacheVideo(videoUrl);
    } catch (e) {
      // تجاهل الأخطاء في pre-cache
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  void deactivate() {
    // عند مغادرة الصفحة، إيقاف الفيديو
    _pause();
    super.deactivate();
  }

  void _setupAnimations() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.linear),
    );
  }

  void _cleanup() {
    _loadingAnimationController.dispose();
    _visibilityDebouncer?.cancel();
    _unregisterPlayer();
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Aggressive cleanup: Remove listeners first
    if (_controller != null && _isInitialized) {
      try {
        _controller!.controller.removeListener(_videoListener);
      } catch (e) {
        // Ignore errors during cleanup if controller is in bad state
      }
    }
    
    // ✅ Immediate synchronous disposal to free memory ASAP
    if (_controller != null) {
      try {
        _controller!.controller.pause();
        _controller!.controller.dispose();
        _controller!.dispose();
        _controller = null;
      } catch (e) {
        // Force null even if disposal fails
        _controller = null;
      }
    }
    
    // ✅ Clear from recent players list
    _recentPlayers.remove(this);
  }

  void _registerPlayer() {
    _allPlayers.add(this);
    _recentPlayers.add(this);
    
    // ✅ Memory optimization: Dispose oldest players when limit exceeded
    if (_recentPlayers.length > _maxConcurrentPlayers) {
      final oldestPlayer = _recentPlayers.removeAt(0);
      if (oldestPlayer.mounted && oldestPlayer != this) {
        oldestPlayer._disposeController();
      }
    }
  }

  void _unregisterPlayer() {
    _allPlayers.remove(this);
    _recentPlayers.remove(this);
    if (_currentActivePlayer == this) {
      _currentActivePlayer = null;
    }
  }
  
  /// Dispose controller without disposing the widget
  void _disposeController() {
    if (_controller != null) {
      try {
        _controller!.controller.removeListener(_videoListener);
        _controller!.controller.pause();
        _controller!.controller.dispose();
        _controller!.dispose();
        _controller = null;
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _hasError = false;
          });
        }
      } catch (e) {
        _controller = null;
      }
    }
  }

  void _pauseOtherPlayers() {
    for (final player in _allPlayers) {
      if (player != this && 
          player._controller != null && 
          player._isInitialized &&
          player.mounted &&
          player._controller!.controller.value.isInitialized &&
          player._controller!.controller.value.isPlaying == true) {
        try {
          player._controller!.controller.pause();
          player._updateState();
        } catch (e) {
          // تجاهل الأخطاء
        }
      }
    }
    _currentActivePlayer = this;
  }

  Future<void> _initializeVideo() async {
    if (!mounted) return;

    try {
      // Get best quality video URL
      String videoUrl = _getBestQualityUrl();
      
      // Check if video is already cached
      final isCached = VideoPrecacheService().isCached(videoUrl);
      
      if (!isCached) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
        _loadingAnimationController.repeat();
      } else {
        // اذا كان الفيديو في الكاش، لا نعرض مؤشر التحميل
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }

      // Try to use cached version first
      if (widget.enableCaching) {
        await _initializeWithCache(videoUrl);
      } else {
        await _initializeFromNetwork(videoUrl);
      }

    } catch (e) {
      _handleError(e.toString());
    }
  }

  String _getBestQualityUrl() {
    if (!widget.video.hasAnySource) {
      throw Exception('No video sources available');
    }

    // Try to get the best quality from available sources
    final availableSources = widget.video.availableSources;
    if (availableSources.isNotEmpty) {
      final preferredOrder = ['2160p', '1440p', '1080p', '720p', '480p', '360p', '240p'];
      
      for (final quality in preferredOrder) {
        final url = availableSources[quality];
        if (url != null && url.isNotEmpty) {
          return widget.mediaResolver(url).toString();
        }
      }
      
      // If no preferred quality found, use first available
      final firstUrl = availableSources.values.first;
      return widget.mediaResolver(firstUrl).toString();
    }

  // Fallback to original source
    return widget.mediaResolver(widget.video.originalSource).toString();
  }

  Future<void> _initializeWithCache(String videoUrl) async {
    try {
      // cached_video_player سيقوم بالكاش تلقائياً
      await _initializeFromNetwork(videoUrl);
    } catch (e) {
      await _initializeFromNetwork(videoUrl);
    }
  }

  Future<void> _initializeFromNetwork(String videoUrl) async {
    _controller = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(videoUrl),
      invalidateCacheIfOlderThan: const Duration(days: 3), // ✅ Reduced from 7 to 3 days
      httpHeaders: {
        'Range': 'bytes=0-', // ✅ Enable range requests for better memory handling
      },
    );
    await _setupController();
  }

  Future<void> _setupController() async {
    if (_controller == null || !mounted) return;

    await _controller!.initialize();

    if (!mounted) return;

    // Configure controller with memory-efficient settings
    await _controller!.controller.setVolume(widget.muted ? 0.0 : 1.0);
    await _controller!.controller.setLooping(widget.loop);
    
    // ✅ Reduce buffer size to save memory (only for network videos)
    // This prevents loading entire video into memory
    try {
      // Set playback speed to normal (prevents buffering issues)
      await _controller!.controller.setPlaybackSpeed(1.0);
    } catch (e) {
      // Ignore if not supported
    }

    _controller!.controller.addListener(_videoListener);

    setState(() {
      _isInitialized = true;
      _isLoading = false;
    });

    _loadingAnimationController.stop();

    // Auto-play ONLY if enabled and visible
    // لا تشغل الفيديو إلا إذا كان مرئياً بالفعل
    if (widget.autoplay && _isVisible) {
      // Use Future.delayed to ensure state is updated first
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _isVisible) _play();
      });
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    try {
      final value = _controller!.controller.value;
      if (mounted) {
        setState(() {
          _isPaused = !value.isPlaying;
        });
      }

      // Auto-replay when video ends
      if (value.position >= value.duration && 
          value.duration.inMilliseconds > 0 && 
          widget.loop) {
        _controller!.controller.seekTo(Duration.zero);
      }
    } catch (e) {
      // تجاهل الأخطاء في حالة dispose
    }
  }

  Future<void> _play() async {
    if (_controller == null || !_isInitialized || !mounted) return;
    
    try {
      _pauseOtherPlayers();
      if (_controller!.controller.value.isInitialized) {
        await _controller!.controller.play();
      }
      _updateState();
    } catch (e) {
      // تجاهل الأخطاء في حالة dispose
    }
  }

  Future<void> _pause() async {
    if (_controller == null || !mounted) return;
    
    try {
      if (_controller!.controller.value.isInitialized && 
          _controller!.controller.value.isPlaying) {
        await _controller!.controller.pause();
      }
      _updateState();
    } catch (e) {
      // تجاهل الأخطاء في حالة dispose
    }
  }

  void _updateState() {
    if (!mounted) return;
    
    try {
      if (_controller != null && _controller!.controller.value.isInitialized) {
        setState(() {
          _isPaused = !_controller!.controller.value.isPlaying;
        });
      }
    } catch (e) {
      // تجاهل الأخطاء في حالة dispose
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPaused) {
      await _play();
    } else {
      await _pause();
    }
  }

  void _handleError(String error) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _isLoading = false;
    });

    _loadingAnimationController.stop();
  }

  void _onVisibilityChanged(bool isVisible) {
    // Cancel previous debouncer
    _visibilityDebouncer?.cancel();

    // Debounce visibility changes to prevent rapid play/pause cycles
    _visibilityDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      // Only act if visibility state actually changed
      if (_lastVisibilityState == isVisible) return;

      _lastVisibilityState = isVisible;
      _isVisible = isVisible;
      
      if (widget.autoplay && _isInitialized) {
        if (isVisible) {
          // Auto-play when visible
          // إذا كان الفيديو مخزن في الكاش، يجب أن يشغل مباشرة
          _play();
        } else {
          // Pause when not visible
          _pause();
          
          // ✅ Memory optimization: Dispose controller if far from view
          // This frees memory for videos that are scrolled away
          Future.delayed(const Duration(seconds: 3), () {
            if (!mounted || !_isVisible) {
              _disposeController();
            }
          });
        }
      }
    });
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading || !_isInitialized) {
      return _buildLoadingState();
    }

    return _buildCachedVideoPlayer();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 6.28,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.video_play,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Iconsax.warning_2,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Video not available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Video loading failed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _initializeVideo,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedVideoPlayer() {
    if (_controller == null || !_controller!.controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video with proper aspect ratio handling
          _buildVideoWithAspectRatio(),
          
          // Pause indicator
          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoWithAspectRatio() {
    final controller = _controller!;
    final videoSize = controller.controller.value.size;
    
    if (videoSize.width == 0 || videoSize.height == 0) {
      return VideoPlayer(controller.controller);
    }

    final screenSize = MediaQuery.of(context).size;
    final videoAspectRatio = videoSize.width / videoSize.height;
    final screenAspectRatio = screenSize.width / screenSize.height;

    // Define thresholds for different video types
    const wideVideoThreshold = 1.5; // Videos wider than 3:2 ratio
    const portraitVideoThreshold = 0.8; // Videos taller than 4:5 ratio

    if (videoAspectRatio > wideVideoThreshold) {
      // Very wide landscape videos (like 16:9 or wider)
      // Show them with black bars to prevent stretching
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: videoAspectRatio,
            child: VideoPlayer(controller.controller),
          ),
        ),
      );
    } else if (videoAspectRatio < portraitVideoThreshold) {
      // Very tall portrait videos (like 9:16 - typical reels)
      // Use cover to fill screen
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: VideoPlayer(controller.controller),
          ),
        ),
      );
    } else {
      // Square-ish videos (between 4:5 and 3:2)
      // Use intelligent fitting based on screen ratio
      if (videoAspectRatio > screenAspectRatio) {
        // Video is wider than screen - fit height
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fitHeight,
            alignment: Alignment.center,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(controller.controller),
            ),
          ),
        );
      } else {
        // Video is taller than screen - fit width
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(controller.controller),
            ),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // إيقاف الفيديو عند إغلاق التطبيق أو مغادرة الصفحة
        if (_controller?.controller.value.isPlaying == true) {
          _pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Don't auto-resume, let visibility detector handle it
        break;
      case AppLifecycleState.hidden:
        // إيقاف عند إخفاء التطبيق
        if (_controller?.controller.value.isPlaying == true) {
          _pause();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('reel_${widget.video.hashCode}'),
      onVisibilityChanged: (info) {
        // Require higher visibility threshold (75%) to reduce flickering
        // and ensure video is truly visible before playing
        final isVisible = info.visibleFraction >= 0.75;
        _onVisibilityChanged(isVisible);
      },
      child: Container(
        color: Colors.black,
        child: _buildVideoContent(),
      ),
    );
  }
}