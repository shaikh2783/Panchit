import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/ui_constants.dart';
import 'package:snginepro/core/widgets/skeletons.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import '../../data/models/offer.dart';
import '../../domain/offers_repository.dart';
import 'offer_detail_page.dart';
import 'offer_create_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
class OffersListPage extends StatefulWidget {
  final bool mineOnly;
  const OffersListPage({super.key, this.mineOnly = false});
  @override
  State<OffersListPage> createState() => _OffersListPageState();
}
class _OffersListPageState extends State<OffersListPage> {
  final _scroll = ScrollController();
  List<Offer> _items = [];
  // Categories reserved for future filter UI
  // List<OfferCategory> _categories = [];
  int? _categoryId;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _prime();
    _scroll.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
  Future<void> _prime() async {
    // Categories reserved for future filter dropdown
    // try {
    //   final repo = context.read<OffersRepository>();
    //   final cats = await repo.getCategories();
    //   setState(() => _categories = cats);
    // } catch (_) {}
    await _load();
  }
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _offset = 0;
      _hasMore = true;
    });
    try {
      final repo = context.read<OffersRepository>();
      final response = await repo.getOffers(offset: 0, limit: _limit, categoryId: _categoryId);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['offers'] as List).map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
      final filtered = widget.mineOnly ? _filterMine(list) : list;
      setState(() {
        _items = filtered;
        _loading = false;
        _hasMore = filtered.length >= _limit && (data['has_more'] == true);
        _offset = filtered.length;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final repo = context.read<OffersRepository>();
      final response = await repo.getOffers(offset: _offset, limit: _limit, categoryId: _categoryId);
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['offers'] as List).map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
      final filtered = widget.mineOnly ? _filterMine(list) : list;
      setState(() {
        _items.addAll(filtered);
        _loadingMore = false;
        _hasMore = filtered.length >= _limit && (data['has_more'] == true);
        _offset += filtered.length;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }
  List<Offer> _filterMine(List<Offer> items) {
    final auth = context.read<AuthNotifier>();
    final id = auth.currentUser?['user_id']?.toString();
    if (id == null || id.isEmpty) return const [];
    return items.where((o) => o.author.userId.toString() == id).toList();
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.mineOnly ? 'my_offers'.tr : 'offers'.tr)),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Get.to(() => const OfferCreatePage())?.then((_) => _load()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.add_copy, size: 20, color: scheme.onPrimary),
                  const SizedBox(width: 12),
                  Text('create_offer'.tr, style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
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
                      const Icon(Iconsax.danger_copy, size: 48),
                      SizedBox(height: UI.md),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: UI.md),
                      ElevatedButton(onPressed: _load, child: Text('retry'.tr)),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(child: Text('no_offers_found'.tr))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        controller: _scroll,
                        padding: EdgeInsets.all(UI.lg),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: UI.lg),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final item = _items[i];
                          return _card(item);
                        },
                      ),
                    ),
    );
  }
  Widget _card(Offer o) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Get.to(() => OfferDetailPage(offerId: int.parse(o.postId)))?.then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(UI.rLg),
          boxShadow: UI.softShadow(context),
        ),
        padding: EdgeInsets.all(UI.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (o.thumbnail != null && o.thumbnail!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(o.thumbnail!, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey[300])),
              )
            else
              Container(width: 72, height: 72, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(Iconsax.discount_circle_copy, color: scheme.primary)),
            SizedBox(width: UI.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 6),
                if (o.price != null)
                  Text(' ${o.price!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
            if (o.discountPercent != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Text('-${o.discountPercent!.toStringAsFixed(0)}% ', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              )
          ]),
          SizedBox(height: UI.sm),
          Row(children: [
            if (o.author.userPicture != null && o.author.userPicture!.isNotEmpty)
              CircleAvatar(radius: 12, backgroundImage: CachedNetworkImageProvider(o.author.userPicture!))
            else
              CircleAvatar(radius: 12, backgroundColor: scheme.primary.withOpacity(0.2), child: Icon(Iconsax.user_copy, size: 12, color: scheme.primary)),
            SizedBox(width: UI.sm),
            Expanded(child: Text(o.author.userName, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Spacer(),
            if (o.endDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Iconsax.timer_1, size: 14, color: Colors.orange), const SizedBox(width: 4), Text(o.endDate!, style: const TextStyle(fontSize: 11, color: Colors.orange))]),
              ),
          ]),
        ]),
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
        padding: EdgeInsets.all(UI.lg),
        child: Row(children: const [
          SkeletonBox(height: 72, width: 72, radius: 8),
          SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 20, radius: 8)),
        ]),
      ),
    );
  }
}
