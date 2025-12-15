import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
class BoostButton extends StatefulWidget {
  final bool isBoosted;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;
  final String? remainingText;
  const BoostButton({
    super.key,
    required this.isBoosted,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
    this.remainingText,
  });
  @override
  State<BoostButton> createState() => _BoostButtonState();
}
class _BoostButtonState extends State<BoostButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  void _handleTap() {
    if (!widget.enabled || widget.isLoading) return;
    _animationController.forward().then((_) {
      _animationController.reverse();
      widget.onTap();
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.isBoosted
                  ? LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [
                              theme.cardColor.withOpacity(0.5),
                              theme.cardColor.withOpacity(0.3),
                            ]
                          : [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                    ),
              border: Border.all(
                color: widget.isBoosted
                    ? Colors.orange.shade300
                    : theme.colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: widget.isBoosted
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.isBoosted ? Colors.white : theme.colorScheme.primary,
                    ),
                  )
                else
                  Icon(
                    widget.isBoosted ? Iconsax.star_1 : Iconsax.star,
                    size: 18,
                    color: widget.isBoosted ? Colors.white : theme.colorScheme.primary,
                  ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isBoosted ? 'boosted'.tr : 'boost_post'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isBoosted ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                    if (widget.remainingText != null && !widget.isBoosted)
                      Text(
                        widget.remainingText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
