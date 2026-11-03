import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/theme/panchit_auth_ui.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  late AnimationController _contentController;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      type: OnboardingType.connect,
      titleKey: 'onboarding_connect_title',
      fallbackTitle: 'Connect',
      descriptionKey: 'onboarding_connect_desc',
      fallbackDescription:
      'Meet new people and\nbuild real connections.',
      accentColor: PanchitAuthColors.purple,
    ),
    OnboardingItem(
      type: OnboardingType.share,
      titleKey: 'onboarding_share_title',
      fallbackTitle: 'Share',
      descriptionKey: 'onboarding_share_desc',
      fallbackDescription:
      'Share your moments,\nphotos, videos and stories.',
      accentColor: PanchitAuthColors.pink,
    ),
    OnboardingItem(
      type: OnboardingType.belong,
      titleKey: 'onboarding_belong_title',
      fallbackTitle: 'Belong',
      descriptionKey: 'onboarding_belong_desc',
      fallbackDescription:
      'Find your community\nand belong together.',
      accentColor: PanchitAuthColors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    _completeOnboarding();
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'onboarding_completed',
      true,
    );

    if (!mounted) return;

    widget.onComplete();
  }

  String _translate({
    required String key,
    required String fallback,
  }) {
    final translated = key.tr;

    // GetX normally returns the key itself if translation doesn't exist.
    return translated == key ? fallback : translated;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: PanchitAuthColors.background(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(isDark),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPage(
                    item: _items[index],
                    isDark: isDark,
                  );
                },
              ),
            ),

            _buildBottomSection(isDark),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    _contentController
      ..reset()
      ..forward();
  }

  Widget _buildTopSection(bool isDark) {
    return SizedBox(
      height: 52,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            end: 16,
          ),
          child: TextButton(
            onPressed: _skipOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: PanchitAuthColors.textMuted(isDark),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Text(
              _translate(
                key: 'skip',
                fallback: 'Skip',
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required OnboardingItem item,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight < 520;

        final illustrationSize = constraints.maxWidth < 360
            ? 175.0
            : isSmallHeight
            ? 180.0
            : 210.0;

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOut,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _contentController,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  _OnboardingIllustration(
                    type: item.type,
                    accentColor: item.accentColor,
                    size: illustrationSize,
                    isDark: isDark,
                  ),

                  SizedBox(
                    height: isSmallHeight ? 24 : 38,
                  ),

                  Text(
                    _translate(
                      key: item.titleKey,
                      fallback: item.fallbackTitle,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: item.accentColor,
                      fontSize: isSmallHeight ? 22 : 25,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _translate(
                      key: item.descriptionKey,
                      fallback: item.fallbackDescription,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PanchitAuthColors.textSecondary(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(bool isDark) {
    final item = _items[_currentPage];
    final isLastPage = _currentPage == _items.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicators(
            activeColor: item.accentColor,
            isDark: isDark,
          ),

          const SizedBox(height: 34),

          _buildNextButton(
            isLastPage: isLastPage,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators({
    required Color activeColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _items.length,
            (index) {
          final isActive = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : isDark
                  ? const Color(0xFF4A4C5C)
                  : const Color(0xFFD8D6DF),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton({
    required bool isLastPage,
  }) {
    return PanchitPrimaryButton(
      label: _translate(
        key: isLastPage
            ? 'onboarding_get_started'
            : 'onboarding_next',
        fallback: isLastPage ? 'Get Started' : 'Next',
      ),
      onPressed: _nextPage,
      trailingIcon:
          isLastPage ? null : Icons.arrow_forward_rounded,
    );
  }
}

enum OnboardingType {
  connect,
  share,
  belong,
}

class OnboardingItem {
  final OnboardingType type;
  final String titleKey;
  final String fallbackTitle;
  final String descriptionKey;
  final String fallbackDescription;
  final Color accentColor;

  const OnboardingItem({
    required this.type,
    required this.titleKey,
    required this.fallbackTitle,
    required this.descriptionKey,
    required this.fallbackDescription,
    required this.accentColor,
  });
}

///
/// Custom line-art illustration made only with Flutter.
/// No additional SVG/image asset is required.
///
class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.type,
    required this.accentColor,
    required this.size,
    required this.isDark,
  });

  final OnboardingType type;
  final Color accentColor;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildDecoration(
            icon: Icons.person_outline_rounded,
            alignment: const Alignment(-0.86, 0.20),
            size: 23,
          ),

          _buildDecoration(
            icon: Icons.favorite_border_rounded,
            alignment: const Alignment(0.84, -0.55),
            size: 16,
          ),

          _buildDecoration(
            icon: Icons.auto_awesome_rounded,
            alignment: const Alignment(-0.72, -0.60),
            size: 15,
          ),

          _buildDecoration(
            icon: Icons.chat_bubble_outline_rounded,
            alignment: const Alignment(0.80, 0.55),
            size: 18,
          ),

          CustomPaint(
            size: Size.square(size * 0.74),
            painter: _OnboardingPainter(
              type: type,
              accentColor: accentColor,
              backgroundLineColor: isDark
                  ? const Color(0xFF452084)
                  : const Color(0xFFDCCCFB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoration({
    required IconData icon,
    required Alignment alignment,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Icon(
        icon,
        size: size,
        color: accentColor.withOpacity(
          isDark ? 0.28 : 0.20,
        ),
      ),
    );
  }
}

class _OnboardingPainter extends CustomPainter {
  _OnboardingPainter({
    required this.type,
    required this.accentColor,
    required this.backgroundLineColor,
  });

  final OnboardingType type;
  final Color accentColor;
  final Color backgroundLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case OnboardingType.connect:
        _paintConnect(canvas, size);
        break;

      case OnboardingType.share:
        _paintShare(canvas, size);
        break;

      case OnboardingType.belong:
        _paintBelong(canvas, size);
        break;
    }
  }

  Paint _mainPaint(Size size) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.6, size.width * 0.019)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.78),
          accentColor,
        ],
      ).createShader(
        Offset.zero & size,
      );
  }

  Paint _secondaryPaint(Size size) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, size.width * 0.012)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = backgroundLineColor;
  }

  void _paintConnect(
      Canvas canvas,
      Size size,
      ) {
    final main = _mainPaint(size);
    final secondary = _secondaryPaint(size);

    final w = size.width;
    final h = size.height;

    // Center person
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.37),
      w * 0.115,
      main,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.50,
          h * 0.70,
        ),
        width: w * 0.42,
        height: h * 0.33,
      ),
      math.pi,
      math.pi,
      false,
      main,
    );

    // Left person
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.45),
      w * 0.075,
      secondary,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.25,
          h * 0.68,
        ),
        width: w * 0.27,
        height: h * 0.22,
      ),
      math.pi,
      math.pi,
      false,
      secondary,
    );

    // Right person
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.45),
      w * 0.075,
      secondary,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.75,
          h * 0.68,
        ),
        width: w * 0.27,
        height: h * 0.22,
      ),
      math.pi,
      math.pi,
      false,
      secondary,
    );

    canvas.drawCircle(
      Offset(w * 0.16, h * 0.26),
      4,
      main,
    );

    canvas.drawCircle(
      Offset(w * 0.84, h * 0.26),
      3,
      secondary,
    );
  }

  void _paintShare(
      Canvas canvas,
      Size size,
      ) {
    final main = _mainPaint(size);
    final secondary = _secondaryPaint(size);

    final w = size.width;
    final h = size.height;

    final plane = Path()
      ..moveTo(w * 0.16, h * 0.41)
      ..lineTo(w * 0.84, h * 0.18)
      ..lineTo(w * 0.61, h * 0.82)
      ..lineTo(w * 0.45, h * 0.56)
      ..close();

    canvas.drawPath(
      plane,
      main,
    );

    final centerLine = Path()
      ..moveTo(w * 0.45, h * 0.56)
      ..lineTo(w * 0.84, h * 0.18);

    canvas.drawPath(
      centerLine,
      main,
    );

    // Small background elements similar to reference.
    canvas.drawCircle(
      Offset(w * 0.13, h * 0.69),
      w * 0.04,
      secondary,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.13,
          h * 0.82,
        ),
        width: w * 0.16,
        height: h * 0.12,
      ),
      math.pi,
      math.pi,
      false,
      secondary,
    );

    canvas.drawCircle(
      Offset(w * 0.86, h * 0.50),
      w * 0.035,
      secondary,
    );
  }

  void _paintBelong(
      Canvas canvas,
      Size size,
      ) {
    final main = _mainPaint(size);
    final secondary = _secondaryPaint(size);

    final w = size.width;
    final h = size.height;

    final heart = Path();

    heart.moveTo(
      w * 0.50,
      h * 0.76,
    );

    heart.cubicTo(
      w * 0.40,
      h * 0.66,
      w * 0.19,
      h * 0.51,
      w * 0.19,
      h * 0.34,
    );

    heart.cubicTo(
      w * 0.19,
      h * 0.18,
      w * 0.39,
      h * 0.13,
      w * 0.50,
      h * 0.29,
    );

    heart.cubicTo(
      w * 0.61,
      h * 0.13,
      w * 0.81,
      h * 0.18,
      w * 0.81,
      h * 0.34,
    );

    heart.cubicTo(
      w * 0.81,
      h * 0.51,
      w * 0.60,
      h * 0.66,
      w * 0.50,
      h * 0.76,
    );

    canvas.drawPath(
      heart,
      main,
    );

    // Person left
    canvas.drawCircle(
      Offset(w * 0.12, h * 0.49),
      w * 0.045,
      secondary,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.12,
          h * 0.64,
        ),
        width: w * 0.18,
        height: h * 0.14,
      ),
      math.pi,
      math.pi,
      false,
      secondary,
    );

    // Person right
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.49),
      w * 0.045,
      secondary,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          w * 0.88,
          h * 0.64,
        ),
        width: w * 0.18,
        height: h * 0.14,
      ),
      math.pi,
      math.pi,
      false,
      secondary,
    );
  }

  @override
  bool shouldRepaint(
      covariant _OnboardingPainter oldDelegate,
      ) {
    return oldDelegate.type != type ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.backgroundLineColor != backgroundLineColor;
  }
}