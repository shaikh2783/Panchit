import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/application/bloc/posts_bloc.dart';
import '../../../feed/application/bloc/posts_events.dart';
import '../../data/models/group.dart';
import '../../data/services/group_posts_service.dart';
/// ويدجت عرض منشورات المجموعة
class GroupPostsWidget extends StatefulWidget {
  final Group group;
  const GroupPostsWidget({
    super.key,
    required this.group,
  });
  @override
  State<GroupPostsWidget> createState() => _GroupPostsWidgetState();
}
class _GroupPostsWidgetState extends State<GroupPostsWidget> with AutomaticKeepAliveClientMixin {
  late final GroupPostsService _postsService;
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _limit = 10;
  String? _error;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _postsService = GroupPostsService(context.read<ApiClient>());
    _loadInitialPosts();
  }
  @override
  void dispose() {
    super.dispose();
  }
  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentOffset = 0;
    });
    try {
      final posts = await _postsService.getGroupPosts(
        groupId: widget.group.groupId,
        offset: _currentOffset,
        limit: _limit,
      );
      final hasMore = await _postsService.hasMorePosts(
        groupId: widget.group.groupId,
        offset: _currentOffset + _limit,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _hasMore = hasMore;
          _currentOffset = posts.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load posts: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final newPosts = await _postsService.getGroupPosts(
        groupId: widget.group.groupId,
        offset: _currentOffset,
        limit: _limit,
      );
      final hasMore = await _postsService.hasMorePosts(
        groupId: widget.group.groupId,
        offset: _currentOffset + _limit,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _hasMore = hasMore;
          _currentOffset = _posts.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }
  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _currentOffset = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadInitialPosts();
  }
  void _updatePostReaction(String postId, String reaction) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id.toString() == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWithReaction(reaction);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null && _posts.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialPosts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.post_add_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No posts in this group yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to post!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // تحميل المزيد عند الوصول قرب النهاية
          if (!_isLoading && 
              !_isLoadingMore && 
              _hasMore &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMorePosts();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(), // السماح بالـ scroll دائماً
          itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = _posts[index];
          return PostCard(
            post: post,
            key: ValueKey('group_post_${post.id}'),
            onReactionChanged: (postId, reaction) {
              // تحديث الـ local state
              _updatePostReaction(postId, reaction);
              // إرسال للـ Bloc العام
              context.read<PostsBloc>().add(
                ReactToPostEvent(int.parse(postId), reaction),
              );
            },
          );
        },
      ),
      ),
    );
  }
}