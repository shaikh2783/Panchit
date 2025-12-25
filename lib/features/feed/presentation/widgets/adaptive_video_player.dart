import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/core/services/video_precache_service.dart';

typedef MediaPathResolver = Uri? Function(String path);

/// Standalone adaptive video player with caching, auto quality switching,
/// fullscreen support, and global coordination to ensure only one video plays at a time.
class AdaptiveVideoPlayer extends StatefulWidget {
  const AdaptiveVideoPlayer({
    super.key,
    required this.video,
    this.mediaResolver,
    this.isFullscreen = false,
    this.startMuted = true,
    this.initialPosition = Duration.zero,
    this.autoQualityEnabled = true,
    this.disableAutoOnManualSelection = true,
    this.borderRadius = 20,
    this.showDurationBadge = true,
    this.autoplayWhenVisible = false,
  });

  final PostVideo video;
  final MediaPathResolver? mediaResolver;
  final bool isFullscreen;
  final bool startMuted;
  final Duration initialPosition;
  final bool autoQualityEnabled;
  final bool disableAutoOnManualSelection;
  final double borderRadius;
  final bool showDurationBadge;
  final bool autoplayWhenVisible;

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer>
    with WidgetsBindingObserver {
  static final Set<_AdaptiveVideoPlayerState> _activePlayers =
      <_AdaptiveVideoPlayerState>{};

  CachedVideoPlayerPlus? _controller;
  Future<void>? _initialization;

  bool _showControls = false;
  late bool _isMuted;
  bool _isBuffering = true;
  bool _previousBuffering = false;

  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;

  final List<_QualityOption> _qualityOptions = [];
  int _currentQualityIndex = -1;
  Duration? _pendingSeekPosition;
  bool? _resumeAfterSetup;
  double? _lastVisibleFraction;

  Timer? _hideControlsTimer;

  DateTime? _bufferStart;
  int _recentBufferEvents = 0;
  bool _manualOverride = false;
  DateTime? _lastStableStart;
  DateTime? _lastQualityChange;
  DateTime? _lastDebouncedDowngrade;
  DateTime? _lastDebouncedUpgrade;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.startMuted;
    WidgetsBinding.instance.addObserver(this);
    _registerPlayer();
    _rebuildQualityOptions();
    if (widget.initialPosition > Duration.zero) {
      _pendingSeekPosition = widget.initialPosition;
    }
    
    // Pre-cache الفيديوهات المتاحة الأخرى في الخلفية
    _precacheQualityOptions();
    
    _setupController();
  }

