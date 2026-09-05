import 'package:flutter/material.dart';

/// Centralized Panchit color system.
/// Supports light and dark modes.
class AppColors {
  AppColors._();

  // ========== Panchit Brand Colors ==========
  static const Color primary = Color(0xFF7B00FF);
  static const Color primaryDark = Color(0xFF5700C9);
  static const Color primaryLight = Color(0xFFA855F7);

  static const Color secondary = Color(0xFFF000A8);
  static const Color secondaryDark = Color(0xFFC60088);
  static const Color secondaryLight = Color(0xFFFF4FC3);

  static const Color brandOrange = Color(0xFFFF6A24);
  static const Color brandPink = Color(0xFFFF1B8D);

  // ========== Light Mode - Backgrounds ==========
  static const Color backgroundLight = Color(0xFFF8F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE8E8F0);

  // ========== Dark Mode - Backgrounds ==========
  static const Color backgroundDark = Color(0xFF030312);
  static const Color surfaceDark = Color(0xFF080819);
  static const Color cardDark = Color(0xFF0D0D20);
  static const Color surfaceElevatedDark = Color(0xFF131329);
  static const Color dividerDark = Color(0xFF24243A);

  // ========== Text - Light Mode ==========
  static const Color textPrimaryLight = Color(0xFF11111A);
  static const Color textSecondaryLight = Color(0xFF666678);
  static const Color textTertiaryLight = Color(0xFF9090A0);
  static const Color textDisabledLight = Color(0xFFBCBCC8);

  // ========== Text - Dark Mode ==========
  static const Color textPrimaryDark = Color(0xFFF7F7FA);
  static const Color textSecondaryDark = Color(0xFFAAAAba);
  static const Color textTertiaryDark = Color(0xFF777789);
  static const Color textDisabledDark = Color(0xFF555568);

  // ========== Borders ==========
  static const Color borderLight = Color(0xFFE7E7EF);
  static const Color borderDark = Color(0xFF25253A);

  // ========== Status Colors ==========
  static const Color success = Color(0xFF31C76A);
  static const Color successLight = Color(0xFFE9F9EF);
  static const Color successDark = Color(0xFF168A43);

  static const Color error = Color(0xFFF04452);
  static const Color errorLight = Color(0xFFFFECEE);
  static const Color errorDark = Color(0xFFC62835);

  static const Color warning = Color(0xFFFFA62B);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF5B8DEF);
  static const Color infoLight = Color(0xFFEEF4FF);
  static const Color infoDark = Color(0xFF315FC2);

  // ========== Interactive ==========
  static const Color hoverLight = Color(0xFFF3F3F8);
  static const Color hoverDark = Color(0xFF141428);

  static const Color pressedLight = Color(0xFFEAEAF2);
  static const Color pressedDark = Color(0xFF1C1C33);

  static const Color focusLight = Color(0xFFF4ECFF);
  static const Color focusDark = Color(0xFF22123D);

  // ========== Social / Feed Colors ==========
  static const Color like = Color(0xFFFF2D73);
  static const Color comment = Color(0xFFB9B9C8);
  static const Color share = Color(0xFFB9B9C8);
  static const Color bookmark = Color(0xFFB9B9C8);

  // ========== Post Type Colors ==========
  static const Color postTypeText = primary;
  static const Color postTypePhoto = Color(0xFF45BD62);
  static const Color postTypeAlbum = Color(0xFFF02849);
  static const Color postTypeVideo = Color(0xFF9B5CFF);
  static const Color postTypeReel = brandPink;
  static const Color postTypeAudio = brandOrange;
  static const Color postTypeFile = Color(0xFF6C7CFF);
  static const Color postTypePoll = Color(0xFF20C997);
  static const Color postTypeFeeling = Color(0xFFFFC107);
  static const Color postTypeColored = secondary;
  static const Color postTypeOffer = Color(0xFF00BCD4);
  static const Color postTypeJob = Color(0xFFB34DDB);

  // ========== Panchit Gradients ==========
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF6B00FF),
      Color(0xFFF000A8),
      Color(0xFFFF5A36),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalBrandGradient = LinearGradient(
    colors: [
      Color(0xFF6B00FF),
      Color(0xFFF000A8),
      Color(0xFFFF6A24),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [
      Color(0xFF6B00FF),
      Color(0xFFF000A8),
      Color(0xFFFF6A24),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reelGradient = LinearGradient(
    colors: [
      Color(0xFFF000A8),
      Color(0xFFFF6A24),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF030312),
      Color(0xFF080819),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF3F3F8),
      Color(0xFFC6C6CA),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ========== Shadows ==========
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get brandGlow => [
    BoxShadow(
      color: secondary.withValues(alpha: 0.22),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  // ========== Opacity ==========
  static const double overlayLight = 0.05;
  static const double overlayMedium = 0.12;
  static const double overlayHigh = 0.24;

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}

/// Shared design tokens for the onboarding / auth flow
/// (OnboardingPage, LoginPage, SignUpPage). Keeping these in one place
/// ensures every screen in that flow uses the same colors, gradient
/// button, text field and error/divider styling.
class PanchitAuthColors {
  PanchitAuthColors._();

  static const Color backgroundDark = Color(0xFF030615);
  static const Color backgroundLight = Color(0xFFFCFCFF);

  static const Color surfaceDark = Color(0xFF080B18);
  static const Color inputDark = Color(0xFF0B0E1C);

  static const Color borderDark = Color(0xFF292C3D);
  static const Color borderLight = Color(0xFFE4E4EA);

  static const Color purple = Color(0xFF6C20FF);
  static const Color purpleAccentDark = Color(0xFFB593FF);
  static const Color pink = Color(0xFFFF267F);
  static const Color orange = Color(0xFFFF8A00);

  static const Color textPrimaryDark = Colors.white;
  static const Color textPrimaryLight = Color(0xFF15151D);

  static const Color textSecondaryDark = Color(0xFFB8B9C5);
  static const Color textSecondaryLight = Color(0xFF62636D);

  static const Color textMutedDark = Color(0xFF777988);
  static const Color textMutedLight = Color(0xFF888994);

  static const Color textFieldValueDark = Colors.white;
  static const Color textFieldValueLight = Color(0xFF17171E);

  static const Color textFieldHintDark = Color(0xFF606271);
  static const Color textFieldHintLight = Color(0xFFA0A1AA);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color errorTextDark = Color(0xFFFFB4B4);
  static const Color errorTextLight = Color(0xFFB42318);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF6200FF),
      Color(0xFF8B00FF),
      Color(0xFFFF267F),
    ],
  );

  static Color background(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  static Color border(bool isDark) => isDark ? borderDark : borderLight;

  static Color inputFill(bool isDark) =>
      isDark ? inputDark : Colors.white;

  static Color textPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondaryLight;

  static Color textMuted(bool isDark) =>
      isDark ? textMutedDark : textMutedLight;

  static Color textFieldValue(bool isDark) =>
      isDark ? textFieldValueDark : textFieldValueLight;

  static Color textFieldHint(bool isDark) =>
      isDark ? textFieldHintDark : textFieldHintLight;

  static Color linkAccent(bool isDark) =>
      isDark ? purpleAccentDark : purple;
}