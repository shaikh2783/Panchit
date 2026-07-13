import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/widgets/color_filter_picker.dart';
import 'package:video_player/video_player.dart';

class ReelEditController extends GetxController {
  ReelEditController({
    required this.videoPath,
    required this.selectedMusic,
    this.audioMerged = false,
  });

  final String videoPath;
  final SelectedMusic? selectedMusic;

  /// True when the music is already burned into [videoPath]; the video then
  /// plays its own audio and the side music player stays off.
  final bool audioMerged;

  /// The side music player only runs while the music is NOT in the file yet
  /// (gallery flow) — otherwise it would double the audio.
  bool get _needsMusicOverlay => selectedMusic != null && !audioMerged;

  VideoPlayerController? videoPlayerCtrl;
  PlayerController? musicPlayerCtrl;

  final RxBool isVideoReady = false.obs;
  final RxBool isPlaying = false.obs;
  final RxList<double> activeFilter = kDefaultFilter.obs;
  final RxString activeFilterName = kReelFilters.first.name.obs;

  @override
  void onInit() {
    super.onInit();
    _initVideo();
    if (_needsMusicOverlay) _initMusic();
  }

  @override
  void onClose() {
    videoPlayerCtrl?.dispose();
    musicPlayerCtrl?.release();
    musicPlayerCtrl?.dispose();
    super.onClose();
  }

  Future<void> _initVideo() async {
    videoPlayerCtrl = VideoPlayerController.file(File(videoPath));
    await videoPlayerCtrl!.initialize();
    videoPlayerCtrl!.setLooping(true);
    // Mute video only while a separate music preview carries the audio.
    if (_needsMusicOverlay) {
      videoPlayerCtrl!.setVolume(0);
    }
    isVideoReady.value = true;
    await play();
  }

  Future<void> _initMusic() async {
    if (selectedMusic == null) return;
    musicPlayerCtrl = PlayerController();
    await musicPlayerCtrl!.preparePlayer(
      path: selectedMusic!.downloadedURL,
      volume: 1.0,
      shouldExtractWaveform: false,
    );
    await musicPlayerCtrl!.seekTo(selectedMusic!.audioStartMS);
    musicPlayerCtrl!.setFinishMode(finishMode: FinishMode.loop);
    await musicPlayerCtrl!.startPlayer();
  }

  Future<void> play() async {
    await videoPlayerCtrl?.play();
    isPlaying.value = true;
    if (_needsMusicOverlay) {
      await musicPlayerCtrl?.seekTo(selectedMusic!.audioStartMS);
      await musicPlayerCtrl?.startPlayer();
    }
  }

  Future<void> pause() async {
    await videoPlayerCtrl?.pause();
    isPlaying.value = false;
    await musicPlayerCtrl?.pausePlayer();
  }

  Future<void> togglePlay() async {
    isPlaying.value ? await pause() : await play();
  }

  /// Updates the preview filter (matrix + name together).
  ///
  /// Note: this only affects runtime rendering via [ColorFiltered]; the video
  /// file itself is untouched. The metadata is carried to the publish step.
  void setFilter(ReelFilter filter) {
    activeFilter.value = filter.matrix;
    activeFilterName.value = filter.name;
  }
}
