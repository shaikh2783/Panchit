import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_recharge_page.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_utils.dart';

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
    final currencySymbol = summary.wallet.currencySymbol.isNotEmpty
        ? summary.wallet.currencySymbol
        : summary.wallet.currency;
    final updatedText = summary.updatedAt != null
        ? 'Updated ${walletFormatDate(summary.updatedAt!)}'
        : null;
    final availableActions = <Widget>[];
    final balanceEntries = summary.balances.entries.entries.toList();
    final otherBalanceEntries = balanceEntries
        .where((entry) => entry.key != 'available')
        .toList();

    // Add recharge action if wallet is enabled
    if (summary.wallet.enabled) {
      availableActions.add(
        WalletActionButton(
          icon: Iconsax.wallet_add,
          label: 'Recharge',
          onTap: () async {
            final result = await Navigator.of(context).push<dynamic>(
              MaterialPageRoute(
                builder: (_) => WalletRechargePage(summary: summary),
              ),
            );
            if (result != null) {
              onRefresh();
            }
          },
        ),
      );
    }

    if (summary.wallet.transferEnabled) {
      availableActions.add(
        WalletActionButton(
          icon: Iconsax.send_2,
          label: 'Transfer',
          onTap: () => onAction(WalletActionType.transfer),
        ),
      );
    }

    if (summary.tips.enabled) {
      availableActions.add(
        WalletActionButton(
          icon: Iconsax.money_send,
          label: 'Send Tip',
          onTap: () => onAction(WalletActionType.tip),
        ),
      );
    }

    final hasWithdrawalOption = summary.withdrawalSources.values.any(
      (source) => source.enabled,
    );
    if (summary.wallet.withdrawalEnabled && hasWithdrawalOption) {
      availableActions.add(
        WalletActionButton(
          icon: Iconsax.wallet_money,
          label: 'Withdraw',
          onTap: () => onAction(WalletActionType.withdraw),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current balance',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        '$currencySymbol${summary.wallet.balance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (updatedText != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          updatedText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh balance',
                  onPressed: onRefresh,
                  icon: isRefreshing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : const Icon(Iconsax.refresh),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                WalletMetricChip(
                  label: 'Available',
                  value:
                      '$currencySymbol${summary.balances['available'].toStringAsFixed(2)}',
                ),
                if (otherBalanceEntries.isNotEmpty)
                  ...otherBalanceEntries.map(
                    (entry) => WalletMetricChip(
                      label: _formatLabel(entry.key),
                      value: '$currencySymbol${entry.value.toStringAsFixed(2)}',
                    ),
                  ),
                if (summary.points.enabled)
                  WalletMetricChip(
                    label: 'Points',
                    value: summary.points.balance.toStringAsFixed(2),
                    trailing: summary.points.value > 0
                        ? '≈ $currencySymbol${summary.points.value.toStringAsFixed(2)}'
                        : null,
                  ),
                if (summary.tips.enabled)
                  WalletMetricChip(
                    label: 'Tips today',
                    value: summary.tips.maxAmount > 0
                        ? '$currencySymbol${summary.tips.maxAmount.toStringAsFixed(2)}'
                        : summary.tips.minAmount.toStringAsFixed(2),
                  ),
              ],
            ),
            if (summary.wallet.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'Payment methods: ${summary.wallet.paymentMethods.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (availableActions.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: availableActions,
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
    );
  }

  String _formatLabel(String value) {
    if (value.isEmpty) return value;
    final pieces = value.split('_').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    });
    return pieces.join(' ');
  }
}

class WalletSummarySkeleton extends StatelessWidget {
  const WalletSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
