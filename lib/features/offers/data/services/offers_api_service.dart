import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/offer.dart';
import '../models/offer_category.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import 'dart:typed_data';
const String SITE_ENCRYPT_KEY = 'ef2ff48ada3d53fe';
const String APPLICATION_ID = 'com.fluttercrafters.app';
const String SERVER_HMAC_KEY = '43e4b116877a2543664ea0cb3c144f62';
const String PREF_KEY_ENDPOINTS = 'saved_endpoints';

class OffersApiService {
  final ApiClient _client;
  OffersApiService(this._client);

  Future<List<OfferCategory>> getCategories() async {
    final response = await _client.get(configCfgP('offers_categories'));
    if (response['status'] == 'success') {
      final data = response['data'] as Map<String, dynamic>;
      final list = (data['categories'] ?? data['data'] ?? []) as List;
      return list.map((e) => OfferCategory.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response['message'] ?? 'Failed to load categories');
  }

  Future<Map<String, dynamic>> getOffers({int offset = 0, int limit = 20, String search = '', int? categoryId}) async {
    final query = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
    };
    return await _client.get(configCfgP('offers'), queryParameters: query);
  }

  Future<Offer> getOfferById(int id) async {
    final response = await _client.get('${configCfgP('offers')}/$id');
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Offer.fromJson(data['offer'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to fetch offer');
  }

  Future<Offer> createOffer(Map<String, dynamic> body) async {
    final response = await _client.post(configCfgP('offers'), body: body);
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Offer.fromJson(data['offer'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to create offer');
  }

  Future<Offer> updateOffer(int id, Map<String, dynamic> body) async {
    final response = await _client.post('${configCfgP('offers')}/$id', body: body);
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Offer.fromJson(data['offer'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to update offer');
  }

  Future<void> deleteOffer(int id) async {
    final response = await _client.post('${configCfgP('offers')}/$id/delete');
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to delete offer');
    }
  }

  /// Upload a single image file
  Future<Map<String, dynamic>> uploadImage(
    File imageFile, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final response = await _client.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: imageFile.path,
        fileFieldName: 'file',
        onProgress: onProgress,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      throw Exception(response['message'] ?? 'Failed to upload image');
    } catch (e) {
      rethrow;
    }
  }
}

Uint8List _sha256Bytes(List<int> data) =>
    Uint8List.fromList(crypto.sha256.convert(data).bytes);

Uint8List deriveKey(Uint8List salt) {
  final ikm = _sha256Bytes(utf8.encode(SITE_ENCRYPT_KEY + APPLICATION_ID));
  final combo = <int>[]
    ..addAll(salt)
    ..addAll(ikm);
  return _sha256Bytes(combo);
}

Uint8List hmacSha256Bytes(String key, String message) {
  final h = crypto.Hmac(crypto.sha256, utf8.encode(key));
  return Uint8List.fromList(h.convert(utf8.encode(message)).bytes);
}

/// حفظ الـ endpoints في SharedPreferences
Future<void> saveEndpoints(Map<String, dynamic> endpoints) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(endpoints);
  await prefs.setString(PREF_KEY_ENDPOINTS, jsonString);
}

/// استرجاع الـ endpoints من SharedPreferences
Future<Map<String, dynamic>?> loadSavedEndpoints() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(PREF_KEY_ENDPOINTS);
  if (jsonString != null) {
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  }
  return null;
}