import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 Modern Onboarding Page - Professional Design
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _backgroundController;
  late AnimationController _contentController;

  // Onboarding data
  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.people_alt_rounded,
      titleKey: 'onboarding_connect_title',
      descriptionKey: 'onboarding_connect_desc',
      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
    ),
    OnboardingItem(
      icon: Icons.share_rounded,
      titleKey: 'onboarding_share_title',
      descriptionKey: 'onboarding_share_desc',
      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    OnboardingItem(
      icon: Icons.explore_rounded,
      titleKey: 'onboarding_discover_title',
      descriptionKey: 'onboarding_discover_desc',
      gradient: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    ),
    OnboardingItem(
      icon: Icons.security_rounded,
      titleKey: 'onboarding_secure_title',
      descriptionKey: 'onboarding_secure_desc',
      gradient: const [Color(0xFF5B86E5), Color(0xFF36D1DC)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Save that onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentItem = _items[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Animated Gradient Background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        currentItem.gradient[0],
                        currentItem.gradient[1],
                        (_backgroundController.value * 0.5),
                      )!,
                      Color.lerp(
                        currentItem.gradient[1],
                        currentItem.gradient[0],
                        (_backgroundController.value * 0.5),
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // ✨ Floating Particles
          ...List.generate(12, (index) {
            return AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final offset =
                    (_backgroundController.value + index * 0.083) % 1;
                final x = size.width * ((index * 0.083) % 1);
                final y = size.height * offset;
                final scale = 0.3 + math.sin(offset * math.pi * 2) * 0.2;

                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 0.2,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 4 + (index % 3) * 2,
                        height: 4 + (index % 3) * 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // 📄 Content
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'skip'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _contentController.reset();
                      _contentController.forward();
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_items[index]);
                    },
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_items.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Next / Get Started Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: currentItem.gradient[0],
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _items.length - 1
                                    ? 'onboarding_get_started'.tr
                                    : 'onboarding_next'.tr,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _items.length - 1
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Curves.easeOutCubic,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                item.titleKey.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                item.descriptionKey.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final List<Color> gradient;

  OnboardingItem({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.gradient,
  });
}
