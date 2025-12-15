import 'package:flutter/material.dart';
/// Integrated color system for the application
/// Supports light and dark modes
class AppColors {
  AppColors._();
  // ========== Primary Brand Colors ==========
  static const Color primary = Color(0xff008dd2); // Facebook Blue
  static const Color primaryDark = Color(0xff02628f);
  static const Color primaryLight = Color(0xff5caad1);
  static const Color secondary = Color(0xFF42B72A); // Green
  static const Color secondaryDark = Color(0xFF36A420);
  static const Color secondaryLight = Color(0xFF5BC43A);
  static const Color accent = Color(0xFFE7F3FF); // Very light blue
  static const Color accentDark = Color(0xFF1C2B33);
  // ========== Light Mode - Backgrounds ==========
  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE4E6EB);
  // ========== Dark Mode - Backgrounds ==========
  static const Color backgroundDark = Color(0xFF18191A);
  static const Color surfaceDark = Color(0xFF242526);
  static const Color cardDark = Color(0xFF3A3B3C);
  static const Color dividerDark = Color(0xFF3E4042);
  // ========== Text - Light Mode ==========
  static const Color textPrimaryLight = Color(0xFF050505);
  static const Color textSecondaryLight = Color(0xFF65676B);
  static const Color textTertiaryLight = Color(0xFF8A8D91);
  static const Color textDisabledLight = Color(0xFFBCC0C4);
  // ========== Text - Dark Mode ==========
  static const Color textPrimaryDark = Color(0xFFE4E6EB);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);
  static const Color textTertiaryDark = Color(0xFF8A8D91);
  static const Color textDisabledDark = Color(0xFF606770);
  // ========== Status Colors ==========
  static const Color success = Color(0xFF42B72A);
  static const Color successLight = Color(0xFFE7F3E8);
  static const Color successDark = Color(0xFF2D7A1F);
  static const Color error = Color(0xFFED4956);
  static const Color errorLight = Color(0xFFFEEBED);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color info = Color(0xFF1877F2);
  static const Color infoLight = Color(0xFFE7F3FF);
  static const Color infoDark = Color(0xFF0D47A1);
  // ========== Interactive Colors ==========
  static const Color hoverLight = Color(0xFFF2F3F5);
  static const Color hoverDark = Color(0xFF3A3B3C);
  static const Color pressedLight = Color(0xFFE4E6EB);
  static const Color pressedDark = Color(0xFF4E4F50);
  static const Color focusLight = Color(0xFFE7F3FF);
  static const Color focusDark = Color(0xFF263951);
  // ========== Post Type Colors ==========
  static const Color postTypeText = Color(0xFF1877F2);
  static const Color postTypePhoto = Color(0xFF45BD62);
  static const Color postTypeAlbum = Color(0xFFF02849);
  static const Color postTypeVideo = Color(0xFF7F66FF);
  static const Color postTypeReel = Color(0xFFE4405F);
  static const Color postTypeAudio = Color(0xFFFF9500);
  static const Color postTypeFile = Color(0xFF5E72E4);
  static const Color postTypePoll = Color(0xFF20C997);
  static const Color postTypeFeeling = Color(0xFFFFC107);
  static const Color postTypeColored = Color(0xFFE91E63);
  static const Color postTypeOffer = Color(0xFF00BCD4);
  static const Color postTypeJob = Color(0xFF9C27B0);
  // ========== Gradient Colors ==========
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient reelGradient = LinearGradient(
    colors: [Color(0xFFE4405F), Color(0xFFF77737)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // ========== Shadows ==========
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  // ========== Opacity ==========
  static const double overlayLight = 0.05;
  static const double overlayMedium = 0.12;
  static const double overlayHigh = 0.24;
  // ========== Semi-transparent ==========
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
