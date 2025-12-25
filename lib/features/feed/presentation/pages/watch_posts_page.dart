import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/data/models/country.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import '../../domain/posts_repository.dart';
import '../../data/models/post.dart';
import '../widgets/post_card.dart';

class WatchPostsPage extends StatefulWidget {
  const WatchPostsPage({super.key});

  @override
  State<WatchPostsPage> createState() => _WatchPostsPageState();
}

class _WatchPostsPageState extends State<WatchPostsPage> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _country;
  List<Country> _countries = [];
  bool _isLoadingCountries = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts(initial: true);
    _loadCountries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadPosts({bool initial = false}) async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      if (initial) {
        _offset = 0;
        _posts.clear();
        _hasMore = true;
      }
    });

    try {
      final repo = context.read<PostsRepository>();
      final response = await repo.fetchWatchPosts(
        limit: _limit,
        offset: _offset,
        country: _country,
      );

      if (!mounted) return;
      setState(() {
        if (initial) {
          _posts = response.posts.toList();
        } else {
          _posts.addAll(response.posts);
        }
        _hasMore = response.hasMore;
        _offset = _posts.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = context.read<PostsRepository>();
      final response = await repo.fetchWatchPosts(
        limit: _limit,
        offset: _offset,
        country: _country,
      );

      if (!mounted) return;
      setState(() {
        _posts.addAll(response.posts);
        _hasMore = response.hasMore;
        _offset = _posts.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      final repo = context.read<PagesRepository>();
      final countries = await repo.getCountries();
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() => _isLoadingCountries = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _chooseCountry() async {
    if (_isLoadingCountries) return;
    if (_countries.isEmpty) {
      await _loadCountries();
      if (_countries.isEmpty) return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Select country')),
              ListTile(
                leading: const Icon(Iconsax.global),
                title: const Text('All countries'),
                onTap: () => Navigator.pop(context, ''),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final c = _countries[index];
                    return ListTile(
                      title: Text(c.countryName),
                      onTap: () => Navigator.pop(context, c.countryName),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _country = selected.isEmpty ? null : selected);
      _loadPosts(initial: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;

    if (_isLoading && _posts.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_posts.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.video, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _country != null && _country!.isNotEmpty
                  ? 'No videos for country: ${_country!}'
                  : 'No videos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    } else {
      content = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final post = _posts[index];
          return PostCard(
            post: post,
            onReactionChanged: (postId, reaction) {
              final id = int.tryParse(postId) ?? post.id;
              final i = _posts.indexWhere((p) => p.id == id);
              if (i != -1) {
                final current = _posts[i];
                final prevReaction = current.myReaction;
                Map<String, int> breakdown = Map<String, int>.from(current.reactionBreakdown);

                if (reaction == 'remove') {
                  if (prevReaction != null && prevReaction.isNotEmpty) {
                    final prevCount = breakdown[prevReaction] ?? 0;
                    breakdown[prevReaction] = (prevCount - 1).clamp(0, 1 << 30);
                  }
                  final updated = current.copyWith(
                    clearMyReaction: true,
                    reactionsCount: (current.reactionsCount - 1).clamp(0, 1 << 30),
                    reactionBreakdown: breakdown,
                  );
                  setState(() => _posts[i] = updated);
                } else {
                  if (prevReaction != null && prevReaction.isNotEmpty && prevReaction != reaction) {
                    final prevCount = breakdown[prevReaction] ?? 0;
                    breakdown[prevReaction] = (prevCount - 1).clamp(0, 1 << 30);
                  }
                  final newCount = breakdown[reaction] ?? 0;
                  breakdown[reaction] = newCount + 1;
                  final alreadyReacted = prevReaction != null && prevReaction.isNotEmpty;
                  final updated = current.copyWith(
                    myReaction: reaction,
                    reactionsCount: alreadyReacted ? current.reactionsCount : current.reactionsCount + 1,
                    reactionBreakdown: breakdown,
                  );
                  setState(() => _posts[i] = updated);
                }
              }
            },
            onPostUpdated: (updatedPost) {
              final i = _posts.indexWhere((p) => p.id == updatedPost.id);
              if (i != -1) {
                setState(() => _posts[i] = updatedPost);
              }
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Watch'),
            const SizedBox(width: 8),
            if (_country != null && _country!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _country!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Iconsax.global), onPressed: _chooseCountry),
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: () => _loadPosts(initial: true)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(initial: true),
        child: content,
      ),
    );
  }
}
