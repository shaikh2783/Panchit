import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/create_post_request.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/audio_extraction_service.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';

enum ReelUploadStage {
  extractingSound,
  uploadingSound,
  uploadingVideo,
  publishing,
  done,
}

class ReelUploadException implements Exception {
  ReelUploadException(this.stage, this.cause);

  final ReelUploadStage stage;
  final Object cause;

  @override
  String toString() => 'ReelUploadException(${stage.name}): $cause';
}

/// Orchestrates the full reel publish pipeline against the backend contract
/// (docs/reels_backend_api.md): optional original-sound derivation, video
/// upload, then post creation. Sound merging is server-side — only
/// `sound_id` / `sound_start_ms` are sent.
///
/// Intermediate results are cached per video path so a retry after a failure
/// resumes at the failed stage instead of re-uploading earlier artifacts.
class ReelUploadService {
  ReelUploadService({
    required PostsApiService postsService,
    required MusicApiService musicService,
    required AudioExtractionService audioExtractor,
    required String? Function() usernameProvider,
  })  : _postsService = postsService,
        _musicService = musicService,
        _audioExtractor = audioExtractor,
        _usernameProvider = usernameProvider;

  final PostsApiService _postsService;
  final MusicApiService _musicService;
  final AudioExtractionService _audioExtractor;
  final String? Function() _usernameProvider;

  // Resumable per-video state.
  String? _stateVideoPath;
  UploadedFileData? _uploadedVideo;
  int? _originalSoundId;
  int? _originalSoundStartMs;
  bool _originalSoundAttempted = false;

  void _log(String msg) {
    if (kDebugMode) debugPrint('🎬 [ReelPublish] $msg');
  }

