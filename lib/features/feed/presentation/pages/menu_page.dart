import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/App_Settings.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/widgets/GradineCard.dart';
import 'package:snginepro/core/theme/widgets/theme_toggle_button.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/pages/presentation/pages/my_pages_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/feed/presentation/pages/settings_page.dart';
import 'package:snginepro/features/groups/presentation/pages/groups_list_page.dart';
import 'package:snginepro/features/events/presentation/pages/events_main_page.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/jobs/presentation/pages/jobs_list_page.dart';
import 'package:snginepro/features/funding/presentation/pages/funding_list_page.dart';
import 'package:snginepro/features/market/presentation/pages/products_page.dart';
import 'package:snginepro/features/blog/presentation/pages/my_blogs_page.dart';
import 'package:snginepro/features/offers/presentation/pages/offers_list_page.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_page.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_packages_page.dart';
import 'package:snginepro/features/boost/presentation/pages/boosted_posts_page.dart';
import 'package:snginepro/features/boost/presentation/pages/boosted_pages_page.dart';
import 'package:snginepro/features/courses/presentation/pages/my_courses_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
class MenuPage extends StatefulWidget {
  const MenuPage({super.key, this.onNavigateToTab});
  final ValueChanged<int>? onNavigateToTab;
  @override
  State<MenuPage> createState() => _MenuPageState();
}
class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isFeedExpanded = true;
  bool _isMineExpanded = false;
  bool _isAdvertisingExpanded = false;
  bool _isExploreExpanded = false;
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  void _hapticTap() => HapticFeedback.lightImpact();
  void _toggleSection(String section) {
    setState(() {
      switch (section) {
        case 'feed':
          _isFeedExpanded = !_isFeedExpanded;
          break;
        case 'mine':
          _isMineExpanded = !_isMineExpanded;
          break;
        case 'advertising':
          _isAdvertisingExpanded = !_isAdvertisingExpanded;
          break;
        case 'explore':
          _isExploreExpanded = !_isExploreExpanded;
          break;
      }
    });
    _hapticTap();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBg = theme.textTheme.bodyLarge?.color;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Text(
          'menu'.tr, // 'القائمة'
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: onBg,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'settings'.tr, // 'الإعدادات'
            icon: const Icon(Iconsax.settings),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            // --------- HERO PROFILE + SEARCH ----------
            AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 420),
              child: SlideAnimation(
                verticalOffset: 36,
                child: FadeInAnimation(
                  child: Column(
                    children: [
                      const _UserProfileCard(),
                      const SizedBox(height: 16),
                      _GlassySearch(controller: _searchCtrl),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleSection('feed'),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Iconsax.home,
                      size: 20,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(width: 8),
                     Text(
                      'feed'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isFeedExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF1E88E5),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Feed Section Content
            if (_isFeedExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Get.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Get.isDarkMode
                      ? Border.all(color: const Color(0xFF333333), width: 0.5)
                      : null,
                ),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    if (AppSettings.enableNewsFeed)
                      _FeedItem(
                        icon: Iconsax.home,
                        label: 'news_feed'.tr,
                        gradient: const [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                        onTap: () {
                          _hapticTap();
                          // Navigate to HomePage (index 0 in main navigation)
                          if (widget.onNavigateToTab != null) {
                            widget.onNavigateToTab!(0); // Switch to Home tab
                          } else {
                            Navigator.pop(context); // Fallback
                          }
                        },
                      ),
                    if (AppSettings.enableRecentUpdates)
                      _FeedItem(
                        icon: Iconsax.refresh,
                        label: 'recent_updates'.tr,
                        gradient: const [Color(0xFF81C784), Color(0xFF43A047)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('recent_updates_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enablePopularPosts)
                      _FeedItem(
                        icon: Iconsax.trend_up,
                        label: 'popular_posts'.tr,
                        gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('popular_posts_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableDiscoverPosts)
                      _FeedItem(
                        icon: Iconsax.discover,
                        label: 'discover_posts'.tr,
                        gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('discover_posts_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ================== MINE SECTION ==================
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleSection('mine'),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Iconsax.profile_circle,
                      size: 20,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(width: 8),
                     Text(
                      'mine'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '9',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF42A5F5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isMineExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF42A5F5),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Mine Section Content
            if (_isMineExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Get.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Get.isDarkMode
                      ? Border.all(color: const Color(0xFF333333), width: 0.5)
                      : null,
                ),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    if (AppSettings.enableMyBlogs)
                      _FeedItem(
                        icon: Iconsax.document_text,
                        label: 'my_blogs'.tr,
                        gradient: const [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBlogsPage(),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMyProducts)
                      _FeedItem(
                        icon: Iconsax.shopping_bag,
                        label: 'my_products'.tr,
                        gradient: const [Color(0xFFE1BEE7), Color(0xFF8E24AA)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('my_products_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMyFunding)
                      _FeedItem(
                        icon: Iconsax.money_send,
                        label: 'my_funding'.tr,
                        gradient: const [Color(0xFFFFC1CC), Color(0xFFE91E63)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const FundingListPage(mineOnly: true),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMyOffers)
                      _FeedItem(
                        icon: Iconsax.tag,
                        label: 'my_offers'.tr,
                        gradient: const [Color(0xFFFF8A65), Color(0xFFEF6C00)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OffersListPage(mineOnly: true),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMyJobs)
                      _FeedItem(
                        icon: Iconsax.briefcase,
                        label: 'my_jobs'.tr,
                        gradient: const [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const JobsListPage(mineOnly: true),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMyCourses)
                      _FeedItem(
                        icon: Iconsax.book,
                        label: 'my_courses'.tr,
                        gradient: const [Color(0xFF80CBC4), Color(0xFF00695C)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyCoursesPage(),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableSaved)
                      _FeedItem(
                        icon: Iconsax.bookmark,
                        label: 'saved'.tr,
                        gradient: const [Color(0xFFE57373), Color(0xFFC62828)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('saved_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableScheduled)
                      _FeedItem(
                        icon: Iconsax.timer_1,
                        label: 'scheduled'.tr,
                        gradient: const [Color(0xFFB0BEC5), Color(0xFF607D8B)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('scheduled_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableMemories)
                      _FeedItem(
                        icon: Iconsax.archive,
                        label: 'memories'.tr,
                        gradient: const [Color(0xFFCE93D8), Color(0xFF6A1B9A)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('memories_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ================== ADVERTISING SECTION ==================
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleSection('advertising'),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Iconsax.flash,
                      size: 20,
                      color: Color(0xFFF57F17),
                    ),
                    const SizedBox(width: 8),
                     Text(
                      'advertising'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF57F17),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF57F17).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isAdvertisingExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFF57F17),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Advertising Section Content
            if (_isAdvertisingExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Get.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Get.isDarkMode
                      ? Border.all(color: const Color(0xFF333333), width: 0.5)
                      : null,
                ),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    if (AppSettings.enableWallet)
                      _FeedItem(
                        icon: Iconsax.wallet_3,
                        label: 'wallet'.tr,
                        gradient: const [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletPage(),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableAdsCampaigns)
                      _FeedItem(
                        icon: Iconsax.chart,
                        label: 'ads_campaigns_title'.tr,
                        gradient: const [Color(0xFFFFD54F), Color(0xFFF57F17)],
                        onTap: () {
                          _hapticTap();
                          Get.toNamed('/ads/campaigns');
                        },
                      ),
                    if (AppSettings.enablePremiumPackages)
                      _FeedItem(
                        icon: Iconsax.crown,
                        label: 'premium_packages'.tr,
                        gradient: const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                        onTap: () {
                          _hapticTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletPackagesPage(),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableBoosted)
                      _FeedItem(
                        icon: Iconsax.flash,
                        label: 'boosted'.tr,
                        gradient: const [Color(0xFFFFD54F), Color(0xFFF57F17)],
                        onTap: () {
                          _hapticTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text('boosted_coming_soon'.tr),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableBoostedPosts)
                      _FeedItem(
                        icon: Iconsax.note,
                        label: 'boosted_posts'.tr,
                        gradient: const [Color(0xFFAED581), Color(0xFF8BC34A)],
                        onTap: () {
                          _hapticTap();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BoostedPostsPage(),
                            ),
                          );
                        },
                      ),
                    if (AppSettings.enableBoostedPages)
                      _FeedItem(
                        icon: Iconsax.document,
                        label: 'boosted_pages'.tr,
                        gradient: const [Color(0xFFBA68C8), Color(0xFF8E24AA)],
                        onTap: () {
                          _hapticTap();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BoostedPagesPage(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ================== EXPLORE SECTION ==================
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleSection('explore'),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4DB6AC), Color(0xFF009688)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Iconsax.discover_1,
                      size: 20,
                      color: Color(0xFF009688),
                    ),
                    const SizedBox(width: 8),
                     Text(
                      'explore'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009688),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '17',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009688),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExploreExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF009688),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Explore Section Content
            if (_isExploreExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Get.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Get.isDarkMode
                      ? Border.all(color: const Color(0xFF333333), width: 0.5)
                      : null,
                ),
                child: Column(
                  children: [
                    // First Row - Main Categories
                    Row(
                      children: [
                        if (AppSettings.enablePeople)
                          Expanded(
                            child: _FeedItem(
                              icon: Iconsax.people,
                              label: 'people'.tr,
                              gradient: const [
                                Color(0xFF4DB6AC),
                                Color(0xFF009688),
                              ],
                              onTap: () {
                                _hapticTap();
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                    content: Text('people_coming_soon'.tr),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (AppSettings.enablePeople &&
                            (AppSettings.enablePages ||
                                AppSettings.enableGroups))
                          const SizedBox(width: 12),
                        if (AppSettings.enablePages)
                          Expanded(
                            child: _FeedItem(
                              icon: Iconsax.document,
                              label: 'pages'.tr,
                              gradient: const [
                                Color(0xFF9FA8DA),
                                Color(0xFF3949AB),
                              ],
                              onTap: () {
                                _hapticTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyPagesPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (AppSettings.enablePages &&
                            AppSettings.enableGroups)
                          const SizedBox(width: 12),
                        if (AppSettings.enableGroups)
                          Expanded(
                            child: _FeedItem(
                              icon: Iconsax.layer,
                              label: 'groups'.tr,
                              gradient: const [
                                Color(0xFF26C6DA),
                                Color(0xFF00ACC1),
                              ],
                              onTap: () {
                                _hapticTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GroupsListPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Grid for the rest
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.9,
                      children: [
                        if (AppSettings.enableEvents)
                          _FeedItem(
                            icon: Iconsax.calendar_1,
                            label: 'events'.tr,
                            gradient: const [
                              Color(0xFFF48FB1),
                              Color(0xFFD81B60),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EventsMainPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableMarket)
                          _FeedItem(
                            icon: Iconsax.shopping_cart,
                            label: 'market_title'.tr,
                            gradient: const [
                              Color(0xFF66BB6A),
                              Color(0xFF388E3C),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductsPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableReels)
                          _FeedItem(
                            icon: Iconsax.video_play,
                            label: 'reels'.tr,
                            gradient: const [
                              Color(0xFFFF8A65),
                              Color(0xFFD84315),
                            ],
                            onTap: () {
                              _hapticTap();
                              // Navigate to ReelsPage (index 3 in main navigation)
                              if (widget.onNavigateToTab != null) {
                                widget.onNavigateToTab!(
                                  3,
                                ); // Switch to Reels tab
                              } else {
                                Navigator.pop(context); // Fallback
                              }
                            },
                          ),
                        if (AppSettings.enableWatch)
                          _FeedItem(
                            icon: Iconsax.play,
                            label: 'watch'.tr,
                            gradient: const [
                              Color(0xFF64B5F6),
                              Color(0xFF1976D2),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('watch_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableBlogs)
                          _FeedItem(
                            icon: Iconsax.document_text,
                            label: 'my_blogs'.tr,
                            gradient: const [
                              Color(0xFFBA68C8),
                              Color(0xFF8E24AA),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyBlogsPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableFunding)
                          _FeedItem(
                            icon: Iconsax.money_send,
                            label: 'funding'.tr,
                            gradient: const [
                              Color(0xFFFFC1CC),
                              Color(0xFFE91E63),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FundingListPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableOffers)
                          _FeedItem(
                            icon: Iconsax.tag,
                            label: 'offers'.tr,
                            gradient: const [
                              Color(0xFFFFB74D),
                              Color(0xFFF57C00),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OffersListPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableJobs)
                          _FeedItem(
                            icon: Iconsax.briefcase,
                            label: 'jobs'.tr,
                            gradient: const [
                              Color(0xFFA5D6A7),
                              Color(0xFF2E7D32),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JobsListPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableCourses)
                          _FeedItem(
                            icon: Iconsax.book,
                            label: 'courses'.tr,
                            gradient: const [
                              Color(0xFF80CBC4),
                              Color(0xFF00695C),
                            ],
                            onTap: () {
                              _hapticTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyCoursesPage(),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableForums)
                          _FeedItem(
                            icon: Iconsax.message_question,
                            label: 'forums'.tr,
                            gradient: const [
                              Color(0xFF90CAF9),
                              Color(0xFF1E88E5),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('forums_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableMovies)
                          _FeedItem(
                            icon: Iconsax.video_square,
                            label: 'movies'.tr,
                            gradient: const [
                              Color(0xFFB39DDB),
                              Color(0xFF5E35B1),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('movies_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableGames)
                          _FeedItem(
                            icon: Iconsax.game,
                            label: 'games'.tr,
                            gradient: const [
                              Color(0xFFAED581),
                              Color(0xFF689F38),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('games_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableDevelopers)
                          _FeedItem(
                            icon: Iconsax.code,
                            label: 'developers'.tr,
                            gradient: const [
                              Color(0xFF424242),
                              Color(0xFF212121),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('developers_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                        if (AppSettings.enableMerits)
                          _FeedItem(
                            icon: Iconsax.medal_star,
                            label: 'merits'.tr,
                            gradient: const [
                              Color(0xFFFFD700),
                              Color(0xFFFF8F00),
                            ],
                            onTap: () {
                              _hapticTap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: Text('merits_coming_soon'.tr),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // --------- LOGOUT ----------
            AnimationConfiguration.staggeredList(
              position: 50,
              duration: const Duration(milliseconds: 420),
              child: SlideAnimation(
                verticalOffset: 36,
                child: FadeInAnimation(child: const _LogoutButton()),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
// ----------------------------------------------------------
//                          PARTS
// ----------------------------------------------------------
class _GlassySearch extends StatelessWidget {
  const _GlassySearch({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0x22FFFFFF), const Color(0x11000000)]
              : [const Color(0x11FFFFFF), const Color(0x08000000)],
        ),
        border: Border.all(
          color: (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
      ),
      child:  TextField(
        decoration: InputDecoration(
          hintText: '${'Search'.tr}…', // 'بحث…'
          prefixIcon: Icon(Iconsax.search_normal),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
        ),
      ),
    );
  }
}
// --------- HORIZONTAL CAROUSEL ---------
class _ExploreCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _ExploreCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
class _ExploreCarousel extends StatefulWidget {
  const _ExploreCarousel({required this.items});
  final List<_ExploreCardData> items;
  @override
  State<_ExploreCarousel> createState() => _ExploreCarouselState();
}
class _ExploreCarouselState extends State<_ExploreCarousel> {
  late final PageController _controller;
  double _page = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.86);
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          // Gentle edge fade // 'تظليل حواف لطيف'
          Positioned.fill(
            child: IgnorePointer(
              child: Row(
                children: [
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0, .12],
                      ).createShader(r),
                      blendMode: BlendMode.dstIn,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0, .12],
                      ).createShader(r),
                      blendMode: BlendMode.dstIn,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PageView.builder(
            controller: _controller,
            itemCount: items.length,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, i) {
              final t = (_page - i).abs().clamp(0.0, 1.0);
              final scale =
                  1 -
                  (t *
                      0.08); // Scale up for the central card // 'تكبير للبطاقة المركزية'
              final translateY =
                  6 *
                  t; // Slight vertical shift for edges // 'نزول خفيف للأطراف'
              final d = items[i];
              return Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: _ExplorePill(
                    icon: d.icon,
                    label: d.title,
                    gradient: d.gradient,
                    subtitle: d.subtitle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class _ExplorePill extends StatelessWidget {
  const _ExplorePill({
    required this.icon,
    required this.label,
    required this.gradient,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return GradientCard(
      borderRadius: Radii.xLarge,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradientColors: gradient,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}
// --------- LOGOUT BUTTON ---------
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      borderRadius: BorderRadius.circular(Radii.large),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Radii.large),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child:  Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.logout, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'sign_out'.tr, // 'تسجيل الخروج'
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text('sign_out'.tr), // 'تسجيل الخروج'
        content:  Text(
          'sign_out_confirm'.tr,
        ), // 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('cancel'.tr), // 'إلغاء'
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:  Text('sign_out'.tr), // 'تسجيل الخروج'
          ),
        ],
      ),
    );
  }
  void _performLogout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.signOut();
      if (context.mounted) Navigator.pop(context); // close loader
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('sign_out_success'.tr), // 'تم تسجيل الخروج بنجاح'
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ), // 'خطأ: $e'
        );
      }
    }
  }
}
// --------- ANIM WRAPPER ---------
// --------- PROFILE HERO ---------
class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.currentUser;
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    final avatarUrl = user?['user_picture'];
    final name = user?['user_fullname'] ?? user?['user_name'] ?? 'Your Profile';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final userId = user?['user_id'];
        final username = user?['user_name'];
        if (username != null && username.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(username: username),
            ),
          );
        } else if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfilePage(userId: int.tryParse(userId.toString())),
            ),
          );
        }
      },
      child: GradientCard(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.zero,
        borderRadius: Radii.xLarge,
        gradientColors: const [
          Color(0xFF7B4397), // purple
          Color(0xFF1D976C), // teal
        ],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.xl,
                Spacing.lg,
                Spacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(mediaAsset(avatarUrl).toString())
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Iconsax.user, size: 26)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'view_profile'.tr, // 'عرض ملفك الشخصي'
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white30, height: 1, thickness: 1),
             Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    count: '97.8k',
                    label: 'points'.tr,
                    color: Color(0xFFE040FB),
                  ), // 'النقاط'
                  _StatItem(
                    count: '172',
                    label: 'followers'.tr,
                    color: Color(0xFF29B6F6),
                  ), // 'المتابعون'
                  _StatItem(
                    count: '0',
                    label: 'following'.tr,
                    color: Color(0xFFFFA726),
                  ), // 'متابع'
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
  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
  });
  final String count;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Iconsax.coin, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
        ),
      ],
    );
  }
}
// --------- SMALL CARD (USED FOR GRID & FEED ITEMS) ---------
class _ShortcutCard extends StatefulWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.gradientColors,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  @override
  State<_ShortcutCard> createState() => _ShortcutCardState();
}
class _ShortcutCardState extends State<_ShortcutCard> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GradientCard(
        borderRadius: Radii.large,
        padding: EdgeInsets.zero,
        gradientColors: widget.gradientColors,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.large),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.large),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: Spacing.sm),
                  Icon(widget.icon, size: 30, color: Colors.white),
                  const SizedBox(height: Spacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    child: Text(
                      widget.label.tr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Unified grid item for new elements // 'عنصر شبكة موحّد للعناصر الجديدة'
class _FeedItem extends StatelessWidget {
  const _FeedItem({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return _ShortcutCard(
      icon: icon,
      label: label,
      gradientColors: gradient,
      onTap: onTap,
    );
  }
}
