import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../domain/movies_repository.dart';
import '../../data/models/movie.dart';
import '../../data/models/genre.dart';
import 'movie_detail_page.dart';

class MoviesListPage extends StatefulWidget {
  const MoviesListPage({super.key});

  @override
  State<MoviesListPage> createState() => _MoviesListPageState();
}

class _MoviesListPageState extends State<MoviesListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final int _limit = 12;

  List<Movie> _movies = [];
  List<Genre> _genres = [];
  int? _selectedGenreId;
  String? _query;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _loadMovies(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadGenres() async {
    try {
      final repo = context.read<MoviesRepository>();
      final genres = await repo.getGenres();
      if (!mounted) return;
      setState(() => _genres = genres);
    } catch (_) {
      // Ignore, optional
    }
  }

  Future<void> _loadMovies({bool initial = false}) async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      if (initial) {
        _offset = 0;
        _movies.clear();
        _hasMore = true;
      }
    });

    try {
      final repo = context.read<MoviesRepository>();
      final response = await repo.listMovies(
        query: _query,
        genreId: _selectedGenreId,
        offset: _offset,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        if (initial) {
          _movies = response.movies.toList();
        } else {
          _movies.addAll(response.movies);
        }
        _hasMore = response.hasMore;
        _offset = _movies.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred_with_message'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = context.read<MoviesRepository>();
      final response = await repo.listMovies(
        query: _query,
        genreId: _selectedGenreId,
        offset: _offset,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        _movies.addAll(response.movies);
        _hasMore = response.hasMore;
        _offset = _movies.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred_with_message'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _openGenrePicker() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text('movies_select_genre'.tr)),
              ListTile(
                leading: const Icon(Iconsax.category),
                title: Text('all_genres_title'.tr),
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final g = _genres[index];
                    return ListTile(
                      title: Text(g.genreName),
                      onTap: () => Navigator.pop(context, g.genreId),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null || _selectedGenreId != selected) {
      setState(() => _selectedGenreId = selected);
      _loadMovies(initial: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('movies_title'.tr),
            const SizedBox(width: 8),
            if (_selectedGenreId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _genres.firstWhere(
                    (g) => g.genreId == _selectedGenreId,
                    orElse: () => Genre(genreId: 0, genreName: 'movies_unknown_genre'.tr),
                  ).genreName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Iconsax.category), onPressed: _openGenrePicker),
          IconButton(icon: const Icon(Iconsax.search_normal), onPressed: () async {
            final query = await showDialog<String?>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('search_movies_title'.tr),
                  content: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: 'movies_search_hint'.tr),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, null), child: Text('cancel'.tr)),
                    TextButton(onPressed: () => Navigator.pop(context, _searchController.text.trim()), child: Text('search_button'.tr)),
                  ],
                );
              },
            );
            if (query != null) {
              setState(() => _query = query.isEmpty ? null : query);
              _loadMovies(initial: true);
            }
          }),
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: () => _loadMovies(initial: true)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMovies(initial: true),
        child: _isLoading && _movies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'movies_search_hint'.tr,
                          prefixIcon: const Icon(Iconsax.search_normal),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: IconButton(
                            icon: const Icon(Iconsax.refresh),
                            tooltip: 'movies_apply_filter'.tr,
                            onPressed: () {
                              final q = _searchController.text.trim();
                              setState(() => _query = q.isEmpty ? null : q);
                              _loadMovies(initial: true);
                            },
                          ),
                        ),
                        onSubmitted: (v) {
                          final q = v.trim();
                          setState(() => _query = q.isEmpty ? null : q);
                          _loadMovies(initial: true);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _movies.length && _isLoadingMore) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (index >= _movies.length) return const SizedBox.shrink();
                          final m = _movies[index];
                          return _PosterCard(
                            title: m.title,
                            poster: m.poster,
                            isPaid: m.isPaid == 1,
                            views: m.views,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MovieDetailPage(movieId: m.movieId)),
                              );
                            },
                          );
                        },
                        childCount: _movies.length + (_isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
                  if (!_isLoading && _movies.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('movies_empty'.tr)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final String title;
  final String? poster;
  final bool isPaid;
  final int views;
  final VoidCallback onTap;

  const _PosterCard({
    required this.title,
    required this.poster,
    required this.isPaid,
    required this.views,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: poster != null && poster!.isNotEmpty
                    ? Image.network(poster!, fit: BoxFit.cover)
                    : Container(color: theme.colorScheme.surfaceVariant),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Row(
                  children: [
                    if (isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('paid_badge'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withOpacity(0.42),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Iconsax.eye, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('$views', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