  /// Pre-cache جميع خيارات الجودة المتاحة
  void _precacheQualityOptions() {
    try {
      final precacheService = VideoPrecacheService();
      for (final option in _qualityOptions) {
        precacheService.precacheVideo(option.uri.toString());
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  @override
  void didUpdateWidget(covariant AdaptiveVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.originalSource != widget.video.originalSource ||
        oldWidget.video.availableSources != widget.video.availableSources) {
      _disposeController();
      _rebuildQualityOptions();
      _pendingSeekPosition = widget.initialPosition > Duration.zero
          ? widget.initialPosition
          : _pendingSeekPosition;
      _manualOverride = false;
      _registerPlayer();
      _setupController();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _activePlayers.remove(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller?.controller.pause();
    }
  }

  void _registerPlayer() {
    _lastVisibleFraction ??= 0;
    _activePlayers.add(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pauseOtherPlayers();
    });
  }

  bool _pauseOtherPlayers() {
    final sorted = _activePlayers.toList()
      ..sort((a, b) {
        final aVisible = a._lastVisibleFraction ?? 0;
        final bVisible = b._lastVisibleFraction ?? 0;
        return bVisible.compareTo(aVisible);
      });
    final top = sorted.isNotEmpty ? sorted.first : null;
    final topVisible = top?._lastVisibleFraction ?? 0;
    for (final player in sorted) {
      final shouldPlay = identical(player, top) && topVisible > 0.05;
      if (shouldPlay) {
        player._controller?.controller.play();
        if (player.mounted) {
          player._hideControlsTimer?.cancel();
          player._hideControlsTimer = null;
          player.setState(() {});
        }
      } else {
        player._controller?.controller.pause();
        if (player.mounted) {
          player._hideControlsTimer?.cancel();
          player._hideControlsTimer = null;
          player.setState(() {
            player._showControls = false;
          });
        }
      }
    }
    return identical(top, this);
  }

  void _disposeController() {
    final cachedPlayer = _controller;
    if (cachedPlayer != null) {
      cachedPlayer.controller
        ..removeListener(_handleControllerUpdate)
        ..dispose();
      cachedPlayer.dispose();
    }
    _controller = null;
    _initialization = null;
  }

  void _rebuildQualityOptions() {
    _qualityOptions
      ..clear()
      ..addAll(_createQualityOptions());
    _currentQualityIndex = _qualityOptions.isEmpty ? -1 : 0;
  }

  List<_QualityOption> _createQualityOptions() {
    final List<_QualityOption> options = [];
    final Set<String> seenPaths = {};

    void addOption(String label, String path) {
      if (path.isEmpty) return;
      final uri = _resolveMediaUri(path);
      if (uri == null) return;
      final key = uri.toString();
      if (seenPaths.contains(key)) return;
      seenPaths.add(key);
      options.add(_QualityOption(label, uri, _qualityRank(label, path)));
    }

    for (var entry in widget.video.availableSources.entries) {
      addOption('${entry.key}p', entry.value);
    }

    addOption('Auto', widget.video.originalSource);

    if (options.isEmpty) {
      final fallback = _resolveMediaUri(widget.video.originalSource);
      if (fallback != null) {
        options.add(_QualityOption('Auto', fallback, 10000));
      }
    }

    options.sort((a, b) => b.rank.compareTo(a.rank));
    return options;
  }

  Uri? _resolveMediaUri(String raw) {
    if (raw.isEmpty) return null;
    final fromCallback = widget.mediaResolver?.call(raw);
    if (fromCallback != null) return fromCallback;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Uri.tryParse(raw);
    }
    return Uri.tryParse(raw);
  }

  int _qualityRank(String label, String path) {
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final pathMatch = RegExp(r'(\d+)p').firstMatch(path);
    if (pathMatch != null) {
      return int.tryParse(pathMatch.group(1)!) ?? 0;
    }
    return 10000;
  }

  void _setupController() {
    if (_currentQualityIndex < 0 ||
        _currentQualityIndex >= _qualityOptions.length) {
      return;
    }
    final uri = _qualityOptions[_currentQualityIndex].uri;
    _initialization = _initializeController(uri);
    setState(() {});
  }

  Future<void> _initializeController(Uri uri) async {
    _isBuffering = true;
    setState(() {});
    
    // استخدام cached_video_player_plus مع الكاش التلقائي
    final cachedPlayer = CachedVideoPlayerPlus.networkUrl(
      uri,
      invalidateCacheIfOlderThan: const Duration(days: 7), // كاش لمدة 7 أيام
    );
    
    await cachedPlayer.initialize();
    final controller = cachedPlayer.controller;
    
    controller
      ..setLooping(false)
      ..setVolume(_isMuted ? 0 : 1);
    controller.addListener(_handleControllerUpdate);

    final targetPosition = _pendingSeekPosition ?? widget.initialPosition;
    if (targetPosition > Duration.zero &&
        targetPosition < cachedPlayer.controller.value.duration) {
      await cachedPlayer.controller.seekTo(targetPosition);
      _videoPosition = targetPosition;
    }
    _pendingSeekPosition = null;

    _controller = cachedPlayer;
    _isBuffering = cachedPlayer.controller.value.isBuffering;
    _videoDuration = cachedPlayer.controller.value.duration;
    _videoPosition = cachedPlayer.controller.value.position;

    if (_resumeAfterSetup ?? false) {
      cachedPlayer.controller.play();
    }
    _resumeAfterSetup = null;
    _recentBufferEvents = 0;
    _lastStableStart = null;

    if (mounted) {
      setState(() {});
    }
  }

  bool get _autoAdaptationActive =>
      widget.autoQualityEnabled &&
      !_manualOverride &&
      _qualityOptions.length > 1;

  void _handleControllerUpdate() {
    final cachedPlayer = _controller;
    if (!mounted || cachedPlayer == null) {
      return;
    }
    final value = cachedPlayer.controller.value;

    if (value.isBuffering && !_previousBuffering) {
      _bufferStart = DateTime.now();
    } else if (!value.isBuffering && _previousBuffering) {
      _handleBufferCompletion();
    }
    _previousBuffering = value.isBuffering;

    if (!value.isBuffering && value.isPlaying) {
      _lastStableStart ??= DateTime.now();
      if (_autoAdaptationActive &&
          _lastStableStart != null &&
          DateTime.now().difference(_lastStableStart!) >=
              const Duration(seconds: 25)) {
        _attemptUpgrade();
        _lastStableStart = DateTime.now();
      }
    } else {
      _lastStableStart = null;
    }

    if (_autoAdaptationActive) {
      final bufferedAhead = _bufferedAhead(value);
      if (bufferedAhead < const Duration(seconds: 3)) {
        _debouncedDowngrade();
      } else if (bufferedAhead > const Duration(seconds: 15) &&
          !value.isBuffering) {
        _debouncedUpgrade();
      }
    }

    final bufferingChanged = value.isBuffering != _isBuffering;
    final positionChanged = value.position != _videoPosition;
    final durationChanged = value.duration != _videoDuration;
    if (!bufferingChanged && !positionChanged && !durationChanged) {
      return;
    }
    setState(() {
      _isBuffering = value.isBuffering;
      _videoPosition = value.position;
      _videoDuration = value.duration;
    });
  }

  void _handleBufferCompletion() {
    if (_bufferStart == null) return;
    final elapsed = DateTime.now().difference(_bufferStart!);
    _bufferStart = null;
    if (!_autoAdaptationActive) return;
    _recentBufferEvents++;
    if (elapsed >= const Duration(seconds: 2) || _recentBufferEvents >= 2) {
      _attemptDowngrade();
      _recentBufferEvents = 0;
    }
  }

  void _attemptDowngrade() {
    if (!_autoAdaptationActive) return;
    if (_currentQualityIndex >= _qualityOptions.length - 1) return;
    _lastQualityChange = DateTime.now();
    _switchQuality(_currentQualityIndex + 1);
  }

  void _attemptUpgrade() {
    if (!_autoAdaptationActive) return;
    if (_currentQualityIndex <= 0) return;
    if (_lastQualityChange != null &&
        DateTime.now().difference(_lastQualityChange!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastQualityChange = DateTime.now();
    _switchQuality(_currentQualityIndex - 1);
  }

  void _debouncedDowngrade() {
    final now = DateTime.now();
    if (_lastDebouncedDowngrade != null &&
        now.difference(_lastDebouncedDowngrade!) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastDebouncedDowngrade = now;
    _attemptDowngrade();
  }

  void _debouncedUpgrade() {
    final now = DateTime.now();
    if (_lastDebouncedUpgrade != null &&
        now.difference(_lastDebouncedUpgrade!) < const Duration(seconds: 20)) {
      return;
    }
    _lastDebouncedUpgrade = now;
    _attemptUpgrade();
  }

  Duration _bufferedAhead(VideoPlayerValue value) {
    if (value.buffered.isEmpty) {
      return Duration.zero;
    }
    final lastRange = value.buffered.last;
    final end = lastRange.end > value.duration ? value.duration : lastRange.end;
    final diff = end - value.position;
    if (diff.isNegative) {
      return Duration.zero;
    }
    return diff;
  }

  void _togglePlay() {
    final cachedPlayer = _controller;
    if (cachedPlayer == null) {
      return;
    }
    if (cachedPlayer.controller.value.isPlaying) {
      cachedPlayer.controller.pause();
    } else {
      final previousVisibility = _lastVisibleFraction ?? 0;
      _lastVisibleFraction = double.maxFinite;
      _pauseOtherPlayers();
      _lastVisibleFraction = previousVisibility;
      cachedPlayer.controller.play();
    }
    _restartHideControlsTimer();
    setState(() {});
  }

  Future<void> _toggleMute() async {
    final cachedPlayer = _controller;
    if (cachedPlayer == null) {
      return;
    }
    _isMuted = !_isMuted;
    await cachedPlayer.controller.setVolume(_isMuted ? 0 : 1);
    _restartHideControlsTimer();
    setState(() {});
  }

  void _switchQuality(int newIndex, {bool byUser = false}) {
    if (newIndex < 0 || newIndex >= _qualityOptions.length) return;
    if (newIndex == _currentQualityIndex) return;

    final cachedPlayer = _controller;
    final currentPosition = cachedPlayer?.controller.value.position ?? Duration.zero;
    final isPlaying = cachedPlayer?.controller.value.isPlaying ?? false;

    _pendingSeekPosition = currentPosition;
    _resumeAfterSetup = isPlaying;
    _currentQualityIndex = newIndex;

    if (byUser && widget.disableAutoOnManualSelection) {
      final label = _qualityOptions[newIndex].label.toLowerCase();
      _manualOverride = label != 'auto';
    }

    _lastQualityChange = DateTime.now();
    _recentBufferEvents = 0;
    _lastStableStart = null;

    _disposeController();
    _setupController();
    setState(() {});
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    _lastVisibleFraction = info.visibleFraction;
    if (info.visibleFraction < 0.25) {
      _controller?.controller.pause();
      if (mounted) {
        setState(() {});
      }
    } else if (widget.autoplayWhenVisible && info.visibleFraction >= 0.6) {
      final isTop = _pauseOtherPlayers();
      if (isTop && !(_controller?.controller.value.isPlaying ?? true)) {
        _controller?.controller.play();
      }
    }
  }

  void _onTapVideo() {
    _showControls = !_showControls;
    if (_showControls) {
      _restartHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
    setState(() {});
  }

  void _restartHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cachedPlayer = _controller;

    final playerContent = VisibilityDetector(
      key: ValueKey('adaptive_video_${widget.video.originalSource}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: cachedPlayer != null
                ? FutureBuilder<void>(
                    future: _initialization,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return _buildPlaceholder();
                      }
                      return GestureDetector(
                        onTap: _onTapVideo,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: cachedPlayer.controller.value.size.width,
                                  height: cachedPlayer.controller.value.size.height,
                                  child: VideoPlayer(cachedPlayer.controller),
                                ),
                              ),
                            ),
                            if (_isBuffering)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            _buildControlsOverlay(),
                          ],
                        ),
                      );
                    },
                  )
                : _buildPlaceholder(),
          ),
          Positioned(top: 14, left: 14, child: _buildInfoBadge()),
          if (!widget.isFullscreen && !_showControls)
            Positioned(top: 14, right: 14, child: _buildFullscreenButton()),
          if (widget.showDurationBadge && !_showControls)
            Positioned(bottom: 14, right: 14, child: _buildDurationChip()),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.isFullscreen ? 0 : widget.borderRadius,
      ),
      child: AspectRatio(
        aspectRatio: cachedPlayer?.controller.value.aspectRatio ?? 16 / 9,
        child: playerContent,
      ),
    );
  }

  Widget _buildPlaceholder() {
    final uri = _resolveMediaUri(widget.video.thumbnail);
    if (uri != null && uri.toString().isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            uri.toString(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black12),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle, color: Colors.white, size: 64),
          ),
        ],
      );
    }
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final cachedPlayer = _controller;
    if (cachedPlayer == null) return const SizedBox.shrink();
    final value = cachedPlayer.controller.value;
    final isPlaying = value.isPlaying;

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                _buildTopControls(),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomControls(value),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _buildQualityChip(),
          const Spacer(),
          if (!widget.isFullscreen) ...[
            Material(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: _enterFullscreen,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Material(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _toggleMute,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(VideoPlayerValue value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressSlider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityChip() {
    if (_qualityOptions.isEmpty) return const SizedBox.shrink();
    final labels = _qualityOptions.map((option) => option.label).toList();
    final activeLabel =
        (_currentQualityIndex >= 0 && _currentQualityIndex < labels.length)
        ? labels[_currentQualityIndex]
        : labels.first;

    return GestureDetector(
      onTap: labels.length > 1
          ? () => _showQualityPicker(labels, activeLabel)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.high_quality_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              activeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (labels.length > 1) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    final cachedPlayer = _controller;
    if (cachedPlayer == null || _videoDuration == Duration.zero) {
      return const LinearProgressIndicator(
        backgroundColor: Colors.white10,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
      );
    }
    final totalMs = math.max(_videoDuration.inMilliseconds, 1);
    final positionMs = _videoPosition.inMilliseconds.clamp(0, totalMs);
    final progress = positionMs / totalMs;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: progress,
        onChangeStart: (_) => _hideControlsTimer?.cancel(),
        onChanged: (value) {
          final newPosition = Duration(milliseconds: (totalMs * value).round());
          cachedPlayer.controller.seekTo(newPosition);
          setState(() {
            _videoPosition = newPosition;
          });
        },
        onChangeEnd: (_) => _restartHideControlsTimer(),
      ),
    );
  }

  Widget _buildInfoBadge() {
    if (_showControls && !widget.isFullscreen) return const SizedBox.shrink();

    final badgeTexts = <String>[];
    if (widget.video.categoryName.isNotEmpty) {
      badgeTexts.add(widget.video.categoryName);
    }
    if (widget.video.viewCount > 0) {
      badgeTexts.add('${_formatViewsCompact(widget.video.viewCount)} مشاهدة');
    }
    if (badgeTexts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            badgeTexts.join(' · '),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenButton() {
    if (_controller == null) return const SizedBox.shrink();
    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _enterFullscreen,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildDurationChip() {
    if (_videoDuration == Duration.zero) return const SizedBox.shrink();
    final label = _formatDuration(_videoDuration);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showQualityPicker(List<String> items, String active) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'اختر الجودة',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              for (final item in items)
                ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: item == active
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      final index = items.indexOf(selected);
      if (index != -1) {
        _switchQuality(index, byUser: true);
      }
    }
  }

  Future<void> _enterFullscreen() async {
    final cachedPlayer = _controller;
    if (cachedPlayer == null) return;
    final wasPlaying = cachedPlayer.controller.value.isPlaying;
    cachedPlayer.controller.pause();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(
          video: widget.video,
          mediaResolver: widget.mediaResolver,
          startMuted: _isMuted,
          initialPosition: _videoPosition,
          autoQualityEnabled: widget.autoQualityEnabled,
          disableAutoOnManualSelection: widget.disableAutoOnManualSelection,
          showDurationBadge: widget.showDurationBadge,
        ),
      ),
    );
    if (wasPlaying) {
      cachedPlayer.controller.play();
    }
    setState(() {
      _showControls = false;
    });
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatViewsCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _QualityOption {
  _QualityOption(this.label, this.uri, this.rank);

  final String label;
  final Uri uri;
  final int rank;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    required this.video,
    this.mediaResolver,
    required this.startMuted,
    required this.initialPosition,
    required this.autoQualityEnabled,
    required this.disableAutoOnManualSelection,
    required this.showDurationBadge,
  });

  final PostVideo video;
  final MediaPathResolver? mediaResolver;
  final bool startMuted;
  final Duration initialPosition;
  final bool autoQualityEnabled;
  final bool disableAutoOnManualSelection;
  final bool showDurationBadge;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  bool _landscapeRight = true;

  @override
  void initState() {
    super.initState();
    _setSystemUi(hidden: true);
    _applyOrientation();
  }

  @override
  void dispose() {
    _setSystemUi(hidden: false);
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _setSystemUi({required bool hidden}) {
    SystemChrome.setEnabledSystemUIMode(
      hidden ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _applyOrientation() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      _landscapeRight
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft,
    ]);
  }

  void _toggleOrientation() {
    setState(() {
      _landscapeRight = !_landscapeRight;
      _applyOrientation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AdaptiveVideoPlayer(
                video: widget.video,
                mediaResolver: widget.mediaResolver,
                isFullscreen: true,
                startMuted: widget.startMuted,
                initialPosition: widget.initialPosition,
                autoQualityEnabled: widget.autoQualityEnabled,
                disableAutoOnManualSelection:
                    widget.disableAutoOnManualSelection,
                showDurationBadge: widget.showDurationBadge,
                borderRadius: 0,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _FullscreenButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _FullscreenButton(
                icon: _landscapeRight
                    ? Icons.screen_rotation_alt_rounded
                    : Icons.screen_rotation_rounded,
                onTap: _toggleOrientation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
