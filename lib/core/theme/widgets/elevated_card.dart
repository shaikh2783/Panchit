import 'package:flutter/material.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
/// A reusable elevated card that adapts to light/dark themes and central tokens.
class ElevatedCard extends StatelessWidget {
  const ElevatedCard({
    super.key,
    this.margin,
    this.padding,
    this.borderRadius,
    this.onTap,
    required this.child,
    this.color,
  });
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? Radii.medium;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: Elevations.level2,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: Elevations.level2,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
