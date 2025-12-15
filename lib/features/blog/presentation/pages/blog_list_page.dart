import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../data/models/models.dart';
import '../../domain/blog_repository.dart';
import '../widgets/article_card.dart';
import 'blog_post_page.dart';
import 'blog_create_page.dart';
class BlogListPage extends StatefulWidget {
  const BlogListPage({super.key});
  @override
  State<BlogListPage> createState() => _BlogListPageState();
}
class _BlogListPageState extends State<BlogListPage> {
  final TextEditingController _search = TextEditingController();
  List<BlogCategory> _categories = [];
  List<BlogPost> _posts = [];
  int? _selectedCategory;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  late BlogRepository _repo;
  @override
  void initState() {
    super.initState();
    _repo = context.read<BlogRepository>();
    _load();
  }
  Future<void> _load({bool refresh = false}) async {
    setState(() {
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _posts.clear();
      }
      _loading = _posts.isEmpty;
      _loadingMore = !refresh && _posts.isNotEmpty;
    });
    try {
      final cats = _categories.isEmpty ? await _repo.getCategories() : _categories;
      final newPosts = await _repo.getPosts(
        categoryId: _selectedCategory,
        search: _search.text.isEmpty ? null : _search.text,
        offset: _offset,
        limit: _limit,
      );
      setState(() {
        _categories = cats;
        if (refresh) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }
        _hasMore = newPosts.length >= _limit;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: UI.surfacePage(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => BlogCreatePage()),
        backgroundColor: scheme.primary,
        child: const Icon(Iconsax.add_copy, color: Colors.white),
        tooltip: 'create_blog'.tr,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Iconsax.document_text, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'blogs'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.filter_copy, size: 20, color: scheme.primary),
            ),
            onPressed: () {},
            tooltip: 'filter'.tr,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Container(
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rLg),
                boxShadow: UI.softShadow(context),
                border: Get.isDarkMode ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              ),
              child: TextField(
                controller: _search,
                onSubmitted: (_) => _load(refresh: true),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'blogs_search_hint'.tr,
                  hintStyle: TextStyle(color: UI.subtleText(context)),
                  prefixIcon: Icon(Iconsax.search_normal_1_copy, color: scheme.primary, size: 20),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Iconsax.close_circle_copy, color: UI.subtleText(context), size: 20),
                          onPressed: () {
                            _search.clear();
                            _load(refresh: true);
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: UI.lg, vertical: UI.lg),
                ),
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            Container(
              height: 42,
              margin: EdgeInsets.only(bottom: UI.md),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                padding: EdgeInsets.symmetric(horizontal: UI.lg),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(
                      context,
                      label: 'all'.tr,
                      icon: Iconsax.menu_copy,
                      isSelected: _selectedCategory == null,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        _load(refresh: true);
                      },
                    );
                  }
                  final c = _categories[index - 1];
                  return _buildCategoryChip(
                    context,
                    label: c.categoryName,
                    icon: _getCategoryIcon(c.categoryName),
                    isSelected: _selectedCategory == c.categoryId,
                    onTap: () {
                      setState(() => _selectedCategory = c.categoryId);
                      _load(refresh: true);
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: _loading
                ? GridView.builder(
                    padding: EdgeInsets.all(UI.lg),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (_, __) => const SkeletonBox(height: 200, radius: 16),
                    itemCount: 6,
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.document_text_copy,
                                size: 48,
                                color: scheme.primary,
                              ),
                            ),
                            SizedBox(height: UI.lg),
                            Text(
                              'no_posts_found'.tr,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: UI.sm),
                            Text(
                              'try_different_search'.tr,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: UI.subtleText(context),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _load(refresh: true),
                        child: ListView.separated(
                          padding: EdgeInsets.all(UI.lg),
                          itemBuilder: (context, index) {
                            if (index >= _posts.length) {
                              if (_hasMore && !_loadingMore) {
                                _offset += _limit;
                                _load();
                              }
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(UI.lg),
                                  child: CircularProgressIndicator(color: scheme.primary),
                                ),
                              );
                            }
                            final p = _posts[index];
                            return ArticleCard(
                              post: p,
                              onTap: () {
                                Get.to(() => BlogPostPage(postId: p.postId));
                              },
                            );
                          },
                          separatorBuilder: (_, __) => SizedBox(height: UI.lg),
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(right: UI.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UI.rMd),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: UI.md, vertical: UI.sm),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                    )
                  : null,
              color: isSelected ? null : UI.surfaceCard(context),
              borderRadius: BorderRadius.circular(UI.rMd),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Get.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
              boxShadow: isSelected ? UI.softShadow(context) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : scheme.primary,
                ),
                SizedBox(width: UI.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : scheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('tech') || name.contains('technology')) return Iconsax.cpu_copy;
    if (name.contains('design') || name.contains('art')) return Iconsax.brush_3_copy;
    if (name.contains('business') || name.contains('finance')) return Iconsax.chart_copy;
    if (name.contains('health') || name.contains('medical')) return Iconsax.health_copy;
    if (name.contains('travel') || name.contains('world')) return Iconsax.global_copy;
    if (name.contains('food') || name.contains('cook')) return Iconsax.coffee_copy;
    if (name.contains('science')) return Iconsax.microscope_copy;
    if (name.contains('sport') || name.contains('fitness')) return Iconsax.cup_copy;
    if (name.contains('music') || name.contains('audio')) return Iconsax.music_copy;
    if (name.contains('video') || name.contains('film')) return Iconsax.video_play_copy;
    return Iconsax.category_copy;
  }
}
