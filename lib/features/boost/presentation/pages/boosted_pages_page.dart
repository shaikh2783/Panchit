import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/boost/domain/boost_repository.dart';
import 'package:snginepro/features/boost/presentation/widgets/boost_info_card.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_profile_page.dart';
class BoostedPagesPage extends StatefulWidget {
  const BoostedPagesPage({super.key});
  @override
  State<BoostedPagesPage> createState() => _BoostedPagesPageState();
}
class _BoostedPagesPageState extends State<BoostedPagesPage> {
  final ScrollController _scrollController = ScrollController();
  List<PageModel> _pages = [];
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
    _loadPages();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _pagination != null && _pagination!.hasMore) {
        _loadMore();
      }
    }
  }
  Future<void> _loadPages() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
      _pages.clear();
      _subscriptionRequired = false;
    });
    try {
      final boostRepository = context.read<BoostRepository>();
      final pagesRepository = context.read<PagesRepository>();
      final response = await boostRepository.getBoostedPages(
        offset: _offset,
        limit: _limit,
      );
      // جلب تفاصيل كل صفحة معززة
      final List<PageModel> fullPages = [];
      for (var pageData in response.pages) {
        try {
          final pageId = pageData['page_id'] is String 
              ? int.parse(pageData['page_id']) 
              : pageData['page_id'] as int;
          final pageDetails = await pagesRepository.fetchPageInfo(pageId: pageId);
          fullPages.add(pageDetails);
        } catch (e) {
        }
      }
      if (mounted) {
        setState(() {
          _pages = fullPages;
          _pagination = response.pagination;
          _boostInfo = response.boostInfo;
          _offset = _pages.length;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        final requiresSub = message.contains('SUBSCRIPTION_REQUIRED') ||
            message.contains('subscribe to a package');
        if (requiresSub) {
          setState(() => _subscriptionRequired = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requiresSub ? 'You need to subscribe to view boosted pages' : 'خطأ: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _loadMore() async {
    if (_isLoadingMore || !(_pagination?.hasMore ?? false)) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final boostRepository = context.read<BoostRepository>();
      final pagesRepository = context.read<PagesRepository>();
      final response = await boostRepository.getBoostedPages(
        offset: _offset,
        limit: _limit,
      );
      // جلب تفاصيل كل صفحة معززة
      final List<PageModel> newPages = [];
      for (var pageData in response.pages) {
        try {
          final pageId = pageData['page_id'] is String 
              ? int.parse(pageData['page_id']) 
              : pageData['page_id'] as int;
          final pageDetails = await pagesRepository.fetchPageInfo(pageId: pageId);
          newPages.add(pageDetails);
        } catch (e) {
        }
      }
      if (mounted) {
        setState(() {
          _pages.addAll(newPages);
          _pagination = response.pagination;
          _offset = _pages.length;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        final requiresSub = message.contains('SUBSCRIPTION_REQUIRED') ||
            message.contains('subscribe to a package');
        if (requiresSub) {
          setState(() => _subscriptionRequired = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requiresSub ? 'You need to subscribe to view boosted pages' : 'خطأ: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
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
        title: Text('my_boosted_pages'.tr),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadPages,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPages,
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
                          'You need to subscribe to view boosted pages',
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
            : _pages.isEmpty
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
                          'no_boosted_pages'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _pages.length + 2, // +2 for info card and loading
                    itemBuilder: (context, index) {
                      // Boost info card at top
                      if (index == 0 && _boostInfo != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BoostInfoCard(
                            boostedCount: _boostInfo!.boostedCount,
                            remainingBoosts: _boostInfo!.remainingBoosts,
                            boostLimit: _boostInfo!.boostLimit,
                            canBoostMore: _boostInfo!.canBoostMore,
                          ),
                        );
                      }
                      // Loading indicator at bottom
                      if (index == _pages.length + 1) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      // Page cards
                      final page = _pages[index - 1];
                      return _PageCard(
                        page: page,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PageProfilePage(page: page),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
class _PageCard extends StatelessWidget {
  final PageModel page;
  final VoidCallback onTap;
  const _PageCard({
    required this.page,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF8C00).withOpacity(0.1),
            const Color(0xFFFF6B00).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8C00).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BOOSTED Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.star_1, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'BOOSTED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Picture
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: page.picture.isNotEmpty
                        ? Image.network(
                            mediaAsset(page.picture).toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.pages),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.pages),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Page Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with verified badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              page.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (page.verified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Iconsax.verify,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Username
                      Text(
                        '@${page.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description preview
                      if (page.description.isNotEmpty)
                        Text(
                          page.description,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Iconsax.like_1,
                  label: 'likes'.tr,
                  value: page.formattedLikes,
                  color: Colors.blue,
                ),
                if (page.iAdmin)
                  _StatItem(
                    icon: Iconsax.shield_tick,
                    label: 'admin'.tr,
                    value: '',
                    color: Colors.orange,
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      // For admin badge - just show icon and label
      return Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }
}
