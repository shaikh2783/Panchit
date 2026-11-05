import 'package:flutter/material.dart';

import '../../../settings.dart';

/// The visual language of the messenger.
///
/// Keep product surfaces on these tokens instead of inventing local colors,
/// radii and shadows in every feature. The reference uses a quiet, mostly-flat
/// interface; depth is reserved for transient surfaces and primary actions.
class MessengerDesign {
  MessengerDesign._();

  static RuntimeThemeColors get _colors => AppRuntimeSettings.themeColors;

  static Color get primary => _colors.primary;
  static Color get primaryDark => _colors.primaryDark;
  static Color get primaryPressed => _colors.primaryPressed;
  static Color get primarySoft => _colors.primarySoft;
  static Color get ink => _colors.lightText;
  static Color get muted => _colors.lightMuted;
  static Color get subtle => _colors.lightSubtle;
  static Color get canvas => _colors.lightCanvas;
  static Color get groupedCanvas => _colors.lightGroupedCanvas;
  static Color get surface => _colors.lightSurface;
  static Color get softSurface => _colors.lightSoftSurface;
  static Color get field => _colors.lightField;
  static Color get divider => _colors.lightDivider;
  static Color get online => _colors.online;
  static Color get destructive => _colors.destructive;
  static Color get warning => _colors.warning;

  static Color get darkCanvas => _colors.darkCanvas;
  static Color get darkGroupedCanvas => _colors.darkGroupedCanvas;
  static Color get darkSurface => _colors.darkSurface;
  static Color get darkSoftSurface => _colors.darkSoftSurface;
  static Color get darkField => _colors.darkField;
  static Color get darkDivider => _colors.darkDivider;
  static Color get darkInk => _colors.darkText;
  static Color get darkMuted => _colors.darkMuted;
  static Color get darkSubtle => _colors.darkSubtle;
  static Color get darkPrimarySoft => _colors.darkPrimarySoft;

  static const double pagePadding = 16;
  static const double compactRadius = 12;
  static const double controlRadius = 16;
  static const double sectionRadius = 18;
  static const double touchTarget = 44;

  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[_colors.gradientStart, _colors.gradientEnd],
  );

  static MessengerPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? MessengerPalette.dark
        : MessengerPalette.light;
  }

  static List<BoxShadow> floatingShadow(Brightness brightness) => <BoxShadow>[
    BoxShadow(
      color: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.30)
          : ink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class MessengerPalette {
  const MessengerPalette({
    required this.canvas,
    required this.groupedCanvas,
    required this.surface,
    required this.softSurface,
    required this.field,
    required this.text,
    required this.muted,
    required this.subtle,
    required this.divider,
    required this.primarySoft,
  });

  static MessengerPalette get light => MessengerPalette(
    canvas: MessengerDesign.canvas,
    groupedCanvas: MessengerDesign.groupedCanvas,
    surface: MessengerDesign.surface,
    softSurface: MessengerDesign.softSurface,
    field: MessengerDesign.field,
    text: MessengerDesign.ink,
    muted: MessengerDesign.muted,
    subtle: MessengerDesign.subtle,
    divider: MessengerDesign.divider,
    primarySoft: MessengerDesign.primarySoft,
  );

  static MessengerPalette get dark => MessengerPalette(
    canvas: MessengerDesign.darkCanvas,
    groupedCanvas: MessengerDesign.darkGroupedCanvas,
    surface: MessengerDesign.darkSurface,
    softSurface: MessengerDesign.darkSoftSurface,
    field: MessengerDesign.darkField,
    text: MessengerDesign.darkInk,
    muted: MessengerDesign.darkMuted,
    subtle: MessengerDesign.darkSubtle,
    divider: MessengerDesign.darkDivider,
    primarySoft: MessengerDesign.darkPrimarySoft,
  );

  final Color canvas;
  final Color groupedCanvas;
  final Color surface;
  final Color softSurface;
  final Color field;
  final Color text;
  final Color muted;
  final Color subtle;
  final Color divider;
  final Color primarySoft;
}
