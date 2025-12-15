import 'package:flutter/material.dart';
import 'package:snginepro/core/theme/app_colors.dart';
/// Text styles used in the application
/// Supports both English and Arabic languages
class AppTextStyles {
  AppTextStyles._();
  // Default font (supports Arabic)
  static const String fontFamily = 'Cairo';
  static const String fontFamilyEn = 'Roboto';
  // ========== Large Headings ==========
  /// Extra large heading (32px)
  static TextStyle h1({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Large heading (28px)
  static TextStyle h2({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Medium heading (24px)
  static TextStyle h3({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Large subheading (20px)
  static TextStyle h4({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Medium subheading (18px)
  static TextStyle h5({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Small subheading (16px)
  static TextStyle h6({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  // ========== Body Text ==========
  /// Large body text (16px)
  static TextStyle bodyLarge({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Medium body text (15px)
  static TextStyle bodyMedium({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Small body text (14px)
  static TextStyle bodySmall({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    fontFamily: fontFamily,
  );
  // ========== Secondary Text ==========
  /// Large secondary text (14px)
  static TextStyle subtitleLarge({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    fontFamily: fontFamily,
  );
  /// Medium secondary text (13px)
  static TextStyle subtitleMedium({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    fontFamily: fontFamily,
  );
  /// Small secondary text (12px)
  static TextStyle subtitleSmall({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    fontFamily: fontFamily,
  );
  // ========== Special Text ==========
  /// Button text (15px)
  static TextStyle button({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: color ?? Colors.white,
    fontFamily: fontFamily,
  );
  /// Label text and tags (13px)
  static TextStyle label({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
    color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    fontFamily: fontFamily,
  );
  /// Very small text (11px)
  static TextStyle caption({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.3,
    color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    fontFamily: fontFamily,
  );
  /// Large text (17px)
  static TextStyle overline({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.5,
    color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    fontFamily: fontFamily,
  );
  // ========== Special Styles ==========
  /// Link text (15px)
  static TextStyle link({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.primary,
    decoration: TextDecoration.none,
    fontFamily: fontFamily,
  );
  /// Link text with underline
  static TextStyle linkUnderlined({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    fontFamily: fontFamily,
  );
  /// Strikethrough text
  static TextStyle strikethrough({Color? color, bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    decoration: TextDecoration.lineThrough,
    color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    fontFamily: fontFamily,
  );
  /// Bold text
  static TextStyle bold({Color? color, bool isDark = false, double? fontSize}) => TextStyle(
    fontSize: fontSize ?? 15,
    fontWeight: FontWeight.bold,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    fontFamily: fontFamily,
  );
  /// Light text
  static TextStyle light({Color? color, bool isDark = false, double? fontSize}) => TextStyle(
    fontSize: fontSize ?? 15,
    fontWeight: FontWeight.w300,
    height: 1.5,
    color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    fontFamily: fontFamily,
  );
  // ========== Post Text ==========
  /// Post username
  static TextStyle postUsername({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    fontFamily: fontFamily,
  );
  /// Post content
  static TextStyle postContent({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    fontFamily: fontFamily,
  );
  /// Post time
  static TextStyle postTime({bool isDark = false}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.3,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    fontFamily: fontFamily,
  );
  // ========== Input Field Text ==========
  /// Input field text
  static TextStyle input({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    fontFamily: fontFamily,
  );
  /// Input field placeholder text
  static TextStyle inputHint({bool isDark = false}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
    fontFamily: fontFamily,
  );
  /// Input field label text
  static TextStyle inputLabel({bool isDark = false}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    fontFamily: fontFamily,
  );
  /// Input field error text
  static TextStyle inputError({bool isDark = false}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    color: AppColors.error,
    fontFamily: fontFamily,
  );
}
