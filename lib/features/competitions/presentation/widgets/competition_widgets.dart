import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/core/theme/widgets/frosted_glass_card.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.primaryButtonLabel,
    required this.onPrimaryTap,
    this.onTap,
    this.secondaryChild,
    this.showCountdown = false,
    this.showRegistrationStart = false,
  });

  final CompetitionModel competition;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback? onTap;
  final Widget? secondaryChild;
  final bool showCountdown;
  final bool showRegistrationStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedGlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      borderRadius: Radii.large,
      blurAmount: 16,
      gradientColors: [
        theme.colorScheme.primary.withValues(alpha: 0.12),
        theme.colorScheme.surface.withValues(alpha: 0.72),
      ],
      borderColor: Colors.white.withValues(alpha: 0.18),
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
                      competition.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((competition.category ?? '').isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        competition.category!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              CompetitionStatusBadge(status: competition.status),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Iconsax.ticket_discount,
                  label: 'Entry Fee',
                  value: formatMoney(
                    competition.entryFee,
                    competition.currencySymbol,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: PrizePoolWidget(
                  amount: competition.prizePool,
                  currencySymbol: competition.currencySymbol,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _InfoRow(
            icon: Iconsax.gallery,
            text: 'Allowed media: ${competition.allowedMediaType.label}',
          ),
          if (showCountdown) ...[
            const SizedBox(height: Spacing.md),
            CompetitionCountdownTimer(
              targetTime: competition.registrationEnd,
              prefix: 'Registration ends in',
              emptyLabel: 'Registration closing soon',
            ),
          ],
          if (showRegistrationStart) ...[
            const SizedBox(height: Spacing.md),
            _InfoRow(
              icon: Iconsax.calendar_1,
              text:
                  'Starts ${formatDateTime(competition.registrationStart) ?? 'TBA'}',
            ),
          ],
          if (secondaryChild != null) ...[
            const SizedBox(height: Spacing.md),
            secondaryChild!,
          ],
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.medium),
                ),
              ),
              child: Text(primaryButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class CompetitionStatusBadge extends StatelessWidget {
  const CompetitionStatusBadge({
    super.key,
    required this.status,
  });

  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      CompetitionStatus.live || CompetitionStatus.registrationOpen => (
          const Color(0xFF14B8A6),
          const Color(0xFF0F766E),
        ),
      CompetitionStatus.upcoming => (
          const Color(0xFF6366F1),
          const Color(0xFF4338CA),
        ),
      CompetitionStatus.voting => (
          const Color(0xFFF59E0B),
          const Color(0xFFD97706),
        ),
      CompetitionStatus.completed => (
          const Color(0xFF22C55E),
          const Color(0xFF15803D),
        ),
      CompetitionStatus.cancelled => (
          const Color(0xFFEF4444),
          const Color(0xFFB91C1C),
        ),
      CompetitionStatus.registrationClosed || CompetitionStatus.unknown => (
          const Color(0xFF64748B),
          const Color(0xFF334155),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.$1, colors.$2]),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PrizePoolWidget extends StatelessWidget {
  const PrizePoolWidget({
    super.key,
    required this.amount,
    this.currencySymbol,
  });

  final double? amount;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    return _MetricTile(
      icon: Iconsax.cup,
      label: 'Prize Pool',
      value: formatMoney(amount, currencySymbol),
    );
  }
}

class CompetitionCountdownTimer extends StatefulWidget {
  const CompetitionCountdownTimer({
    super.key,
    required this.targetTime,
    required this.prefix,
    this.emptyLabel = 'Timer unavailable',
    this.onFinished,
  });

  final DateTime? targetTime;
  final String prefix;
  final String emptyLabel;
  final VoidCallback? onFinished;

  @override
  State<CompetitionCountdownTimer> createState() =>
      _CompetitionCountdownTimerState();
}

