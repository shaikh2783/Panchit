import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/instance_manager.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import '../../application/bloc/wallet_packages_cubit.dart';
import '../../data/models/wallet_action_result.dart';
import '../../domain/wallet_repository.dart';
import '../widgets/wallet_packages.dart';
import '../widgets/wallet_shared_widgets.dart';
class WalletPackagesPage extends StatelessWidget {
  const WalletPackagesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<WalletRepository>(context, listen: false);
    return BlocProvider<WalletPackagesCubit>(
      create: (_) => WalletPackagesCubit(repository)..fetchPackages(),
      child: const _WalletPackagesView(),
    );
  }
}
class _WalletPackagesView extends StatelessWidget {
  const _WalletPackagesView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: BlocConsumer<WalletPackagesCubit, WalletPackagesState>(
        listenWhen: (previous, current) =>
            previous.purchaseStatus != current.purchaseStatus,
        listener: (context, state) {
          if (state.purchaseStatus == WalletPackagePurchaseStatus.failure &&
              state.purchaseError != null &&
              state.purchaseError!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.purchaseError!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state.purchaseStatus == WalletPackagePurchaseStatus.success &&
              state.lastPurchaseResult != null) {
            final result = state.lastPurchaseResult!;
            if (result.message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }
            Navigator.of(context).maybePop<WalletActionResult?>(result);
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.scaffoldBackgroundColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () => context
                  .read<WalletPackagesCubit>()
                  .fetchPackages(forceRefresh: true),
              edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _PackagesSliverAppBar(
                    onRefresh: () => context
                        .read<WalletPackagesCubit>()
                        .fetchPackages(forceRefresh: true),
                  ),
                  ..._buildContentSlivers(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
List<Widget> _buildContentSlivers(
  BuildContext context,
  WalletPackagesState state,
) {
  final cubit = context.read<WalletPackagesCubit>();
  if (state.isLoading) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.lg,
          Spacing.xxxl,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const WalletPackageCardSkeleton(),
            childCount: 3,
          ),
        ),
      ),
    ];
  }
  if (state.status == WalletPackagesStatus.failure) {
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
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final package = state.packages[index];
          final isPurchasing =
              state.purchaseStatus == WalletPackagePurchaseStatus.inProgress &&
              state.purchasingPackageId == package.id;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == state.packages.length - 1 ? 0 : Spacing.lg,
            ),
            child: WalletPackageCard(
              package: package,
              onPurchase: () => cubit.purchasePackage(package.id),
              isPurchasing: isPurchasing,
            ),
          );
        }, childCount: state.packages.length),
      ),
    ),
  ];
}
class _PackagesSliverAppBar extends StatelessWidget {
  const _PackagesSliverAppBar({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 300,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Iconsax.refresh),
          onPressed: onRefresh,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 10),
        title: Text(
          'Premium Packages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: const _PackagesHero(),
      ),
    );
  }
}
class _PackagesHero extends StatelessWidget {
  const _PackagesHero();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.95), secondary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -20,
            child: _HeroOrb(color: Colors.white.withOpacity(0.18), size: 180),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: _HeroOrb(color: Colors.white.withOpacity(0.12), size: 220),
          ),
          Positioned(
            top: Get.height * 0.12,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level up your membership',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Unlock reach boosters, verification, and exclusive tools tailored to your growth.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: const [
                    _HeroChip(
                      icon: Iconsax.shield_tick,
                      label: 'Verified status',
                    ),
                    _HeroChip(
                      icon: Iconsax.trend_up,
                      label: 'Growth accelerators',
                    ),
                    _HeroChip(icon: Iconsax.gift, label: 'Premium perks'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
