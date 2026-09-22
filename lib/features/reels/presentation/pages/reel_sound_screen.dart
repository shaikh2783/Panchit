import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/presentation/widgets/video_reels_player.dart';
import 'package:snginepro/features/reels/data/datasources/reels_api_service.dart';
import 'package:snginepro/features/reels/presentation/widgets/use_sound_sheet.dart';

const Color _kAccent = Color(0xFFE1306C);
const Color _kSurface = Color(0xFF111113);

/// Load state of the audio-only preview player.
enum _PreviewStatus { none, loading, ready, error }

/// Sound detail screen opened from the rotating music disc on a reel:
/// shows the sound's info with an audio-only preview player, the reels
/// using it, and a "Use this sound" action that reuses the existing
/// [showUseSoundSheet] flow.
class ReelSoundScreen extends StatefulWidget {
  final Post sourcePost;
  final MediaPathResolver mediaResolver;

  const ReelSoundScreen({
    super.key,
    required this.sourcePost,
    required this.mediaResolver,
  });

  @override
  State<ReelSoundScreen> createState() => _ReelSoundScreenState();
}

class _ReelSoundScreenState extends State<ReelSoundScreen> {
  bool _isLoading = true;
  String? _error;
  List<Post> _reels = const [];

  /// Server-reported total posts using this sound (§20 `sound.post_count`);
  /// falls back to the loaded list length when the endpoint isn't live yet.
  int? _soundPostCount;

  AudioPlayer? _player;
  _PreviewStatus _previewStatus = _PreviewStatus.none;

  /// Set while the user drags the seek bar so the thumb follows the finger
  /// instead of the position stream.
  double? _dragPositionSec;

  String get _soundTitle =>
      widget.sourcePost.soundTitle ?? 'original_audio'.tr;

  /// Reel video thumbnail used as the sound artwork (header + player card).
  String? get _thumbnailUrl {
    final thumbnail = widget.sourcePost.video?.thumbnail;
    if (thumbnail == null || thumbnail.isEmpty) return null;
    return widget.mediaResolver(thumbnail).toString();
  }

