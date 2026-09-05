import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/core/theme/panchit_auth_ui.dart';
import 'package:snginepro/core/utils/time_ago.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_leaderboard_page.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/models/post_type_config.dart';
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import 'package:snginepro/features/feed/presentation/pages/edit_post_page.dart';
import 'package:snginepro/features/feed/presentation/widgets/adaptive_video_player.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/domain/wallet_repository.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_recharge_page.dart';

class CompetitionDetailPage extends StatefulWidget {
  const CompetitionDetailPage({
    super.key,
    required this.competitionId,
    this.initialCompetition,
  });

  final int competitionId;
  final CompetitionModel? initialCompetition;

  @override
  State<CompetitionDetailPage> createState() => _CompetitionDetailPageState();
}

class _CompetitionDetailPageState extends State<CompetitionDetailPage> {
  CompetitionModel? _competition;
  bool _isLoading = true;
  bool _isCheckingWallet = false;
  bool _descExpanded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _competition = widget.initialCompetition;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = context.read<CompetitionApiService>();
      final details = await api.getCompetitionDetails(widget.competitionId);
      final entries = await api.getCompetitionEntries(widget.competitionId);
      final winners = await api.getCompetitionWinners(widget.competitionId);

      if (!mounted) return;
      final mergedEntries = <CompetitionEntryModel>[
        ...details.entries,
        ...entries.where(
          (remoteEntry) => !details.entries.any(
            (detailEntry) =>
                detailEntry.id == remoteEntry.id ||
                (detailEntry.postId != null &&
                    detailEntry.postId == remoteEntry.postId),
          ),
        ),
      ];
      setState(() {
        _competition = details.copyWith(entries: mergedEntries, winners: winners);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    final competition = _competition;
    if (competition == null) return;

    if (competition.isCancelled) {
      _showMessage('competition_cancelled_msg'.tr);
      return;
    }

    if (competition.isCompleted) {
      _openLeaderboard();
      return;
    }

    if (competition.isVotingOngoing) {
      _showMessage('competition_voting_entries_closed'.tr);
      _openLeaderboard();
      return;
    }

    if (competition.isRegistrationNotStarted) {
      final shouldNotify = await showDialog<bool>(
        context: context,
        builder: (context) => GlassPopupDialog(
          title: 'competition_starts_soon'.tr,
          message: 'competition_registration_not_started_msg'.tr,
          primaryLabel: 'competition_notify_me'.tr,
          secondaryLabel: 'later'.tr,
          icon: Icons.notifications_active_outlined,
        ),
      );
      if (shouldNotify == true && mounted) {
        await _handleNotifyMe();
      }
      return;
    }

    if (!competition.isRegistrationOpen) {
      _showMessage(
        'competition_registration_closed'.tr,
        isError: true,
      );
      await _loadDetails();
      return;
    }

    if (competition.isJoined) {
      _openLeaderboard();
      return;
    }

    final rules = (competition.rules ?? '').trim();
    if (rules.isNotEmpty) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => CompetitionRulesDialog(
          rules: rules,
          entryFeeLabel: formatMoney(
            competition.entryFee,
            competition.currencySymbol,
          ),
        ),
      );
      if (agreed != true || !mounted) return;
    }

