import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/html_text_widget.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../domain/blog_repository.dart';
import '../../data/models/blog_post.dart';
import 'blog_edit_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlogPostPage extends StatefulWidget {
  final int postId;
  const BlogPostPage({super.key, required this.postId});

  @override
  State<BlogPostPage> createState() => _BlogPostPageState();
}

class _BlogPostPageState extends State<BlogPostPage> {
  BlogPost? _post;
  bool _loading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final showTitle = _scrollController.offset > 200;
      if (showTitle != _showTitle) {
        setState(() => _showTitle = showTitle);
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<BlogRepository>();
      final p = await repo.getPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = p;
          _loading = false;
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

  void _handleMenuAction(String action) {
    if (action == 'edit') {
      _editPost();
    } else if (action == 'delete') {
      _confirmDelete();
    }
  }

  void _editPost() {
    if (_post == null) return;
    Get.to(() => const BlogEditPage(), arguments: _post)?.then((_) => _load());
  }

  Future<void> _confirmDelete() async {
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
      _deletePost();
    }
  }

  Future<void> _deletePost() async {
    if (_post == null) return;
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final repo = context.read<BlogRepository>();
      await repo.deletePost(_post!.postId);
      Get.back(); // Close loading
      Get.back(); // Close post page
      Get.snackbar('success'.tr, 'blog_deleted_successfully'.tr);
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar('error'.tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUserId = int.tryParse(
        context.read<AuthNotifier>().currentUser?['user_id']?.toString() ?? '');
    final isOwner = _post != null && (
      _post!.iOwner == true ||
      (currentUserId != null && _post!.author.userId == currentUserId)
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            _showTitle ? UI.surfacePage(context) : Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _showTitle ? null : Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: _showTitle && _post != null
            ? Text(
                _post!.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        actions: [
          if (isOwner)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showTitle
                    ? scheme.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: Icon(Iconsax.more_copy,
                    color: _showTitle ? scheme.primary : Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Iconsax.edit_2_copy, size: 18),
                        SizedBox(width: UI.sm),
                        Text('edit'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash_copy, size: 18, color: scheme.error),
                        SizedBox(width: UI.sm),
                        Text('delete'.tr, style: TextStyle(color: scheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _showTitle
                  ? scheme.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Iconsax.share_copy,
                  color: _showTitle ? scheme.primary : Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? Center(child: Text('${'error'.tr}: $_error'))
              : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 300, radius: 0),
          Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 32, width: double.infinity, radius: 8),
                SizedBox(height: UI.md),
                const SkeletonBox(height: 16, width: 200, radius: 8),
                SizedBox(height: UI.lg),
                const SkeletonBox(height: 100, width: double.infinity, radius: 8),
                SizedBox(height: UI.md),
                const SkeletonBox(height: 100, width: double.infinity, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final p = _post!;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Hero Image with Gradient Overlay
        if (p.cover.isNotEmpty)
          Stack(
            children: [
              Image.network(
                p.cover,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: Icon(Iconsax.image_copy,
                      size: 48, color: Colors.grey[400]),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

        // Content Container
        Container(
          color: UI.surfacePage(context),
          padding: EdgeInsets.all(UI.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: UI.md, vertical: UI.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(UI.rSm),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.category_2_copy,
                        size: 14, color: Colors.white),
                    SizedBox(width: UI.xs),
                    Text(
                      p.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: UI.lg),

              // Title
              Text(
                p.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
              ),
              SizedBox(height: UI.lg),

              // Author Card
              Container(
                padding: EdgeInsets.all(UI.md),
                decoration: BoxDecoration(
                  color: UI.surfaceCard(context),
                  borderRadius: BorderRadius.circular(UI.rMd),
                  boxShadow: UI.softShadow(context),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withOpacity(0.7)
                          ],
                        ),
                      ),
                      child: p.author.userPicture.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                p.author.userPicture,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Iconsax.user_copy,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            )
                          : const Icon(Iconsax.user_copy,
                              color: Colors.white, size: 24),
                    ),
                    SizedBox(width: UI.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.author.userName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: UI.lg),
                          Row(
                            children: [
                              Icon(Iconsax.clock_copy,
                                  size: 14, color: UI.subtleText(context)),
                              SizedBox(width: UI.lg),
                              Text(
                                p.createdTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: UI.subtleText(context),
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
              SizedBox(height: UI.xl),

              // Content
              HtmlTextWidget(
                htmlContent: p.textHtml,
                fontSize: 16,
                lineHeight: 1.8,
                maxLength: 50000,
              ),
              SizedBox(height: UI.xl),

              // Tags
              if (p.tags.isNotEmpty) ...[
                Divider(color: UI.subtleText(context).withOpacity(0.2)),
                SizedBox(height: UI.lg),
                Row(
                  children: [
                    Icon(Iconsax.hashtag_copy, size: 20, color: scheme.primary),
                    SizedBox(width: UI.sm),
                    Text(
                      'tags'.tr,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
                SizedBox(height: UI.md),
                Wrap(
                  spacing: UI.sm,
                  runSpacing: UI.sm,
                  children: p.tags.map((t) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: UI.md, vertical: UI.sm),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(UI.rSm),
                        border: Border.all(
                          color: scheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.hashtag_copy,
                              size: 14, color: scheme.primary),
                          SizedBox(width: UI.lg),
                          Text(
                            t,
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: UI.xl),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
