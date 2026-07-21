import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';
import 'package:snginepro/features/reels/data/services/reel_audio_merge_service.dart';
import 'package:snginepro/features/reels/presentation/controllers/music_sheet_controller.dart';
import 'package:snginepro/features/reels/presentation/controllers/reel_camera_controller.dart';
import 'package:snginepro/features/reels/presentation/pages/music_sheet.dart'
    as reel_music_sheet;
import 'package:snginepro/features/reels/presentation/pages/reel_edit_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:snginepro/features/reels/presentation/pages/selected_music_sheet.dart';
import 'dart:async';
const Color _accentColor = Color(0xFFE1306C);
class _CameraEffect {
  final String id;
  final String label;
  final List<double> matrix;

  const _CameraEffect({
    required this.id,
    required this.label,
    required this.matrix,
  });
}
const List<double> _originalEffectMatrix = [
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

const List<_CameraEffect> _cameraEffects = [
  _CameraEffect(
    id: 'original',
    label: 'Original',
    matrix: _originalEffectMatrix,
  ),
  _CameraEffect(
    id: 'warm',
    label: 'Warm',
    matrix: [
      1.10, 0, 0, 0, 8,
      0, 1.02, 0, 0, 3,
      0, 0, 0.90, 0, -3,
      0, 0, 0, 1, 0,
    ],
  ),
  _CameraEffect(
    id: 'cool',
    label: 'Cool',
    matrix: [
      0.92, 0, 0, 0, -2,
      0, 1, 0, 0, 2,
      0, 0, 1.12, 0, 8,
      0, 0, 0, 1, 0,
    ],
  ),
  _CameraEffect(
    id: 'mono',
    label: 'Mono',
    matrix: [
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ],
  ),
  _CameraEffect(
    id: 'vivid',
    label: 'Vivid',
    matrix: [
      1.20, -0.10, -0.10, 0, 0,
      -0.10, 1.20, -0.10, 0, 0,
      -0.10, -0.10, 1.20, 0, 0,
      0, 0, 0, 1, 0,
    ],
  ),
];
class ReelCameraScreen extends StatefulWidget {
  final MusicApiService musicService;
  final SelectedMusic? initialMusic;

  /// When true, this screen returns the recorded file path instead of
  /// navigating to [ReelEditScreen].
  final bool popOnFinish;

  /// Initial recording length. The user can change it using the
  /// available duration options.
  final int initialDurationSec;

  const ReelCameraScreen({
    super.key,
    required this.musicService,
    this.initialMusic,
    this.popOnFinish = false,
    this.initialDurationSec = kMaxRecordSec,
  });

  @override
  State<ReelCameraScreen> createState() => _ReelCameraScreenState();
}

class _ReelCameraScreenState extends State<ReelCameraScreen> {
  late final ReelCameraController _controller;

  bool _isFinishing = false;
  bool _isMusicSheetOpen = false;
  Timer? _countdownTimer;

  int _selectedTimerSeconds = 0;
  int _countdownValue = 0;

  bool _isCountingDown = false;
  _CameraEffect _selectedEffect = _cameraEffects.first;
  @override
  void initState() {
    super.initState();

    _controller = Get.put(
      ReelCameraController(
        musicService: widget.musicService,
        initialMusic: widget.initialMusic,
        initialDurationSec: widget.initialDurationSec,
      ),
    );

    _controller.onAutoStop = _handleAutoStop;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.onAutoStop = null;

    if (Get.isRegistered<ReelCameraController>()) {
      Get.delete<ReelCameraController>();
    }

    super.dispose();
  }

  void _handleAutoStop(String path) {
    if (!mounted || _isFinishing) {
      return;
    }

    _finishRecording(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildCameraScrims(),
          _buildRecordingProgress(),
          _buildSafeAreaControls(),
          _buildCountdownOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Camera preview
  // ---------------------------------------------------------------------------

  Widget _buildCameraPreview() {
    return Obx(() {
      final cameraController = _controller.cameraCtrl;

      if (!_controller.isCameraReady.value ||
          cameraController == null ||
          !cameraController.value.isInitialized) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        );
      }

      final previewSize = cameraController.value.previewSize;

      Widget preview;

      if (previewSize == null) {
        preview = CameraPreview(cameraController);
      } else {
        preview = ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
        );
      }

      return ColorFiltered(
        colorFilter: ColorFilter.matrix(
          _selectedEffect.matrix,
        ),
        child: preview,
      );
    });
  }

  /// Adds dark gradients over the preview so controls remain readable.
  Widget _buildCameraScrims() {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6000000),
                  Color(0x33000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xE6000000),
                  Color(0x66000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recording progress
  // ---------------------------------------------------------------------------

  Widget _buildRecordingProgress() {
    return Obx(() {
      if (!_controller.isRecording.value) {
        return const SizedBox.shrink();
      }

      final progress = _controller.recordProgress.value
          .clamp(0.0, 1.0)
          .toDouble();

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: _accentColor,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Main controls
  // ---------------------------------------------------------------------------

  Widget _buildSafeAreaControls() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopControls(),
          const SizedBox(height: 12),
          _buildSelectedMusicPill(),
          const Spacer(),
          _buildRecordingTimerOrDurationSelector(),
          const SizedBox(height: 14),
          _buildBottomControls(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    if (!_isCountingDown) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              '$_countdownValue',
              key: ValueKey(_countdownValue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 92,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _openTimerPicker() async {
    if (_controller.isRecording.value ||
        _isFinishing ||
        _isCountingDown) {
      return;
    }

    final selectedSeconds = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161618),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Timer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ...[0, 3, 5, 10].map((seconds) {
                final isSelected =
                    _selectedTimerSeconds == seconds;

                return ListTile(
                  onTap: () {
                    Navigator.of(sheetContext).pop(seconds);
                  },
                  leading: Icon(
                    seconds == 0
                        ? Icons.timer_off_outlined
                        : Icons.timer_outlined,
                    color: isSelected
                        ? _accentColor
                        : Colors.white70,
                  ),
                  title: Text(
                    seconds == 0
                        ? 'Off'
                        : '$seconds seconds',
                    style: TextStyle(
                      color: isSelected
                          ? _accentColor
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                    Icons.check_rounded,
                    color: _accentColor,
                  )
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedSeconds == null) {
      return;
    }

    setState(() {
      _selectedTimerSeconds = selectedSeconds;
    });
  }
  void _startRecordingWithCountdown() {
    if (_selectedTimerSeconds <= 0) {
      _controller.startRecording();
      return;
    }

    _countdownTimer?.cancel();

    setState(() {
      _isCountingDown = true;
      _countdownValue = _selectedTimerSeconds;
    });

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_countdownValue <= 1) {
          timer.cancel();

          setState(() {
            _isCountingDown = false;
            _countdownValue = 0;
          });

          _controller.startRecording();
          return;
        }

        setState(() {
          _countdownValue -= 1;
        });
      },
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Obx(() {
        final isRecording = _controller.isRecording.value;

        return Row(
          children: [
            _circleControlButton(
              icon: Icons.close_rounded,
              onTap: isRecording ? null : _closeCamera,
            ),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isRecording ? 0 : 1,
              child: IgnorePointer(
                ignoring: isRecording,
                child: Row(
                  children: [
                    _circleControlButton(
                      icon: _controller.isFlashOn.value
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _controller.toggleFlash,
                    ),
                    const SizedBox(width: 10),
                    _circleControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _controller.flipCamera,
                    ),
                    // const SizedBox(width: 10),
                    // _circleControlButton(
                    //   icon: Icons.auto_awesome_rounded,
                    //   onTap: _openEffectPicker,
                    //   isActive: _selectedEffect.id != 'original',
                    // ),
                    const SizedBox(width: 10),
                    _circleControlButton(
                      icon: Icons.timer_outlined,
                      onTap: () {
                        _openTimerPicker();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openEffectPicker() async {
    if (_controller.isRecording.value ||
        _isFinishing ||
        _isCountingDown) {
      return;
    }

    final selectedEffect =
    await showModalBottomSheet<_CameraEffect>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161618),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Effects',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cameraEffects.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(width: 14);
                  },
                  itemBuilder: (context, index) {
                    final effect = _cameraEffects[index];
                    final isSelected =
                        effect.id == _selectedEffect.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(sheetContext).pop(effect);
                      },
                      child: SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 180),
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _accentColor
                                      : Colors.white24,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: ColorFiltered(
                                  colorFilter:
                                  ColorFilter.matrix(effect.matrix),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFE1306C),
                                          Color(0xFF833AB4),
                                          Color(0xFFFCAF45),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              effect.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedEffect == null) {
      return;
    }

    setState(() {
      _selectedEffect = selectedEffect;
    });
  }
  Widget _buildSelectedMusicPill() {
    return Obx(() {
      final selectedMusic = _controller.selectedMusic;

      if (!_controller.hasMusicSelected.value || selectedMusic == null) {
        return const SizedBox.shrink();
      }

      final title = selectedMusic.music?.title ?? 'sound'.tr;
      final isRecording = _controller.isRecording.value;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Music already selected: reopen only the trim sheet, not the list.
        onTap: isRecording
            ? null
            : () => _openSelectedMusicSheet(selectedMusic),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.58),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: _accentColor,
                size: 17,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isRecording) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecordingTimerOrDurationSelector() {
    return Obx(() {
      if (!_controller.isRecording.value) {
        return _buildDurationSelector();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.52),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          _formatDuration(_controller.remainingSec),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    });
  }

  Widget _buildDurationSelector() {
    return Obx(() {
      final selectedDuration = _controller.selectedDurationSec.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ReelCameraController.durationOptions.map((seconds) {
            final isSelected = selectedDuration == seconds;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _controller.setDuration(seconds);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${seconds}s',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Bottom controls
  // ---------------------------------------------------------------------------

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLeftAction(),
          _buildRecordButton(),
          _buildRightAction(),
        ],
      ),
    );
  }

  Widget _buildLeftAction() {
    return Obx(() {
      if (_controller.isRecording.value) {
        final isPaused = _controller.isPaused.value;

        return _bottomActionButton(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: isPaused ? 'resume'.tr : 'pause'.tr,
          onTap: () {
            if (isPaused) {
              _controller.resumeRecording();
            } else {
              _controller.pauseRecording();
            }
          },
        );
      }

      return _bottomActionButton(
        icon: Icons.music_note_rounded,
        label: 'sound'.tr,
        isActive: _controller.hasMusicSelected.value,
        onTap: _openMusicSheet,
      );
    });
  }

  Widget _buildRightAction() {
    return Obx(() {
      if (_controller.isRecording.value ||
          !_controller.hasMusicSelected.value) {
        return const SizedBox(width: 64, height: 62);
      }

      return _bottomActionButton(
        icon: Icons.music_off_rounded,
        label: 'remove'.tr,
        onTap: () {
          _controller.setSelectedMusic(null);
        },
      );
    });
  }

  Widget _buildRecordButton() {
    return Obx(() {
      final isRecording = _controller.isRecording.value;
      final progress = _controller.recordProgress.value
          .clamp(0.0, 1.0)
          .toDouble();

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isFinishing ? null : _toggleRecording,
        child: SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    color: _accentColor,
                    backgroundColor: Colors.white30,
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isRecording ? 30 : 62,
                    height: isRecording ? 30 : 62,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(isRecording ? 7 : 40),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _bottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _accentColor : Colors.black.withOpacity(0.5),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? _accentColor
                : Colors.black.withOpacity(0.46),
            border: Border.all(
              color: isActive
                  ? _accentColor
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Music selection
  // ---------------------------------------------------------------------------

  Future<void> _openMusicSheet() async {
    if (_controller.isRecording.value || _isFinishing || _isMusicSheetOpen) {
      return;
    }

    _isMusicSheetOpen = true;

    final musicController = MusicSheetController(
      musicService: widget.musicService,
      videoDurationSec: _controller.selectedDurationSec.value,
    );

    try {
      final SelectedMusic? result = await reel_music_sheet.showMusicSheet(
        context,
        controller: musicController,
      );

      if (!mounted || result == null) {
        return;
      }

      _controller.setSelectedMusic(result);
    } catch (error, stackTrace) {
      debugPrint('Failed to open music sheet: $error\n$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('music_load_failed'.tr)));
      }
    } finally {
      musicController.dispose();
      _isMusicSheetOpen = false;
    }
  }

  /// Reopens only the trim sheet for [selectedMusic]; used by the
  /// selected-music pill. Dismissing without Done keeps the current music.
  Future<void> _openSelectedMusicSheet(SelectedMusic selectedMusic) async {
    if (_controller.isRecording.value || _isFinishing || _isMusicSheetOpen) {
      return;
    }

    _isMusicSheetOpen = true;

    try {
      final result = await showModalBottomSheet<SelectedMusic>(
        context: context,
        isScrollControlled: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) {
          return SelectedMusicSheet(
            selectedMusic: selectedMusic,
            videoDurationSec: _controller.selectedDurationSec.value,
          );
        },
      );

      if (!mounted || result == null) {
        return;
      }

      _controller.setSelectedMusic(result);
    } finally {
      _isMusicSheetOpen = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  Future<void> _toggleRecording() async {
    if (_isFinishing || _isCountingDown) {
      return;
    }

    if (_controller.isRecording.value) {
      final path = await _controller.stopRecording();

      if (!mounted || path == null) {
        return;
      }

      await _finishRecording(path);
      return;
    }

    _startRecordingWithCountdown();
  }

  Future<void> _finishRecording(String videoPath) async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    final selectedMusic = _controller.selectedMusic;

    var finalPath = videoPath;
    var audioMerged = false;

    if (selectedMusic != null) {
      final mergedPath = await _mergeMusic(videoPath, selectedMusic);

      if (mergedPath != null) {
        finalPath = mergedPath;
        audioMerged = true;
      }
    }

    if (!mounted) {
      return;
    }

    if (widget.popOnFinish) {
      Navigator.of(context).pop(finalPath);
      return;
    }

    await _goToEdit(finalPath, audioMerged: audioMerged);

    if (mounted) {
      setState(() {
        _isFinishing = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Audio merge
  // ---------------------------------------------------------------------------

  Future<String?> _mergeMusic(String videoPath, SelectedMusic music) async {
    _showProcessingDialog();

    String? mergedPath;

    try {
      mergedPath = await ReelAudioMergeService.mergeMusicIntoVideo(
        videoPath: videoPath,
        music: music,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to merge reel music: $error\n$stackTrace');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (mergedPath == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sound_merge_failed'.tr)));
    }

    return mergedPath;
  }

  void _showProcessingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  color: _accentColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _closeCamera() {
    if (_isFinishing ||
        _controller.isRecording.value ||
        _isCountingDown) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _goToEdit(String videoPath, {required bool audioMerged}) async {
    final selectedMusic = _controller.selectedMusic;

    String? thumbnailPath;

    try {
      thumbnailPath = await vt.VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        quality: 75,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to create reel thumbnail: $error\n$stackTrace');
    }

    if (!mounted) {
      return;
    }

    // Replacement is used so the camera screen and camera resources
    // are disposed when editing begins.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) {
          return ReelEditScreen(
            videoPath: videoPath,
            thumbnailPath: thumbnailPath,
            selectedMusic: selectedMusic,
            audioMerged: audioMerged,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('feature_coming_soon'.trParams({'feature': feature})),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
