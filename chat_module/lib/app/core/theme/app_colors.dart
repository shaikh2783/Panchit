import 'package:flutter/material.dart';

import 'messenger_design.dart';

class AppColors {
  AppColors._();

  /// Compatibility aliases backed by the server-provided Messenger palette.
  static Color get primary => MessengerDesign.primary;
  static Color get surfaceDark => MessengerDesign.ink;
  static Color get accent => MessengerDesign.muted;
  static Color get white => MessengerDesign.canvas;
  static Color get background => MessengerDesign.canvas;
  static Color get textPrimary => MessengerDesign.ink;
  static Color get textSecondary => MessengerDesign.muted;
}
