import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../domain/boost_repository.dart';
import '../widgets/boost_info_card.dart';
import '../../../feed/domain/posts_repository.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/presentation/widgets/post_card.dart';
class BoostedPostsPage extends StatefulWidget {
  const BoostedPostsPage({super.key});
  @override
  State<BoostedPostsPage> createState() => _BoostedPostsPageState();
}
class _BoostedPostsPageState extends State<BoostedPostsPage> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  PaginationInfo? _pagination;
  BoostInfo? _boostInfo;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _subscriptionRequired = false;
  int _offset = 0;
  final int _limit = 20;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBoostedPosts();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _pagination != null && _pagination!.hasMore) {
        _loadMore();
      }
    }
  }
  Future<void> _loadBoostedPosts() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
      _posts.clear();
      _subscriptionRequired = false;
    });
    try {
      final boostRepository = context.read<BoostRepository>();
      final postsRepository = context.read<PostsRepository>();
      final response = await boostRepository.getBoostedPosts(offset: _offset, limit: _limit);
      // جلب تفاصيل كل منشور معزز
      final List<Post> fullPosts = [];
      for (var postData in response.posts) {
        try {
          final postId = postData['post_id'] is String 
              ? int.parse(postData['post_id']) 
              : postData['post_id'] as int;
          final postDetails = await postsRepository.fetchPost(postId);
          final post = Post.fromJson(postDetails);
          fullPosts.add(post);
        } catch (e) {
        }
      }
      if (mounted) {
        setState(() {
          _posts = fullPosts;
          _pagination = response.pagination;
          _boostInfo = response.boostInfo;
          _offset = _posts.length;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('post_text') || errorMessage.contains('Unknown column')) {
          errorMessage = 'خطأ في الخادم: Backend API يحتاج إلى تحديث\n(use "text" instead of "post_text")';
        }
        final requiresSub = errorMessage.contains('SUBSCRIPTION_REQUIRED') ||
            errorMessage.contains('subscribe to a package');
        if (requiresSub) {
          setState(() => _subscriptionRequired = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requiresSub ? 'You need to subscribe to view boosted posts' : '${'error'.tr}: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _loadMore() async {
    if (_isLoadingMore || _subscriptionRequired) return;
    setState(() => _isLoadingMore = true);
    try {
      final boostRepository = context.read<BoostRepository>();
      final postsRepository = context.read<PostsRepository>();
      final response = await boostRepository.getBoostedPosts(offset: _offset, limit: _limit);
      // جلب تفاصيل كل منشور معزز
      final List<Post> newPosts = [];
      for (var postData in response.posts) {
        try {
          final postId = postData['post_id'] is String 
              ? int.parse(postData['post_id']) 
              : postData['post_id'] as int;
          final postDetails = await postsRepository.fetchPost(postId);
          final post = Post.fromJson(postDetails);
          newPosts.add(post);
        } catch (e) {
        }
      }
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _pagination = response.pagination;
          _offset = _posts.length;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('post_text') || errorMessage.contains('Unknown column')) {
          errorMessage = 'خطأ في الخادم: Backend API يحتاج إلى تحديث';
        }
        final requiresSub = errorMessage.contains('SUBSCRIPTION_REQUIRED') ||
            errorMessage.contains('subscribe to a package');
        if (requiresSub) {
          setState(() => _subscriptionRequired = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requiresSub ? 'You need to subscribe to view boosted posts' : '${'error'.tr}: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
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
        title: Text('my_boosted_posts'.tr),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadBoostedPosts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBoostedPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _subscriptionRequired
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.danger, size: 64, color: theme.colorScheme.error.withOpacity(0.8)),
                        const SizedBox(height: 12),
                        Text(
                          'You need to subscribe to view boosted posts',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SUBSCRIPTION_REQUIRED',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
            : Column(
                children: [
                  // Boost Info Card
                  if (_boostInfo != null)
                    BoostInfoCard(
                      boostedCount: _boostInfo!.boostedCount,
                      remainingBoosts: _boostInfo!.remainingBoosts,
                      boostLimit: _boostInfo!.boostLimit,
                      canBoostMore: _boostInfo!.canBoostMore,
                    ),
                  // Posts List
                  Expanded(
                    child: _posts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.star,
                                  size: 80,
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_boosted_posts'.tr,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                                ),
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
                              return PostCard(post: _posts[index]);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