class _CompetitionCountdownTimerState extends State<CompetitionCountdownTimer> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant CompetitionCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _remaining = _buildRemaining();

    if (widget.targetTime == null) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = _buildRemaining();
      if (!mounted) return;
      setState(() {
        _remaining = next;
      });
      if (next != null && next <= Duration.zero) {
        widget.onFinished?.call();
      }
    });
  }

  Duration? _buildRemaining() {
    final target = widget.targetTime;
    if (target == null) return null;
    return target.difference(DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _remaining;
    final label = remaining == null || remaining <= Duration.zero
        ? widget.emptyLabel
        : '${widget.prefix} ${formatDuration(remaining)}';

    return Row(
      children: [
        Icon(
          Iconsax.timer_1,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class WinnerRankBadge extends StatelessWidget {
  const WinnerRankBadge({
    super.key,
    required this.rank,
    this.compact = false,
  });

  final int rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = switch (rank) {
      1 => (
          '1st Place Winner',
          const [Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
      2 => (
          '2nd Place Winner',
          const [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
        ),
      _ => (
          '3rd Place Winner',
          const [Color(0xFFCD7F32), Color(0xFF8B5A2B)],
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [style.$2[0], style.$2[1]]),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          ),
          child: Text(
            compact ? '${rank}st Winner'.replaceFirst('3st', '3rd').replaceFirst('2st', '2nd') : style.$1,
            style: TextStyle(
              color: rank == 2 ? Colors.black87 : Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class CompetitionEntryBadge extends StatelessWidget {
  const CompetitionEntryBadge({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  const Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.cup, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileAchievementTag extends StatelessWidget {
  const ProfileAchievementTag({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedGlassCard(
      blurAmount: 12,
      borderRadius: Radii.pill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gradientColors: [
        theme.colorScheme.primary.withValues(alpha: 0.18),
        theme.colorScheme.secondary.withValues(alpha: 0.12),
      ],
      borderColor: Colors.white.withValues(alpha: 0.14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.verify, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassPopupDialog extends StatelessWidget {
  const GlassPopupDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.icon,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlassCard(
        blurAmount: 18,
        borderRadius: Radii.xLarge,
        gradientColors: [
          theme.colorScheme.surface.withValues(alpha: 0.8),
          theme.colorScheme.primary.withValues(alpha: 0.12),
        ],
        borderColor: Colors.white.withValues(alpha: 0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.md),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                if (secondaryLabel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(secondaryLabel!),
                    ),
                  ),
                if (secondaryLabel != null) const SizedBox(width: Spacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompetitionRulesDialog extends StatelessWidget {
  const CompetitionRulesDialog({
    super.key,
    required this.rules,
  });

  final String rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlassCard(
        blurAmount: 18,
        borderRadius: Radii.xLarge,
        gradientColors: [
          theme.colorScheme.surface.withValues(alpha: 0.8),
          theme.colorScheme.primary.withValues(alpha: 0.12),
        ],
        borderColor: Colors.white.withValues(alpha: 0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_outlined, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Competition Rules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  rules,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('I Agree'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompetitionSectionPlaceholder extends StatelessWidget {
  const CompetitionSectionPlaceholder({
    super.key,
    required this.title,
    required this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String title;
  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: FrostedGlassCard(
          borderRadius: Radii.xLarge,
          blurAmount: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.cup, size: 42, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (showRetry && onRetry != null) ...[
                const SizedBox(height: Spacing.lg),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CompetitionWinnerTile extends StatelessWidget {
  const CompetitionWinnerTile({
    super.key,
    required this.winner,
  });

  final CompetitionWinnerModel winner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: [
          WinnerRankBadge(rank: winner.rank, compact: true),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.userName ?? 'Winner',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if ((winner.postText ?? '').isNotEmpty)
                  Text(
                    winner.postText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (winner.prizeAmount != null)
            Text(
              formatMoney(winner.prizeAmount, winner.currencySymbol),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}

class CompetitionHistoryTile extends StatelessWidget {
  const CompetitionHistoryTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final UserCompetitionModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CompetitionCard(
      competition: item.competition,
      onTap: onTap,
      primaryButtonLabel: item.statusLabel ?? 'View Details',
      onPrimaryTap: onTap ?? () {},
      secondaryChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.currentRank != null)
            Text('Current Rank: #${item.currentRank}'),
          if (item.prizeWon != null)
            Text(
              'Prize Won: ${formatMoney(item.prizeWon, item.competition.currencySymbol)}',
            ),
          if ((item.refundStatus ?? '').isNotEmpty)
            Text('Refund: ${item.refundStatus}'),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: Spacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

String formatDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String formatMoney(double? value, String? currencySymbol) {
  final symbol = (currencySymbol ?? '').trim().isEmpty ? '₹' : currencySymbol!;
  final amount = value ?? 0;
  return '$symbol${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
}

String? formatDateTime(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
