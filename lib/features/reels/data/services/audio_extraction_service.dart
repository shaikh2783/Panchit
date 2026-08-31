import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/stream_information.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ExtractedAudio {
  const ExtractedAudio({required this.file, required this.durationMs});

  final File file;
  final int durationMs;
}

/// Extracts the audio track of a recorded/picked reel video so it can be
/// uploaded as a reusable "original sound" (sounds_add endpoint).
class AudioExtractionService {
  void _log(String msg) {
    if (kDebugMode) debugPrint('🎵 [SoundExtract] $msg');
  }

  /// Returns null when the video has no audio track or extraction fails —
  /// callers treat that as "publish without an original sound".
  Future<ExtractedAudio?> extractAudio(String videoPath) async {
    _log('Probing video for audio track: $videoPath');
    final probeSession = await FFprobeKit.getMediaInformation(videoPath);
    final info = probeSession.getMediaInformation();
    if (info == null) {
      _log('FFprobe returned no media information — cannot extract sound.');
      return null;
    }

    StreamInformation? audioStream;
    for (final stream in info.getStreams()) {
      if (stream.getType() == 'audio') {
        audioStream = stream;
        break;
      }
    }
    if (audioStream == null) {
      _log('Video has NO audio stream — publishing without original sound.');
      return null;
    }
    _log('Audio stream found: codec=${audioStream.getCodec()}');

    final durationSec = double.tryParse(info.getDuration() ?? '') ?? 0;
    final durationMs = (durationSec * 1000).round();
    if (durationMs <= 0) {
      _log('Invalid duration ($durationSec s) — cannot extract sound.');
      return null;
    }
    _log('Duration: ${durationMs}ms');

    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/reel_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // AAC sources remux without re-encoding; anything else is re-encoded.
    final isAac = audioStream.getCodec() == 'aac';
    var success = await _runFfmpeg(videoPath, outputPath, copyCodec: isAac);
    if (!success && isAac) {
      _log('Codec-copy remux failed, retrying with AAC re-encode…');
      success = await _runFfmpeg(videoPath, outputPath, copyCodec: false);
    }
    if (!success) {
      _log('FFmpeg extraction FAILED — publishing without original sound.');
      return null;
    }

    final output = File(outputPath);
    if (!await output.exists() || await output.length() == 0) {
      _log('FFmpeg reported success but output file is missing/empty.');
      return null;
    }

    _log(
      'Extraction OK → $outputPath (${await output.length()} bytes, ${durationMs}ms)',
    );
    return ExtractedAudio(file: output, durationMs: durationMs);
  }

  Future<bool> _runFfmpeg(
    String inputPath,
    String outputPath, {
    required bool copyCodec,
  }) async {
    final codecArgs = copyCodec ? '-c:a copy' : '-c:a aac -b:a 128k';
    _log('Running ffmpeg (copyCodec=$copyCodec)…');
    final session = await FFmpegKit.execute(
      '-y -i "$inputPath" -vn $codecArgs "$outputPath"',
    );
    final returnCode = await session.getReturnCode();
    final success = ReturnCode.isSuccess(returnCode);
    if (!success) {
      final logs = await session.getAllLogsAsString();
      final tail = logs == null || logs.length <= 600
          ? logs
          : logs.substring(logs.length - 600);
      _log('ffmpeg failed (rc=$returnCode). Log tail:\n$tail');
    }
    return success;
  }

  /// "MM:SS" as required by the sounds_add contract (§13).
  static String formatDuration(int durationMs) {
    final totalSec = (durationMs / 1000).round();
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}