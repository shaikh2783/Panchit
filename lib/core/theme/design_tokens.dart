/// Design tokens: spacing, radii, elevations, durations, curves, layout metrics.
/// Central place to evolve the visual language without hunting magic numbers.
library;
import 'package:flutter/animation.dart';
/// Spacing scale (4pt grid).
class Spacing {
  static const double xxxs = 2;
  static const double xxs = 4; // Tiny icon gaps
  static const double xs = 6;
  static const double sm = 8; // Small padding
  static const double md = 12; // Default component inner padding
  static const double lg = 16; // Section padding
  static const double xl = 24; // Larger block spacing
  static const double xxl = 32; // Page level spacing
  static const double xxxl = 40; // Oversized hero spacing
}
/// Corner radii.
class Radii {
  static const double xxSmall = 4;
  static const double xSmall = 6;
  static const double small = 8;
  static const double medium = 12; // Cards, surfaces
  static const double large = 16; // Dialogs / modals
  static const double xLarge = 24; // Special highlight containers
  static const double pill = 1000; // Fully rounded capsules
}
/// Elevation levels (approx Material shadow depth) expressed as blurRadius.
class Elevations {
  static const double hairline = 1; // Dividers / subtle separators
  static const double level1 = 4; // Low card
  static const double level2 = 8; // Raised card / nav bar
  static const double level3 = 12; // Sticky elements
  static const double level4 = 20; // Dialogs
  static const double level5 = 28; // Highest surfaces
}
/// Animation durations.
class AnimDurations {
  static const Duration fast = Duration(milliseconds: 120); // micro-interactions
  static const Duration medium = Duration(milliseconds: 240); // most transitions
  static const Duration slow = Duration(milliseconds: 400); // page transitions
  static const Duration verySlow = Duration(milliseconds: 700); // large hero / reel load
}
/// Curves for consistent motion language.
class CurvesToken {
  // Use widely available curves to avoid SDK version drift. Keep as `final` for flexibility.
  static final Curve accelerate = Curves.easeIn;
  static final Curve decelerate = Curves.decelerate;
  static final Curve standard = Curves.easeInOut;
  static final Curve spring = Curves.easeOutBack;
  static final Curve fadeOut = Curves.easeOut;
}
/// Layout specific metrics.
class LayoutTokens {
  static const double navBarHeight = 56;
  static const double postCardRadius = Radii.medium;
  static const double avatarRadius = 22;
}
/// Gestures / physics configuration.
class GestureTokens {
  static const double tapScale = 0.94; // Slight press animation scale
  static const double minSwipeVelocity = 300; // reels/story swipe threshold
}
/// Opacity standards for layering.
class OpacityTokens {
  static const double disabled = 0.38;
  static const double mediumEmphasis = 0.6;
  static const double lowEmphasis = 0.42;
}
/// Reusable shadow colors may adjust dynamically by brightness externally.
class ShadowTokens {
  static const double lightBlur = Elevations.level1;
  static const double cardBlur = Elevations.level2;
  static const double popoverBlur = Elevations.level3;
}
