import 'dart:io';

import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/main.dart' show configCfgP;

class MusicApiService {
  MusicApiService(this._client);

  final ApiClient _client;

  Future<List<Music>> fetchMusicExplore({int? lastItemId}) async {
    final params = <String, String>{};
    if (lastItemId != null) params['last_item_id'] = '$lastItemId';

    final response = await _client.get(
      configCfgP('sounds'),
      queryParameters: params,
    );
    return _parseMusicList(response);
  }

  Future<List<MusicCategory>> fetchMusicCategories() async {
    final response = await _client.get(configCfgP('sound_categories'));
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MusicCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<Music>> fetchMusicByCategory({
    required int categoryId,
    int? lastItemId,
  }) async {
    final params = <String, String>{'category_id': '$categoryId'};
    if (lastItemId != null) params['last_item_id'] = '$lastItemId';

    final response = await _client.get(
      configCfgP('sounds'),
      queryParameters: params,
    );
    return _parseMusicList(response);
  }

  Future<List<Music>> fetchSavedMusics() async {
    final response = await _client.get(configCfgP('sounds_saved'));
    return _parseMusicList(response);
  }

  Future<List<Music>> searchMusic({
    required String keyword,
    int? lastItemId,
  }) async {
    final params = <String, String>{'q': keyword};
    if (lastItemId != null) params['last_item_id'] = '$lastItemId';

    final response = await _client.get(
      configCfgP('sounds_search'),
      queryParameters: params,
    );
    return _parseMusicList(response);
  }

  Future<Music?> uploadUserMusic({
    required File audioFile,
    required String title,
    required String artist,
    required String duration,
    File? coverImage,
  }) async {
    final fields = <String, String>{
      'title': title,
      'artist': artist,
      'duration': duration,
      'added_by': '1',
    };

    final response = await _client.multipartPost(
      configCfgP('sounds_add'),
      body: fields,
      filePath: audioFile.path,
      fileFieldName: 'sound',
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Music.fromJson(data);
    }
    return null;
  }

  List<Music> _parseMusicList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Music.fromJson).toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['data'] ?? data['items'] ?? data['sounds'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(Music.fromJson)
            .toList();
      }
    }
    return [];
  }
}