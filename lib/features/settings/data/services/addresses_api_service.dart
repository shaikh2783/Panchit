import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/address.dart';

class AddressesApiService {
  final ApiClient _apiClient;

  AddressesApiService(this._apiClient);

  /// جلب جميع العناوين
  Future<Map<String, dynamic>> getUserAddresses() async {
    try {

      final response = await _apiClient.get(configCfgP('addresses'));


      if (response['error'] == false) {
        final data = response['data'] as List;
        return {
          'success': true,
          'addresses': data.map((a) => Address.fromJson(a)).toList(),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل تحميل العناوين',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// جلب عنوان واحد
  Future<Map<String, dynamic>> getAddress(String addressId) async {
    try {

      final response = await _apiClient.get(
        configCfgP('addresses_get'),
        queryParameters: {'id': addressId},
      );


      if (response['error'] == false) {
        return {'success': true, 'address': Address.fromJson(response['data'])};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'العنوان غير موجود',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// إضافة عنوان جديد
  Future<Map<String, dynamic>> addAddress(Address address) async {
    try {

      final response = await _apiClient.post(
        configCfgP('addresses_add'),
        body: address.toJson(),
      );


      if (response['error'] == false) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم إضافة العنوان بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل إضافة العنوان',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// تحديث عنوان موجود
  Future<Map<String, dynamic>> updateAddress(Address address) async {
    try {

      final response = await _apiClient.post(
        configCfgP('addresses_update'),
        body: address.toUpdateJson(),
      );


      if (response['error'] == false) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم تحديث العنوان بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل تحديث العنوان',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// حذف عنوان
  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {

      final response = await _apiClient.post(
        configCfgP('addresses_delete'),
        body: {'address_id': addressId},
      );


      if (response['error'] == false) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم حذف العنوان بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل حذف العنوان',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
