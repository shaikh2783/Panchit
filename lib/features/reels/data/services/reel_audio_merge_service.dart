import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';

/// Burns a selected music track into a recorded reel video so the prepared
/// clip carries its soundtrack from the edit step onward. The music replaces
/// the video's audio track (recordings with music are captured with the mic
/// disabled, so there is nothing to mix).
///
/// Merging is best-effort: callers fall back to the original video on
/// failure — the reel still references the sound via `sound_id` at publish.
class ReelAudioMergeService {
  static void _log(String msg) {
    if (kDebugMode) debugPrint('🎵 [SoundMerge] $msg');
  }

  /// Returns the path of the merged video, or null when merging fails.
  static Future<String?> mergeMusicIntoVideo({
    required String videoPath,
    required SelectedMusic music,
  }) async {
    final audioPath = music.downloadedURL;
    if (audioPath.isEmpty || !await File(audioPath).exists()) {
      _log('Music file missing at "$audioPath" — skipping merge.');
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/reel_merged_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final startSec = (music.audioStartMS / 1000).toStringAsFixed(3);

    _log('Merging music into video…');
    _log('  video: $videoPath');
    _log('  audio: $audioPath (start at ${music.audioStartMS}ms)');

    // -ss before the audio input seeks the music to the trim offset; video
    // stream is copied untouched; -shortest ends the output with the video.
    final session = await FFmpegKit.execute(
      '-y -i "$videoPath" -ss $startSec -i "$audioPath" '
      '-map 0:v -map 1:a -c:v copy -c:a aac -b:a 128k -shortest '
      '-movflags +faststart "$outputPath"',
    );

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      final tail = logs == null || logs.length <= 600
          ? logs
          : logs.substring(logs.length - 600);
      _log('❌ ffmpeg merge failed (rc=$returnCode). Log tail:\n$tail');
      return null;
    }

    final output = File(outputPath);
    if (!await output.exists() || await output.length() == 0) {
      _log('❌ ffmpeg reported success but output is missing/empty.');
      return null;
    }

    _log('✅ Merge OK → $outputPath (${await output.length()} bytes)');
    return outputPath;
  }
}
