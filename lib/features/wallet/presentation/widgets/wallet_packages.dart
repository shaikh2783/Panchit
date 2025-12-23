import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/data/models/wallet_package.dart';
import 'package:get/get.dart';

class WalletPackageCard extends StatefulWidget {
  const WalletPackageCard({
    super.key,
    required this.package,
    required this.onPurchase,
    this.isPurchasing = false,
  });

  final WalletPackage package;
  final VoidCallback onPurchase;
  final bool isPurchasing;

  @override
  State<WalletPackageCard> createState() => _WalletPackageCardState();
}

class _WalletPackageCardState extends State<WalletPackageCard> {
  bool _showPermissions = false;

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    final theme = Theme.of(context);
    final highlight = _parseColor(package.color, theme.colorScheme.primary);
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final features = describePackageFeatures(package);
    final featuresToShow = features.take(6).toList(growable: false);
    final remainingCount = features.length - featuresToShow.length;
    final capabilities = describePackageCapabilities(package);
    final isPurchasing = widget.isPurchasing;
    final isCurrentPlan = package.isCurrentPlan;
    final hasSubscription = package.wasPurchased;
    final isExpiredPlan = package.isSubscriptionExpired;
    final canRenew = package.canRenew;
    final statusLabel = package.subscriptionStatusLabel;
    final secondaryStatus = package.subscriptionSecondaryLabel;

    final badges = <Widget>[];
    if (package.isRecommended) {
      badges.add(
        _BadgeChip(label: 'recommended_badge'.tr, color: highlight, icon: Iconsax.star),
      );
    }
    if (isCurrentPlan) {
      badges.add(
        _BadgeChip(
          label: 'your_current_plan'.tr,
          color: highlight,
          icon: Iconsax.verify,
        ),
      );
    } else if (hasSubscription) {
      badges.add(
        _BadgeChip(
          label: isExpiredPlan ? 'Plan expired' : 'Previously purchased',
          color: isExpiredPlan
              ? theme.colorScheme.error
              : theme.colorScheme.tertiary,
          icon: isExpiredPlan ? Iconsax.info_circle : Iconsax.refresh,
        ),
      );
    }
    if (package.isPopular) {
      badges.add(
        _BadgeChip(
          label: 'popular_choice_badge'.tr,
          color: theme.colorScheme.secondary,
          icon: Iconsax.flash,
        ),
      );
    }

