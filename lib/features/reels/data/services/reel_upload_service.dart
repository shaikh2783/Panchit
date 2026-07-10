import 'dart:async';
import 'dart:io';

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

    // 1. Sound: selected library sound wins; otherwise derive an original
    //    sound once per video. Derivation failure is non-fatal — the reel is
    //    published without a sound, matching the reference app's behavior.
    int? soundId = selectedMusic?.music?.id;
    int? soundStartMs = selectedMusic != null ? selectedMusic.audioStartMS : null;

    if (selectedMusic == null) {
      if (!_originalSoundAttempted) {
        _originalSoundAttempted = true;
        try {
          onProgress?.call(ReelUploadStage.extractingSound, 0);
          final extracted = await _audioExtractor.extractAudio(videoPath);
          if (extracted != null) {
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
          }
        } catch (_) {
          // Non-fatal: continue publishing without a sound.
        }
      }
      soundId = _originalSoundId;
      soundStartMs = _originalSoundStartMs;
    }

    // 2. Video upload (skipped when already uploaded by a previous attempt).
    if (_uploadedVideo == null) {
      try {
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
      } catch (e) {
        throw ReelUploadException(ReelUploadStage.uploadingVideo, e);
      }
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

    try {
      final response =
          await _withRetry(() => _postsService.createPostAdvanced(request));
      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to create reel');
      }
      onProgress?.call(ReelUploadStage.done, 1);
      _resetState(null);
      return response;
    } on ReelUploadException {
      rethrow;
    } catch (e) {
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
      } catch (_) {
        attempt++;
        if (attempt > retries) rethrow;
        await Future.delayed(Duration(seconds: attempt == 1 ? 1 : 3));
      }
    }
  }
}
