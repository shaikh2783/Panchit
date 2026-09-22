import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
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

  void _log(String msg) {
    if (kDebugMode) debugPrint('🎵 [SoundUpload] $msg');
  }

  Future<Music?> uploadUserMusic({
    required File audioFile,
    required String title,
    required String artist,
    required String duration,
    File? coverImage,
  }) async {
    final endpoint = configCfgP('sounds_add');
    if (endpoint.isEmpty) {
      _log('❌ "sounds_add" endpoint missing from server config — '
          'sound cannot be uploaded.');
      throw ApiException('sounds_add endpoint not configured on server');
    }

    final fields = <String, String>{
      'title': title,
      'artist': artist,
      'duration': duration,
      'added_by': '1',
    };

    _log('Uploading sound "$title" (${await audioFile.length()} bytes, '
        'duration=$duration) → $endpoint');

    final response = await _client.multipartPost(
      endpoint,
      body: fields,
      filePath: audioFile.path,
      fileFieldName: 'sound',
      contentType: _inferAudioMediaType(audioFile.path),
      fileName:
          'sound_${DateTime.now().millisecondsSinceEpoch}${_extension(audioFile.path)}',
    );

    final music = _parseUploadedMusic(response);
    if (music == null) {
      _log('❌ Upload response could not be parsed into a Music object: '
          '$response');
    } else if (music.id == null) {
      _log('❌ Upload succeeded but response has no sound id: $response');
    } else {
      _log('✅ Sound uploaded, id=${music.id}');
    }
    return music;
  }

  /// Servers vary in how they wrap the created sound; accept the documented
  /// `data: {...}` plus common `data.sound` / `data.data` nestings.
  Music? _parseUploadedMusic(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['sound'] ?? data['data'] ?? data['music'];
      if (nested is Map<String, dynamic>) {
        return Music.fromJson(nested);
      }
      return Music.fromJson(data);
    }
    return null;
  }

  MediaType _inferAudioMediaType(String path) {
    switch (_extension(path)) {
      case '.mp3':
        return MediaType('audio', 'mpeg');
      case '.wav':
        return MediaType('audio', 'wav');
      case '.ogg':
        return MediaType('audio', 'ogg');
      case '.m4a':
      case '.aac':
      case '.mp4':
      default:
        return MediaType('audio', 'mp4');
    }
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '';
    return path.substring(dot).toLowerCase();
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