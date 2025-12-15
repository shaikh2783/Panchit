import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/widgets/skeletons.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/funding_donor.dart';
import '../../domain/funding_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
class FundingDonorsPage extends StatefulWidget {
  final int fundingId;
  const FundingDonorsPage({super.key, required this.fundingId});
  @override
  State<FundingDonorsPage> createState() => _FundingDonorsPageState();
}
class _FundingDonorsPageState extends State<FundingDonorsPage> {
  final _scrollCtrl = ScrollController();
  List<FundingDonor> _donors = [];
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
      final response = await repo.getDonors(widget.fundingId, offset: 0, limit: _limit);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['donors'] as List).map((e) => FundingDonor.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _donors = list;
        _hasMore = data['has_more'] == true;
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
      final response = await repo.getDonors(widget.fundingId, offset: newOffset, limit: _limit);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['donors'] as List).map((e) => FundingDonor.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _donors.addAll(list);
        _offset = newOffset;
        _hasMore = data['has_more'] == true;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('donors'.tr)),
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
              : _donors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.people_copy, size: 48, color: UI.subtleText(context)),
                          SizedBox(height: UI.md),
                          Text('no_donors_yet'.tr, style: TextStyle(color: UI.subtleText(context))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.all(UI.lg),
                        itemCount: _donors.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: UI.md),
                        itemBuilder: (context, i) {
                          if (i >= _donors.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final donor = _donors[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: UI.surfaceCard(context),
                              borderRadius: BorderRadius.circular(UI.rMd),
                              boxShadow: UI.softShadow(context),
                            ),
                            padding: EdgeInsets.all(UI.md),
                            child: Row(
                              children: [
                                if (donor.donorPicture != null && donor.donorPicture!.isNotEmpty)
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: CachedNetworkImageProvider(donor.donorPicture!),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: scheme.primary.withOpacity(0.2),
                                    child: Icon(Iconsax.user_copy, color: scheme.primary),
                                  ),
                                SizedBox(width: UI.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        donor.donorName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        donor.time,
                                        style: TextStyle(fontSize: 12, color: UI.subtleText(context)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '\$${donor.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
  Widget _buildSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.all(UI.lg),
      itemCount: 8,
      separatorBuilder: (_, __) => SizedBox(height: UI.md),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: UI.surfaceCard(context), borderRadius: BorderRadius.circular(UI.rMd)),
        padding: EdgeInsets.all(UI.md),
        child: Row(
          children: [
            const SkeletonBox(height: 48, width: 48, radius: 24),
            SizedBox(width: UI.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 120, radius: 8),
                  SizedBox(height: 4),
                  SkeletonBox(height: 12, width: 80, radius: 8),
                ],
              ),
            ),
            const SkeletonBox(height: 28, width: 60, radius: 12),
          ],
        ),
      ),
    );
  }
}
