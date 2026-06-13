import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_event.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_state.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_payments_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_payments_event.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_transactions_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_transactions_event.dart';
import 'package:snginepro/features/wallet/data/models/wallet_action_result.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/domain/wallet_repository.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_action_sheet.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_summary_section.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_tabs.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<WalletRepository>(context, listen: false);

    return MultiBlocProvider(
      providers: [
        BlocProvider<WalletOverviewBloc>(
          create: (_) =>
              WalletOverviewBloc(repository)..add(const LoadWalletOverview()),
        ),
        BlocProvider<WalletTransactionsBloc>(
          create: (_) =>
              WalletTransactionsBloc(repository)
                ..add(const LoadWalletTransactions()),
        ),
        BlocProvider<WalletPaymentsBloc>(
          create: (_) =>
              WalletPaymentsBloc(repository)..add(const LoadWalletPayments()),
        ),
        BlocProvider<WalletActionCubit>(
          create: (_) => WalletActionCubit(repository),
        ),
      ],
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  void _handleRefreshTap() {
    HapticFeedback.lightImpact();
    _refreshOverview();
    context.read<WalletTransactionsBloc>().add(
      const RefreshWalletTransactions(),
    );
    context.read<WalletPaymentsBloc>().add(const RefreshWalletPayments());
  }

  void _refreshOverview() {
    context.read<WalletOverviewBloc>().add(const RefreshWalletOverview());
  }

  Future<void> _refreshTransactions() async {
    _refreshOverview();
    context.read<WalletTransactionsBloc>().add(
      const RefreshWalletTransactions(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _refreshPayments() async {
    context.read<WalletPaymentsBloc>().add(const RefreshWalletPayments());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  bool _onTransactionsScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.extentAfter < 240) {
      context.read<WalletTransactionsBloc>().add(
        const LoadMoreWalletTransactions(),
      );
    }
    return false;
  }

  bool _onPaymentsScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.extentAfter < 240) {
      context.read<WalletPaymentsBloc>().add(const LoadMoreWalletPayments());
    }
    return false;
  }

  Future<void> _openActionSheet(
    WalletSummary summary,
    WalletActionType action,
  ) async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<WalletActionResult?>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<WalletActionCubit>(),
          child: WalletActionBottomSheet(summary: summary, action: action),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'operation_successful'.tr : result.message,
          ),
        ),
      );
      _refreshOverview();
      context.read<WalletTransactionsBloc>().add(
        const RefreshWalletTransactions(),
      );
      context.read<WalletPaymentsBloc>().add(const RefreshWalletPayments());
    } else if (result.message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('wallet_page_title'.tr),
          actions: [
            IconButton(
              tooltip: 'refresh'.tr,
              icon: const Icon(Iconsax.refresh),
              onPressed: _handleRefreshTap,
            ),
          ],
        ),
        body: NestedScrollView(
          physics: const ClampingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: BlocBuilder<WalletOverviewBloc, WalletOverviewState>(
                builder: (context, state) {
                  if (state.isLoading && state.summary == null) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(
                        Spacing.lg,
                        Spacing.lg,
                        Spacing.lg,
                        Spacing.sm,
                      ),
                      child: WalletSummarySkeleton(),
                    );
                  }
                  if (state.errorMessage != null && state.summary == null) {
                    return Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: WalletErrorView(
                        message: 'failed_to_load'.tr,
                        errorDetails: state.errorMessage!,
                        onRetry: _refreshOverview,
                      ),
                    );
                  }
                  final summary = state.summary;
                  if (summary == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.sm,
                    ),
                    child: WalletSummaryCard(
                      summary: summary,
                      isRefreshing: state.isLoading,
                      errorMessage: state.errorMessage,
                      onAction: (action) => _openActionSheet(summary, action),
                      onRefresh: _refreshOverview,
                    ),
                  );
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _WalletTabHeaderDelegate(
                tabBar: TabBar(
                  labelPadding: const EdgeInsets.symmetric(
                    vertical: Spacing.sm,
                  ),
                  tabs: [
                    Tab(text: 'transactions'.tr),
                    Tab(text: 'payments'.tr),
                  ],
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
                dividerColor: theme.dividerColor,
              ),
            ),
          ],
          body: TabBarView(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onTransactionsScroll,
                child: WalletTransactionsTab(onRefresh: _refreshTransactions),
              ),
              NotificationListener<ScrollNotification>(
                onNotification: _onPaymentsScroll,
                child: WalletPaymentsTab(onRefresh: _refreshPayments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _WalletTabHeaderDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.dividerColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;
  final Color dividerColor;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          Divider(height: 1, color: dividerColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_WalletTabHeaderDelegate old) =>
      old.tabBar != tabBar ||
      old.backgroundColor != backgroundColor ||
      old.dividerColor != dividerColor;
}
