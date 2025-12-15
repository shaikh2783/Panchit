import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.boxShadow,
    this.border,
    this.elevation,
    // إضافات الفخامة
    this.bezelGradientColors,
    this.bezelWidth = 1.0,
    this.isFrosted = false,
    this.frostOpacity = 0.85,
  });
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius; // من نوع double (يتحوّل لـ BorderRadius داخليًا)
  final VoidCallback? onTap;
  final Color? color;
  final List<Color>? gradientColors;
  final Alignment? gradientBegin;
  final Alignment? gradientEnd;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final double? elevation;
  // Edge glow (bezel)
  final List<Color>? bezelGradientColors;
  final double bezelWidth;
  // Frosted glass
  final bool isFrosted;
  final double frostOpacity;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double radius = borderRadius ?? Radii.medium;
    final BorderRadius clipRadius = BorderRadius.circular(radius);
    // ظل افتراضي حسب الإضاءة/الارتفاع
    final double effectiveElevation = elevation ?? Elevations.level2;
    final List<BoxShadow>? effectiveBoxShadow = boxShadow ??
        (effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
                  blurRadius: effectiveElevation,
                  offset: const Offset(0, 2),
                )
              ]
            : null);
    // لون الخلفية (في حالة frosted، يكون شبه شفاف)
    Color backgroundColor;
    if (gradientColors == null || gradientColors!.length < 2) {
      backgroundColor = color ?? theme.colorScheme.surface;
    } else {
      // عند وجود تدرّج، نستخدم أول لون كأساس للشفافية عند تفعيل frosted
      backgroundColor = gradientColors!.first.withValues(alpha: 0.5);
    }
    if (isFrosted) backgroundColor = backgroundColor.withValues(alpha: frostOpacity);
    // ديكور الحاوية الخارجية
    BoxDecoration outerDecoration = BoxDecoration(
      gradient: (gradientColors != null &&
              gradientColors!.length >= 2 &&
              !isFrosted)
          ? LinearGradient(
              colors: gradientColors!,
              begin: gradientBegin ?? Alignment.topLeft,
              end: gradientEnd ?? Alignment.bottomRight,
            )
          : null,
      color: (gradientColors == null || gradientColors!.length < 2 || isFrosted)
          ? backgroundColor
          : null,
      borderRadius: clipRadius,
      border: (bezelGradientColors == null) ? border : null,
      boxShadow: effectiveBoxShadow,
    );
    // المحتوى الافتراضي
    Widget inner = Container(padding: padding, child: child);
    // إن وُجد Bezel Gradient: نرسم إطارًا لامعًا ثم المحتوى الداخلي
    if (bezelGradientColors != null && bezelGradientColors!.length >= 2) {
      final innerRadius = math.max(0.0, radius - bezelWidth);
      inner = Container(
        padding: EdgeInsets.all(bezelWidth),
        decoration: BoxDecoration(
          borderRadius: clipRadius,
          gradient: LinearGradient(
            colors: bezelGradientColors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: effectiveBoxShadow,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (gradientColors == null)
                ? (color ?? theme.colorScheme.surface)
                : null,
            gradient: (gradientColors != null)
                ? LinearGradient(
                    colors: gradientColors!,
                    begin: gradientBegin ?? Alignment.topLeft,
                    end: gradientEnd ?? Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      );
      // عندما نستخدم Bezel ننقل الظل للداخل ونخفف ديكور الخارج
      outerDecoration = BoxDecoration(
        borderRadius: clipRadius,
      );
    }
    // البطاقة (مع الضباب إن طُلب)
    Widget card = Container(
      margin: margin,
      decoration: outerDecoration,
      clipBehavior: Clip.antiAlias,
      child: isFrosted
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: inner,
            )
          : inner,
    );
    // معالجة الضغط بدون استخدام borderRadius المباشر في InkWell
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        // ✅ بديل آمن ومتوافق لكل الإصدارات
        customBorder: RoundedRectangleBorder(borderRadius: clipRadius),
        child: card,
      ),
    );
  }
}
