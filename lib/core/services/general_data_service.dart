import '../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../core/models/country.dart';
import '../../core/models/language.dart';

/// خدمة البيانات العامة (Countries, Languages)
class GeneralDataService {
  final ApiClient _apiClient;

  GeneralDataService(this._apiClient);

  /// جلب قائمة الدول
  Future<List<Country>> getCountries() async {
    try {

      final response = await _apiClient.get(configCfgP('countries'));

      if (response['status'] == 'success') {
        final data = response['data']['countries'] as List? ?? [];
        final countries = data.map((c) => Country.fromJson(c)).toList();

        if (countries.isNotEmpty) {

        }
        return countries;
      }

      return [];
    } catch (e) {

      return [];
    }
  }

  /// جلب قائمة اللغات
  Future<List<Language>> getLanguages() async {
    try {

      final response = await _apiClient.get(configCfgP('languages'));

      if (response['status'] == 'success') {
        final data = response['data']['languages'] as List? ?? [];
        final languages = data.map((l) => Language.fromJson(l)).toList();

        if (languages.isNotEmpty) {

        }
        return languages;
      }

      return [];
    } catch (e) {

      return [];
    }
  }
}
