import 'dart:async';
import 'dart:math' as math;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';

const Color _accentColor = AppColors.brandPink;

class WaveSliderController {
  WaveSliderController({
    required this.selectedMusic,
    required this.videoDurationMs,
  });

  final SelectedMusic selectedMusic;
  final int videoDurationMs;

  final PlayerController audioPlayer = PlayerController();

  int audioStartMS = 0;
  int? totalDurationMs;
  bool isPlaying = false;

  final ValueNotifier<int> _startNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _playingNotifier = ValueNotifier<bool>(false);

  ValueNotifier<int> get startNotifier => _startNotifier;
  ValueNotifier<bool> get playingNotifier => _playingNotifier;

  Timer? _previewTimer;

  bool _resumeAfterDrag = false;
  Future<void>? _dragPauseFuture;

  Future<void> init() async {
    await audioPlayer.preparePlayer(
      path: selectedMusic.downloadedURL,
    );

    totalDurationMs = await audioPlayer.getDuration();
    audioStartMS = _clampStart(selectedMusic.audioStartMS);

    _startNotifier.value = audioStartMS;

    await audioPlayer.seekTo(audioStartMS);

    audioPlayer.setFinishMode(
      finishMode: FinishMode.pause,
    );

    await _play();
  }

  int _clampStart(int milliseconds) {
    final durationMs = totalDurationMs ?? 0;
    final maxStartMs = math.max(0, durationMs - videoDurationMs);

    return milliseconds.clamp(0, maxStartMs).toInt();
  }

  Future<void> _play() async {
    if (isPlaying) {
      return;
    }

    _previewTimer?.cancel();

    await audioPlayer.seekTo(audioStartMS);
    await audioPlayer.startPlayer();

    isPlaying = true;
    _playingNotifier.value = true;

    final durationMs = totalDurationMs ?? videoDurationMs;
    final remainingDurationMs = math.max(
      0,
      durationMs - audioStartMS,
    );

    final previewDurationMs = math.min(
      videoDurationMs,
      remainingDurationMs,
    );

    if (previewDurationMs > 0) {
      _previewTimer = Timer(
        Duration(milliseconds: previewDurationMs),
        pause,
      );
    }
  }

  Future<void> pause() async {
    _previewTimer?.cancel();

    if (!isPlaying) {
      return;
    }

    // Update immediately so repeated drag events cannot trigger
    // multiple pause/play operations.
    isPlaying = false;
    _playingNotifier.value = false;

    await audioPlayer.pausePlayer();
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      await _play();
    }
  }

  /// Called once when dragging starts.
  void beginSelectionDrag() {
    _resumeAfterDrag = isPlaying;

    _dragPauseFuture = isPlaying
        ? pause()
        : Future<void>.value();
  }

  /// Updates only the selected start position.
  ///
  /// Audio is not restarted for every pointer movement.
  void seekTo(int milliseconds) {
    final newStartMs = _clampStart(milliseconds);

    if (newStartMs == audioStartMS) {
      return;
    }

    audioStartMS = newStartMs;
    _startNotifier.value = audioStartMS;
  }

  /// Called once when dragging finishes.
  Future<void> endSelectionDrag() async {
    final shouldResume = _resumeAfterDrag;

    _resumeAfterDrag = false;

    await _dragPauseFuture;
    _dragPauseFuture = null;

    await audioPlayer.seekTo(audioStartMS);

    if (shouldResume) {
      await _play();
    }
  }

  SelectedMusic buildResult() {
    return SelectedMusic(
      music: selectedMusic.music,
      audioStartMS: audioStartMS,
      downloadedURL: selectedMusic.downloadedURL,
      endMilliSec: audioStartMS + videoDurationMs,
    );
  }

  void dispose() {
    _previewTimer?.cancel();

    audioPlayer.release();
    audioPlayer.dispose();

    _startNotifier.dispose();
    _playingNotifier.dispose();
  }
}

class WaveSlider extends StatefulWidget {
  const WaveSlider({
    super.key,
    required this.controller,
  });

  final WaveSliderController controller;

  @override
  State<WaveSlider> createState() => _WaveSliderState();
}

class _WaveSliderState extends State<WaveSlider> {
  double _dragStartX = 0;
  int _dragStartMs = 0;

  WaveSliderController get ctrl => widget.controller;

  int get totalMs => math.max(
    ctrl.totalDurationMs ?? 0,
    1,
  );

  int get videoMs => ctrl.videoDurationMs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ctrl.startNotifier,
      builder: (context, startMs, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              // Keep padding outside LayoutBuilder so maxWidth represents
              // the actual draggable waveform width.
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;

                  final selectionFraction =
                  (videoMs / totalMs).clamp(0.0, 1.0);

                  final selectionWidth =
                      trackWidth * selectionFraction;

                  final travelWidth = math.max(
                    0.0,
                    trackWidth - selectionWidth,
                  );

                  final maxStartMs = math.max(
                    0,
                    totalMs - videoMs,
                  );

                  final progress = maxStartMs > 0
                      ? (startMs / maxStartMs).clamp(0.0, 1.0)
                      : 0.0;

                  final selectionLeft = travelWidth * progress;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      _dragStartX = details.localPosition.dx;
                      _dragStartMs = startMs;

                      ctrl.beginSelectionDrag();
                    },
                    onHorizontalDragUpdate: (details) {
                      if (travelWidth <= 0 || maxStartMs <= 0) {
                        return;
                      }

                      final dragDistance =
                          details.localPosition.dx - _dragStartX;

                      final deltaMs = (
                          dragDistance / travelWidth * maxStartMs
                      ).round();

                      ctrl.seekTo(_dragStartMs + deltaMs);
                    },
                    onHorizontalDragEnd: (_) {
                      unawaited(ctrl.endSelectionDrag());
                    },
                    onHorizontalDragCancel: () {
                      unawaited(ctrl.endSelectionDrag());
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _WaveBars(
                                totalMs: totalMs,
                                videoMs: videoMs,
                                startMs: startMs,
                              ),
                            ),

                            // Draggable fixed-duration selection window.
                            Positioned(
                              left: selectionLeft,
                              top: 0,
                              bottom: 0,
                              width: selectionWidth,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _accentColor.withOpacity(0.20),
                                    border: Border.all(
                                      color: _accentColor,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      _SelectionHandle(),
                                      _SelectionHandle(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: ctrl.playingNotifier,
                  builder: (context, isPlaying, _) {
                    return GestureDetector(
                      onTap: ctrl.togglePlay,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  '${_formatMs(startMs)} – '
                      '${_formatMs(startMs + videoMs)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatMs(int milliseconds) {
    final safeMilliseconds = math.max(0, milliseconds);
    final totalSeconds = safeMilliseconds ~/ 1000;

    final seconds = totalSeconds % 60;
    final minutes = totalSeconds ~/ 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({
    required this.totalMs,
    required this.videoMs,
    required this.startMs,
  });

  final int totalMs;
  final int videoMs;
  final int startMs;

  @override
  Widget build(BuildContext context) {
    const barCount = 40;

    return Row(
      children: List.generate(barCount, (index) {
        final barMs = (index / barCount * totalMs).toInt();

        final isSelected = barMs >= startMs &&
            barMs < startMs + videoMs;

        final barHeight =
            8.0 + ((index * 7 + 3) % 28).toDouble();

        return Expanded(
          child: Center(
            child: Container(
              width: 2,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor
                    : Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }),
    );
  }
}