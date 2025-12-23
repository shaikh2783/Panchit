import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../data/models/job.dart';
import '../../domain/jobs_repository.dart';
import 'job_apply_page.dart';
import '../../../auth/application/auth_notifier.dart';
import 'job_edit_page.dart';
import 'job_candidates_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JobDetailPage extends StatefulWidget {
  final int jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  Job? _job;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<JobsRepository>();
      final j = await repo.getJob(widget.jobId);
      setState(() {
        _job = j;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUserId = int.tryParse(context.read<AuthNotifier>().currentUser?['user_id']?.toString() ?? '');
    final isOwner = _job != null && currentUserId != null && _job!.author.userId == currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text('job_details'.tr),
        actions: [
          if (isOwner && _job != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Get.to(() => const JobEditPage(), arguments: _job);
                } else if (v == 'delete') {
                  _confirmDelete();
                } else if (v == 'candidates') {
                  Get.to(() => JobCandidatesPage(jobId: _job!.postId));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'candidates', child: Row(children: [const Icon(Iconsax.people_copy, size: 18), SizedBox(width: UI.sm), Text('candidates'.tr)])),
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Iconsax.edit_2_copy, size: 18), SizedBox(width: UI.sm), Text('edit'.tr)])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Iconsax.trash_copy, size: 18, color: Theme.of(context).colorScheme.error), SizedBox(width: UI.sm), Text('delete'.tr, style: TextStyle(color: Theme.of(context).colorScheme.error))])),
              ],
            ),
        ],
      ),
      floatingActionButton: _job == null
          ? null
          : Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => Get.to(() => JobApplyPage(jobId: _job!.postId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.send_2_copy,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'apply_now'.tr,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? Center(child: Text('${'error'.tr}: $_error'))
              : _buildContent(scheme),
    );
  }

  Future<void> _confirmDelete() async {
    if (_job == null) return;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_job'.tr),
        content: Text('delete_job_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text('delete'.tr), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final repo = context.read<JobsRepository>();
        await repo.deleteJob(_job!.postId);
        Get.back();
        Get.snackbar('success'.tr, 'job_deleted_successfully'.tr);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString());
      }
    }
  }

  Widget _buildContent(ColorScheme scheme) {
    final j = _job!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (j.cover.isNotEmpty)
          Stack(children: [
            Image.network(
              j.cover,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 260,
                color: Colors.grey[300],
                child: Icon(Iconsax.image_copy, color: Colors.grey[400]),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black38],
                  ),
                ),
              ),
            ),
          ]),

        // Floating info card
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: UI.lg),
            child: Container(
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rLg),
                boxShadow: UI.softShadow(context),
              ),
              padding: EdgeInsets.all(UI.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(j.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                SizedBox(height: UI.sm),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(context, j.typeMeta, scheme.primary.withOpacity(0.12), scheme.primary),
                  if (j.paySalaryPerMeta.isNotEmpty) _chip(context, j.paySalaryPerMeta, UI.surfacePage(context), UI.subtleText(context)),
                ]),
                SizedBox(height: UI.md),
                Row(children: [
                  Icon(Iconsax.location_copy, size: 18, color: UI.subtleText(context)),
                  SizedBox(width: UI.sm),
                  Expanded(child: Text(j.location, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: UI.subtleText(context))))
                ]),
                SizedBox(height: UI.md),
                Row(children: [
                  Icon(Iconsax.people_copy, size: 18, color: UI.subtleText(context)),
                  SizedBox(width: UI.sm),
                  Text('${'candidates'.tr}: ${j.candidatesCount}', style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  if (j.salaryMin != null && j.salaryMax != null && j.salaryMinCurrency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${j.salaryMinCurrency!.format(j.salaryMin!)} - ${j.salaryMaxCurrency!.format(j.salaryMax!)}',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                ]),
                SizedBox(height: UI.lg),
                Row(children: [
                  if (j.author.userPicture.isNotEmpty)
                    CircleAvatar(backgroundImage: CachedNetworkImageProvider(j.author.userPicture))
                  else
                    CircleAvatar(backgroundColor: scheme.primary, child: const Icon(Iconsax.user_copy, color: Colors.white)),
                  SizedBox(width: UI.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j.author.userName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(j.createdTime, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context))),
                  ])),
                ]),
              ]),
            ),
          ),
        ),

        // Description card
        if (j.description.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(UI.lg, 0, UI.lg, UI.lg),
            child: Container(
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rLg),
                boxShadow: UI.softShadow(context),
              ),
              padding: EdgeInsets.all(UI.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('description'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                SizedBox(height: UI.sm),
                Html(
                  data: j.description,
                  style: {
                    "*": Style(
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.6),
                    ),
                    "p": Style(
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.6),
                      margin: Margins.only(bottom: 12),
                    ),
                  },
                ),
              ]),
            ),
          ),
        SizedBox(height: UI.xl * 2),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSkeleton() => ListView(children: const [SkeletonBox(height: 240, radius: 0)]);
}
