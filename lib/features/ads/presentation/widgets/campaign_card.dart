import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.title,
    required this.budget,
    required this.spend,
    required this.views,
    required this.clicks,
    required this.active,
    this.imageUrl,
    this.bidding,
    this.status,
    this.createdAt,
    this.isApproved = false,
    this.onTap,
    this.onToggleActive,
  });
  final String title;
  final String budget;
  final String spend;
  final String views;
  final String clicks;
  final bool active;
  final String? imageUrl;
  final String? bidding;
  final String? status;
  final String? createdAt;
  final bool isApproved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Image Header with Overlay
              if (imageUrl != null)
                Stack(
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.3),
                                theme.colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    if (status != null && status!.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _StatusBadge(
                          text: status!,
                          isApproved: isApproved,
                        ),
                      ),
                    // Active Indicator
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.green.withValues(alpha: 0.9)
                              : Colors.grey.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (active ? Colors.green : Colors.grey)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              active ? 'active'.tr : 'paused'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with Action Button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (onToggleActive != null && isApproved)
                          IconButton(
                            tooltip: active
                                ? 'pause_campaign'.tr
                                : 'activate_campaign'.tr,
                            icon: Icon(
                              active ? Iconsax.pause : Iconsax.play,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: onToggleActive,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.wallet_money,
                                  label: 'budget'.tr,
                                  value: budget,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: theme.dividerColor.withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.chart_21,
                                  label: 'spent'.tr,
                                  value: spend,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                            height: 1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.eye,
                                  label: 'views'.tr,
                                  value: views,
                                  color: Colors.blue,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: theme.dividerColor.withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.mouse_1,
                                  label: 'clicks'.tr,
                                  value: clicks,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Bidding & Created
                    if (bidding != null || createdAt != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (bidding != null && bidding!.isNotEmpty)
                            _InfoChip(
                              icon: Iconsax.chart_1,
                              text: bidding!,
                              color: Colors.purple,
                            ),
                          if (createdAt != null && createdAt!.isNotEmpty)
                            _InfoChip(
                              icon: Iconsax.clock,
                              text: createdAt!,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.isApproved,
  });
  final String text;
  final bool isApproved;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isApproved ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Iconsax.tick_circle : Iconsax.clock,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
