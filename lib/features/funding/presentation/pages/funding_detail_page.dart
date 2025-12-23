import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/widgets/skeletons.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';

import '../../../../core/theme/ui_constants.dart';
import '../../data/models/funding.dart';
import '../../domain/funding_repository.dart';
import 'funding_donate_page.dart';
import 'funding_donors_page.dart';
import 'funding_edit_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FundingDetailPage extends StatefulWidget {
  final int fundingId;

  const FundingDetailPage({super.key, required this.fundingId});

  @override
  State<FundingDetailPage> createState() => _FundingDetailPageState();
}

class _FundingDetailPageState extends State<FundingDetailPage> {
  Funding? _funding;
  bool _loading = true;
  String? _error;
  String? _currentUserId;

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
      final repo = context.read<FundingRepository>();
      final funding = await repo.getFundingById(widget.fundingId);
      // Get current user ID from AuthNotifier if available
      final userMap = context.read<AuthNotifier?>()?.currentUser;
      final userId = userMap != null ? userMap['user_id']?.toString() : null;
      setState(() {
        _funding = funding;
        _currentUserId = userId;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_funding'.tr),
        content: Text('delete_funding_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = context.read<FundingRepository>();
      await repo.deleteFunding(widget.fundingId);
      Get.back();
      Get.snackbar('success'.tr, 'funding_deleted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOwner = _funding != null && _currentUserId != null && _funding!.author.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('funding_details'.tr),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Get.to(() => FundingEditPage(funding: _funding!))?.then((_) => _load());
                } else if (value == 'delete') {
                  _delete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Iconsax.edit_copy, size: 18), const SizedBox(width: 8), Text('edit'.tr)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Iconsax.trash_copy, size: 18, color: Colors.red), const SizedBox(width: 8), Text('delete'.tr, style: const TextStyle(color: Colors.red))])),
              ],
            ),
        ],
      ),
      floatingActionButton: _funding == null
          ? null
          : Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => Get.to(() => FundingDonatePage(funding: _funding!))?.then((_) => _load()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.card_send_copy,
                          size: 20,
                          color: scheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'donate_now'.tr,
                          style: TextStyle(
                            color: scheme.onPrimary,
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

  Widget _buildContent(ColorScheme scheme) {
    final f = _funding!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover with gradient
          if (f.cover != null && f.cover!.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  f.cover!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 280, color: Colors.grey[300]),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.38)],
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Floating info card
          Transform.translate(
            offset: f.cover != null && f.cover!.isNotEmpty ? const Offset(0, -20) : Offset.zero,
            child: Padding(
              padding: EdgeInsets.fromLTRB(UI.lg, 0, UI.lg, UI.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: UI.surfaceCard(context),
                  borderRadius: BorderRadius.circular(UI.rLg),
                  boxShadow: UI.softShadow(context),
                ),
                padding: EdgeInsets.all(UI.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      f.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: UI.md),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: f.progress,
                        minHeight: 12,
                        backgroundColor: scheme.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                    SizedBox(height: UI.sm),
                    
                    // Completion percentage
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${f.fundingCompletion}% ${'completed'.tr}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: UI.md),

                    // Amount stats
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            context,
                            icon: Iconsax.money_recive_copy,
                            label: 'raised'.tr,
                            value: '\$${f.raisedAmount.toStringAsFixed(0)}',
                            color: scheme.primary,
                          ),
                        ),
                        SizedBox(width: UI.md),
                        Expanded(
                          child: _statCard(
                            context,
                            icon: Iconsax.flag_2_copy,
                            label: 'goal'.tr,
                            value: '\$${f.amount.toStringAsFixed(0)}',
                          ),
                        ),
                        SizedBox(width: UI.md),
                        Expanded(
                          child: _statCard(
                            context,
                            icon: Iconsax.people_copy,
                            label: 'donors'.tr,
                            value: '${f.totalDonations}',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UI.md),

                    // Donors list button
                    if (f.totalDonations > 0)
                      OutlinedButton.icon(
                        onPressed: () => Get.to(() => FundingDonorsPage(fundingId: int.parse(f.postId))),
                        icon: const Icon(Iconsax.user_octagon_copy, size: 18),
                        label: Text('view_donors'.tr),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    SizedBox(height: UI.md),

                    // Publisher
                    const Divider(),
                    SizedBox(height: UI.sm),
                    Row(
                      children: [
                        if (f.author.userPicture != null && f.author.userPicture!.isNotEmpty)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(f.author.userPicture!),
                          )
                        else
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: scheme.primary.withOpacity(0.2),
                            child: Icon(Iconsax.user_copy, size: 20, color: scheme.primary),
                          ),
                        SizedBox(width: UI.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.author.userName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                f.createdTime,
                                style: TextStyle(fontSize: 12, color: UI.subtleText(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Description card
          if (f.description.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(UI.lg, 0, UI.lg, UI.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: UI.surfaceCard(context),
                  borderRadius: BorderRadius.circular(UI.rLg),
                  boxShadow: UI.softShadow(context),
                ),
                padding: EdgeInsets.all(UI.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('description'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(height: UI.sm),
                    Html(
                      data: f.description,
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
                  ],
                ),
              ),
            ),
          SizedBox(height: UI.xl * 2),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, {required IconData icon, required String label, required String value, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final statColor = color ?? scheme.onSurface;
    return Container(
      padding: EdgeInsets.all(UI.md),
      decoration: BoxDecoration(
        color: (color ?? scheme.primary).withOpacity(0.06),
        borderRadius: BorderRadius.circular(UI.rMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: statColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: UI.subtleText(context)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: statColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SkeletonBox(height: 280, radius: 0),
          Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Column(
              children: [
                const SkeletonBox(height: 24, width: 250, radius: 8),
                SizedBox(height: UI.md),
                const SkeletonBox(height: 12, width: double.infinity, radius: 6),
                SizedBox(height: UI.md),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 80, radius: UI.rMd)),
                    SizedBox(width: UI.md),
                    Expanded(child: SkeletonBox(height: 80, radius: UI.rMd)),
                    SizedBox(width: UI.md),
                    Expanded(child: SkeletonBox(height: 80, radius: UI.rMd)),
                  ],
                ),
                SizedBox(height: UI.md),
                const SkeletonBox(height: 60, width: double.infinity, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
