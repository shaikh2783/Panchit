import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:get/get.dart';

class WalletInlineMessage extends StatelessWidget {
  const WalletInlineMessage({
    super.key,
    required this.message,
    required this.isError,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isError
        ? theme.colorScheme.error.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Iconsax.danger : Iconsax.info_circle,
            color: foreground,
            size: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text('retry_button'.tr)),
        ],
      ),
    );
  }
}

class WalletErrorView extends StatelessWidget {
  const WalletErrorView({
    super.key,
    required this.message,
    required this.errorDetails,
    required this.onRetry,
  });

  final String message;
  final String errorDetails;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.warning_2, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: Spacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          errorDetails,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.sm),
        FilledButton.icon(
          icon: const Icon(Iconsax.refresh, size: 18),
          label: Text('retry_button'.tr),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class WalletEmptyState extends StatelessWidget {
  const WalletEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 42, color: theme.colorScheme.primary),
          const SizedBox(height: Spacing.sm),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class WalletLoadMoreIndicator extends StatelessWidget {
  const WalletLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.md),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class WalletActionButton extends StatelessWidget {
  const WalletActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class WalletStatusBadge extends StatelessWidget {
  const WalletStatusBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
