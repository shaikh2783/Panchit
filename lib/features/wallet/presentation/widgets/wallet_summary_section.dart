import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_recharge_page.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_utils.dart';

class _ChipData {
  const _ChipData({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final String? trailing;
}

// ─────────────────────────────────────────────────────────────────────────────
// WalletSummaryCard
// ─────────────────────────────────────────────────────────────────────────────

class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.summary,
    required this.isRefreshing,
    required this.onAction,
    required this.onRefresh,
    this.errorMessage,
  });

  final WalletSummary summary;
  final bool isRefreshing;
  final String? errorMessage;
  final void Function(WalletActionType action) onAction;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 600;

    final currencySymbol = summary.wallet.currencySymbol.isNotEmpty
        ? summary.wallet.currencySymbol
        : summary.wallet.currency;
    final updatedText = summary.updatedAt != null
        ? 'wallet_balance_updated_at'.trParams(
            {'date': walletFormatDate(summary.updatedAt!)},
          )
        : null;

    final chips = _buildChips(currencySymbol);
    final actions = _buildActions(context);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient balance header ─────────────────────────────────────
          _BalanceHeader(
            currencySymbol: currencySymbol,
            balance: summary.wallet.balance,
            updatedText: updatedText,
            isRefreshing: isRefreshing,
            onRefresh: onRefresh,
            colorScheme: colorScheme,
            theme: theme,
          ),

          // ── Stats chips + actions ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (chips.isNotEmpty) ...[
                  _ChipGrid(
                    chips: chips,
                    columns: isWide ? 4 : (screenWidth >= 360 ? 3 : 2),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (summary.wallet.paymentMethods.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Iconsax.card,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          'wallet_payment_methods'.trParams({
                            'methods':
                                summary.wallet.paymentMethods.join(', '),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (actions.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: Spacing.md),
                  _ActionRow(
                    actions: actions,
                    columns: isWide ? 4 : 2,
                  ),
                ],
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.md),
                    child: WalletInlineMessage(
                      message: errorMessage!,
                      isError: true,
                      onRetry: onRefresh,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_ChipData> _buildChips(String currencySymbol) {
    final chips = <_ChipData>[];
    chips.add(_ChipData(
      label: 'wallet_label_available'.tr,
      value:
          '$currencySymbol${summary.balances['available'].toStringAsFixed(2)}',
    ));
    final otherEntries = summary.balances.entries.entries.where(
      (e) => e.key != 'available',
    );
    for (final entry in otherEntries) {
      chips.add(_ChipData(
        label: _formatLabel(entry.key),
        value: '$currencySymbol${entry.value.toStringAsFixed(2)}',
      ));
    }
    if (summary.points.enabled) {
      chips.add(_ChipData(
        label: 'wallet_label_points'.tr,
        value: summary.points.balance.toStringAsFixed(2),
        trailing: summary.points.value > 0
            ? '≈ $currencySymbol${summary.points.value.toStringAsFixed(2)}'
            : null,
      ));
    }
    if (summary.tips.enabled) {
      chips.add(_ChipData(
        label: 'wallet_label_tips_today'.tr,
        value: summary.tips.maxAmount > 0
            ? '$currencySymbol${summary.tips.maxAmount.toStringAsFixed(2)}'
            : summary.tips.minAmount.toStringAsFixed(2),
      ));
    }
    return chips;
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    if (summary.wallet.enabled) {
      actions.add(_ActionTile(
        icon: Iconsax.wallet_add,
        label: 'wallet_action_recharge'.tr,
        isPrimary: true,
        onTap: () async {
          final result = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(
              builder: (_) => WalletRechargePage(summary: summary),
            ),
          );
          if (result != null) onRefresh();
        },
      ));
    }
    if (summary.wallet.transferEnabled) {
      actions.add(_ActionTile(
        icon: Iconsax.send_2,
        label: 'wallet_action_transfer'.tr,
        onTap: () => onAction(WalletActionType.transfer),
      ));
    }
    if (summary.tips.enabled) {
      actions.add(_ActionTile(
        icon: Iconsax.money_send,
        label: 'wallet_action_send_tip'.tr,
        onTap: () => onAction(WalletActionType.tip),
      ));
    }
    final hasWithdrawalOption = summary.withdrawalSources.values.any(
      (s) => s.enabled,
    );
    if (summary.wallet.withdrawalEnabled && hasWithdrawalOption) {
      actions.add(_ActionTile(
        icon: Iconsax.wallet_money,
        label: 'wallet_action_withdraw'.tr,
        onTap: () => onAction(WalletActionType.withdraw),
      ));
    }
    return actions;
  }

  String _formatLabel(String value) {
    if (value.isEmpty) return value;
    return value.split('_').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BalanceHeader  — gradient top section of the card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.currencySymbol,
    required this.balance,
    required this.isRefreshing,
    required this.onRefresh,
    required this.colorScheme,
    required this.theme,
    this.updatedText,
  });

  final String currencySymbol;
  final double balance;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final String? updatedText;

  @override
  Widget build(BuildContext context) {
    final onPrimary = colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.45)!,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wallet_current_balance_label'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onPrimary.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$currencySymbol${balance.toStringAsFixed(2)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: onPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                if (updatedText != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 11,
                        color: onPrimary.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        updatedText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _RefreshButton(
            isRefreshing: isRefreshing,
            onRefresh: onRefresh,
            color: onPrimary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RefreshButton
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
    required this.color,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'wallet_refresh_balance'.tr,
      onPressed: isRefreshing ? null : onRefresh,
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
      ),
      icon: isRefreshing
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : const Icon(Iconsax.refresh, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChipGrid
// ─────────────────────────────────────────────────────────────────────────────

class _ChipGrid extends StatelessWidget {
  const _ChipGrid({required this.chips, required this.columns});

  final List<_ChipData> chips;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_ChipData>>[];
    for (var i = 0; i < chips.length; i += columns) {
      rows.add(chips.sublist(i, (i + columns).clamp(0, chips.length)));
    }
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows[r].length; i++) ...[
                if (i > 0) const SizedBox(width: Spacing.sm),
                Expanded(
                  child: WalletMetricChip(
                    label: rows[r][i].label,
                    value: rows[r][i].value,
                    trailing: rows[r][i].trailing,
                  ),
                ),
              ],
              for (var i = rows[r].length; i < columns; i++) ...[
                const SizedBox(width: Spacing.sm),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionRow — evenly-spaced icon + label tiles
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions, required this.columns});

  final List<Widget> actions;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < actions.length; i += columns) {
      rows.add(actions.sublist(i, (i + columns).clamp(0, actions.length)));
    }
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: Spacing.sm),
          Row(
            children: [
              for (var i = 0; i < rows[r].length; i++) ...[
                if (i > 0) const SizedBox(width: Spacing.sm),
                Expanded(child: rows[r][i]),
              ],
              for (var i = rows[r].length; i < columns; i++) ...[
                const SizedBox(width: Spacing.sm),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionTile — tappable column with icon + label
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final bgColor = isPrimary
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fgColor = isPrimary
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(Radii.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.large),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 22),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WalletSummarySkeleton — shimmer loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class WalletSummarySkeleton extends StatefulWidget {
  const WalletSummarySkeleton({super.key});

  @override
  State<WalletSummarySkeleton> createState() => _WalletSummarySkeletonState();
}

class _WalletSummarySkeletonState extends State<WalletSummarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final shimmerOpacity = 0.06 + _anim.value * 0.1;
        final baseColor =
            colorScheme.onSurface.withValues(alpha: shimmerOpacity);

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xLarge),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15 + _anim.value * 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Bone(width: 80, height: 12, color: baseColor),
                        const SizedBox(width: Spacing.sm),
                        _Bone(width: 60, height: 12, color: baseColor),
                        const SizedBox(width: Spacing.sm),
                        _Bone(width: 70, height: 12, color: baseColor),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _Bone(
                            height: 44,
                            color: baseColor,
                            radius: Radii.large,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: _Bone(
                            height: 44,
                            color: baseColor,
                            radius: Radii.large,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.color,
    this.width,
    required this.height,
    this.radius = Radii.pill,
  });

  final Color color;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WalletMetricChip
// ─────────────────────────────────────────────────────────────────────────────

class WalletMetricChip extends StatelessWidget {
  const WalletMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.large),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
