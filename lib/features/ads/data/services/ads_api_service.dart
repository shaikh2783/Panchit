import 'dart:convert';
import 'package:snginepro/core/network/api_client.dart';
class AdsApiService {
  final ApiClient _client;
  AdsApiService(this._client);
  Future<Map<String, dynamic>> listCampaigns({
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
    final query = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      'sort_by': sortBy,
      'sort_dir': sortDir,
      if (isActive != null) 'is_active': isActive ? '1' : '0',
      if (isApproved != null) 'is_approved': isApproved ? '1' : '0',
      if (bidding != null) 'bidding': bidding,
      if (placement != null) 'placement': placement,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    return _client.get('/data/ads/campaigns', queryParameters: query);
  }
  Future<Map<String, dynamic>> setCampaignActive({
    required int campaignId,
    required bool active,
  }) async {
    final body = {
      'is_active': active ? '1' : '0',
    };
    return _client.post('/data/ads/campaigns/$campaignId/status', body: body, asJson: true);
  }
  Future<Map<String, dynamic>> createCampaign({
    required String title,
    required String placement,
    required String bidding,
    required String budget,
    String? startDate,
    String? endDate,
    Map<String, dynamic>? targeting,
    String? adsType,
    String? adsUrl,
    String? adsPostUrl,
    String? adsPageId,
    String? adsGroupId,
    String? adsEventId,
    String? imageFilename,
    String? adsTitle,
    String? adsDescription,
  }) async {
    // Normalize bidding values to backend expected: 'click' or 'view'
    final normalizedBidding = bidding == 'clicks' ? 'click' : (bidding == 'views' ? 'view' : bidding);
    final body = <String, dynamic>{
      'campaign_title': title,
      'ads_placement': placement,
      'campaign_bidding': normalizedBidding,
      'campaign_budget': _parseNumeric(budget),
      if (startDate != null) 'campaign_start_date': startDate,
      if (endDate != null) 'campaign_end_date': endDate,
      if (targeting != null) ...{
        'audience_countries': targeting['countries'] ?? [],
        'audience_gender': targeting['gender'] ?? 'all',
        'audience_relationship': targeting['relationship'] ?? 'all',
      },
      if (adsType != null) 'ads_type': adsType,
      if (adsUrl != null) 'ads_url': adsUrl,
      if (adsPostUrl != null) 'ads_post_url': adsPostUrl,
      if (adsPageId != null) 'ads_page': adsPageId,
      if (adsGroupId != null) 'ads_group': adsGroupId,
      if (adsEventId != null) 'ads_event': adsEventId,
      if (imageFilename != null) 'ads_image': imageFilename,
      if (adsTitle != null) 'ads_title': adsTitle,
      if (adsDescription != null) 'ads_description': adsDescription,
    };
    // Backend expects JSON with auth/HMAC headers on this endpoint
    return _client.post(
      '/data/ads/campaigns',
      body: body,
      asJson: true,
    );
  }
  Future<Map<String, dynamic>> updateCampaign({
    required int campaignId,
    String? title,
    String? placement,
    String? bidding,
    num? budget,
    String? startDate,
    String? endDate,
    Map<String, dynamic>? targeting,
    String? adsType,
    String? adsUrl,
    String? adsPostUrl,
    String? adsPageId,
    String? adsGroupId,
    String? adsEventId,
    String? imageFilename,
    String? adsTitle,
    String? adsDescription,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'campaign_title': title,
      if (placement != null) 'ads_placement': placement,
      if (bidding != null)
        'campaign_bidding': (bidding == 'clicks'
            ? 'click'
            : (bidding == 'views' ? 'view' : bidding)),
      if (budget != null) 'campaign_budget': budget,
      if (startDate != null) 'campaign_start_date': startDate,
      if (endDate != null) 'campaign_end_date': endDate,
      if (targeting != null) ...{
        'audience_countries': targeting['countries'] ?? [],
        'audience_gender': targeting['gender'] ?? 'all',
        'audience_relationship': targeting['relationship'] ?? 'all',
      },
      if (adsType != null) 'ads_type': adsType,
      if (adsUrl != null) 'ads_url': adsUrl,
      if (adsPostUrl != null) 'ads_post_url': adsPostUrl,
      if (adsPageId != null) 'ads_page': adsPageId,
      if (adsGroupId != null) 'ads_group': adsGroupId,
      if (adsEventId != null) 'ads_event': adsEventId,
      if (imageFilename != null) 'ads_image': imageFilename,
      if (adsTitle != null) 'ads_title': adsTitle,
      if (adsDescription != null) 'ads_description': adsDescription,
      if (isActive != null) 'campaign_is_active': isActive ? '1' : '0',
    };
    return _client.put(
      '/data/ads/campaigns/$campaignId',
      body: body,
      asJson: true,
    );
  }
  num _parseNumeric(String v) {
    return num.tryParse(v) ?? 0;
  }
}
