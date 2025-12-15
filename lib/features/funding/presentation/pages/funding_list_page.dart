import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/widgets/skeletons.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/funding.dart';
import '../../domain/funding_repository.dart';
import 'funding_create_page.dart';
import 'funding_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
class FundingListPage extends StatefulWidget {
  final bool mineOnly;
  const FundingListPage({super.key, this.mineOnly = false});
  @override
  State<FundingListPage> createState() => _FundingListPageState();
}
class _FundingListPageState extends State<FundingListPage> {
  final _scrollCtrl = ScrollController();
  List<Funding> _items = [];
  bool _loading = true;
  String _error = '';
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _loadingMore = false;
  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _offset = 0;
    });
    try {
      final repo = context.read<FundingRepository>();
      final response = await repo.getFunding(offset: 0, limit: _limit);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['funding'] as List).map((e) => Funding.fromJson(e as Map<String, dynamic>)).toList();
      final filtered = widget.mineOnly ? _filterMine(list) : list;
      setState(() {
        _items = filtered;
        _hasMore = filtered.length >= _limit && (data['has_more'] == true);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final repo = context.read<FundingRepository>();
      final newOffset = _offset + _limit;
      final response = await repo.getFunding(offset: newOffset, limit: _limit);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['funding'] as List).map((e) => Funding.fromJson(e as Map<String, dynamic>)).toList();
      final filtered = widget.mineOnly ? _filterMine(list) : list;
      setState(() {
        _items.addAll(filtered);
        _offset = newOffset;
        _hasMore = filtered.length >= _limit && (data['has_more'] == true);
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mineOnly ? 'funding'.tr : 'funding'.tr)),
      floatingActionButton: Container(
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
            onTap: () => Get.to(() => const FundingCreatePage())?.then((_) => _load()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.add_copy,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'create_funding'.tr,
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
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.danger_copy, size: 48, color: UI.subtleText(context)),
                      SizedBox(height: UI.md),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: UI.md),
                      ElevatedButton(onPressed: _load, child: Text('retry'.tr)),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.money_recive_copy, size: 48, color: UI.subtleText(context)),
                          SizedBox(height: UI.md),
                          Text('no_funding_found'.tr, style: TextStyle(color: UI.subtleText(context))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.all(UI.lg),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: UI.lg),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final item = _items[i];
                          return _buildCard(context, item);
                        },
                      ),
                    ),
    );
  }
  List<Funding> _filterMine(List<Funding> items) {
    // Compare author.userId to current user id
    final auth = context.read<AuthNotifier>();
    final currentId = auth.currentUser?['user_id']?.toString();
    if (currentId == null || currentId.isEmpty) return const [];
    return items.where((f) => f.author.userId.toString() == currentId).toList();
  }
  Widget _buildCard(BuildContext context, Funding f) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Get.to(() => FundingDetailPage(fundingId: int.parse(f.postId)))?.then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(UI.rLg),
          boxShadow: UI.softShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with gradient
            if (f.cover != null && f.cover!.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    f.cover!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300]),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: EdgeInsets.all(UI.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    f.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: UI.sm),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: f.progress,
                      minHeight: 8,
                      backgroundColor: scheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  SizedBox(height: UI.sm),
                  // Amount info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'raised'.tr,
                            style: TextStyle(fontSize: 11, color: UI.subtleText(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${f.raisedAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'goal'.tr,
                            style: TextStyle(fontSize: 11, color: UI.subtleText(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${f.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'donors'.tr,
                            style: TextStyle(fontSize: 11, color: UI.subtleText(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${f.totalDonations}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: UI.md),
                  // Publisher row
                  Row(
                    children: [
                      // Avatar
                      if (f.author.userPicture != null && f.author.userPicture!.isNotEmpty)
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: CachedNetworkImageProvider(f.author.userPicture!),
                        )
                      else
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.primary.withOpacity(0.2),
                          child: Icon(Iconsax.user_copy, size: 14, color: scheme.primary),
                        ),
                      SizedBox(width: UI.sm),
                      Expanded(
                        child: Text(
                          f.author.userName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Completion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${f.fundingCompletion}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.all(UI.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: UI.lg),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: UI.surfaceCard(context), borderRadius: BorderRadius.circular(UI.rLg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(height: 180, radius: 0),
          Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              SkeletonBox(height: 20, width: 200, radius: 8),
              SizedBox(height: 12),
              SkeletonBox(height: 8, width: double.infinity, radius: 4),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(height: 14, width: 80, radius: 8),
                  SkeletonBox(height: 14, width: 80, radius: 8),
                  SkeletonBox(height: 14, width: 60, radius: 8),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
