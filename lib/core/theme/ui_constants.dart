import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// UI constants and helpers for consistent spacing, radii, and shadows.
class UI {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  // Radii
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;

  // Shadows
  static List<BoxShadow> softShadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Themed surfaces
  static Color surfaceCard(BuildContext context) {
    return Get.isDarkMode ? const Color(0xFF252d48) : Colors.white;
  }

  static Color surfacePage(BuildContext context) {
    return Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.grey[50]!;
  }

  static Color subtleText(BuildContext context) {
    return Get.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  }
}