    await _startJoinFlow();
  }

  Future<void> _handleNotifyMe() async {
    final competition = _competition;
    if (competition == null) return;

    try {
      await context.read<CompetitionApiService>().notifyCompetition(competition.id);
      if (!mounted) return;
      setState(() {
        _competition = competition.copyWith(isNotifyEnabled: true);
      });
      _showMessage('competition_reminder_enabled'.tr);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  void _applyPaymentState(
    CompetitionPaymentResponse payment,
    CompetitionModel competition,
  ) {
    if (!mounted) return;
    final resolvedStatus = payment.paymentStatus ?? 'completed';
    setState(() {
      final current = _competition;
      if (current == null || current.id != competition.id) return;
      _competition = current.copyWith(
        isPaymentCompleted: true,
        paymentStatus: resolvedStatus,
        paymentId: payment.paymentId,
        paymentReference: payment.paymentReference,
        paymentPaidAt: payment.paidAt,
        paidAmount: payment.paidAmount ?? current.entryFee,
        walletBalanceAfterPayment: payment.walletBalance,
      );
    });
  }

  Future<bool> _completeWalletPaymentBeforeUpload(
    CompetitionModel competition,
    WalletSummary initialSummary,
  ) async {
    final entryFee = competition.entryFee ?? 0;
    if (entryFee <= 0 || competition.isPaymentCompleted) return true;

    final walletRepository = context.read<WalletRepository>();
    var summary = initialSummary;

    while (mounted) {
      final result = await showDialog<Object?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CompetitionWalletPaymentDialog(
          competition: competition,
          summary: summary,
        ),
      );

      if (!mounted) return false;

      if (result is CompetitionPaymentResponse) {
        _applyPaymentState(result, competition);
        _showMessage(result.message ?? 'Competition entry fee paid successfully.');
        return true;
      }

      if (result == 'recharge') {
        final rechargeResult = await Navigator.of(context).push<dynamic>(
          MaterialPageRoute(
            builder: (_) => WalletRechargePage(summary: summary),
          ),
        );
        if (!mounted || rechargeResult == null) return false;
        summary = await walletRepository.fetchSummary();
        if (!mounted) return false;
        continue;
      }

      return false;
    }

    return false;
  }

  Future<void> _startJoinFlow() async {
    final competition = _competition;
    if (competition == null || _isCheckingWallet) return;

    setState(() => _isCheckingWallet = true);
    try {
      final api = context.read<CompetitionApiService>();
      final eligibility = await api.checkEligibility(competition.id);
      if (!mounted) return;

      if (!eligibility.success &&
          (eligibility.message ?? '').toLowerCase().contains('already')) {
        _showMessage(eligibility.message ?? 'competition_already_joined'.tr);
        await _loadDetails();
        return;
      }

      if (competition.requiresPayment) {
        final walletSummary = await context.read<WalletRepository>().fetchSummary();
        if (!mounted) return;

        final paymentCompleted = await _completeWalletPaymentBeforeUpload(
          competition,
          walletSummary,
        );
        if (!paymentCompleted || !mounted) return;
      }

      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreatePostPageModern(
            competition: competition,
            initialPostType: switch (competition.allowedMediaType) {
              CompetitionAllowedMediaType.imageOnly => PostTypeOption.photos,
              CompetitionAllowedMediaType.videoOnly => PostTypeOption.video,
              CompetitionAllowedMediaType.textOnly => PostTypeOption.text,
              CompetitionAllowedMediaType.all => PostTypeOption.text,
            },
            showPrivacySelector: false,
            initialPrivacy: 'public',
          ),
        ),
      );

      if (submitted == true && mounted) {
        _showMessage('competition_entry_submitted'.tr);
        _loadDetails();
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCheckingWallet = false);
      }
    }
  }

  int? get _currentUserId {
    final auth = context.read<AuthNotifier?>();
    return int.tryParse(auth?.currentUser?['user_id']?.toString() ?? '');
  }

  Future<void> _editEntry(CompetitionEntryModel entry) async {
    final postId = entry.postId;
    if (postId == null) {
      _showMessage('Unable to edit this entry right now.', isError: true);
      return;
    }

    try {
      final postService = PostManagementApiService(
        Provider.of<ApiClient>(context, listen: false),
      );
      final details = await postService.getPostDetails(postId);
      if (!mounted) return;

      final data = details['data'];
      Map<String, dynamic>? postJson;
      if (data is Map<String, dynamic>) {
        if (data['post'] is Map<String, dynamic>) {
          postJson = <String, dynamic>{
            ...Map<String, dynamic>.from(data),
            ...Map<String, dynamic>.from(data['post'] as Map<String, dynamic>),
          };
        } else {
          postJson = Map<String, dynamic>.from(data);
        }
      } else if (details['post'] is Map<String, dynamic>) {
        postJson = Map<String, dynamic>.from(details['post'] as Map<String, dynamic>);
      }

      if (postJson == null || postJson.isEmpty) {
        _showMessage('Unable to load entry post details.', isError: true);
        return;
      }

      final post = Post.fromJson(postJson);
      final updated = await Navigator.of(context).push<Post>(
        MaterialPageRoute(
          builder: (_) => EditPostPage(post: post),
        ),
      );
      if (updated != null && mounted) {
        _showMessage('post_updated_successfully'.tr);
        _loadDetails();
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  void _openLeaderboard() {
    final competition = _competition;
    if (competition == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitionLeaderboardPage(
          competitionId: competition.id,
          competitionName: competition.title,
          initialEntries: competition.leaders.isNotEmpty
              ? competition.leaders
              : competition.entries,
          votingEnd: competition.votingEnd,
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competition = _competition;

    if (_isLoading && competition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('competition_details'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && competition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('competition_details'.tr)),
        body: CompetitionSectionPlaceholder(
          title: 'competition_load_failed'.tr,
          message: _errorMessage!,
          showRetry: true,
          onRetry: _loadDetails,
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(competition!),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                110,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOverviewCard(competition),
                  const SizedBox(height: Spacing.lg),
                  if ((competition.description ?? '').isNotEmpty ||
                      (competition.rules ?? '').isNotEmpty) ...[
                    _buildDescriptionCard(competition),
                    const SizedBox(height: Spacing.lg),
                  ],
                  _buildScheduleCard(competition),
                  const SizedBox(height: Spacing.lg),
                  _buildPrizesCard(competition),
                  const SizedBox(height: Spacing.lg),
                  _buildLeaderboardCard(competition),
                  const SizedBox(height: Spacing.lg),
                  _buildWinnersCard(competition),
                  const SizedBox(height: Spacing.lg),
                  _buildParticipantsSection(competition),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(competition),
    );
  }

  Widget _buildBottomBar(CompetitionModel competition) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.sm,
          ),
          child: Row(
            children: [
              Visibility(
                visible: competition.isRegistrationOpen,
                child: Expanded(
                  child: OutlinedButton(
                    onPressed: _openLeaderboard,
                    child: Text('competition_view_entries'.tr),
                  ),
                ),
              ),
              if (competition.isRegistrationOpen)
                const SizedBox(width: Spacing.md),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _isCheckingWallet
                        ? null
                        : AppColors.verticalBrandGradient,
                    color: _isCheckingWallet
                        ? (isDark ? AppColors.hoverDark : AppColors.hoverLight)
                        : null,
                    borderRadius: BorderRadius.circular(Radii.medium),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.medium),
                      onTap: _isCheckingWallet ? null : _handlePrimaryAction,
                      child: Center(
                        child: _isCheckingWallet
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _primaryActionLabel(competition),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner hero ──────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(CompetitionModel competition) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBanner = (competition.bannerUrl ?? '').isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: PanchitAuthColors.background(isDark),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadDetails,
          icon: const Icon(Icons.refresh),
          color: Colors.white,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image or gradient fallback
            if (hasBanner)
              Image.network(
                competition.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildBannerFallback(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _buildBannerFallback(),
              )
            else
              _buildBannerFallback(),

            // Top scrim for toolbar icons
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Bottom scrim for info content
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Competition info pinned to bottom of banner
            Positioned(
              left: Spacing.lg,
              right: Spacing.lg,
              bottom: Spacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status + category row
                  Row(
                    children: [
                      CompetitionStatusBadge(status: competition.status),
                      if ((competition.category ?? '').isNotEmpty) ...[
                        const SizedBox(width: Spacing.sm),
                        _BannerChip(label: competition.category!),
                      ],
                      const Spacer(),
                      if (competition.isJoined)
                        _BannerChip(
                          label: 'Joined',
                          icon: Icons.check_circle_outline,
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Title
                  Text(
                    competition.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          shadows: const [
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.md),

                  // Stat chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _BannerStatChip(
                          icon: Iconsax.ticket_discount,
                          label: 'Entry Fee',
                          value: formatMoney(
                            competition.entryFee,
                            competition.currencySymbol,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        _BannerStatChip(
                          icon: Iconsax.cup,
                          label: 'Prize Pool',
                          value: formatMoney(
                            competition.prizePool,
                            competition.currencySymbol,
                          ),
                        ),
                        if (competition.totalParticipants != null) ...[
                          const SizedBox(width: Spacing.sm),
                          _BannerStatChip(
                            icon: Iconsax.people,
                            label: 'Participants',
                            value: '${competition.totalParticipants}',
                          ),
                        ],
                        const SizedBox(width: Spacing.sm),
                        _BannerStatChip(
                          icon: Iconsax.gallery,
                          label: 'Media',
                          value: competition.allowedMediaType.label,
                        ),
                      ],
                    ),
                  ),

                  // Countdown
                  if (competition.isRegistrationOpen) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationEnd,
                      prefix: 'competition_closes_in'.tr,
                      emptyLabel: 'competition_closing_soon'.tr,
                    ),
                  ] else if (competition.isRegistrationNotStarted) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationStart,
                      prefix: 'competition_opens_in'.tr,
                      emptyLabel: 'competition_opening_soon'.tr,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.verticalBrandGradient,
      ),
      child: Center(
        child: Icon(
          Iconsax.cup,
          size: 72,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  // ── Section cards ────────────────────────────────────────────────────────────

  Widget _buildOverviewCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'competition_overview'.tr,
      icon: Iconsax.info_circle,
      child: Column(
        children: [
          _detailRow('competition_category'.tr, competition.category ?? 'competition_general'.tr),
          _detailRow('competition_allowed_media'.tr, competition.allowedMediaType.label),
          _detailRow(
            'competition_entry_fee'.tr,
            formatMoney(competition.entryFee, competition.currencySymbol),
          ),
          _detailRow(
            'competition_prize_pool'.tr,
            formatMoney(competition.prizePool, competition.currencySymbol),
          ),
          if (competition.minimumUsersRequired != null)
            _detailRow(
              'competition_minimum_users'.tr,
              '${competition.minimumUsersRequired}',
            ),
          if (competition.totalParticipants != null)
            _detailRow(
              'competition_participants'.tr,
              '${competition.totalParticipants}',
            ),
          _detailRow('competition_status'.tr, competition.status.label),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(CompetitionModel competition) {
    final theme = Theme.of(context);
    final description = (competition.description ?? '').trim();
    final rules = (competition.rules ?? '').trim();
    final ruleItems = _parseRules(rules);
    const descCollapseAt = 180;
    final descLong = description.length > descCollapseAt;

    return _sectionCard(
      title: 'competition_about'.tr,
      icon: Iconsax.document_text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description ──────────────────────────────────────────────────
          if (description.isNotEmpty) ...[
            Text(
              _descExpanded || !descLong
                  ? description
                  : '${description.substring(0, descCollapseAt)}…',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
            ),
            if (descLong) ...[
              const SizedBox(height: Spacing.xs),
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Text(
                  _descExpanded ? 'competition_show_less'.tr : 'competition_read_more'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],

          // ── Rules ────────────────────────────────────────────────────────
          if (ruleItems.isNotEmpty) ...[
            if (description.isNotEmpty) const SizedBox(height: Spacing.lg),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(Radii.medium),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'competition_rules_header'.tr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      '${ruleItems.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // Rule items
            ...ruleItems.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          rule,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.55,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Splits a rules string into individual items, stripping leading
  /// numbers/bullets so the UI can render its own numbering.
  List<String> _parseRules(String raw) {
    if (raw.isEmpty) return const [];
    final lines = raw
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    // If every line starts with a number/bullet, strip that prefix.
    final numbered = RegExp(r'^[\d]+[.)]\s*');
    final bulleted = RegExp(r'^[-•*]\s*');
    return lines.map((l) {
      return l
          .replaceFirst(numbered, '')
          .replaceFirst(bulleted, '')
          .trim();
    }).where((l) => l.isNotEmpty).toList(growable: false);
  }

  Widget _buildScheduleCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'competition_schedule'.tr,
      icon: Iconsax.calendar_1,
      child: Column(
        children: [
          _detailRow(
            'competition_registration_start'.tr,
            formatDateTime(competition.registrationStart) ?? 'competition_tba'.tr,
          ),
          _detailRow(
            'competition_registration_end'.tr,
            formatDateTime(competition.registrationEnd) ?? 'competition_tba'.tr,
          ),
          _detailRow(
            'competition_voting_end'.tr,
            formatDateTime(competition.votingEnd) ?? 'competition_tba'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildPrizesCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'competition_prize_distribution'.tr,
      icon: Iconsax.medal_star,
      child: Column(
        children: competition.prizes.isEmpty
            ? [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('competition_no_prizes'.tr),
                ),
              ]
            : competition.prizes
                .map(
                  (prize) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _detailRow(
                      prize.displayTitle,
                      formatMoney(prize.amount, prize.currencySymbol),
                    ),
                  ),
                )
                .toList(growable: false),
      ),
    );
  }

  Widget _buildLeaderboardCard(CompetitionModel competition) {
    final leaders = competition.leaders.isNotEmpty
        ? competition.leaders
        : competition.entries.take(3).toList(growable: false);

    return _sectionCard(
      title: 'competition_leaderboard'.tr,
      icon: Iconsax.ranking,
      trailing: TextButton(
        onPressed: _openLeaderboard,
        child: Text('view_all'.tr),
      ),
      child: leaders.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text('competition_leaderboard_empty'.tr),
            )
          : Column(
              children: leaders.take(3).map((entry) {
                final rank = entry.rank ?? (leaders.indexOf(entry) + 1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Row(
                    children: [
                      WinnerRankBadge(
                        rank: rank,
                        compact: true,
                        showLabel: competition.isCompleted,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          entry.userName ?? 'competition_participant_default'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (entry.totalScore != null)
                        Text(
                          entry.totalScore!.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Widget _buildWinnersCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'competition_winners'.tr,
      icon: Iconsax.crown_1,
      child: competition.winners.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text('competition_winners_empty'.tr),
            )
          : Column(
              children: competition.winners
                  .take(3)
                  .map((winner) => CompetitionWinnerTile(winner: winner))
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildParticipantsSection(CompetitionModel competition) {
    final currentUserId = _currentUserId;
    final myEntries = currentUserId != null
        ? competition.entries
            .where((e) => e.userId == currentUserId)
            .toList(growable: false)
        : const <CompetitionEntryModel>[];

    // Hide section entirely when user hasn't joined and no entry found
    if (!competition.isJoined && myEntries.isEmpty) return const SizedBox.shrink();

    final canEdit = competition.isRegistrationOpen;
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Radii.medium),
                ),
                child: Icon(
                  Iconsax.gallery,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'competition_my_entry'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        // Empty state when joined but entry not yet visible
        if (myEntries.isEmpty)
          Text(
            'competition_no_entry_yet'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          )
        else
          ...myEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: _CompetitionEntryCard(
                entry: entry,
                mediaAsset: mediaAsset,
                currencySymbol: competition.currencySymbol,
                canEdit: canEdit,
                onEdit: canEdit ? () => _editEntry(entry) : null,
                isCompleted: competition.isCompleted,
              ),
            ),
          ),
      ],
    );
  }

  // ── Shared card shell ────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.medium),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: Spacing.md),
            const Divider(height: 1),
            const SizedBox(height: Spacing.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark.withValues(alpha: 0.65)
                    : AppColors.textPrimaryLight.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _primaryActionLabel(CompetitionModel competition) {
    if (competition.isCancelled) return 'competition_action_cancelled'.tr;
    if (competition.isCompleted) return 'competition_action_view_winners'.tr;
    if (competition.isVotingOngoing) return 'competition_action_voting_ongoing'.tr;
    if (competition.isRegistrationNotStarted) {
      return competition.isNotifyEnabled
          ? 'competition_action_reminder_enabled'.tr
          : 'competition_notify_me'.tr;
    }
    if (competition.isJoined) return 'competition_action_view_my_entry'.tr;
    if (competition.isRegistrationOpen) return 'competition_action_join'.tr;
    return 'competition_starts_soon'.tr;
  }
}

class _CompetitionWalletPaymentDialog extends StatefulWidget {
  const _CompetitionWalletPaymentDialog({
    required this.competition,
    required this.summary,
  });

  final CompetitionModel competition;
  final WalletSummary summary;

  @override
  State<_CompetitionWalletPaymentDialog> createState() =>
      _CompetitionWalletPaymentDialogState();
}

class _CompetitionWalletPaymentDialogState
    extends State<_CompetitionWalletPaymentDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _onPayPressed() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final api = context.read<CompetitionApiService>();
      final payment = await api.payCompetitionWithWallet(widget.competition.id);
      if (!mounted) return;
      Navigator.of(context).pop(payment);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      final normalized = message.toLowerCase();
      if (normalized.contains('already paid') ||
          normalized.contains('already completed') ||
          normalized.contains('payment completed')) {
        Navigator.of(context).pop(
          CompetitionPaymentResponse(
            success: true,
            message: message,
            paymentStatus: 'completed',
          ),
        );
        return;
      }
      setState(() {
        _isProcessing = false;
        _errorMessage = message.replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    final isSmall = screenWidth < 360;

    final dialogPadding = isSmall ? Spacing.md : Spacing.lg;
    final headerIconSize = isSmall ? 36.0 : 44.0;
    final tileIconBoxSize = isSmall ? 32.0 : 38.0;
    final tileIconSize = isSmall ? 15.0 : 18.0;

    final wallet = widget.summary.wallet;
    final currencySymbol = wallet.currencySymbol.isNotEmpty
        ? wallet.currencySymbol
        : (widget.competition.currencySymbol ?? wallet.currency);
    final balance = wallet.balance;
    final entryFee = widget.competition.entryFee ?? 0;
    final remaining = balance - entryFee;
    final hasEnoughBalance = balance >= entryFee;

    Widget buildAmountTile({
      required IconData icon,
      required String label,
      required String value,
      Color? iconColor,
      Color? valueColor,
    }) {
      return Container(
        padding: EdgeInsets.all(isSmall ? Spacing.sm : Spacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.hoverLight,
          borderRadius: BorderRadius.circular(Radii.large),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: tileIconBoxSize,
              height: tileIconBoxSize,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: tileIconSize,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: isSmall ? Spacing.xs : Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: (isSmall
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelMedium)
                        ?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: (isSmall
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.85,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xLarge),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: headerIconSize,
                      height: headerIconSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: isSmall ? 18 : 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmall ? Spacing.sm : Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'competition_payment_title'.tr,
                            style: (isSmall
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.titleLarge)
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.competition.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? Spacing.sm : Spacing.md),
                Text(
                  hasEnoughBalance
                      ? 'competition_payment_review_msg'.tr
                      : 'competition_payment_low_balance_msg'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                SizedBox(height: isSmall ? Spacing.md : Spacing.lg),
                buildAmountTile(
                  icon: Iconsax.wallet_money,
                  label: 'competition_current_balance'.tr,
                  value: formatMoney(balance, currencySymbol),
                ),
                SizedBox(height: isSmall ? Spacing.xs : Spacing.sm),
                buildAmountTile(
                  icon: Iconsax.ticket_discount,
                  label: 'competition_entry_fee'.tr,
                  value: formatMoney(entryFee, currencySymbol),
                  iconColor: Colors.amber[800],
                  valueColor: Colors.amber[900],
                ),
                SizedBox(height: isSmall ? Spacing.xs : Spacing.sm),
                buildAmountTile(
                  icon: remaining >= 0
                      ? Iconsax.tick_circle
                      : Iconsax.info_circle,
                  label: remaining >= 0
                      ? 'competition_balance_after_payment'.tr
                      : 'competition_balance_shortfall'.tr,
                  value: formatMoney(remaining.abs(), currencySymbol),
                  iconColor: remaining >= 0
                      ? AppColors.success
                      : theme.colorScheme.error,
                  valueColor: remaining >= 0
                      ? AppColors.success
                      : theme.colorScheme.error,
                ),
                if (!hasEnoughBalance) ...[
                  SizedBox(height: isSmall ? Spacing.sm : Spacing.md),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmall ? Spacing.sm : Spacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.error.withValues(alpha: 0.18)
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(Radii.large),
                    ),
                    child: Text(
                      'competition_insufficient_balance_msg'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  SizedBox(height: isSmall ? Spacing.sm : Spacing.md),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmall ? Spacing.sm : Spacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.error.withValues(alpha: 0.18)
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(Radii.large),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: isSmall ? Spacing.md : Spacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(null),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    SizedBox(width: isSmall ? Spacing.sm : Spacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : hasEnoughBalance
                                ? _onPayPressed
                                : () => Navigator.of(context).pop('recharge'),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                hasEnoughBalance
                                    ? 'competition_pay_from_wallet'.tr
                                    : 'competition_recharge_wallet'.tr,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private banner widgets ───────────────────────────────────────────────────

class _BannerStatChip extends StatelessWidget {
  const _BannerStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.medium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Radii.medium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
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
    );
  }
}

// ── Competition entry card (PostCard-style) ───────────────────────────────────

class _CompetitionEntryCard extends StatelessWidget {
  const _CompetitionEntryCard({
    required this.entry,
    required this.mediaAsset,
    this.currencySymbol,
    this.canEdit = false,
    this.onEdit,
    this.isCompleted = false,
  });

  final CompetitionEntryModel entry;
  final Uri Function(String) mediaAsset;
  final String? currencySymbol;
  final bool canEdit;
  final VoidCallback? onEdit;
  final bool isCompleted;

  String? _resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return mediaAsset(raw).toString();
  }

  String _formatCount(int? value) {
    final count = value ?? 0;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return '$count';
  }

  IconData _privacyIcon(String? privacy) {
    switch ((privacy ?? '').toLowerCase()) {
      case 'friends':
        return Iconsax.people;
      case 'private':
      case 'only_me':
      case 'only me':
        return Iconsax.lock;
      default:
        return Icons.public;
    }
  }

  String _privacyLabel(String? privacy) {
    switch ((privacy ?? '').toLowerCase()) {
      case 'friends':
        return 'friends'.tr;
      case 'private':
      case 'only_me':
      case 'only me':
        return 'only_me'.tr;
      default:
        return 'public'.tr;
    }
  }

  DateTime? _parsePublishedAt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      if (value.contains('T')) {
        return DateTime.parse(value);
      }
      if (value.contains(' ')) {
        return DateTime.parse('${value.replaceFirst(' ', 'T')}Z');
      }
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatPublishedAt(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final formatted = TimeAgo.formatFromString(value);
    final looksLikeTranslationKey =
        RegExp(r'^[a-z0-9_]+$').hasMatch(formatted) ||
        formatted.contains('_ago_');
    if (!looksLikeTranslationKey) {
      return formatted;
    }
    final parsed = _parsePublishedAt(value)?.toLocal();
    if (parsed == null) return formatted;
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(parsed),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '${localizations.formatShortDate(parsed)} $formattedTime';
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCountChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.hoverLight,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avatarUrl = _resolveUrl(entry.userAvatar);
    final previewUrl = _resolveUrl(entry.previewUrl);
    final hasText = (entry.postText ?? '').trim().isNotEmpty;
    final isVideo = (entry.mediaType ?? '').toLowerCase().contains('video');
    final resolvedVideoUrl = _resolveUrl(entry.videoUrl);
    final hasPreview = previewUrl != null;
    final hasVideo = isVideo && resolvedVideoUrl != null;
    final postVideo = hasVideo
        ? PostVideo(
            originalSource: resolvedVideoUrl,
            availableSources: const {},
            thumbnail: previewUrl ?? '',
            categoryName: '',
            viewCount: entry.viewsCount ?? 0,
          )
        : null;
    final metaItems = <Widget>[
      if ((entry.publishedAt ?? '').trim().isNotEmpty)
        _buildMetaItem(
          context,
          icon: Iconsax.clock,
          text: _formatPublishedAt(context, entry.publishedAt),
        ),
      if ((entry.privacy ?? '').trim().isNotEmpty)
        _buildMetaItem(
          context,
          icon: _privacyIcon(entry.privacy),
          text: _privacyLabel(entry.privacy),
        ),
      if ((entry.mediaType ?? '').trim().isNotEmpty)
        _buildMetaItem(
          context,
          icon: isVideo ? Iconsax.video_play : Iconsax.gallery,
          text: isVideo ? 'video'.tr : 'image'.tr,
        ),
    ];
    final countChips = <Widget>[
      if ((entry.reactionsCount ?? 0) > 0)
        _buildCountChip(
          context,
          icon: Icons.favorite_rounded,
          iconColor: AppColors.like,
          text: '${_formatCount(entry.reactionsCount)} ${'likes_label'.tr}',
        ),
      if ((entry.reviewsCount ?? 0) > 0)
        _buildCountChip(
          context,
          icon: Iconsax.star,
          iconColor: Colors.amber[700],
          text: 'post_reviews'.trParams({
            'count': _formatCount(entry.reviewsCount),
          }),
        ),
      if ((entry.viewsCount ?? 0) > 0)
        _buildCountChip(
          context,
          icon: Iconsax.eye,
          text: 'post_views'.trParams({
            'count': _formatCount(entry.viewsCount),
          }),
        ),
      if ((entry.commentsCount ?? 0) > 0)
        _buildCountChip(
          context,
          icon: Iconsax.message,
          text: '${_formatCount(entry.commentsCount)} ${'comments'.tr}',
        ),
      if ((entry.sharesCount ?? 0) > 0)
        _buildCountChip(
          context,
          icon: Iconsax.repeat,
          text: 'post_shares2'.trParams({
            'count': _formatCount(entry.sharesCount),
          }),
        ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (author row) ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.sm,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.userName ?? 'competition_participant_default'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (entry.rank != null)
                            Text(
                              '${'competition_rank_prefix'.tr}${entry.rank}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ...metaItems,
                        ],
                      ),
                    ],
                  ),
                ),
                // Rank badge for top 3
                if (entry.rank != null && entry.rank! <= 3)
                  WinnerRankBadge(
                    rank: entry.rank!,
                    compact: true,
                    showLabel: isCompleted,
                  ),
              ],
            ),
          ),

          // ── Post text ─────────────────────────────────────────────────────
          if (hasText)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.sm,
              ),
              child: Text(
                entry.postText!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),

          // ── Media preview ─────────────────────────────────────────────────
          if (hasVideo && postVideo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: ClipRRect(
                borderRadius: entry.rank != null && entry.rank! <= 3
                    ? BorderRadius.zero
                    : BorderRadius.circular(Radii.large),
                child: AdaptiveVideoPlayer(
                  isFullscreen: false,
                  startMuted: true,
                  autoplayWhenVisible: false,
                  video: postVideo,
                  mediaResolver: mediaAsset,
                ),
              ),
            )
          else if (hasPreview)
            ClipRRect(
              borderRadius: entry.rank != null && entry.rank! <= 3
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      bottomLeft: Radius.circular(Radii.large),
                      bottomRight: Radius.circular(Radii.large),
                    ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: previewUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 220,
                      color: isDark ? AppColors.cardDark : AppColors.hoverLight,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      color: isDark ? AppColors.cardDark : AppColors.hoverLight,
                      child: Center(
                        child: Icon(
                          Iconsax.gallery,
                          size: 40,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  // Video play overlay
                  if (isVideo)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Footer stats ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (countChips.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: countChips,
                  ),
                if (countChips.isNotEmpty &&
                    (entry.totalScore != null ||
                        (entry.prizeAmount != null && entry.prizeAmount! > 0) ||
                        (canEdit && onEdit != null)))
                  const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    if (entry.totalScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.totalScore!.toStringAsFixed(0),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (entry.prizeAmount != null && entry.prizeAmount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          formatMoney(entry.prizeAmount, currencySymbol),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (canEdit && onEdit != null) ...[
                      const SizedBox(width: Spacing.xs),
                      TextButton.icon(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: Text('edit'.tr),
                      ),
                    ],
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
