import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../domain/posts_repository.dart';
import '../../data/models/post.dart';
import '../widgets/post_card.dart';

class MemoriesPostsPage extends StatefulWidget {
  const MemoriesPostsPage({super.key});

  @override
  State<MemoriesPostsPage> createState() => _MemoriesPostsPageState();
}

class _MemoriesPostsPageState extends State<MemoriesPostsPage> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMemories();
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

  Future<void> _loadMemories() async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
      _posts.clear();
      _hasMore = true;
    });

    try {
      final repo = context.read<PostsRepository>();
      final response = await repo.fetchMemories(limit: _limit, offset: _offset);

      if (mounted) {
        setState(() {
          _posts = response.posts.toList();
          _hasMore = response.hasMore;
          _offset = _posts.length;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error'.tr}: $e'),
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
      final repo = context.read<PostsRepository>();
      final response = await repo.fetchMemories(limit: _limit, offset: _offset);

      if (mounted) {
        setState(() {
          _posts.addAll(response.posts);
          _hasMore = response.hasMore;
          _offset = _posts.length;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error'.tr}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Memories'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadMemories,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMemories,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.archive,
                          size: 80,
                          color:
                              theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text('No memories found'),
                      ],
                    ),
                  )
                : ListView.builder(
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
                  ),
      ),
    );
  }
}