  @override
  void initState() {
    super.initState();
    _loadReels();
    _initPreviewPlayer();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _loadReels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    var reels = <Post>[widget.sourcePost];
    int? postCount;

    // Reels-by-sound per docs/reels_backend_api.md §20. The endpoint is not
    // implemented server-side yet (docs/reels_backend_gaps.md gap 2), and
    // some posts carry sound_url without sound_id — in both cases the grid
    // degrades to the source reel only, as before.
    final soundId = widget.sourcePost.soundId;
    if (soundId != null) {
      try {
        final result = await context
            .read<ReelsApiService>()
            .fetchReelsBySound(soundId: soundId);
        if (result.reels.isNotEmpty) {
          reels = result.reels;
        }
        postCount = result.sound?.postCount;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🎵 [SoundScreen] reels_by_sound unavailable '
              '(gap 2), showing source reel only: $e');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _reels = reels;
      _soundPostCount = postCount;
      _isLoading = false;
    });
  }

  // ─── Audio preview ────────────────────────────────────────────────────

  Future<void> _initPreviewPlayer() async {
    final url = widget.sourcePost.soundUrl;
    if (url == null || url.isEmpty) return;

    await _player?.dispose();
    final player = AudioPlayer();
    _player = player;
    setState(() => _previewStatus = _PreviewStatus.loading);

    try {
      await player.setUrl(url);
      if (!mounted) return;
      setState(() => _previewStatus = _PreviewStatus.ready);
    } catch (_) {
      if (!mounted || !identical(_player, player)) return;
      setState(() => _previewStatus = _PreviewStatus.error);
    }
  }

  Future<void> _togglePreview() async {
    final player = _player;
    if (player == null || _previewStatus != _PreviewStatus.ready) return;

    if (player.processingState == ProcessingState.completed) {
      await _replayPreview();
      return;
    }
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _replayPreview() async {
    final player = _player;
    if (player == null || _previewStatus != _PreviewStatus.ready) return;
    await player.seek(Duration.zero);
    await player.play();
  }

  /// Stops preview audio before navigating anywhere or handing playback
  /// over to a video surface.
  Future<void> _pausePreview() async {
    final player = _player;
    if (player != null && player.playing) {
      await player.pause();
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────

  void _useThisSound() {
    if (widget.sourcePost.soundUrl == null) return;
    _pausePreview();
    showUseSoundSheet(context, widget.sourcePost);
  }

  void _openReel(Post post) {
    _pausePreview();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ReelSoundViewerPage(
        post: post,
        mediaResolver: widget.mediaResolver,
      ),
    ));
  }

  void _goBack() {
    _pausePreview();
    Navigator.of(context).pop();
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _buildHeader(),
                  if (_previewStatus == _PreviewStatus.error)
                    _buildPreviewError(),
                  if (_previewStatus == _PreviewStatus.ready ||
                      _previewStatus == _PreviewStatus.loading)
                    _buildSeekBar(),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 2),
                  _buildBody(),
                ],
              ),
            ),
            // Pinned CTA, Instagram/TikTok style: always reachable while the
            // grid scrolls behind it.
            _buildUseSoundBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'sound'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Balances the leading button so the title stays centred.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final post = widget.sourcePost;
    final count = _soundPostCount ?? _reels.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArtworkPlayer(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _soundTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'original_audio_by'.trParams({'name': post.authorName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    count == 1
                        ? 'one_reel_count'.trParams({'count': '1'})
                        : 'reels_count'.trParams({'count': '$count'}),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Artwork doubles as the preview control (Instagram-style): tapping it
  /// plays/pauses the sound, with a play/pause glyph overlaid on the cover.
  Widget _buildArtworkPlayer() {
    final isLoading = _previewStatus == _PreviewStatus.loading;
    final hasPreview = _previewStatus == _PreviewStatus.ready || isLoading;

    return GestureDetector(
      onTap: hasPreview ? _togglePreview : null,
      child: Stack(
        children: [
          _SoundArtwork(thumbnailUrl: _thumbnailUrl, size: 96),
          if (hasPreview)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : StreamBuilder<PlayerState>(
                          stream: _player?.playerStateStream,
                          builder: (context, snapshot) {
                            final state = snapshot.data;
                            final isPlaying = state?.playing ?? false;
                            final isCompleted = state?.processingState ==
                                ProcessingState.completed;
                            return Icon(
                              isCompleted
                                  ? Icons.replay
                                  : isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 10),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'sound_preview_failed'.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _initPreviewPlayer,
            child: Text(
              'try_again'.tr,
              style: const TextStyle(
                color: _kAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slim scrubber under the header — position/duration on the sides of a
  /// thin draggable track.
  Widget _buildSeekBar() {
    final player = _player;
    if (player == null) return const SizedBox.shrink();

    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final maxSec =
                duration.inMilliseconds > 0 ? duration.inMilliseconds / 1000 : 1.0;
            final positionSec = _dragPositionSec ??
                (position.inMilliseconds / 1000).clamp(0.0, maxSec);

            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Row(
                children: [
                  Text(
                    _formatDuration(Duration(seconds: positionSec.round())),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: positionSec.clamp(0.0, maxSec).toDouble(),
                        max: maxSec,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChangeStart: (value) =>
                            setState(() => _dragPositionSec = value),
                        onChanged: (value) =>
                            setState(() => _dragPositionSec = value),
                        onChangeEnd: (value) async {
                          await player.seek(
                              Duration(milliseconds: (value * 1000).round()));
                          if (mounted) {
                            setState(() => _dragPositionSec = null);
                          }
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom-pinned "Use audio" bar above the safe area, separated from the
  /// scrolling grid by a hairline.
  Widget _buildUseSoundBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.sourcePost.soundUrl != null ? _useThisSound : null,
          icon: const Icon(Icons.videocam_outlined, size: 20),
          label: Text(
            'use_this_sound'.tr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    }

    if (_error != null) {
      return _buildMessage(
        icon: Iconsax.warning_2,
        message: _error ?? '',
        actionLabel: 'try_again'.tr,
        onAction: _loadReels,
      );
    }

    if (_reels.isEmpty) {
      return _buildMessage(
        icon: Iconsax.video,
        message: 'no_reels_using_sound'.tr,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final post = _reels[index];
        return _SoundReelTile(
          post: post,
          mediaResolver: widget.mediaResolver,
          onTap: () => _openReel(post),
        );
      },
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withOpacity(0.16),
              border: Border.all(color: _kAccent.withOpacity(0.28)),
            ),
            child: Icon(icon, color: _kAccent, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Header artwork: the source reel's video thumbnail as a plain rounded
/// square (Instagram audio-page style), falling back to a music note.
class _SoundArtwork extends StatelessWidget {
  const _SoundArtwork({required this.thumbnailUrl, required this.size});

  final String? thumbnailUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = thumbnailUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _ArtworkPlaceholder(),
              )
            : const _ArtworkPlaceholder(),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _kSurface,
      child: Icon(Iconsax.music, color: Colors.white, size: 34),
    );
  }
}

/// One grid tile: reel thumbnail with a views-count overlay.
class _SoundReelTile extends StatelessWidget {
  final Post post;
  final MediaPathResolver mediaResolver;
  final VoidCallback onTap;

  const _SoundReelTile({
    required this.post,
    required this.mediaResolver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = post.video?.thumbnail;
    final thumbnailUrl = thumbnail != null && thumbnail.isNotEmpty
        ? mediaResolver(thumbnail).toString()
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: _kSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _TilePlaceholder(),
              )
            else
              const _TilePlaceholder(),
            // Readability scrim behind the count overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.play, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    post.viewsCount > 0
                        ? post.viewsCountFormatted
                        : post.reactionsCountFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _kSurface,
      child: Icon(Iconsax.video, color: Colors.white24, size: 26),
    );
  }
}

/// Minimal full-screen player for a reel opened from the sound grid. Reuses
/// [VideoReelsPlayer] unchanged; the full-feed experience (actions rail,
/// comments, etc.) stays on ReelsPage — this is a focused single-reel view.
class _ReelSoundViewerPage extends StatelessWidget {
  final Post post;
  final MediaPathResolver mediaResolver;

  const _ReelSoundViewerPage({
    required this.post,
    required this.mediaResolver,
  });

  @override
  Widget build(BuildContext context) {
    final video = post.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null)
            VideoReelsPlayer(
              video: video,
              mediaResolver: mediaResolver,
              autoplay: true,
              muted: false,
              loop: true,
              enableCaching: true,
            )
          else
            Center(
              child: Text(
                'video_unavailable'.tr,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
                if (post.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 10),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
