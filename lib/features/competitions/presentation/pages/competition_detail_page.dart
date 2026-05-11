import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
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
      setState(() {
        _competition = details.copyWith(entries: entries, winners: winners);
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
      _showMessage('This competition has been cancelled.');
      return;
    }

    if (competition.isCompleted) {
      _openLeaderboard();
      return;
    }

    if (competition.isVotingOngoing) {
      _showMessage('Voting is ongoing. Entries are closed.');
      _openLeaderboard();
      return;
    }

    if (competition.isRegistrationNotStarted) {
      final shouldNotify = await showDialog<bool>(
        context: context,
        builder: (context) => const GlassPopupDialog(
          title: 'Starts Soon',
          message:
              'Registration has not started yet. Enable notifications and we will remind you when the competition opens.',
          primaryLabel: 'Notify Me',
          secondaryLabel: 'Later',
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
        'Registration is closed for this competition.',
        isError: true,
      );
      await _loadDetails();
      return;
    }

    if (competition.isJoined) {
      _openLeaderboard();
      return;
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
      _showMessage('Competition reminder enabled.');
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
        _showMessage(eligibility.message ?? 'You have already joined this competition.');
        await _loadDetails();
        return;
      }

      final wallet = await api.checkWalletBalance();
      final entryFee = competition.entryFee ?? 0;
      if (!mounted) return;

      if (wallet.balance < entryFee) {
        final shouldAddMoney = await showDialog<bool>(
          context: context,
          builder: (context) => const GlassPopupDialog(
            title: 'Insufficient Balance',
            message:
                'Insufficient Balance. Please recharge your wallet to join.',
            primaryLabel: 'Add Money',
            secondaryLabel: 'Cancel',
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
        _showMessage('Competition entry submitted successfully.');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competition Details'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading && competition == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && competition == null
              ? CompetitionSectionPlaceholder(
                  title: 'Unable to load competition',
                  message: _errorMessage!,
                  showRetry: true,
                  onRetry: _loadDetails,
                )
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(Spacing.lg),
                    children: [
                      if (competition != null) ...[
                        _buildHero(competition),
                        const SizedBox(height: Spacing.lg),
                        _buildOverviewCard(competition),
                        const SizedBox(height: Spacing.lg),
                        _buildScheduleCard(competition),
                        const SizedBox(height: Spacing.lg),
                        _buildPrizesCard(competition),
                        const SizedBox(height: Spacing.lg),
                        _buildLeaderboardCard(competition),
                        const SizedBox(height: Spacing.lg),
                        _buildWinnersCard(competition),
                        const SizedBox(height: Spacing.xxxl),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: competition == null
          ? null
          : SafeArea(
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openLeaderboard,
                        child: const Text('View Entries'),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCheckingWallet ? null : _handlePrimaryAction,
                        child: Text(
                          _isCheckingWallet
                              ? 'Checking...'
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

  Widget _buildHero(CompetitionModel competition) {
    final theme = Theme.of(context);
    return CompetitionCard(
      competition: competition,
      primaryButtonLabel: _primaryActionLabel(competition),
      onPrimaryTap: _handlePrimaryAction,
      showCountdown: competition.isRegistrationOpen,
      showRegistrationStart: competition.isRegistrationNotStarted,
      secondaryChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((competition.description ?? '').isNotEmpty)
            Text(
              competition.description!,
              style: theme.textTheme.bodyMedium,
            ),
          if ((competition.rules ?? '').isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              competition.rules!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'Overview',
      child: Column(
        children: [
          _detailRow('Category', competition.category ?? 'General'),
          _detailRow('Allowed Media', competition.allowedMediaType.label),
          _detailRow(
            'Entry Fee',
            formatMoney(competition.entryFee, competition.currencySymbol),
          ),
          _detailRow(
            'Prize Pool',
            formatMoney(competition.prizePool, competition.currencySymbol),
          ),
          if (competition.minimumUsersRequired != null)
            _detailRow(
              'Minimum Users',
              '${competition.minimumUsersRequired}',
            ),
          if (competition.totalParticipants != null)
            _detailRow(
              'Participants',
              '${competition.totalParticipants}',
            ),
          _detailRow('Status', competition.status.label),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'Schedule',
      child: Column(
        children: [
          _detailRow(
            'Registration Start',
            formatDateTime(competition.registrationStart) ?? 'TBA',
          ),
          _detailRow(
            'Registration End',
            formatDateTime(competition.registrationEnd) ?? 'TBA',
          ),
          _detailRow(
            'Voting End',
            formatDateTime(competition.votingEnd) ?? 'TBA',
          ),
        ],
      ),
    );
  }

  Widget _buildPrizesCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'Prize Distribution',
      child: Column(
        children: competition.prizes.isEmpty
            ? [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Prize details are not available yet.'),
                ),
              ]
            : competition.prizes.map((prize) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: _detailRow(
                    prize.displayTitle,
                    formatMoney(prize.amount, prize.currencySymbol),
                  ),
                );
              }).toList(growable: false),
      ),
    );
  }

  Widget _buildLeaderboardCard(CompetitionModel competition) {
    final leaders = competition.leaders.isNotEmpty
        ? competition.leaders
        : competition.entries.take(3).toList(growable: false);

    return _sectionCard(
      title: 'Leaderboard',
      trailing: TextButton(
        onPressed: _openLeaderboard,
        child: const Text('Open'),
      ),
      child: leaders.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text('Leaderboard will appear once entries are available.'),
            )
          : Column(
              children: leaders.take(3).map((entry) {
                final rank = entry.rank ?? (leaders.indexOf(entry) + 1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Row(
                    children: [
                      WinnerRankBadge(rank: rank, compact: true),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(entry.userName ?? 'Participant'),
                      ),
                      if (entry.totalScore != null)
                        Text(entry.totalScore!.toStringAsFixed(0)),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Widget _buildWinnersCard(CompetitionModel competition) {
    return _sectionCard(
      title: 'Winners',
      child: competition.winners.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text('Winner details will be visible after completion.'),
            )
          : Column(
              children: competition.winners
                  .take(3)
                  .map((winner) => CompetitionWinnerTile(winner: winner))
                  .toList(growable: false),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: Spacing.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _primaryActionLabel(CompetitionModel competition) {
    if (competition.isCancelled) return 'Cancelled / Refunded';
    if (competition.isCompleted) return 'View Winners';
    if (competition.isVotingOngoing) return 'Voting Ongoing';
    if (competition.isRegistrationNotStarted) {
      return competition.isNotifyEnabled ? 'Reminder Enabled' : 'Notify Me';
    }
    if (competition.isJoined) return 'View My Entry';
    if (competition.isRegistrationOpen) return 'Join Competition';
    return 'Starts Soon';
  }
}
