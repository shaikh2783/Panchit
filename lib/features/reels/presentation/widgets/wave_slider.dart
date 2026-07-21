import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';

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

  final _startNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get startNotifier => _startNotifier;

  Timer? _timer;
  StreamSubscription? _posSub;

  Future<void> init() async {
    audioStartMS = selectedMusic.audioStartMS;
    await audioPlayer.preparePlayer(path: selectedMusic.downloadedURL);
    totalDurationMs = await audioPlayer.getDuration();
    _startNotifier.value = audioStartMS;
    await audioPlayer.seekTo(audioStartMS);
    audioPlayer.setFinishMode(finishMode: FinishMode.pause);
    await _play();
  }

  Future<void> _play() async {
    await audioPlayer.seekTo(audioStartMS);
    await audioPlayer.startPlayer();
    isPlaying = true;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: videoDurationMs), pause);
  }

  Future<void> pause() async {
    _timer?.cancel();
    await audioPlayer.pausePlayer();
    isPlaying = false;
  }

  Future<void> togglePlay() async {
    isPlaying ? await pause() : await _play();
  }

  void seekTo(int ms) {
    // Songs shorter than the reel duration would make the upper bound
    // negative, and clamp throws when max < min.
    final maxStartMs = (totalDurationMs ?? 0) - videoDurationMs;
    audioStartMS = maxStartMs > 0 ? ms.clamp(0, maxStartMs) : 0;
    _startNotifier.value = audioStartMS;
    if (isPlaying) {
      pause().then((_) => _play());
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
    _timer?.cancel();
    _posSub?.cancel();
    audioPlayer.release();
    audioPlayer.dispose();
    _startNotifier.dispose();
  }
}

class WaveSlider extends StatefulWidget {
  final WaveSliderController controller;

  const WaveSlider({super.key, required this.controller});

  @override
  State<WaveSlider> createState() => _WaveSliderState();
}

class _WaveSliderState extends State<WaveSlider> {
  double _dragStart = 0;
  int _dragStartMs = 0;

  WaveSliderController get ctrl => widget.controller;

  int get totalMs => ctrl.totalDurationMs ?? 1;
  int get videoMs => ctrl.videoDurationMs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ctrl.startNotifier,
      builder: (context, startMs, _) {
        final double progress = totalMs > 0 ? startMs / totalMs : 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform bar
            GestureDetector(
              onHorizontalDragStart: (d) {
                _dragStart = d.localPosition.dx;
                _dragStartMs = startMs;
              },
              onHorizontalDragUpdate: (d) {
                final dx = d.localPosition.dx - _dragStart;
                final screenWidth = MediaQuery.of(context).size.width - 48;
                final deltaMs = (dx / screenWidth * totalMs).toInt();
                ctrl.seekTo(_dragStartMs + deltaMs);
              },
              child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Filled portion representing video duration
                    FractionallySizedBox(
                      widthFactor: (videoMs / totalMs).clamp(0.0, 1.0),
                      alignment: Alignment(progress * 2 - 1, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1306C).withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Wave bars
                    _WaveBars(
                      totalMs: totalMs,
                      videoMs: videoMs,
                      startMs: startMs,
                    ),
                    // Drag handle line
                    Center(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE1306C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: ctrl.togglePlay,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1306C),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ctrl.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_formatMs(startMs)} – ${_formatMs(startMs + videoMs)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatMs(int ms) {
    final s = (ms ~/ 1000) % 60;
    final m = ms ~/ 60000;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _WaveBars extends StatelessWidget {
  final int totalMs;
  final int videoMs;
  final int startMs;

  const _WaveBars({
    required this.totalMs,
    required this.videoMs,
    required this.startMs,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 40;
    return Row(
      children: List.generate(barCount, (i) {
        final barMs = (i / barCount * totalMs).toInt();
        final inWindow = barMs >= startMs && barMs < startMs + videoMs;
        // Pseudo-random height for visual variety
        final h = 8.0 + ((i * 7 + 3) % 28).toDouble();
        return Expanded(
          child: Center(
            child: Container(
              width: 2,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: inWindow ? const Color(0xFFE1306C) : Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }),
    );
  }
}
