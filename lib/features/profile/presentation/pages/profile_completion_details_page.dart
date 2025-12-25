import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../data/models/profile_completion_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/profile_api_service.dart';
import '../../../../core/network/api_client.dart';
import 'profile_edit_page.dart';

class ProfileCompletionDetailsPage extends StatefulWidget {
  final ProfileCompletionData initialCompletionData;
  final UserProfile profile;

  const ProfileCompletionDetailsPage({
    super.key,
    required this.initialCompletionData,
    required this.profile,
  });

  @override
  State<ProfileCompletionDetailsPage> createState() =>
      _ProfileCompletionDetailsPageState();
}

class _ProfileCompletionDetailsPageState
    extends State<ProfileCompletionDetailsPage> {
  late ProfileCompletionData completionData;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    completionData = widget.initialCompletionData;
  }

  Future<void> _refreshCompletionData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final apiClient = context.read<ApiClient>();
      final profileService = ProfileApiService(apiClient);
      final response = await profileService.getProfileCompletion();

      if (!mounted) return;
      setState(() {
        completionData = response.data;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(profile: widget.profile),
      ),
    );

    if (result == true && mounted) {
      await _refreshCompletionData();

      if (completionData.isComplete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            content: Row(
              children: const [
                Icon(Iconsax.magic_star, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 Great! Your profile is 100% complete',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  Color _progressColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final percentage = completionData.completionPercentage.clamp(0, 100);
    final progressColor = _progressColor(percentage);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCompletionData,
        edgeOffset: 100,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 220,
              elevation: 0,
              backgroundColor: cs.surface.withOpacity(0.85),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: FlexibleSpaceBar(
                    title: const Text('Complete Profile'),
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 16.0,
                      bottom: 16.0,
                    ),
                    centerTitle: false,
                    background: _HeaderProgress(
                      percentage: percentage.toDouble(),
                      color: progressColor,
                    ),
                  ),
                ),
              ),
            ),

            // الإحصائيات المختصرة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _StatsRow(
                  completed: completionData.completedSteps,
                  missing: completionData.missingSteps,
                  total: completionData.totalSteps,
                ),
              ),
            ),

            // الحقول المكتملة
            if (completionData.completedFields.isNotEmpty)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionCard(
                    title: 'Completed Fields',
                    icon: Iconsax.task_square,
                    color: Colors.green,
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        for (final field in completionData.completedFields) ...[
                          _CompletedTile(fieldName: field),
                          const SizedBox(height: 6),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // الحقول المطلوبة
            if (completionData.missingFields.isNotEmpty)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionCard(
                    title: 'Required Fields',
                    icon: Iconsax.edit,
                    color: progressColor,
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        for (final f in completionData.missingFields) ...[
                          _MissingTile(field: f, onTap: _navigateToEdit),
                          const SizedBox(height: 6),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // زر التعديل السفلي
      bottomNavigationBar: completionData.isComplete
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withOpacity(0.85),
                        progressColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _navigateToEdit,
                    icon: const Icon(Iconsax.edit, size: 18, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ---------------- Sub-Widgets ----------------

class _HeaderProgress extends StatelessWidget {
  final double percentage; // 0..100
  final Color color;

  const _HeaderProgress({
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            cs.surfaceContainerHighest.withOpacity(0.10),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percentage / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(170),
                    painter: _RingPainter(
                      progress: 1.0,
                      color: cs.surfaceContainerHighest.withOpacity(0.35),
                      strokeWidth: 12,
                      isTrack: true,
                    ),
                  ),
                  CustomPaint(
                    size: const Size.square(170),
                    painter: _RingPainter(
                      progress: value,
                      color: color,
                      strokeWidth: 12,
                      isTrack: false,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      Text(
                        'From your profile',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: value < 1.0
                            ? Text(
                                'Complete the remaining to get a perfect profile',
                                key: const ValueKey('hint'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              )
                            : const SizedBox(key: ValueKey('done')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completed;
  final int missing;
  final int total;

  const _StatsRow({
    required this.completed,
    required this.missing,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item(IconData icon, String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        item(Iconsax.tick_circle, 'Completed', completed, Colors.green),
        const SizedBox(width: 12),
        item(Iconsax.timer_pause, 'Remaining', missing, Colors.orange),
        const SizedBox(width: 12),
        item(Iconsax.task, 'Total', total, Colors.blue),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  final String fieldName;
  const _CompletedTile({required this.fieldName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const fieldLabels = {
      'verified': 'Verification',
      'profile_picture': 'Profile Picture',
      'cover_picture': 'Cover Photo',
      'birthdate': 'Birthdate',
      'relationship': 'Relationship Status',
      'location': 'Location',
      'education': 'Education',
      'work': 'Work Information',
      'biography': 'Biography',
    };

    const fieldIcons = {
      'verified': Iconsax.verify,
      'profile_picture': Iconsax.user,
      'cover_picture': Iconsax.gallery,
      'birthdate': Iconsax.cake,
      'relationship': Iconsax.heart,
      'location': Iconsax.location,
      'education': Iconsax.book,
      'work': Iconsax.briefcase,
      'biography': Iconsax.document_text,
    };

    final label = fieldLabels[fieldName] ?? fieldName;
    final icon = fieldIcons[fieldName] ?? Iconsax.check;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green, size: 20),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: const Icon(Iconsax.tick_circle, color: Colors.green, size: 24),
    );
  }
}

class _MissingTile extends StatelessWidget {
  final MissingField field;
  final VoidCallback onTap;
  const _MissingTile({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = field.required ? Colors.red.shade400 : Colors.orange.shade600;
    final iconData = field.icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.labelAr,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      field.required ? 'Required' : 'Optional',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3,
                size: 18, color: cs.onSurfaceVariant.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ---------------- Painter ----------------

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double strokeWidth;
  final bool isTrack;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.isTrack,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;
    final sweepAngle = (math.pi * 2) * progress;

    if (isTrack) {
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = color;
      canvas.drawArc(rect, startAngle, math.pi * 2, false, trackPaint);
      return;
    }

    if (progress == 0) return;

    // Glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth / 2);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Gradient sweep
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [color.withOpacity(0.6), color],
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp,
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isTrack != isTrack;
  }
}
