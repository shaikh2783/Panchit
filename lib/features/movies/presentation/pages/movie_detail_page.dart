import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../domain/movies_repository.dart';
import '../../data/models/movie.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/feed/data/models/post.dart' show PostVideo;
import 'package:snginepro/features/feed/presentation/widgets/adaptive_video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MovieDetailPage extends StatefulWidget {
  final int movieId;
  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  Movie? _movie;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<MoviesRepository>();
      final m = await repo.getMovie(widget.movieId);
      if (!mounted) return;
      setState(() => _movie = m);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred_with_message'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final repo = context.read<MoviesRepository>();
      final url = await repo.purchaseMovie(widget.movieId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('movie_purchase_success'.trParams({'url': url})),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally navigate with Get.toNamed(url)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred_with_message'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('movie_detail_title'.tr),
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _load),
        ],
      ),
      body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _movie == null
              ? Center(child: Text('movie_not_found'.tr))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _MovieHeader(movie: _movie!)),
                    if ((_movie!.source != null && _movie!.source!.isNotEmpty) &&
                        (_movie!.canWatch == true || _movie!.isPaid == 0))
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: _WatchCard(movie: _movie!),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoChips(movie: _movie!),
                            const SizedBox(height: 12),
                            if (_movie!.description != null &&
                                _movie!.description!.isNotEmpty)
                              _SectionCard(
                                title: 'movie_overview'.tr,
                                child: Text(
                                  _movie!.description!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.4),
                                ),
                              ),
                            if (_movie!.stars != null &&
                                _movie!.stars!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'movie_cast'.tr,
                                child: Text(
                                  _movie!.stars!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                            if (_movie!.genresList.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'movie_genres'.tr,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _movie!.genresList
                                      .map((g) => Chip(label: Text(g.genreName)))
                                      .toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ActionButtons(
                              isPaid: _movie!.isPaid == 1,
                              canWatch: _movie!.canWatch == true,
                              purchasing: _purchasing,
                              onPurchase: _purchase,
                              onWatch: () {
                                final url = _movie!.movieUrl ?? '/movie/${_movie!.movieId}';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('movie_open_link'.trParams({'url': url})),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _MovieHeader extends StatelessWidget {
  final Movie movie;
  const _MovieHeader({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: movie.poster != null && movie.poster!.isNotEmpty
              ? Image.network(movie.poster!, fit: BoxFit.cover)
              : Container(color: Theme.of(context).colorScheme.surfaceVariant),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.eye,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${movie.views}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        if (movie.isPaid == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'paid_badge'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoviePlayer extends StatelessWidget {
  final Movie movie;
  const _MoviePlayer({required this.movie});

  @override
  Widget build(BuildContext context) {
    final src = movie.source ?? '';
    final isYoutube =
        (movie.sourceType?.toLowerCase() == 'youtube') ||
        src.contains('youtube.com') ||
        src.contains('youtu.be');
    if (isYoutube) {
      final videoId = _extractYoutubeId(src);
      if (videoId == null) {
        return Text('invalid_youtube_url'.tr);
      }
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: controller),
        ),
      );
    } else {
      final mediaResolver = context.read<AppConfig>().mediaAsset;
      final video = PostVideo(
        originalSource: src,
        availableSources: const {},
        thumbnail: movie.poster ?? '',
        categoryName: '',
        viewCount: movie.views,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdaptiveVideoPlayer(
          video: video,
          mediaResolver: mediaResolver,
          startMuted: false,
          autoplayWhenVisible: true,
          borderRadius: 12,
        ),
      );
    }
  }

  String? _extractYoutubeId(String url) {
    try {
      // Handle common formats: https://www.youtube.com/watch?v=ID, https://youtu.be/ID
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) return v;
      }
      if (uri.host.contains('youtu.be')) {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (id != null && id.isNotEmpty) return id;
      }
      // Fallback: regex capture
      final reg = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})');
      final m = reg.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    } catch (_) {}
    return null;
  }
}

class _InfoChips extends StatelessWidget {
  final Movie movie;
  const _InfoChips({required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      if (movie.isPaid == 1)
        _pill(theme, label: 'paid_badge'.tr, icon: Iconsax.card, color: Colors.amber),
      _pill(theme, label: 'movie_views_label'.trParams({'count': movie.views.toString()}), icon: Iconsax.eye),
      if (movie.availableFor > 0)
        _pill(theme, label: 'movie_available_for_days'.trParams({'days': movie.availableFor.toString()}), icon: Iconsax.timer),
      if ((movie.sourceType ?? '').toLowerCase() == 'youtube')
        _pill(theme, label: 'movie_source_youtube'.tr, icon: Iconsax.video_play, color: Colors.redAccent),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _pill(ThemeData theme, {required String label, required IconData icon, Color? color}) {
    final bg = (color ?? theme.colorScheme.primary).withOpacity(0.12);
    final fg = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isPaid;
  final bool canWatch;
  final bool purchasing;
  final VoidCallback onPurchase;
  final VoidCallback onWatch;
  const _ActionButtons({
    required this.isPaid,
    required this.canWatch,
    required this.purchasing,
    required this.onPurchase,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPurchase = isPaid && !canWatch;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(showPurchase ? Iconsax.card : Iconsax.play),
            label: Text(showPurchase
              ? (purchasing ? 'movie_purchasing'.tr : 'movie_purchase'.tr)
              : 'movie_watch'.tr),
            onPressed: purchasing
                ? null
                : showPurchase
                    ? onPurchase
                    : onWatch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchCard extends StatelessWidget {
  final Movie movie;
  const _WatchCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container
        ( // modern card shell
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Iconsax.play, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'movie_watch_now'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.eye, size: 14),
                      const SizedBox(width: 4),
                      Text('${movie.views}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: _MoviePlayer(movie: movie),
          ),
        ],
      ),
    );
  }
}
