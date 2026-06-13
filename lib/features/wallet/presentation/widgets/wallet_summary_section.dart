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
    final chipCols = screenWidth >= 600 ? 4 : screenWidth >= 360 ? 3 : 2;
    final actionCols = screenWidth >= 600 ? 4 : 2;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wallet_current_balance_label'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$currencySymbol${summary.wallet.balance.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (updatedText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          updatedText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'wallet_refresh_balance'.tr,
                  onPressed: onRefresh,
                  icon: isRefreshing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Iconsax.refresh),
                ),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              _ChipGrid(chips: chips, columns: chipCols),
            ],
            if (summary.wallet.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'wallet_payment_methods'.trParams(
                  {'methods': summary.wallet.paymentMethods.join(', ')},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              _ActionGrid(actions: actions, columns: actionCols),
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
      actions.add(WalletActionButton(
        icon: Iconsax.wallet_add,
        label: 'wallet_action_recharge'.tr,
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
      actions.add(WalletActionButton(
        icon: Iconsax.send_2,
        label: 'wallet_action_transfer'.tr,
        onTap: () => onAction(WalletActionType.transfer),
      ));
    }
    if (summary.tips.enabled) {
      actions.add(WalletActionButton(
        icon: Iconsax.money_send,
        label: 'wallet_action_send_tip'.tr,
        onTap: () => onAction(WalletActionType.tip),
      ));
    }
    final hasWithdrawalOption = summary.withdrawalSources.values.any(
      (s) => s.enabled,
    );
    if (summary.wallet.withdrawalEnabled && hasWithdrawalOption) {
      actions.add(WalletActionButton(
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

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions, required this.columns});

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

class WalletSummarySkeleton extends StatelessWidget {
  const WalletSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: const Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

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
