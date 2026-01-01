import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/ads/data/services/ads_api_service.dart';
import '../../domain/ads_repository.dart';
import '../widgets/campaign_card.dart';
import '../widgets/filters_bar.dart';

class AdsCampaignsPage extends StatefulWidget {
  const AdsCampaignsPage({super.key});

  @override
  State<AdsCampaignsPage> createState() => _AdsCampaignsPageState();
}

class _AdsCampaignsPageState extends State<AdsCampaignsPage> {
  late final AdsRepository _repo;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String _sortBy = 'campaign_created_date';
  String _sortDir = 'desc';
  bool? _isActive;
  bool? _isApproved;
  String? _placement;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final service = Provider.of<AdsApiService>(context, listen: false);
    _repo = AdsRepository(service);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {

      _items = await _repo.listCampaigns(
        sortBy: _sortBy,
        sortDir: _sortDir,
        isActive: _isActive,
        isApproved: _isApproved,
        placement: _placement,
        q: _search.isEmpty ? null : _search,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load campaigns: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('ads_campaigns_title'.tr),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filters Bar
          FiltersBar(
            sortBy: _sortBy,
            sortDir: _sortDir,
            placement: _placement,
            isApproved: _isApproved,
            searchQuery: _search,
            onSortChanged: (v) {
              setState(() => _sortBy = v);
              _load();
            },
            onSortDirChanged: (desc) {
              setState(() => _sortDir = desc ? 'desc' : 'asc');
              _load();
            },
            onPlacementChanged: (v) {
              setState(() => _placement = v);
              _load();
            },
            onApprovalChanged: (v) {
              setState(() => _isApproved = v);
              _load();
            },
            onSearchChanged: (v) {
              _search = v.trim();
              _load();
            },
          ),

          // Campaigns Grid
          Expanded(
            child: _loading
                ? _ShimmerGrid()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? _EmptyState(message: 'no_campaigns_found'.tr)
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.55,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) {
                              final c = _items[i];
                              final title = (c['campaign_title'] ?? c['ads_title'] ?? '').toString();
                              final budget = c['campaign_budget']?.toString() ?? '-';
                              final spend = c['campaign_spend']?.toString() ?? '0';
                              final views = c['campaign_views']?.toString() ?? '0';
                              final clicks = c['campaign_clicks']?.toString() ?? '0';
                              final bidding = (c['campaign_bidding'] ?? c['ads_bidding'] ?? '').toString();
                              final status = (c['campaign_status'] ?? c['status'] ?? '').toString();
                              final created = (c['campaign_created_date'] ?? c['created_at'] ?? '').toString();
                              final id = int.tryParse((c['campaign_id'] ?? c['ads_id'] ?? '').toString()) ?? 0;
                              final isApproved = c['campaign_is_approved'] == true || c['campaign_is_approved'] == 1;
                              final rawImage = (c['ads_image'] ?? c['campaign_image'] ?? c['image'] ?? '').toString();
                              final imageUri = rawImage.isNotEmpty ? appConfig.mediaAsset(rawImage) : null;
                              
                              return CampaignCard(
                                key: ValueKey('campaign_$id'),
                                title: title.isEmpty ? 'ads_campaign_untitled'.tr : title,
                                budget: budget,
                                spend: spend,
                                views: views,
                                clicks: clicks,
                                active: c['campaign_is_active'] == true,
                                isApproved: isApproved,
                                imageUrl: imageUri?.toString(),
                                bidding: bidding,
                                status: status,
                                createdAt: created,
                                onTap: () async {
                                  if (id <= 0) return;
                                  final updated = await Get.toNamed('/ads/campaigns/edit', arguments: c);
                                  if (updated == true) {
                                    _load();
                                  }
                                },
                                onToggleActive: (id > 0 && isApproved)
                                    ? () async {
                                        final currentActive = c['campaign_is_active'] == true;
                                        final newActive = !currentActive;
                                        try {
                                          final ok = await _repo.setCampaignActive(campaignId: id, active: newActive);
                                          if (ok) {
                                            setState(() {
                                              _items[i]['campaign_is_active'] = newActive;
                                            });
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('operation_failed'.tr)),
                                            );
                                          }
                                        } catch (e) {
                                          final msg = e.toString();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg.contains('approval') ? 'ads_approval_required'.tr : 'Error: $e')),
                                          );
                                        }
                                      }
                                    : null,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary,
        child: InkWell(
          onTap: () async {
            final created = await Get.toNamed('/ads/campaigns/create');
            if (created == true) {
              _load();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.add_circle, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'create_campaign'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sortBy) {
      case 'campaign_spend':
        return 'ads_sort_top_spend'.tr;
      case 'campaign_end_date':
        return 'ads_sort_ending_soon'.tr;
      default:
        return 'ads_sort_newest'.tr;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.chart, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.cardColor.withOpacity(0.3),
          ),
        );
      },
    );
  }
}
