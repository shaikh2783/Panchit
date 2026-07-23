import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_publish_page.dart';
import 'package:snginepro/features/reels/presentation/controllers/reel_edit_controller.dart';
import 'package:snginepro/features/reels/presentation/widgets/color_filter_picker.dart';
import 'package:video_player/video_player.dart';

class ReelEditScreen extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;
  final SelectedMusic? selectedMusic;

  /// True when [selectedMusic] is already burned into [videoPath] (camera
  /// flow) — the video plays its own audio and no side music player runs.
  final bool audioMerged;

  const ReelEditScreen({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
    this.selectedMusic,
    this.audioMerged = false,
  });

  @override
  State<ReelEditScreen> createState() => _ReelEditScreenState();
}

class _ReelEditScreenState extends State<ReelEditScreen> {
  // Tagged so multiple edit screens never share/delete each other's
  // controller.
  late final String _controllerTag;
  late final ReelEditController _ctrl;

  @override
  void initState() {
    super.initState();
    _controllerTag = UniqueKey().toString();
    _ctrl = Get.put(
      ReelEditController(
        videoPath: widget.videoPath,
        selectedMusic: widget.selectedMusic,
        audioMerged: widget.audioMerged,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<ReelEditController>(tag: _controllerTag);
    super.dispose();
  }

  Future<void> _onNext() async {
    // Release (not just pause) the preview player: the publish page runs its
    // own player on the same clip, and two live ExoPlayers on a high-bitrate
    // camera recording exhaust the Java heap.
    await _ctrl.releaseVideo();
    if (!mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelPublishPage(
        videoPath: widget.videoPath,
        thumbnailPath: widget.thumbnailPath,
        selectedMusic: widget.selectedMusic,
        // Preview-only filter for now: the video file itself is unchanged
        // (ColorFiltered is runtime rendering). The metadata travels with
        // the reel so the feed player can re-apply it.
        filterMatrix: _ctrl.activeFilter.toList(),
        filterName: _ctrl.activeFilterName.value,
      ),
    ));

    // Back from publish (publish success pops this route too, in which case
    // we're unmounted and must not touch the deleted controller).
    if (!mounted) return;
    _ctrl.resumeVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video preview with colour filter
            Obx(() {
              final videoController = _ctrl.videoPlayerCtrl;
              if (!_ctrl.isVideoReady.value || videoController == null) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              return GestureDetector(
                onTap: _ctrl.togglePlay,
                child: ColorFiltered(
                  colorFilter:
                      ColorFilter.matrix(_ctrl.activeFilter.toList()),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    ),
                  ),
                ),
              );
            }),

            // Play/pause indicator
            Obx(() {
              if (_ctrl.isPlaying.value) return const SizedBox.shrink();
              return const Center(
                child: Icon(Icons.play_arrow,
                    color: Colors.white70, size: 64),
              );
            }),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _iconButton(
                      Icons.arrow_back,
                      () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    // Next is disabled until the video is ready
                    Obx(() {
                      final isReady = _ctrl.isVideoReady.value;
                      return Opacity(
                        opacity: isReady ? 1 : 0.5,
                        child: GestureDetector(
                          onTap: isReady ? _onNext : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1306C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'next'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Music chip at top-centre
            if (widget.selectedMusic != null)
              Positioned(
                top: 52,
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
                            color: Color(0xFFE1306C), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          widget.selectedMusic!.music?.title ?? 'sound'.tr,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Filter picker at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                child: ColorFilterPicker(
                  onFilterChanged: _ctrl.setFilter,
                  thumbnailPath: widget.thumbnailPath,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
