import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';

const int kMaxRecordSec = 60;

class ReelCameraController extends GetxController {
  ReelCameraController({
    required this.musicService,
    this.initialMusic,
    int initialDurationSec = kMaxRecordSec,
  }) : selectedDurationSec =
            (durationOptions.contains(initialDurationSec)
                    ? initialDurationSec
                    : kMaxRecordSec)
                .obs;

  static const List<int> durationOptions = [15, 30, 60];

  final MusicApiService musicService;
  final SelectedMusic? initialMusic;

  /// Recording length chosen by the user (15/30/60s).
  final RxInt selectedDurationSec;

  // Camera
  List<CameraDescription> cameras = [];
  CameraController? cameraCtrl;
  final RxBool isCameraReady = false.obs;
  final RxBool isFrontCamera = false.obs;
  final RxBool isFlashOn = false.obs;

  // Recording
  final RxBool isRecording = false.obs;
  final RxBool isPaused = false.obs;
  final RxDouble recordProgress = 0.0.obs;
  final RxInt elapsedSec = 0.obs;
  final Stopwatch _recordWatch = Stopwatch();
  Timer? _progressTimer;

  // Output
  String? recordedVideoPath;

  /// Invoked when recording stops because [maxRecordMs] elapsed, so the
  /// screen can continue to the edit step exactly as it does on manual stop.
  void Function(String path)? onAutoStop;

  // Music
  SelectedMusic? selectedMusic;
  final RxBool hasMusicSelected = false.obs;
  PlayerController? _musicPlayer;
  int? _musicDurationMs;

  /// Recording stops automatically once this many milliseconds have elapsed.
  /// With music selected, the cap is the remaining audio after the trim
  /// offset so the reel never outlasts its soundtrack.
  int get maxRecordMs {
    final hardCapMs = selectedDurationSec.value * 1000;
    final music = selectedMusic;
    if (music == null) return hardCapMs;
    final endMs = music.endMilliSec ?? _musicDurationMs;
    if (endMs == null) return hardCapMs;
    final available = endMs - music.audioStartMS;
    if (available <= 0) return hardCapMs;
    return min(hardCapMs, available);
  }

  @override
  void onInit() {
    super.onInit();
    _initCamera().then((_) {
      if (initialMusic != null) setSelectedMusic(initialMusic);
    });
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    cameraCtrl?.dispose();
    _musicPlayer?.release();
    _musicPlayer?.dispose();
    super.onClose();
  }

