import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/download_settings.dart';

class InformationApiService {
  final ApiClient _apiClient;

  InformationApiService(this._apiClient);

  /// جلب إعدادات التحميل
  /// GET /data/information/settings
  Future<Map<String, dynamic>> getDownloadSettings() async {
    try {

      final response = await _apiClient.get('/data/information/settings');

      final isError = response['error'] == true;
      if (!isError && response['data'] != null) {
        return {
          'success': true,
          'settings': DownloadSettings.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to load settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// طلب تحميل البيانات (HTML)
  /// POST /data/information/download
  /// Returns HTML file as attachment (Content-Disposition: attachment; filename="{username}.html")
  Future<Map<String, dynamic>> downloadUserData({
    required Map<String, bool> options,
  }) async {
    try {

      // Check that at least one option is selected
      if (!options.values.any((v) => v)) {
        return {
          'success': false,
          'message': 'Select which information you would like to download',
        };
      }

      final response = await _apiClient.post(
        '/data/information/download',
        body: options,
      );

      final isError = response['error'] == true;
      if (!isError) {
        // Response is HTML content (file download)
        // The API returns raw HTML with proper headers
        return {
          'success': true,
          'message': response['message'] ?? 'Your data has been prepared for download',
          'htmlContent': response['data'], // Raw HTML content
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to download data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
