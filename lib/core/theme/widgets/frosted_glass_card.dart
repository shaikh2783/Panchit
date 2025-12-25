import 'package:flutter/material.dart';
import 'dart:ui'; // For using ImageFilter

class FrostedGlassCard extends StatelessWidget {
  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurAmount = 10.0,
    this.margin,
    this.padding,
    this.onTap,
    this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  final Widget child;
  final double borderRadius;
  final double blurAmount;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Color> effectiveGradientColors = gradientColors ??
        [
          theme.colorScheme.primary.withOpacity(0.1),
          theme.colorScheme.secondary.withOpacity(0.1),
        ];
    final Color effectiveBorderColor = borderColor ?? Colors.white.withOpacity(0.3);

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          margin: margin,
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: effectiveGradientColors,
              begin: gradientBegin,
              end: gradientEnd,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: cardContent,
      ),
    );
  }
}