import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
// Bloc Pages
import 'package:snginepro/features/feed/presentation/pages/home_page.dart';
// Traditional Provider Pages (for gradual migration)
import 'package:snginepro/features/feed/presentation/pages/reels_page.dart';
import 'package:snginepro/features/feed/presentation/pages/menu_page.dart';
import 'package:snginepro/features/friends/presentation/pages/friend_requests_page.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/notifications/presentation/pages/notifications_page.dart';
import 'package:snginepro/features/discover/presentation/pages/discover_page.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Initialize badge animation
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

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
    } catch (e) {
    }
  }

  // 🔄 Migration: Using Bloc pages for specific features while keeping Provider for others
  List<Widget> get _pages => [
    const HomePage(), // ✅ Bloc Migration: Feed page using Bloc pattern
    const FriendRequestsPage(), // Provider (to be migrated later)
    const DiscoverPage(), // New discover page
    const ReelsPage(), // Provider (to be migrated later)
    const NotificationsPage(), // ✅ Bloc Migration: Notifications page using Bloc pattern
    MenuPage(onNavigateToTab: (index) => setState(() => _currentIndex = index)), // Pass callback to MenuPage
  ];

  // --- 💡 2. تحديث الأيقونات لاستخدام Iconsax ---
  static const List<_NavItem> _items = [
    _NavItem(icon: Iconsax.home, activeIcon: Iconsax.home),
    _NavItem(icon: Iconsax.people, activeIcon: Iconsax.profile_2user),
    _NavItem(icon: Iconsax.search_normal, activeIcon: Iconsax.search_favorite),
    _NavItem(icon: Iconsax.video_play, activeIcon: Iconsax.video),
    _NavItem(icon: Iconsax.notification, activeIcon: Iconsax.notification_1),
    _NavItem(icon: Iconsax.menu, activeIcon: Iconsax.menu_1),
  ];
  // --- نهاية التحديث ---

  @override
  Widget build(BuildContext context) {
    final isDarkDestination = _currentIndex == 3; // Reels page (updated index)
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkDestination
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.brightness == Brightness.dark 
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex, 
            children: _pages
          ),
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          items: _items,
          friendRequestsCount: _friendRequestsCount,
          onItemSelected: (index) {
            if (index == _currentIndex) {
              // Add haptic feedback for same tab tap
              HapticFeedback.selectionClick();
              return;
            }
            
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);

            // إعادة تحديث العدادات عند التبديل إلى صفحة الأصدقاء
            if (index == 1) {
              _loadFriendRequestsCount();
            }
          },
        ),
      ),
    );
  }
}

// ... (_BottomNavBar و _NavItem كما هي) ...
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onItemSelected,
    this.friendRequestsCount = 0,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onItemSelected;
  final int friendRequestsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: LayoutTokens.navBarHeight + MediaQuery.of(context).padding.bottom + 8,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            top: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [
                    const Color(0xFF1A1A1A).withOpacity(0.95),
                    const Color(0xFF0A0A0A).withOpacity(0.98),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    const Color(0xFFF8F9FA).withOpacity(0.98),
                  ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: isDark 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  badgeCount: index == 1 ? friendRequestsCount : 0,
                  onTap: () => onItemSelected(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 💡 3. إعادة تصميم الزر بالكامل (احترافي) ---
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0.08),
                    ],
                  )
                : null,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
              boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive
                          ? theme.colorScheme.primary
                          : isDark 
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
                // Enhanced Badge Design
                if (badgeCount > 0)
                  Positioned(
                    right: 8,
                    top: 4,
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: ModalRoute.of(context)?.animation ?? 
                               const AlwaysStoppedAnimation(1.0),
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4757), Color(0xFFFF3742)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                              ? const Color(0xFF1A1A1A) 
                              : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4757).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- نهاية التحديث ---

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon});

  final IconData icon;
  final IconData activeIcon;
}
