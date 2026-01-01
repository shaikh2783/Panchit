import 'package:snginepro/core/network/api_client.dart';

class AdsTrackingService {
  final ApiClient _client;
  
  // Track which ads have been viewed/clicked to avoid duplicate tracking
  final Set<String> _trackedViews = {};
  final Set<String> _trackedClicks = {};

  AdsTrackingService(this._client);

  /// Track ad view (impression)
  /// Returns true if tracking was successful
  Future<bool> trackAdView(int campaignId) async {
    final key = 'view_$campaignId';
    
    // Avoid duplicate view tracking
    if (_trackedViews.contains(key)) {

      return false;
    }

    try {

      final response = await _client.post(
        '/data/ads/track',
        data: {
          'campaign_id': campaignId,
          'action': 'view',
        },
      );

      if (response['status'] == 'success') {
        final tracked = response['data']?['tracked'] ?? false;
        
        if (tracked) {
          _trackedViews.add(key);

          return true;
        } else {
          final reason = response['data']?['reason'] ?? 'unknown';

          return false;
        }
      }
      
      return false;
    } catch (e) {
      // Silent fail - don't break the app

      return false;
    }
  }

  /// Track ad click
  /// Returns true if tracking was successful
  Future<bool> trackAdClick(int campaignId) async {
    final key = 'click_$campaignId';
    
    // Avoid duplicate click tracking (optional - you might want multiple clicks)
    if (_trackedClicks.contains(key)) {

      return false;
    }

    try {

      final response = await _client.post(
        '/data/ads/track',
        data: {
          'campaign_id': campaignId,
          'action': 'click',
        },
      );

      if (response['status'] == 'success') {
        final tracked = response['data']?['tracked'] ?? false;
        
        if (tracked) {
          _trackedClicks.add(key);
          final cost = response['data']?['cost'];
          final remainingBudget = response['data']?['remaining_budget'];

          return true;
        } else {
          final reason = response['data']?['reason'] ?? 'unknown';

          return false;
        }
      }
      
      return false;
    } catch (e) {

      return false;
    }
  }

  /// Clear tracking cache (useful for testing or after logout)
  void clearCache() {
    _trackedViews.clear();
    _trackedClicks.clear();

  }
}
