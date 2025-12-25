import '../data/services/ads_api_service.dart';

class AdsRepository {
  final AdsApiService api;
  AdsRepository(AdsApiService service) : api = service;

  Future<List<Map<String, dynamic>>> listCampaigns({
    int offset = 0,
    int limit = 20,
    String sortBy = 'campaign_created_date',
    String sortDir = 'desc',
    bool? isActive,
    bool? isApproved,
    String? bidding,
    String? placement,
    String? q,
  }) async {
    final res = await api.listCampaigns(
      offset: offset,
      limit: limit,
      sortBy: sortBy,
      sortDir: sortDir,
      isActive: isActive,
      isApproved: isApproved,
      bidding: bidding,
      placement: placement,
      q: q,
    );
    final data = res;
    final campaigns = ((data['data'] ?? const {}) as Map<String, dynamic>)[
          'campaigns'] ??
        [];
    return List<Map<String, dynamic>>.from(campaigns);
  }

  Future<bool> setCampaignActive({required int campaignId, required bool active}) async {
    final res = await api.setCampaignActive(campaignId: campaignId, active: active);
    final ok = (res['success'] ?? res['status']) == true || (res['code'] == 200);
    return ok == true;
  }
}
