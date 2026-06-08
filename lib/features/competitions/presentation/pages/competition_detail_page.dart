import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_entry_page.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_leaderboard_page.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_page.dart';

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
        builder: (context) => CompetitionRulesDialog(rules: rules),
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

      final wallet = await api.checkWalletBalance();
      final entryFee = competition.entryFee ?? 0;
      if (!mounted) return;

      if (wallet.balance < entryFee) {
        final shouldAddMoney = await showDialog<bool>(
          context: context,
          builder: (context) => GlassPopupDialog(
            title: 'competition_insufficient_balance_title'.tr,
            message: 'competition_insufficient_balance_msg'.tr,
            primaryLabel: 'add_money'.tr,
            secondaryLabel: 'cancel'.tr,
            icon: Icons.account_balance_wallet_outlined,
          ),
        );
        if (shouldAddMoney == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WalletPage()),
          );
        }
        return;
      }

      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CompetitionEntryPage(competition: competition),
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

  Future<void> _editEntry(
    CompetitionEntryModel entry,
    CompetitionModel competition,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompetitionEntryPage(
          competition: competition,
          existingEntry: entry,
        ),
      ),
    );
    if (updated == true && mounted) {
      _showMessage('competition_entry_updated'.tr);
      _loadDetails();
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
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
              const SizedBox(width: Spacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCheckingWallet ? null : _handlePrimaryAction,
                  child: Text(
                    _isCheckingWallet
                        ? 'competition_checking'.tr
                        : _primaryActionLabel(competition),
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
    final hasBanner = (competition.bannerUrl ?? '').isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
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
                errorBuilder: (_, __, ___) => _buildBannerFallback(theme),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _buildBannerFallback(theme),
              )
            else
              _buildBannerFallback(theme),

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

  Widget _buildBannerFallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.primary.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
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
                onEdit: canEdit ? () => _editEntry(entry, competition) : null,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avatarUrl = _resolveUrl(entry.userAvatar);
    final previewUrl = _resolveUrl(entry.previewUrl);
    final hasPreview = previewUrl != null;
    final hasText = (entry.postText ?? '').trim().isNotEmpty;
    final isVideo = (entry.mediaType ?? '').toLowerCase().contains('video');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                      if (entry.rank != null)
                        Text(
                          '${'competition_rank_prefix'.tr}${entry.rank}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
          if (hasPreview)
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
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Iconsax.gallery,
                          size: 40,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
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
            child: Row(
              children: [
                if (entry.reactionsCount != null) ...[
                  Icon(
                    Icons.favorite_rounded,
                    size: 15,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.reactionsCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                ],
                if (entry.commentsCount != null) ...[
                  Icon(
                    Iconsax.message,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.commentsCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                ],
                if (entry.totalScore != null) ...[
                  Icon(
                    Iconsax.star,
                    size: 15,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.totalScore!.toStringAsFixed(0),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
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
          ),
        ],
      ),
    );
  }
}
