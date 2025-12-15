import 'dart:ui' show ImageFilter;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/profile_completion_model.dart';
import '../../data/models/user_profile_model.dart';
import '../pages/profile_completion_details_page.dart';
class ProfileCompletionCard extends StatelessWidget {
  final ProfileCompletionData completionData;
  final UserProfile? profile;
  final VoidCallback? onTap;
  const ProfileCompletionCard({
    super.key,
    required this.completionData,
    this.profile,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isComplete = completionData.isComplete;
    // ✅ تأكدنا أن النوع int (كان num قبل كذا)
    final int percentage = completionData.completionPercentage.clamp(0, 100).toInt();
    // Dynamic color palette based on completion percentage
    final Palette p = _paletteFor(percentage, cs);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _SurfaceCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [p.base.withOpacity(0.10), p.base.withOpacity(0.22)]
              : [p.base.withOpacity(0.06), p.base.withOpacity(0.14)],
        ),
        borderColor: p.base.withOpacity(0.25),
        child: Material( // ✅ عشان يظهر الـ ripple تبع InkWell
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _IconBadge(
                        icon: isComplete
                            ? Icons.verified_rounded
                            : Icons.account_circle_outlined,
                        color: p.base,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isComplete
                                  ? 'Your profile is complete!'
                                  : 'Complete Your Profile',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isComplete
                                  ? 'Great! All information is complete'
                                  : '${completionData.missingSteps} ${completionData.missingSteps == 1 ? 'step remaining' : 'steps remaining'},',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isComplete)
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Progress + Stats
                  Row(
                    children: [
                      _ArcProgress(
                        size: 110,
                        progress: percentage / 100,
                        trackColor: cs.surfaceContainerHighest.withOpacity(0.35),
                        gradientColors: [p.base, p.accent],
                        textColor: p.base,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _statRow(
                              context,
                              icon: Icons.check_circle_rounded,
                              label: 'Completed',
                              value: '${completionData.completedSteps}',
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _statRow(
                              context,
                              icon: Icons.pending_rounded,
                              label: 'Remaining',
                              value: '${completionData.missingSteps}',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _statRow(
                              context,
                              icon: Icons.format_list_numbered_rounded,
                              label: 'Total',
                              value: '${completionData.totalSteps}',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Missing fields
                  if (!isComplete && completionData.missingFields.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Required Fields:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in completionData.missingFields.take(6))
                          _FieldChip(field: f),
                      ],
                    ),
                    if (completionData.missingFields.length > 6) ...[
                      const SizedBox(height: 8),
                      Text(
                        'and ${completionData.missingFields.length - 6} more fields…',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                  // Actions
                  if (!isComplete) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (profile != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileCompletionDetailsPage(
                                      initialCompletionData: completionData,
                                      profile: profile!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline_rounded, size: 18),
                              label: const Text('Details'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: p.base),
                                foregroundColor: p.base,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (profile != null) const SizedBox(width: 12),
                        Expanded(
                          flex: profile != null ? 2 : 1,
                          child: ElevatedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Complete Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: p.base,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ——— Helpers ———
  static Widget _statRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
  static Palette _paletteFor(int percentage, ColorScheme cs) {
    if (percentage >= 90) return Palette(cs.primary, cs.tertiary);
    if (percentage >= 70) return Palette(cs.tertiary, cs.primary);
    if (percentage >= 50) return Palette(Colors.orange, cs.tertiary);
    return Palette(Colors.red, cs.errorContainer);
  }
}
// ——— Sub-widgets ———
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final Color borderColor;
  const _SurfaceCard({
    required this.child,
    required this.gradient,
    required this.borderColor,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Smooth gradient background
          Container(
            decoration: BoxDecoration(
              gradient: gradient,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Subtle glass effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.04),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [color.withOpacity(0.15), color.withOpacity(0.35)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
class _ArcProgress extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  final Color trackColor;
  final List<Color> gradientColors;
  final Color textColor;
  const _ArcProgress({
    required this.size,
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _ArcPainter(
              progress: value,
              trackColor: trackColor,
              gradientColors: gradientColors,
              strokeWidth: 10,
            ),
            child: Center(
              child: Text(
                '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class _ArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color trackColor;
  final List<Color> gradientColors;
  final double strokeWidth;
  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
    required this.strokeWidth,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    // Background path (full circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );
    // Progress path with circular gradient shader
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: gradientColors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      sweepPaint,
    );
  }
  @override
  bool shouldRepaint(covariant _ArcPainter old) {
    return old.progress != progress ||
        old.trackColor != trackColor ||
        old.strokeWidth != strokeWidth ||
        old.gradientColors != gradientColors;
  }
}
class _FieldChip extends StatelessWidget {
  final MissingField field;
  const _FieldChip({required this.field});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color c = field.required ? Colors.red : Colors.orange;
    return Container(
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        border: Border.all(color: c.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(field.icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            field.labelAr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
// Simple color palette
class Palette {
  final Color base;
  final Color accent;
  const Palette(this.base, this.accent);
}
