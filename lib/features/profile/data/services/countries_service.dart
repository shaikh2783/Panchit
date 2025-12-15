import 'package:snginepro/main.dart' show configCfgP;
import '../../../../core/network/api_client.dart';
class CountryData {
  final int countryId;
  final String countryCode;
  final String countryName;
  final String phoneCode;
  CountryData({
    required this.countryId,
    required this.countryCode,
    required this.countryName,
    required this.phoneCode,
  });
  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      countryId: json['country_id'] ?? 0,
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      phoneCode: json['phone_code'] ?? '',
    );
  }
}
class CountriesService {
  final ApiClient _apiClient;
  CountriesService(this._apiClient);
  Future<List<CountryData>> getCountries() async {
    try {
      final response = await _apiClient.get(configCfgP('countries'));
      final List<dynamic> countriesData = response['data']['countries'] ?? [];
      final countries = countriesData.map((json) => CountryData.fromJson(json)).toList();
      return countries;
    } catch (e) {
      rethrow;
    }
  }
}
