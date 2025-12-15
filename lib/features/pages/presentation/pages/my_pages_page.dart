import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/pages/application/pages_notifier.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_profile_page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_create_page.dart';
import 'package:snginepro/features/boost/domain/boost_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
class MyPagesPage extends StatefulWidget {
  const MyPagesPage({super.key});
  @override
  State<MyPagesPage> createState() => _MyPagesPageState();
}
class _MyPagesPageState extends State<MyPagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'My Pages'),
    Tab(text: 'Liked'),
    Tab(text: 'Suggested'),
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_onTabChanged);
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PagesNotifier>()
        ..setTab(PagesTab.myPages)
        ..loadMyPages();
    });
  }
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final notifier = context.read<PagesNotifier>();
    switch (_tabController.index) {
      case 0:
        notifier.setTab(PagesTab.myPages);
        break;
      case 1:
        notifier.setTab(PagesTab.likedPages);
        break;
      case 2:
        notifier.setTab(PagesTab.suggestedPages);
        break;
    }
    // Optional: refresh per-tab if empty
    if (notifier.currentPages.isEmpty && !notifier.isLoading) {
      notifier.refresh();
    }
  }
  Future<void> _handleRefresh() => context.read<PagesNotifier>().refresh();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                title: Text(
                  'Pages',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Iconsax.search_favorite),
                    tooltip: 'Search',
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        insets: const EdgeInsets.only(bottom: 6),
                      ),
                      tabs: _tabs,
                    ),
                  ),
                ),
              ),
              // Content per tab
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _PagesList(tab: PagesTab.myPages),
                    _PagesList(tab: PagesTab.likedPages),
                    _PagesList(tab: PagesTab.suggestedPages),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Get.to(() => const PageCreatePage());
            if (result != null && mounted) {
              // Refresh the pages list
              context.read<PagesNotifier>().refresh();
            }
          },
          child: const Icon(Iconsax.add),
        ),
      ),
    );
  }
}
class _PagesList extends StatelessWidget {
  const _PagesList({required this.tab});
  final PagesTab tab;
  Future<void> _refresh(BuildContext context) =>
      context.read<PagesNotifier>().refresh();
  @override
  Widget build(BuildContext context) {
    return Consumer<PagesNotifier>(
      builder: (context, notifier, _) {
        final isLoading = notifier.isLoading;
        final error = notifier.error;
        final pages = notifier.currentPages;
        if (isLoading && pages.isEmpty) {
          return const _ListLoader();
        }
        if (error != null && pages.isEmpty) {
          return _StateMessage(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: error,
            actionLabel: 'Retry',
            onAction: () => _refresh(context),
          );
        }
        if (pages.isEmpty) {
          return _StateMessage(
            icon: Icons.pages_outlined,
            title: _emptyTitle(tab),
            message: _emptySubtitle(tab),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: pages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PageCard(page: pages[index]),
        );
      },
    );
  }
  static String _emptyTitle(PagesTab tab) {
    switch (tab) {
      case PagesTab.myPages:
        return 'No pages yet';
      case PagesTab.likedPages:
        return 'No liked pages';
      case PagesTab.suggestedPages:
        return 'No suggestions';
    }
  }
  static String _emptySubtitle(PagesTab tab) {
    switch (tab) {
      case PagesTab.myPages:
        return 'Create or manage a page to see it here.';
      case PagesTab.likedPages:
        return 'Like a page and it will appear in this list.';
      case PagesTab.suggestedPages:
        return 'We’ll show recommended pages when available.';
    }
  }
}
class _ListLoader extends StatelessWidget {
  const _ListLoader();
  @override
  Widget build(BuildContext context) {
    // Simple skeletons without extra packages
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        height: 160,
      ),
    );
  }
}
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: onSurface.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
class _PageCard extends StatefulWidget {
  const _PageCard({required this.page});
  final PageModel page;
  @override
  State<_PageCard> createState() => _PageCardState();
}
class _PageCardState extends State<_PageCard> {
  late bool _isBoosted;
  bool _isBoostLoading = false;
  @override
  void initState() {
    super.initState();
    _isBoosted = widget.page.boosted;
  }
  Future<void> _handleBoost() async {
    if (_isBoostLoading) return;
    setState(() {
      _isBoostLoading = true;
    });
    try {
      final boostRepository = context.read<BoostRepository>();
      final result = _isBoosted
          ? await boostRepository.unboostPage(widget.page.id)
          : await boostRepository.boostPage(widget.page.id);
      if (result.success) {
        setState(() {
          _isBoosted = result.boosted ?? false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBoostLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover
          if (widget.page.cover.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 6,
                    child: Image.network(
                      mediaAsset(widget.page.cover).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  ),
                  // Top gradient
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Featured badge
                  if (_isBoosted)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Featured',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: widget.page.picture.isNotEmpty
                          ? CachedNetworkImageProvider(
                              mediaAsset(widget.page.picture).toString(),
                            )
                          : null,
                      child: widget.page.picture.isEmpty
                          ? const Icon(Icons.pages_rounded, size: 30)
                          : null,
                    ),
                    if (widget.page.verified)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Title & desc
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.page.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (widget.page.iAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.page.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.page.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.page.formattedLikes} likes',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
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
          const Divider(height: 1),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PageProfilePage(page: widget.page),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                if (!widget.page.iAdmin)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<PagesNotifier>().toggleLikePage(
                          widget.page,
                        );
                      },
                      icon: Icon(
                        widget.page.iLike
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        color: widget.page.iLike ? AppColors.primary : null,
                        size: 20,
                      ),
                      label: Text(
                        widget.page.iLike ? 'Liked' : 'Like',
                        style: TextStyle(
                          color: widget.page.iLike ? AppColors.primary : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: widget.page.iLike
                              ? AppColors.primary.withOpacity(0.4)
                              : Theme.of(context).dividerColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                // زر Boost (يظهر فقط للـ Admin)
                if (widget.page.iAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBoostLoading ? null : _handleBoost,
                      icon: _isBoostLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isBoosted ? Iconsax.star_1 : Iconsax.star,
                              color: _isBoosted
                                  ? const Color(0xFFFF8C00)
                                  : null,
                              size: 20,
                            ),
                      label: Text(
                        _isBoosted ? 'boosted'.tr : 'boost_page'.tr,
                        style: TextStyle(
                          color: _isBoosted ? const Color(0xFFFF8C00) : null,
                          fontWeight: _isBoosted
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isBoosted
                              ? const Color(0xFFFF8C00).withOpacity(0.4)
                              : Theme.of(context).dividerColor.withOpacity(0.6),
                        ),
                      ),
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
