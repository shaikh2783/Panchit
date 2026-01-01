import 'package:snginepro/core/network/api_client.dart';
import '../models/user_photo.dart';
import '../models/user_album.dart';

class UserPhotosService {
  final ApiClient _apiClient;

  UserPhotosService(this._apiClient);

  /// Get User Photos
  Future<Map<String, dynamic>> getUserPhotos({
    String? username,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (username != null) {
        params['username'] = username;
      }

      final response = await _apiClient.get(
        '/data/users/photos',
        queryParameters: params,
      );

      final photosList = (response['data']['photos'] as List? ?? [])
          .map((json) => UserPhoto.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'photos': photosList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {

      rethrow;
    }
  }

  /// Get User Albums
  Future<Map<String, dynamic>> getUserAlbums({
    String? username,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (username != null) {
        params['username'] = username;
      }

      final response = await _apiClient.get(
        '/data/users/albums',
        queryParameters: params,
      );

      final albumsList = (response['data']['albums'] as List? ?? [])
          .map((json) => UserAlbum.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'albums': albumsList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {

      rethrow;
    }
  }

  /// Get Album Photos
  Future<Map<String, dynamic>> getAlbumPhotos({
    required String albumId,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'album_id': albumId,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiClient.get(
        '/data/albums/photos',
        queryParameters: params,
      );

      final photosList = (response['data']['photos'] as List? ?? [])
          .map((json) => UserPhoto.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'photos': photosList,
        'pagination': response['data']['pagination'] ?? {},
        'album_info': response['data']['album_info'] ?? {},
      };
    } catch (e) {

      rethrow;
    }
  }
}
