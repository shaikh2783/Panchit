import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/app_colors.dart';
// Bloc Pages
import 'package:snginepro/features/feed/presentation/pages/home_page.dart';
// Traditional Provider Pages (for gradual migration)
import 'package:snginepro/features/feed/presentation/pages/reels_page.dart';
import 'package:snginepro/features/feed/presentation/pages/menu_page.dart';
import 'package:snginepro/features/friends/presentation/pages/friend_requests_page.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/notifications/presentation/pages/notifications_page.dart';
import 'package:snginepro/features/competitions/presentation/pages/competitions_hub_page.dart';

// ... (صفحة FriendsPage كما هي) ...
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Friends Page')));
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final FriendsApiService _friendsService;
  int _friendRequestsCount = 0;
  late AnimationController _badgeAnimationController;
  bool _showNavBar = true;
  DateTime? _lastBackPress;
  static const double _navBarHeight = 75;
  static const double _navBarBottomMargin = 8;
  // Global Keys للوصول إلى ScrollControllers
  late final GlobalKey<HomePageState> _homePageKey;

  @override
  void initState() {
    super.initState();

    // Initialize Global Keys
    _homePageKey = GlobalKey<HomePageState>();

    // Initialize badge animation
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Build pages once — IndexedStack keeps all alive, preventing repeated initState
    // and the redundant API calls those would trigger.
    _pages = [
      HomePage(
        key: _homePageKey,
        onScrollDirectionChanged: (isScrollingDown) {
          if (_currentIndex != 0) return;
          final shouldShow = !isScrollingDown;
          if (shouldShow != _showNavBar) {
            setState(() => _showNavBar = shouldShow);
          }
        },
      ),
      const FriendRequestsPage(),
      const CompetitionsHubPage(),
      const ReelsPage(),
      const NotificationsPage(),
      MenuPage(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFriendsService();
      _startPeriodicUpdate();
    });
  }

  @override
  void dispose() {
    _badgeAnimationController.dispose();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadFriendRequestsCount();
      } else {
        timer.cancel();
      }
    });
  }

  void _initializeFriendsService() {
    final apiClient = context.read<ApiClient>();
    _friendsService = FriendsApiService(apiClient);
    _loadFriendRequestsCount();
  }

  Future<void> _loadFriendRequestsCount() async {
    try {
      final requests = await _friendsService.getFriendRequests();
      if (mounted) {
        setState(() {
          final oldCount = _friendRequestsCount;
          _friendRequestsCount = requests.length;

          // Animate badge when count changes
          if (_friendRequestsCount != oldCount) {
            _badgeAnimationController.reset();
            _badgeAnimationController.forward();
          }

          // Add haptic feedback for new friend requests
          if (_friendRequestsCount > oldCount && oldCount > 0) {
            HapticFeedback.mediumImpact();
          }
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  // 🔄 Migration: Using Bloc pages for specific features while keeping Provider for others
  // Field (not getter) so page widgets are created once and kept alive by IndexedStack.
  late final List<Widget> _pages;

  final List<_NavItem> _items = const [
    _NavItem(icon: Iconsax.message, activeIcon: Iconsax.message, label: 'Home'),
    _NavItem(
      icon: Iconsax.profile_2user,
      activeIcon: Iconsax.profile_2user,
      label: 'Friends',
    ),
    _NavItem(icon: Iconsax.cup, activeIcon: Iconsax.cup, label: 'Competition'),
    _NavItem(
      icon: Iconsax.video_play,
      activeIcon: Iconsax.video_play,
      label: 'Reels',
    ),
    _NavItem(
      icon: Icons.notifications_none,
      activeIcon: Icons.notifications,
      label: 'Notifications',
    ),
    _NavItem(icon: Icons.menu, activeIcon: Icons.menu, label: 'Menu'),
  ];
  // --- نهاية التحديث ---

  @override
  Widget build(BuildContext context) {
    final isDarkDestination = _currentIndex == 3; // Reels page (updated index)
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // Not on home tab → go home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _showNavBar = true;
          });
          return;
        }

        // On home tab → double-back to exit
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDarkDestination
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          extendBody: true,
          backgroundColor: theme.brightness == Brightness.dark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.02),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(
                bottom: _currentIndex == 3 || !_showNavBar
                    ? 0
                    : _navBarHeight +
                          _navBarBottomMargin +
                          MediaQuery.of(context).padding.bottom,
              ),
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),
          bottomNavigationBar: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            offset: Offset(0, _showNavBar ? 0 : 1),
            child: _BottomNavBar(
              currentIndex: _currentIndex,
              items: _items,
              friendRequestsCount: _friendRequestsCount,
              navBarHeight: _navBarHeight,
              bottomMargin: _navBarBottomMargin,
              onItemSelected: (index) {
                if (index == _currentIndex) {
                  HapticFeedback.selectionClick();

                  if (index == 0) {
                    _homePageKey.currentState?.scrollToTop();
                    if (!_showNavBar) setState(() => _showNavBar = true);
                  }
                  return;
                }

                HapticFeedback.lightImpact();
                setState(() {
                  _currentIndex = index;
                  if (!_showNavBar) _showNavBar = true;
                });

                if (index == 1) {
                  _loadFriendRequestsCount();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onItemSelected,
    required this.navBarHeight,
    required this.bottomMargin,
    this.friendRequestsCount = 0,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onItemSelected;
  final int friendRequestsCount;
  final double navBarHeight;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? AppColors.surfaceDark : Colors.white;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
        child: Container(
          height: navBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: navBarColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return Flexible(
                flex: isActive ? 2 : 1,
                child: _NavButton(
                  item: item,
                  isActive: isActive,
                  badgeCount: index == 1 ? friendRequestsCount : 0,
                  navBarColor: navBarColor,
                  onTap: () => onItemSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.navBarColor,
    this.badgeCount = 0,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color navBarColor;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white : AppColors.textSecondaryLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 12 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: isActive
                  ? Center(
                      key: const ValueKey('active'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.activeIcon,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      key: const ValueKey('inactive'),
                      child: Icon(item.icon, color: inactiveColor, size: 22),
                    ),
            ),
          ),

          if (badgeCount > 0)
            Positioned(
              top: 2,
              right: isActive ? 12 : 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: navBarColor, width: 2),
                ),
                child: Text(
                  badgeCount > 999 ? '999+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
