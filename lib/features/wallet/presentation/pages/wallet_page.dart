import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late final ScrollController _transactionsController;
  late final ScrollController _paymentsController;
  @override
  void initState() {
    super.initState();
    _transactionsController = ScrollController()
      ..addListener(_onTransactionsScroll);
    _paymentsController = ScrollController()..addListener(_onPaymentsScroll);
  }
  @override
  void dispose() {
    _transactionsController
      ..removeListener(_onTransactionsScroll)
      ..dispose();
    _paymentsController
      ..removeListener(_onPaymentsScroll)
      ..dispose();
    super.dispose();
  }
  void _onTransactionsScroll() {
    if (!_transactionsController.hasClients) return;
    if (_transactionsController.position.extentAfter < 240) {
      context.read<WalletTransactionsBloc>().add(
        const LoadMoreWalletTransactions(),
      );
    }
  }
  void _onPaymentsScroll() {
    if (!_paymentsController.hasClients) return;
    if (_paymentsController.position.extentAfter < 240) {
      context.read<WalletPaymentsBloc>().add(const LoadMoreWalletPayments());
    }
  }
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
    if (!mounted || result == null) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty
                ? 'Wallet updated successfully'
                : result.message,
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Iconsax.refresh),
              onPressed: _handleRefreshTap,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<WalletOverviewBloc, WalletOverviewState>(
              builder: (context, state) {
                if (state.isLoading && state.summary == null) {
                  return const Padding(
                    padding: EdgeInsets.all(Spacing.lg),
                    child: WalletSummarySkeleton(),
                  );
                }
                if (state.errorMessage != null && state.summary == null) {
                  return Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: WalletErrorView(
                      message: 'Unable to load wallet overview',
                      errorDetails: state.errorMessage!,
                      onRetry: _refreshOverview,
                    ),
                  );
                }
                final summary = state.summary;
                if (summary == null) {
                  return const SizedBox.shrink();
                }
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
            const Divider(height: 1),
            const TabBar(
              labelPadding: EdgeInsets.symmetric(vertical: Spacing.sm),
              tabs: [
                Tab(text: 'Transactions'),
                Tab(text: 'Payments'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  WalletTransactionsTab(
                    controller: _transactionsController,
                    onRefresh: _refreshTransactions,
                  ),
                  WalletPaymentsTab(
                    controller: _paymentsController,
                    onRefresh: _refreshPayments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
