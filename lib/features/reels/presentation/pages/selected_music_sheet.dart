import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/widgets/wave_slider.dart';

const Color _accentColor = AppColors.brandPink;
const Color _sheetColor = Color(0xFF161618);
const Color _surfaceColor = Color(0xFF242428);

class SelectedMusicSheet extends StatefulWidget {
  final SelectedMusic selectedMusic;
  final int videoDurationSec;

  const SelectedMusicSheet({
    super.key,
    required this.selectedMusic,
    required this.videoDurationSec,
  });

  @override
  State<SelectedMusicSheet> createState() => _SelectedMusicSheetState();
}

class _SelectedMusicSheetState extends State<SelectedMusicSheet> {
  late final WaveSliderController _controller;

  bool _isReady = false;
  bool _hasError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _controller = WaveSliderController(
      selectedMusic: widget.selectedMusic,
      videoDurationMs: widget.videoDurationSec * 1000,
    );

    _initializeController();
  }

  Future<void> _initializeController() async {
    if (mounted) {
      setState(() {
        _isReady = false;
        _hasError = false;
      });
    }

    try {
      await _controller.init();

      if (!mounted) {
        return;
      }

      setState(() {
        _isReady = true;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'SelectedMusicSheet initialization failed: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSheet() {
    Navigator.of(context).pop();
  }

  void _onDone() {
    if (!_isReady || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = _controller.buildResult();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final music = widget.selectedMusic.music;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset + 16),
        decoration: const BoxDecoration(
          color: _sheetColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(
              title: music?.title ?? 'selected_music'.tr,
              artist: music?.artist,
            ),
            const SizedBox(height: 18),
            _buildInstruction(),
            const SizedBox(height: 18),
            _buildWaveSection(),
            const SizedBox(height: 20),
            _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildHeader({required String title, String? artist}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (artist?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _closeSheet,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white10,
              minimumSize: const Size(38, 38),
              maximumSize: const Size(38, 38),
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swipe_rounded,
              color: _accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'drag_choose_song_part'.tr,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          Text(
            _formatDuration(widget.videoDurationSec),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildWaveContent(),
      ),
    );
  }

  Widget _buildWaveContent() {
    if (_hasError) {
      return SizedBox(
        key: const ValueKey('error'),
        height: 106,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'audio_load_failed'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _initializeController,
              child: Text(
                'try_again'.tr,
                style: const TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isReady) {
      return const SizedBox(
        key: ValueKey('loading'),
        height: 106,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _accentColor,
            ),
          ),
        ),
      );
    }

    /*
     * Keep WaveSlider directly in the widget tree.
     *
     * Do not wrap it with a horizontal GestureDetector, InkWell or
     * IgnorePointer, because those can prevent WaveSlider from receiving
     * its drag gestures.
     *
     * The fixed height also gives the slider a proper touch area.
     */
    return SizedBox(
      key: const ValueKey('wave-slider'),
      width: double.infinity,
      height: 106,
      child: RepaintBoundary(child: WaveSlider(controller: _controller)),
    );
  }

  Widget _buildDoneButton() {
    final isEnabled = _isReady && !_hasError && !_isSubmitting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isEnabled ? _onDone : null,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isSubmitting
                ? const SizedBox(
                    key: ValueKey('submitting'),
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    key: const ValueKey('done'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 21),
                      const SizedBox(width: 7),
                      Text(
                        'done'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