    return AnimatedContainer(
      duration: AnimDurations.medium,
      curve: CurvesToken.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        border: Border.all(
          color: highlight.withOpacity(package.isRecommended ? 0.45 : 0.18),
          width: package.isRecommended ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        onTap: isPurchasing ? null : () => _showPackageDetails(context),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -50,
              child: _AccentBlob(color: highlight.withOpacity(0.18), size: 210),
            ),
            Positioned(
              bottom: -70,
              left: -40,
              child: _AccentBlob(color: highlight.withOpacity(0.08), size: 200),
            ),
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xLarge),
                color: isDark ? surface.withOpacity(0.94) : surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badges.isNotEmpty) ...[
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      children: badges,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            if (package.description != null &&
                                package.description!.isNotEmpty)
                              Text(
                                package.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.lg),
                      _PriceColumn(
                        package: package,
                        highlight: highlight,
                        textColor: textColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  Divider(height: 1, color: textColor.withOpacity(0.08)),
                  const SizedBox(height: Spacing.lg),
                  if (statusLabel != null) ...[
                    _SubscriptionStatusBanner(
                      primary: statusLabel,
                      secondary: secondaryStatus,
                      highlight: highlight,
                      isActive: isCurrentPlan,
                      isExpired: isExpiredPlan,
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                  if (featuresToShow.isNotEmpty) ...[
                    Text(
                      'What’s included',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final feature in featuresToShow)
                          _FeaturePill(label: feature, accent: highlight),
                      ],
                    ),
                    if (remainingCount > 0) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '+ $remainingCount more benefits',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),
                  ],
                  if (capabilities.isNotEmpty) ...[
                    Text(
                      'Permissions & publishing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    if (_showPermissions)
                      Column(
                        children: capabilities
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.xs,
                                ),
                                child: _CapabilityRow(
                                  label: item.label,
                                  enabled: item.enabled,
                                  accent: highlight,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      )
                    else
                      Text(
                        'Tap to see full permissions list.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: Spacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _togglePermissions,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          foregroundColor: highlight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.large),
                          ),
                        ),
                        icon: Icon(
                          _showPermissions
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(
                          _showPermissions
                              ? 'Hide permissions'
                              : 'Show permissions',
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (isPurchasing || isCurrentPlan)
                              ? null
                              : widget.onPurchase,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.large),
                            ),
                            backgroundColor: highlight,
                            foregroundColor: Colors.white,
                          ),
                          child: isPurchasing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCurrentPlan
                                          ? Iconsax.tick_circle
                                          : canRenew
                                          ? Iconsax.refresh
                                          : Iconsax.flash,
                                      size: 18,
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Text(
                                      isCurrentPlan
                                          ? 'Current plan'
                                          : canRenew
                                          ? 'Renew plan'
                                          : 'Activate plan',
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      TextButton.icon(
                        onPressed: isPurchasing
                            ? null
                            : () => _showPackageDetails(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.sm,
                          ),
                          foregroundColor: highlight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.large),
                          ),
                        ),
                        icon: const Icon(Iconsax.info_circle, size: 18),
                        label: Text('see_details_button'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePermissions() {
    setState(() => _showPermissions = !_showPermissions);
  }

  void _showPackageDetails(BuildContext context) {
    final theme = Theme.of(context);
    final package = widget.package;
    final highlight = _parseColor(package.color, theme.colorScheme.primary);
    final features = describePackageFeatures(package);
    final capabilities = describePackageCapabilities(package);
    final subscription = package.subscription;
    final statusLabel = package.subscriptionStatusLabel;
    final secondaryStatus = package.subscriptionSecondaryLabel;
    final purchasedLabel = package.subscriptionPurchasedLabel;
    final expiryLabel = subscription?.expiryLabel;
    final isCurrentPlan = package.isCurrentPlan;
    final isExpiredPlan = package.isSubscriptionExpired;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      barrierColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xLarge)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.45,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, controller) {
            final padding = MediaQuery.of(context).viewPadding.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: Spacing.xl,
                right: Spacing.xl,
                top: Spacing.xl,
                bottom: Spacing.xl + padding,
              ),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    package.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Membership details & full benefits',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(height: Spacing.lg),
                    _SubscriptionStatusBanner(
                      primary: statusLabel,
                      secondary: secondaryStatus,
                      highlight: highlight,
                      isActive: isCurrentPlan,
                      isExpired: isExpiredPlan,
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  _DetailsRow(label: 'price_label'.tr, value: package.formattedPrice),
                  _DetailsRow(
                    label: 'billing_cycle_label'.tr,
                    value: package.hasPeriod
                        ? package.period!.label
                        : 'One-time activation',
                  ),
                  if (purchasedLabel != null) ...[
                    _DetailsRow(label: 'purchased_on_label'.tr, value: purchasedLabel),
                  ],
                  if (subscription != null &&
                      expiryLabel != null &&
                      !subscription.isLifetime) ...[
                    _DetailsRow(
                      label: subscription.isExpired
                          ? 'Expired on'
                          : 'Renews on',
                      value: expiryLabel,
                    ),
                  ],
                  if (subscription != null && subscription.isLifetime) ...[
                    _DetailsRow(label: 'expiry_label'.tr, value: 'lifetime_access'.tr),
                  ],
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Benefits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  if (features.isEmpty)
                    Text(
                      'No additional benefits listed.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              size: 18,
                              color: highlight,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: Spacing.xl),
                  if (capabilities.isNotEmpty) ...[
                    Text(
                      'Permissions & publishing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    ...capabilities.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        child: _CapabilityRow(
                          label: item.label,
                          enabled: item.enabled,
                          accent: highlight,
                          dense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class WalletPackageCardSkeleton extends StatelessWidget {
  const WalletPackageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.25 : 0.4,
    );

    Widget shimmer({double height = 16, double width = double.infinity}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.94 : 1,
        ),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmer(height: 18, width: 120),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmer(height: 26, width: double.infinity),
                    const SizedBox(height: Spacing.xs),
                    shimmer(height: 16, width: 180),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.lg),
              shimmer(height: 32, width: 84),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          shimmer(height: 1, width: double.infinity),
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: List.generate(
              4,
              (index) => shimmer(height: 18, width: 120),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          shimmer(height: 48, width: double.infinity),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.tick_circle, size: 16, color: accent),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  const _AccentBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
    required this.package,
    required this.highlight,
    required this.textColor,
  });

  final WalletPackage package;
  final Color highlight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceStyle =
        theme.textTheme.displaySmall ??
        theme.textTheme.headlineLarge ??
        const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          package.formattedPrice,
          style: priceStyle.copyWith(
            color: highlight,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          package.hasPeriod
              ? 'per ${package.period!.label}'
              : 'One-time access',
          style: theme.textTheme.labelLarge?.copyWith(
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

Color _parseColor(String? value, Color fallback) {
  if (value == null || value.isEmpty) {
    return fallback;
  }
  final hex = value.replaceAll('#', '').trim();
  if (hex.length == 6 || hex.length == 8) {
    final buffer = StringBuffer();
    if (hex.length == 6) {
      buffer.write('ff');
    }
    buffer.write(hex);
    final parsed = int.tryParse(buffer.toString(), radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  return fallback;
}

List<String> describePackageFeatures(WalletPackage package) {
  final features = package.features;
  if (features.isEmpty) {
    return const [];
  }
  final descriptions = <String>[];
  final handledKeys = <String>{};

  void addIfTrue(String key, String description) {
    if (_asBool(features[key])) {
      descriptions.add(description);
      handledKeys.add(key);
    }
  }

  addIfTrue('verification_badge', 'Verification badge included');
  addIfTrue('badge', 'Verification badge included');

  void parseBoost(String key, String label) {
    final value = features[key];
    if (value is Map<String, dynamic>) {
      final enabled = _asBool(value['enabled']);
      if (enabled) {
        final count = value['count'];
        final countText = count == null ? '' : ' (${_formatCount(count)})';
        descriptions.add('$label$countText');
      }
      handledKeys.add(key);
    }
  }

  parseBoost('boost_posts', 'Boost posts');
  parseBoost('boost_pages', 'Boost pages');

  void parseLimit(String key, String label) {
    final amount = _asInt(features[key]);
    if (amount > 0) {
      descriptions.add('Up to $amount $label');
      handledKeys.add(key);
    }
  }

  parseLimit('allowed_products', 'products');
  parseLimit('allowed_blogs_categories', 'blog categories');
  parseLimit('allowed_videos_categories', 'video categories');
  parseLimit('max_groups', 'groups');
  parseLimit('max_pages', 'pages');

  final stored = features['storage'];
  if (stored != null) {
    descriptions.add('Storage: ${stored.toString()}');
    handledKeys.add('storage');
  }

  features.forEach((key, value) {
    if (handledKeys.contains(key)) {
      return;
    }
    if (value == null) {
      return;
    }
    if (value is bool) {
      if (value) {
        descriptions.add(_titleCase(key));
      }
      return;
    }
    if (value is Map || value is List) {
      descriptions.add(_titleCase(key));
      return;
    }
    if (value.toString().isEmpty) {
      return;
    }
    descriptions.add('${_titleCase(key)}: ${value.toString()}');
  });

  return descriptions;
}

List<_CapabilityItem> describePackageCapabilities(WalletPackage package) {
  final permissions = package.permissions;
  if (permissions == null || !permissions.hasCapabilities) {
    return const [];
  }

  final entries = <_CapabilityItem>[];
  final relevantEntries = permissions.capabilities.entries
      .where((entry) => _capabilityKeys.contains(entry.key))
      .toList(growable: false);

  if (relevantEntries.isEmpty) {
    return const [];
  }

  final allEnabled =
      relevantEntries.isNotEmpty &&
      relevantEntries.every((entry) => entry.value == true);

  if (allEnabled) {
    entries.add(const _CapabilityItem('All permissions enabled', true));
  }

  for (final descriptor in _capabilityDescriptors) {
    final value = permissions.capabilities[descriptor.key];
    if (value == null) {
      continue;
    }
    entries.add(_CapabilityItem(descriptor.label, value));
  }

  return entries;
}

String _formatCount(Object? value) {
  final number = _asInt(value);
  if (number <= 0) {
    return 'unlimited';
  }
  return number.toString();
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
  }
  return false;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _titleCase(String input) {
  if (input.isEmpty) return input;
  final normalized = input.replaceAll('_', ' ');
  return normalized
      .split(' ')
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            segment[0].toUpperCase() + segment.substring(1).toLowerCase(),
      )
      .join(' ');
}

class _SubscriptionStatusBanner extends StatelessWidget {
  const _SubscriptionStatusBanner({
    required this.primary,
    required this.highlight,
    this.secondary,
    this.isActive = false,
    this.isExpired = false,
  });

  final String primary;
  final String? secondary;
  final Color highlight;
  final bool isActive;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent;
    if (isActive) {
      accent = highlight;
    } else if (isExpired) {
      accent = theme.colorScheme.error;
    } else {
      accent = highlight;
    }

    final background = isActive
        ? highlight.withOpacity(0.16)
        : isExpired
        ? theme.colorScheme.error.withOpacity(0.12)
        : highlight.withOpacity(0.12);
    final icon = isActive
        ? Iconsax.tick_circle
        : isExpired
        ? Iconsax.close_circle
        : Iconsax.info_circle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.large),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  primary,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (secondary != null) ...[
            const SizedBox(height: Spacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                secondary!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapabilityItem {
  const _CapabilityItem(this.label, this.enabled);

  final String label;
  final bool enabled;
}

class _CapabilityDescriptor {
  const _CapabilityDescriptor(this.key, this.label);

  final String key;
  final String label;
}

const List<_CapabilityDescriptor> _capabilityDescriptors = [
  _CapabilityDescriptor('pages', 'Create Pages'),
  _CapabilityDescriptor('groups', 'Create Groups'),
  _CapabilityDescriptor('events', 'Create Events'),
  _CapabilityDescriptor('reels', 'Can Add Reels'),
  _CapabilityDescriptor('watch', 'Watch Videos'),
  _CapabilityDescriptor('blogs_create', 'Create Blogs'),
  _CapabilityDescriptor('blogs_read', 'Read Blogs'),
  _CapabilityDescriptor('offers_create', 'Create Offers'),
  _CapabilityDescriptor('offers_read', 'Read Offers'),
  _CapabilityDescriptor('jobs', 'Create Jobs'),
  _CapabilityDescriptor('market', 'Access Market'),
  _CapabilityDescriptor('stories', 'Add Stories'),
  _CapabilityDescriptor('posts', 'Add Posts'),
  _CapabilityDescriptor('schedule_posts', 'Schedule Posts'),
  _CapabilityDescriptor('colored_posts', 'Add Colored Posts'),
  _CapabilityDescriptor('feelings_posts', 'Add Feelings & Activity Posts'),
  _CapabilityDescriptor('polls_posts', 'Add Poll Posts'),
  _CapabilityDescriptor('gif_posts', 'Add GIF Posts'),
  _CapabilityDescriptor('anonymous_posts', 'Add Anonymous Posts'),
  _CapabilityDescriptor('upload_videos', 'Upload Videos'),
  _CapabilityDescriptor('upload_audios', 'Upload Audios'),
  _CapabilityDescriptor('upload_files', 'Upload Files'),
  _CapabilityDescriptor('ads_create', 'Create Ads'),
  _CapabilityDescriptor('funding', 'Access Funding'),
  _CapabilityDescriptor('monetization', 'Monetization Tools'),
  _CapabilityDescriptor('tips', 'Receive Tips'),
  _CapabilityDescriptor('audio_calls', 'Audio Calls'),
  _CapabilityDescriptor('video_calls', 'Video Calls'),
  _CapabilityDescriptor('live', 'Go Live'),
  _CapabilityDescriptor('invitations', 'Send Invitations'),
  _CapabilityDescriptor('gifts', 'Send Gifts'),
  _CapabilityDescriptor('games', 'Play Games'),
  _CapabilityDescriptor('movies', 'Watch Movies'),
  _CapabilityDescriptor('courses', 'Access Courses'),
  _CapabilityDescriptor('forums', 'Forums Access'),
];

const Set<String> _capabilityKeys = {
  'pages',
  'groups',
  'events',
  'reels',
  'watch',
  'blogs_create',
  'blogs_read',
  'offers_create',
  'offers_read',
  'jobs',
  'market',
  'stories',
  'posts',
  'schedule_posts',
  'colored_posts',
  'feelings_posts',
  'polls_posts',
  'gif_posts',
  'anonymous_posts',
  'upload_videos',
  'upload_audios',
  'upload_files',
  'ads_create',
  'funding',
  'monetization',
  'tips',
  'audio_calls',
  'video_calls',
  'live',
  'invitations',
  'gifts',
  'games',
  'movies',
  'courses',
  'forums',
};

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.label,
    required this.enabled,
    required this.accent,
    this.dense = false,
  });

  final String label;
  final bool enabled;
  final Color accent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = enabled ? Iconsax.tick_circle : Iconsax.close_square;
    final color = enabled ? accent : theme.colorScheme.error;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: enabled
          ? theme.textTheme.bodyMedium?.color
          : theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
      fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: dense
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: dense ? 16 : 18,
          color: color.withOpacity(enabled ? 1 : 0.85),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(label, style: textStyle)),
      ],
    );
  }
}
