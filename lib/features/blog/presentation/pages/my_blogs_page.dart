import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../domain/blog_repository.dart';
import '../../data/models/blog_post.dart';
import '../widgets/article_card.dart';
import 'blog_create_page.dart';
import 'blog_post_page.dart';
import 'blog_edit_page.dart';
class MyBlogsPage extends StatefulWidget {
  const MyBlogsPage({super.key});
  @override
  State<MyBlogsPage> createState() => _MyBlogsPageState();
}
class _MyBlogsPageState extends State<MyBlogsPage> {
  List<BlogPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final repo = context.read<BlogRepository>();
      final posts = await repo.getMyPosts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        offset: 0,
        limit: _limit,
      );
      // Extra client-side filter to ensure only my posts
      final auth = context.read<AuthNotifier>();
      final userIdStr = auth.currentUser?['user_id']?.toString();
      final myId = int.tryParse(userIdStr ?? '');
      final filtered = myId != null
          ? posts.where((p) => p.author.userId == myId).toList()
          : posts;
      if (mounted) {
        setState(() {
          _posts = filtered;
          _loading = false;
          _hasMore = filtered.length >= _limit;
          _offset = filtered.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final repo = context.read<BlogRepository>();
      final posts = await repo.getMyPosts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        offset: _offset,
        limit: _limit,
      );
      final auth = context.read<AuthNotifier>();
      final myId = int.tryParse(auth.currentUser?['user_id']?.toString() ?? '');
      final filtered = myId != null
          ? posts.where((p) => p.author.userId == myId).toList()
          : posts;
      if (mounted) {
        setState(() {
          _posts.addAll(filtered);
          _loadingMore = false;
          _hasMore = filtered.length >= _limit;
          _offset += filtered.length;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }
  void _onSearch(String query) {
    _searchQuery = query;
    _load();
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUserId = int.tryParse(
        context.read<AuthNotifier>().currentUser?['user_id']?.toString() ?? '');
    return Scaffold(
      backgroundColor: UI.surfacePage(context),
      appBar: AppBar(
        title: Text('my_blogs'.tr),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const BlogCreatePage())?.then((_) => _load()),
        icon: const Icon(Iconsax.add_copy, size: 20),
        label: Text('create_blog'.tr),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.all(UI.lg),
            decoration: BoxDecoration(
              color: UI.surfaceCard(context),
              borderRadius: BorderRadius.circular(UI.rLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'blogs_search_hint'.tr,
                prefixIcon: Icon(Iconsax.search_normal_copy, color: scheme.primary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: UI.md, vertical: UI.md),
              ),
              onSubmitted: _onSearch,
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.danger_copy, size: 48, color: UI.subtleText(context)),
                            SizedBox(height: UI.md),
                            Text('${'error'.tr}: $_error'),
                            SizedBox(height: UI.lg),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Iconsax.refresh_copy, size: 18),
                              label: Text('try_again'.tr),
                            ),
                          ],
                        ),
                      )
                    : _posts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.document_text_copy, size: 64, color: UI.subtleText(context)),
                                SizedBox(height: UI.lg),
                                Text(
                                  'no_posts_found'.tr,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                SizedBox(height: UI.sm),
                                Text(
                                  'create_first_blog'.tr,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: UI.subtleText(context),
                                      ),
                                ),
                                SizedBox(height: UI.xl),
                                ElevatedButton.icon(
                                  onPressed: () => Get.to(() => const BlogCreatePage())?.then((_) => _load()),
                                  icon: const Icon(Iconsax.add_copy, size: 18),
                                  label: Text('create_blog'.tr),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(UI.lg, 0, UI.lg, UI.xl * 3),
                              itemCount: _posts.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => SizedBox(height: UI.lg),
                              itemBuilder: (context, index) {
                                if (index >= _posts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final post = _posts[index];
                                final isOwner = post.iOwner == true ||
                                    (currentUserId != null && post.author.userId == currentUserId);
                                return Stack(
                                  children: [
                                    ArticleCard(
                                      post: post,
                                      onTap: () => Get.to(() => BlogPostPage(postId: post.postId))?.then((_) => _load()),
                                    ),
                                    if (isOwner)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'edit'.tr,
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withOpacity(0.35),
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Iconsax.edit_2_copy, size: 18),
                                              onPressed: () => _editPost(post),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'delete'.tr,
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withOpacity(0.35),
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Iconsax.trash_copy, size: 18),
                                              onPressed: () => _confirmDelete(post),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  void _editPost(BlogPost post) {
    Get.to(() => const BlogEditPage(), arguments: post)?.then((_) => _load());
  }
  Future<void> _confirmDelete(BlogPost post) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_blog'.tr),
        content: Text('delete_blog_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deletePost(post);
    }
  }
  Future<void> _deletePost(BlogPost post) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final repo = context.read<BlogRepository>();
      final ok = await repo.deletePost(post.postId);
      Get.back();
      if (ok) {
        setState(() => _posts.removeWhere((p) => p.postId == post.postId));
        Get.snackbar('success'.tr, 'blog_deleted_successfully'.tr);
      } else {
        Get.snackbar('error'.tr, 'operation_failed'.tr);
      }
    } catch (e) {
      Get.back();
      Get.snackbar('error'.tr, e.toString());
    }
  }
  Widget _buildSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.all(UI.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: UI.lg),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(UI.rLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 180, radius: 0),
            Padding(
              padding: EdgeInsets.all(UI.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(height: 12, width: 80, radius: 6),
                  SizedBox(height: UI.sm),
                  const SkeletonBox(height: 20, width: double.infinity, radius: 8),
                  SizedBox(height: UI.sm),
                  const SkeletonBox(height: 16, width: 200, radius: 8),
                  SizedBox(height: UI.md),
                  const SkeletonBox(height: 14, width: 150, radius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
