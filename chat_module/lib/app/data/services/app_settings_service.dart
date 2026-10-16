import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/app_settings_model.dart';

class AppSettingsService {
  AppSettingsService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<AppSettingsModel> fetchAppSettings() async {
    final response = await _apiClient.get(ApiEndpoints.appSettings);
    return AppSettingsModel.fromJson(response);
  }
}