  Future<void> _initCamera() async {
    isCameraReady.value = false;
    cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final index = isFrontCamera.value
        ? cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front)
        : cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.back);

    await _startCamera(cameras[index < 0 ? 0 : index]);
  }

  Future<void> _startCamera(CameraDescription desc) async {
    cameraCtrl?.dispose();
    cameraCtrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: selectedMusic == null,
    );
    try {
      await cameraCtrl!.initialize();
      isCameraReady.value = true;
    } catch (_) {
      isCameraReady.value = false;
    }
  }

  /// Seconds left before auto-stop; shown as a countdown while recording.
  int get remainingSec => max(0, (maxRecordMs ~/ 1000) - elapsedSec.value);

  void setDuration(int seconds) {
    if (isRecording.value || !durationOptions.contains(seconds)) return;
    selectedDurationSec.value = seconds;
  }

  Future<void> flipCamera() async {
    if (isRecording.value) return;
    isFrontCamera.value = !isFrontCamera.value;
    await _initCamera();
  }

  Future<void> toggleFlash() async {
    if (cameraCtrl == null || !isCameraReady.value) return;
    isFlashOn.value = !isFlashOn.value;
    await cameraCtrl!.setFlashMode(
      isFlashOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  void setSelectedMusic(SelectedMusic? music) {
    if (isRecording.value) return;
    selectedMusic = music;
    hasMusicSelected.value = music != null;
    // Restart camera with audio disabled when music is selected
    _initCamera();
    if (music != null) {
      _prepareMusicPlayer(music);
    } else {
      _musicPlayer?.release();
      _musicPlayer?.dispose();
      _musicPlayer = null;
      _musicDurationMs = null;
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('🎥 [ReelCamera] $msg');
  }

  Future<void> _prepareMusicPlayer(SelectedMusic music) async {
    _musicPlayer?.release();
    _musicPlayer?.dispose();
    _musicPlayer = PlayerController();
    try {
      // No waveform is rendered on the camera screen; skipping extraction
      // makes prepare instant and avoids extraction failures blocking
      // playback of cache-manager files.
      await _musicPlayer!.preparePlayer(
        path: music.downloadedURL,
        volume: 1.0,
        shouldExtractWaveform: false,
      );
      _musicDurationMs = await _musicPlayer!.getDuration(DurationType.max);
      await _musicPlayer!.seekTo(music.audioStartMS);
      _musicPlayer!.setFinishMode(finishMode: FinishMode.pause);
      _log('Music player ready: "${music.music?.title}" '
          '(${_musicDurationMs}ms, start at ${music.audioStartMS}ms)');
    } catch (e) {
      _log('❌ Music player prepare FAILED for "${music.downloadedURL}": $e');
      _musicPlayer?.dispose();
      _musicPlayer = null;
      _musicDurationMs = null;
    }
  }

  Future<void> startRecording() async {
    if (cameraCtrl == null ||
        !isCameraReady.value ||
        isRecording.value) return;

    await cameraCtrl!.startVideoRecording();
    isRecording.value = true;
    isPaused.value = false;
    elapsedSec.value = 0;
    recordProgress.value = 0;
    _recordWatch
      ..reset()
      ..start();

    if (selectedMusic != null) {
      if (_musicPlayer == null) {
        // Prepare failed earlier (or is still in flight) — retry once so the
        // user still hears the track while recording.
        _log('Music player not ready at record start — re-preparing…');
        await _prepareMusicPlayer(selectedMusic!);
      }
      try {
        await _musicPlayer?.seekTo(selectedMusic!.audioStartMS);
        await _musicPlayer?.startPlayer();
        _log('Music playback started with recording.');
      } catch (e) {
        _log('❌ Could not start music playback: $e');
      }
    }

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsedMs = _recordWatch.elapsedMilliseconds;
      elapsedSec.value = elapsedMs ~/ 1000;
      recordProgress.value = elapsedMs / maxRecordMs;
      if (elapsedMs >= maxRecordMs) {
        stopRecording().then((path) {
          if (path != null) onAutoStop?.call(path);
        });
      }
    });
  }

  Future<void> pauseRecording() async {
    if (!isRecording.value || isPaused.value) return;
    isPaused.value = true;
    _recordWatch.stop();
    await _musicPlayer?.pausePlayer();
    try {
      await cameraCtrl!.pauseVideoRecording();
    } catch (_) {
      // Pause unsupported on this device: keep recording, undo the pause UI.
      isPaused.value = false;
      _recordWatch.start();
      if (selectedMusic != null) await _musicPlayer?.startPlayer();
    }
  }

  Future<void> resumeRecording() async {
    if (!isRecording.value || !isPaused.value) return;
    await cameraCtrl!.resumeVideoRecording();
    isPaused.value = false;
    _recordWatch.start();
    if (selectedMusic != null && _musicPlayer != null) {
      await _musicPlayer!.startPlayer();
    }
  }

  Future<String?> stopRecording() async {
    if (!isRecording.value) return null;
    _progressTimer?.cancel();
    _recordWatch.stop();
    isRecording.value = false;
    isPaused.value = false;

    await _musicPlayer?.pausePlayer();

    if (isFlashOn.value) {
      isFlashOn.value = false;
      try {
        await cameraCtrl?.setFlashMode(FlashMode.off);
      } catch (_) {}
    }

    try {
      final file = await cameraCtrl!.stopVideoRecording();
      recordedVideoPath = file.path;
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> finishRecording() async {
    final path = isRecording.value ? await stopRecording() : recordedVideoPath;
    return path;
  }

  bool get hasRecording => recordedVideoPath != null;
  File? get recordedFile =>
      recordedVideoPath != null ? File(recordedVideoPath!) : null;
}
