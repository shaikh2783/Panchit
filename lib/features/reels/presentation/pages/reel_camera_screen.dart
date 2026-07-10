import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';
import 'package:snginepro/features/reels/presentation/controllers/music_sheet_controller.dart';
import 'package:snginepro/features/reels/presentation/controllers/reel_camera_controller.dart';
import 'package:snginepro/features/reels/presentation/pages/music_sheet.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_edit_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class ReelCameraScreen extends StatelessWidget {
  final MusicApiService musicService;
  final SelectedMusic? initialMusic;

  /// When true, the screen pops with the recorded file path
  /// (`Navigator.pop(context, path)`) instead of pushing [ReelEditScreen].
  final bool popOnFinish;

  /// Initial recording length; the user can change it via the 15/30/60 chips.
  final int initialDurationSec;

  const ReelCameraScreen({
    super.key,
    required this.musicService,
    this.initialMusic,
    this.popOnFinish = false,
    this.initialDurationSec = kMaxRecordSec,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReelCameraController(
      musicService: musicService,
      initialMusic: initialMusic,
      initialDurationSec: initialDurationSec,
    ));
    ctrl.onAutoStop = (path) {
      if (context.mounted) _finishRecording(context, ctrl, path);
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            Obx(() {
              if (!ctrl.isCameraReady.value ||
                  ctrl.cameraCtrl == null) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              return CameraPreview(ctrl.cameraCtrl!);
            }),

            // Top controls
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _iconButton(
                    Icons.arrow_back,
                    () {
                      Get.delete<ReelCameraController>();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  Obx(() => _iconButton(
                        ctrl.isFlashOn.value
                            ? Icons.flash_on
                            : Icons.flash_off,
                        ctrl.toggleFlash,
                      )),
                  const SizedBox(width: 8),
                  _iconButton(Icons.flip_camera_ios, ctrl.flipCamera),
                  const SizedBox(width: 8),
                  // TODO(reels): effect rendering pipeline.
                  _iconButton(Icons.auto_awesome,
                      () => _showComingSoon(context, 'effects'.tr)),
                  const SizedBox(width: 8),
                  // TODO(reels): self-timer countdown before recording.
                  _iconButton(Icons.timer_outlined,
                      () => _showComingSoon(context, 'timer'.tr)),
                ],
              ),
            ),

            // Music indicator at top-centre
            Obx(() {
              if (!ctrl.hasMusicSelected.value ||
                  ctrl.selectedMusic == null) return const SizedBox.shrink();
              return Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note,
                            color: Color(0xFFE1306C), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          ctrl.selectedMusic!.music?.title ?? 'sound'.tr,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Progress bar
            Obx(() {
              if (!ctrl.isRecording.value) return const SizedBox.shrink();
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: ctrl.recordProgress.value,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFE1306C),
                  minHeight: 3,
                ),
              );
            }),

            // Bottom controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Countdown while recording, duration selector otherwise
                  Obx(() {
                    if (!ctrl.isRecording.value) {
                      return _durationSelector(ctrl);
                    }
                    return Text(
                      '${ctrl.remainingSec}s',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Music button, or pause/resume while recording
                      Obx(() {
                        if (ctrl.isRecording.value) {
                          return GestureDetector(
                            onTap: () => ctrl.isPaused.value
                                ? ctrl.resumeRecording()
                                : ctrl.pauseRecording(),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white24,
                              ),
                              child: Icon(
                                ctrl.isPaused.value
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: () async {
                            final musicCtrl = MusicSheetController(
                              musicService: musicService,
                              videoDurationSec: 30,
                            );
                            final result = await showMusicSheet(
                              context,
                              controller: musicCtrl,
                            );
                            musicCtrl.dispose();
                            if (result != null) {
                              ctrl.setSelectedMusic(result);
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ctrl.hasMusicSelected.value
                                  ? const Color(0xFFE1306C)
                                  : Colors.white24,
                            ),
                            child: const Icon(Icons.music_note,
                                color: Colors.white, size: 22),
                          ),
                        );
                      }),

                      // Record button
                      Obx(() => GestureDetector(
                            onTap: () async {
                              if (ctrl.isRecording.value) {
                                final path = await ctrl.stopRecording();
                                if (path == null || !context.mounted) return;
                                _finishRecording(context, ctrl, path);
                              } else {
                                ctrl.startRecording();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 4),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: ctrl.isRecording.value
                                      ? BorderRadius.circular(6)
                                      : BorderRadius.circular(38),
                                  color: const Color(0xFFE1306C),
                                ),
                              ),
                            ),
                          )),

                      // Remove music / placeholder
                      Obx(() {
                        if (!ctrl.hasMusicSelected.value ||
                            ctrl.isRecording.value) {
                          return const SizedBox(width: 48, height: 48);
                        }
                        return GestureDetector(
                          onTap: () => ctrl.setSelectedMusic(null),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: const Icon(Icons.music_off,
                                color: Colors.white, size: 22),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Routes the finished recording: pops with the file path when
  /// [popOnFinish] is set (CreateReelPage flow), otherwise continues to the
  /// edit step (default entry flow).
  Future<void> _finishRecording(
    BuildContext context,
    ReelCameraController ctrl,
    String videoPath,
  ) async {
    if (popOnFinish) {
      Get.delete<ReelCameraController>();
      Navigator.of(context).pop(videoPath);
      return;
    }
    await _goToEdit(context, ctrl, videoPath);
  }

  Widget _durationSelector(ReelCameraController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ReelCameraController.durationOptions.map((seconds) {
        final selected = ctrl.selectedDurationSec.value == seconds;
        return GestureDetector(
          onTap: () => ctrl.setDuration(seconds),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE1306C) : Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${seconds}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('feature_coming_soon'.trParams({'feature': feature})),
      ),
    );
  }

  Future<void> _goToEdit(
    BuildContext context,
    ReelCameraController ctrl,
    String videoPath,
  ) async {
    // Generate thumbnail
    final thumb = await vt.VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      quality: 75,
    );

    if (!context.mounted) return;

    Get.delete<ReelCameraController>();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelEditScreen(
        videoPath: videoPath,
        thumbnailPath: thumb,
        selectedMusic: ctrl.selectedMusic,
      ),
    ));
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black38,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
