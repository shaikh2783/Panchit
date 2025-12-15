import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_event.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_packages_cubit.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_payments_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_payments_event.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_payments_state.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_transactions_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_transactions_event.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_transactions_state.dart';
import 'package:snginepro/features/wallet/data/models/wallet_payment.dart';
import 'package:snginepro/features/wallet/data/models/wallet_transaction.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_packages.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
class WalletTransactionsTab extends StatelessWidget {
  const WalletTransactionsTab({
    super.key,
    required this.controller,
    required this.onRefresh,
  });
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletTransactionsBloc, WalletTransactionsState>(
      builder: (context, state) {
        if (state.isLoading && state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xxxl,
            ),
            children: [
              if (state.errorMessage != null && state.transactions.isEmpty)
                WalletErrorView(
                  message: 'Unable to load transactions',
                  errorDetails: state.errorMessage!,
                  onRetry: () {
                    context.read<WalletTransactionsBloc>().add(
                      const LoadWalletTransactions(),
                    );
                  },
                ),
              if (!state.isLoading &&
                  state.transactions.isEmpty &&
                  state.errorMessage == null)
                const WalletEmptyState(
                  icon: Iconsax.wallet_money,
                  message: 'No wallet transactions yet',
                ),
              if (state.transactions.isNotEmpty) ...[
                if (state.errorMessage != null)
                  WalletInlineMessage(
                    message: state.errorMessage!,
                    isError: true,
                    onRetry: () {
                      context.read<WalletTransactionsBloc>().add(
                        const LoadWalletTransactions(),
                      );
                    },
                  ),
                ...state.transactions.map(
                  (transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: WalletTransactionTile(transaction: transaction),
                  ),
                ),
                if (state.isLoadingMore || state.hasMore)
                  const WalletLoadMoreIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }
}
class WalletPaymentsTab extends StatelessWidget {
  const WalletPaymentsTab({
    super.key,
    required this.controller,
    required this.onRefresh,
  });
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletPaymentsBloc, WalletPaymentsState>(
      builder: (context, state) {
        if (state.isLoading && state.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xxxl,
            ),
            children: [
              if (state.errorMessage != null && state.payments.isEmpty)
                WalletErrorView(
                  message: 'Unable to load payments',
                  errorDetails: state.errorMessage!,
                  onRetry: () {
                    context.read<WalletPaymentsBloc>().add(
                      const LoadWalletPayments(),
                    );
                  },
                ),
              if (!state.isLoading &&
                  state.payments.isEmpty &&
                  state.errorMessage == null)
                const WalletEmptyState(
                  icon: Iconsax.card,
                  message: 'No payout requests yet',
                ),
              if (state.payments.isNotEmpty) ...[
                if (state.errorMessage != null)
                  WalletInlineMessage(
                    message: state.errorMessage!,
                    isError: true,
                    onRetry: () {
                      context.read<WalletPaymentsBloc>().add(
                        const LoadWalletPayments(),
                      );
                    },
                  ),
                ...state.payments.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: WalletPaymentTile(payment: payment),
                  ),
                ),
                if (state.isLoadingMore || state.hasMore)
                  const WalletLoadMoreIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }
}
class WalletPackagesTab extends StatelessWidget {
  const WalletPackagesTab({
    super.key,
    required this.controller,
    required this.onRefresh,
  });
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<WalletPackagesCubit, WalletPackagesState>(
      listenWhen: (previous, current) =>
          previous.purchaseStatus != current.purchaseStatus,
      listener: (context, state) {
        if (state.purchaseStatus == WalletPackagePurchaseStatus.failure &&
            state.purchaseError != null &&
            state.purchaseError!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.purchaseError!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        if (state.purchaseStatus == WalletPackagePurchaseStatus.success &&
            state.lastPurchaseResult != null) {
          final result = state.lastPurchaseResult!;
          final message = result.message.isNotEmpty
              ? result.message
              : 'Plan activated successfully';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          context.read<WalletOverviewBloc>().add(const RefreshWalletOverview());
          context.read<WalletPackagesCubit>().fetchPackages(forceRefresh: true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<WalletPackagesCubit>();
        final slivers = _buildPackageSlivers(context, state, cubit);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.06),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: onRefresh,
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.md,
                    ),
                    child: _PackagesTabHeader(),
                  ),
                ),
                ...slivers,
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxxl)),
              ],
            ),
          ),
        );
      },
    );
  }
}
List<Widget> _buildPackageSlivers(
  BuildContext context,
  WalletPackagesState state,
  WalletPackagesCubit cubit,
) {
  if (state.isLoading && !state.hasPackages) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.md,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : Spacing.lg),
              child: const WalletPackageCardSkeleton(),
            ),
            childCount: 3,
          ),
        ),
      ),
    ];
  }
  if (state.status == WalletPackagesStatus.failure && !state.hasPackages) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: WalletErrorView(
            message: 'Unable to load packages',
            errorDetails: state.errorMessage ?? 'Please try again shortly.',
            onRetry: () => cubit.fetchPackages(forceRefresh: true),
          ),
        ),
      ),
    ];
  }
  if (!state.hasPackages) {
    return const [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: WalletEmptyState(
            icon: Iconsax.box,
            message: 'No premium packages available right now',
          ),
        ),
      ),
    ];
  }
  final children = <Widget>[];
  if (state.status == WalletPackagesStatus.failure &&
      state.errorMessage != null &&
      state.errorMessage!.isNotEmpty) {
    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: WalletInlineMessage(
          message: state.errorMessage!,
          isError: true,
          onRetry: () => cubit.fetchPackages(forceRefresh: true),
        ),
      ),
    );
  }
  for (var index = 0; index < state.packages.length; index++) {
    final package = state.packages[index];
    final isPurchasing =
        state.purchaseStatus == WalletPackagePurchaseStatus.inProgress &&
        state.purchasingPackageId == package.id;
    children.add(
      Padding(
        padding: EdgeInsets.only(
          bottom: index == state.packages.length - 1 ? 0 : Spacing.lg,
        ),
        child: WalletPackageCard(
          package: package,
          onPurchase: () => cubit.purchasePackage(package.id),
          isPurchasing: isPurchasing,
        ),
      ),
    );
  }
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      sliver: SliverList(delegate: SliverChildListDelegate(children)),
    ),
  ];
}
class _PackagesTabHeader extends StatelessWidget {
  const _PackagesTabHeader();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Packages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Unlock verification, reach boosts, and creator tools tailored to your growth.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.transaction});
  final WalletTransaction transaction;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.amount >= 0;
    final amountText = transaction.amountFormatted.isNotEmpty
        ? transaction.amountFormatted
        : transaction.amount.toStringAsFixed(2);
    final subtitleParts = <String>[
      if (transaction.label.isNotEmpty) transaction.label,
      if (transaction.date.isNotEmpty) transaction.date,
    ];
    final related = transaction.relatedUser;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isCredit ? Colors.green : Colors.red).withValues(
                      alpha: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(Radii.medium),
                  ),
                  child: Icon(
                    isCredit ? Iconsax.import_1 : Iconsax.export_1,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amountText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isCredit
                              ? Colors.green
                              : theme.textTheme.titleMedium?.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' • '),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (related != null) ...[
              const SizedBox(height: Spacing.sm),
              WalletRelatedUserRow(relatedUser: related),
            ],
            if (transaction.metadata != null &&
                transaction.metadata!.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              WalletMetadataView(metadata: transaction.metadata!),
            ],
          ],
        ),
      ),
    );
  }
}
class WalletPaymentTile extends StatelessWidget {
  const WalletPaymentTile({super.key, required this.payment});
  final WalletPayment payment;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = payment.amountFormatted.isNotEmpty
        ? payment.amountFormatted
        : payment.amount.toStringAsFixed(2);
    final statusColor = walletStatusColor(payment.status);
    final requestedAt = payment.requestedAt.isNotEmpty
        ? payment.requestedAt
        : walletFormatDate(walletDateTimeFromTimestamp(payment.timestamp));
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(Radii.medium),
                  ),
                  child: Icon(Iconsax.card, color: statusColor),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amountText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Requested $requestedAt',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                WalletStatusBadge(text: payment.status, color: statusColor),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Method: ${payment.methodValue.isNotEmpty ? payment.methodValue : payment.method}',
              style: theme.textTheme.bodyMedium,
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(payment.notes!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
class WalletRelatedUserRow extends StatelessWidget {
  const WalletRelatedUserRow({super.key, required this.relatedUser});
  final WalletRelatedUser relatedUser;
  @override
  Widget build(BuildContext context) {
    final mediaAsset = Provider.of<AppConfig>(
      context,
      listen: false,
    ).mediaAsset;
    final avatarUrl = relatedUser.picture;
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(mediaAsset(avatarUrl).toString())
              : null,
          child: avatarUrl.isEmpty ? const Icon(Iconsax.user, size: 16) : null,
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relatedUser.fullName.isNotEmpty
                    ? relatedUser.fullName
                    : relatedUser.username,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (relatedUser.username.isNotEmpty)
                Text(
                  '@${relatedUser.username}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (relatedUser.verified)
          const Icon(Iconsax.verify, color: Colors.lightBlue, size: 18),
      ],
    );
  }
}
class WalletMetadataView extends StatelessWidget {
  const WalletMetadataView({super.key, required this.metadata});
  final Map<String, dynamic> metadata;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadata.entries
          .where(
            (entry) => entry.value != null && entry.value.toString().isNotEmpty,
          )
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_formatKey(entry.key)}: ${entry.value}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          )
          .toList(),
    );
  }
  String _formatKey(String key) {
    if (key.isEmpty) return key;
    final buffer = StringBuffer();
    for (final segment in key.split('_')) {
      if (segment.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(segment[0].toUpperCase());
      buffer.write(segment.substring(1));
    }
    return buffer.toString();
  }
}