  Future<CreatePostResponse> publishReel({
    required String videoPath,
    required String message,
    String privacy = 'public',
    SelectedMusic? selectedMusic,
    void Function(ReelUploadStage stage, double progress)? onProgress,
  }) async {
    if (_stateVideoPath != videoPath) {
      _resetState(videoPath);
    }

    _log('▶︎ publishReel started');
    _log('  video: $videoPath');
    _log(
      '  selectedMusic: ${selectedMusic == null ? 'none (will derive original sound from video)' : 'id=${selectedMusic.music?.id} title="${selectedMusic.music?.title}" startMs=${selectedMusic.audioStartMS}'}',
    );

    // 1. Sound: selected library sound wins; otherwise derive an original
    //    sound once per video. Derivation failure is non-fatal — the reel is
    //    published without a sound, matching the reference app's behavior.
    int? soundId = selectedMusic?.music?.id;
    int? soundStartMs = selectedMusic != null ? selectedMusic.audioStartMS : null;

    if (selectedMusic != null && soundId == null) {
      // "Use this sound" can hand over a music object without an id when the
      // feed post carried sound_url but no sound_id (gaps doc §1). The reel
      // still publishes (audio is merged client-side) but won't reference
      // the sound.
      _log('⚠️ Selected music has NO id — sound_id will not be sent and '
          'original-sound derivation is skipped.');
    }

    if (selectedMusic == null) {
      if (!_originalSoundAttempted) {
        _originalSoundAttempted = true;
        try {
          _log('Stage 1a: extracting audio track from video…');
          onProgress?.call(ReelUploadStage.extractingSound, 0);
          final extracted = await _audioExtractor.extractAudio(videoPath);
          if (extracted != null) {
            _log('Stage 1b: uploading extracted sound '
                '(${await extracted.file.length()} bytes)…');
            onProgress?.call(ReelUploadStage.uploadingSound, 0);
            final username = _usernameProvider() ?? 'Unknown';
            final music = await _withRetry(() => _musicService.uploadUserMusic(
                  audioFile: extracted.file,
                  title: 'Original sound - $username',
                  artist: username,
                  duration:
                      AudioExtractionService.formatDuration(extracted.durationMs),
                ));
            _originalSoundId = music?.id;
            _originalSoundStartMs = 0;
            if (_originalSoundId == null) {
              _log('⚠️ Sound upload returned no id — reel will be published '
                  'WITHOUT a sound.');
            } else {
              _log('Original sound ready: sound_id=$_originalSoundId');
            }
          } else {
            _log('⚠️ No audio extracted (no track or ffmpeg failure) — reel '
                'will be published WITHOUT a sound.');
          }
        } catch (e) {
          // Non-fatal: continue publishing without a sound, but allow the
          // next explicit retry to attempt the sound again.
          _originalSoundAttempted = false;
          _log('⚠️ Original-sound derivation FAILED (non-fatal, reel will be '
              'published without sound): $e');
        }
      } else {
        _log('Original sound already attempted for this video: '
            'sound_id=$_originalSoundId');
      }
      soundId = _originalSoundId;
      soundStartMs = _originalSoundStartMs;
    }

    _log('Sound resolution complete: sound_id=$soundId, '
        'sound_start_ms=$soundStartMs');

    // 2. Video upload (skipped when already uploaded by a previous attempt).
    if (_uploadedVideo == null) {
      try {
        _log('Stage 2: uploading video…');
        final uploaded = await _withRetry(
          () => _postsService.uploadFile(
            File(videoPath),
            type: FileUploadType.video,
            onProgress: (sent, total) {
              if (total > 0) {
                onProgress?.call(ReelUploadStage.uploadingVideo, sent / total);
              }
            },
          ),
        );
        if (uploaded == null) {
          throw Exception('Video upload returned no data');
        }
        _uploadedVideo = uploaded;
        _log('Video uploaded: source=${uploaded.source} thumb=${uploaded.thumb}');
      } catch (e) {
        _log('❌ Video upload FAILED: $e');
        throw ReelUploadException(ReelUploadStage.uploadingVideo, e);
      }
    } else {
      _log('Stage 2: video already uploaded on a previous attempt — skipping.');
    }

    // 3. Create the post.
    onProgress?.call(ReelUploadStage.publishing, 0);
    final thumbPath = _relativeThumbPath(_uploadedVideo!.thumb);
    final request = CreatePostRequest(
      handle: 'me',
      privacy: privacy,
      message: message,
      reel: {
        'source': _uploadedVideo!.source,
        if (thumbPath != null) 'thumb': thumbPath,
        if (soundId != null) 'sound_id': '$soundId',
        if (soundId != null) 'sound_start_ms': '${soundStartMs ?? 0}',
      },
      reelThumbnail: thumbPath,
    );
    _log('Stage 3: creating reel post, reel payload: '
        '${request.toJson()['reel']}');

    try {
      final response =
          await _withRetry(() => _postsService.createPostAdvanced(request));
      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to create reel');
      }
      _log('✅ Reel published: post_id=${response.postId} '
          '(sound_id=${soundId ?? 'NONE'})');
      onProgress?.call(ReelUploadStage.done, 1);
      _resetState(null);
      return response;
    } on ReelUploadException {
      rethrow;
    } catch (e) {
      _log('❌ Reel post creation FAILED: $e');
      throw ReelUploadException(ReelUploadStage.publishing, e);
    }
  }

  void _resetState(String? videoPath) {
    _stateVideoPath = videoPath;
    _uploadedVideo = null;
    _originalSoundId = null;
    _originalSoundStartMs = null;
    _originalSoundAttempted = false;
  }

  /// Thumbnail is stored relative to `/content/uploads/` per the contract.
  String? _relativeThumbPath(String? thumbUrl) {
    if (thumbUrl == null) return null;
    if (thumbUrl.contains('/content/uploads/')) {
      return thumbUrl.split('/content/uploads/').last;
    }
    return thumbUrl;
  }

  Future<T> _withRetry<T>(Future<T> Function() op, {int retries = 2}) async {
    var attempt = 0;
    while (true) {
      try {
        return await op();
      } catch (e) {
        attempt++;
        if (attempt > retries) rethrow;
        _log('Attempt $attempt failed ($e) — retrying…');
        await Future.delayed(Duration(seconds: attempt == 1 ? 1 : 3));
      }
    }
  }
}
