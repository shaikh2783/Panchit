import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/presentation/widgets/video_reels_player.dart';
import 'package:snginepro/features/reels/presentation/widgets/use_sound_sheet.dart';

const Color _kAccent = Color(0xFFE1306C);
const Color _kSurface = Color(0xFF111113);

/// Sound detail screen opened from the rotating music disc on a reel:
/// shows the sound's info, the reels using it, and a "Use this sound"
/// action that reuses the existing [showUseSoundSheet] flow.
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

  String get _soundTitle => widget.sourcePost.soundTitle ?? 'Original audio';

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO(reels): replace with the API result once the backend exposes a
      // reels-by-sound endpoint (none exists in docs/reels_backend_api.md
      // yet, e.g. GET /api/reels?sound_id=...). Until then the grid shows
      // the source reel only.
      final reels = [widget.sourcePost];

      if (!mounted) return;
      setState(() {
        _reels = reels;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load reels for this sound.';
        _isLoading = false;
      });
    }
  }

  void _useThisSound() {
    if (widget.sourcePost.soundUrl == null) return;
    showUseSoundSheet(context, widget.sourcePost);
  }

  void _openReel(Post post) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ReelSoundViewerPage(
        post: post,
        mediaResolver: widget.mediaResolver,
      ),
    ));
  }

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
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildSectionTitle(),
                  const SizedBox(height: 10),
                  _buildBody(),
                ],
              ),
            ),
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Sound',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    final avatarUrl = post.authorAvatarUrl;
    final artwork = avatarUrl != null && avatarUrl.isNotEmpty
        ? CachedNetworkImageProvider(
            widget.mediaResolver(avatarUrl).toString())
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _kAccent,
                  _kAccent.withOpacity(0.35),
                ],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: _kSurface,
              backgroundImage: artwork,
              child: artwork == null
                  ? const Icon(Iconsax.music, color: Colors.white, size: 34)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _soundTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Original audio • ${post.authorName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (!_isLoading && _error == null) ...[
            const SizedBox(height: 6),
            Text(
              '${_reels.length} ${_reels.length == 1 ? 'reel' : 'reels'}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  widget.sourcePost.soundUrl != null ? _useThisSound : null,
              icon: const Icon(Icons.videocam),
              label: const Text(
                'Use this sound',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Reels using this sound',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
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
        actionLabel: 'Try Again',
        onAction: _loadReels,
      );
    }

    if (_reels.isEmpty) {
      return _buildMessage(
        icon: Iconsax.video,
        message: 'No reels using this sound yet',
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
            const Center(
              child: Text(
                'Video unavailable',
                style: TextStyle(color: Colors.white54),
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
