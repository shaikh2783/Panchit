import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_edit_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

/// Trim step between the gallery picker and [ReelEditScreen]: the user picks
/// a 1–30s window of the selected video, the clip is exported with FFmpeg,
/// and the trimmed file continues into the existing edit → publish pipeline.
class ReelGalleryTrimScreen extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;
  final SelectedMusic? selectedMusic;

  const ReelGalleryTrimScreen({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
    this.selectedMusic,
  });

  @override
  State<ReelGalleryTrimScreen> createState() => _ReelGalleryTrimScreenState();
}

class _ReelGalleryTrimScreenState extends State<ReelGalleryTrimScreen> {
  static const int _maxTrimSec = 30;
  static const int _minTrimSec = 1;
  static const Color _accent = Color(0xFFE1306C);
  static const double _bottomPanelReservedHeight = 292;
  VideoPlayerController? _playerCtrl;

  bool _isInitialized = false;
  bool _initFailed = false;
  bool _isExporting = false;
  bool _isPaused = false;

  double _videoDurationSec = 0;
  RangeValues _range = const RangeValues(0, _maxTrimSec * 1.0);

  double get _selectedSpanSec => _range.end - _range.start;

  double get _minSpanSec =>
      math.min(_minTrimSec.toDouble(), _videoDurationSec);

  bool get _canContinue =>
      _isInitialized && !_isExporting && _selectedSpanSec >= _minSpanSec;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    final controller = _playerCtrl;
    if (controller != null) {
      controller.removeListener(_loopWithinRange);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.file(File(widget.videoPath));
    _playerCtrl = controller;

    try {
      await controller.initialize();
    } catch (_) {
      if (mounted) {
        setState(() => _initFailed = true);
      }
      return;
    }

    if (!mounted) return;

    _videoDurationSec = controller.value.duration.inMilliseconds / 1000;
    final defaultEnd = math.min(_videoDurationSec, _maxTrimSec.toDouble());

    controller
      ..addListener(_loopWithinRange)
      ..play();

    setState(() {
      _range = RangeValues(0, defaultEnd);
      _isInitialized = true;
      _isPaused = false;
    });
  }

  /// Keeps preview playback inside the selected window.
  void _loopWithinRange() {
    final controller = _playerCtrl;
    if (controller == null || !controller.value.isInitialized) return;

    final positionMs = controller.value.position.inMilliseconds;
    if (positionMs >= (_range.end * 1000).round()) {
      controller.seekTo(
        Duration(milliseconds: (_range.start * 1000).round()),
      );

      if (!_isPaused && !controller.value.isPlaying) {
        controller.play();
      }
    }
  }

  void _togglePlayPause() {
    final controller = _playerCtrl;
    if (controller == null || !_isInitialized || _isExporting) return;

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _isPaused = true);
    } else {
      controller.play();
      setState(() => _isPaused = false);
    }
  }

  /// Clamps the handle the user moved so the window stays within
  /// [_minTrimSec, _maxTrimSec], then reseeks the preview to the new start.
  void _onRangeChanged(RangeValues values) {
    if (!_isInitialized || _isExporting) return;

    final startMoved = (values.start - _range.start).abs() >=
        (values.end - _range.end).abs();

    var start = values.start;
    var end = values.end;

    if (startMoved) {
      start = start.clamp(
        math.max(0.0, end - _maxTrimSec),
        end - _minSpanSec,
      );
    } else {
      end = end.clamp(
        start + _minSpanSec,
        math.min(_videoDurationSec, start + _maxTrimSec),
      );
    }

    setState(() => _range = RangeValues(start, end));

    final controller = _playerCtrl;
    controller?.seekTo(Duration(milliseconds: (start * 1000).round()));

    if (!_isPaused) {
      controller?.play();
    }
  }

  void _applyQuickDuration(int seconds) {
    if (!_isInitialized || _isExporting) return;

    final duration = math.min(seconds.toDouble(), _videoDurationSec);
    var start = _range.start;

    if (start + duration > _videoDurationSec) {
      start = math.max(0, _videoDurationSec - duration);
    }

    final end = math.min(_videoDurationSec, start + duration);

    setState(() {
      _range = RangeValues(start, end);
    });

    _playerCtrl?.seekTo(Duration(milliseconds: (start * 1000).round()));

    if (!_isPaused) {
      _playerCtrl?.play();
    }
  }

  Future<void> _onNext() async {
    if (!_canContinue) return;

    setState(() => _isExporting = true);
    await _playerCtrl?.pause();

    try {
      final trimmedPath = await _exportTrimmedVideo();
      final thumb = await _generateThumbnail(trimmedPath);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReelEditScreen(
            videoPath: trimmedPath,
            thumbnailPath: thumb ?? widget.thumbnailPath,
            selectedMusic: widget.selectedMusic,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<String> _exportTrimmedVideo() async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/reel_trim_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final start = _range.start.toStringAsFixed(2);
    final duration = _selectedSpanSec.toStringAsFixed(2);

    // Re-encode for maximum compatibility; fall back to a keyframe-aligned
    // stream copy when the bundled FFmpeg flavor lacks libx264 (GPL).
    var success = await _runTrim(
      outputPath,
      start: start,
      duration: duration,
      codecArgs: '-c:v libx264 -preset veryfast -c:a aac',
    );

    if (!success) {
      success = await _runTrim(
        outputPath,
        start: start,
        duration: duration,
        codecArgs: '-c copy',
      );
    }

    final output = File(outputPath);
    if (!success || !await output.exists() || await output.length() == 0) {
      throw Exception('Could not prepare the selected clip. Please try again.');
    }

    return outputPath;
  }

  Future<bool> _runTrim(
      String outputPath, {
        required String start,
        required String duration,
        required String codecArgs,
      }) async {
    final session = await FFmpegKit.execute(
      '-y -ss $start -i "${widget.videoPath}" -t $duration '
          '$codecArgs -movflags +faststart "$outputPath"',
    );

    return ReturnCode.isSuccess(await session.getReturnCode());
  }

  /// Thumbnail failure is non-fatal — the caller falls back to the original
  /// gallery thumbnail.
  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      return await vt.VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        quality: 75,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatSec(double seconds) {
    final total = seconds.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final previewBottomOffset =
    _isInitialized ? _bottomPanelReservedHeight : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            bottom: previewBottomOffset,
            child: _buildPreview(),
          ),
          Positioned.fill(
            bottom: previewBottomOffset,
            child: const _TrimScreenGradients(),
          ),
          _buildTopBar(),
          _buildBottomPanel(),
          if (_isExporting) _buildExportOverlay(),
        ],
      ),
    );
  }
  Widget _buildPreview() {
    final controller = _playerCtrl;

    if (_initFailed) {
      return _buildMessageState(
        icon: Icons.video_file_outlined,
        title: 'Could not load this video',
        subtitle: 'Please choose another video from your gallery.',
      );
    }

    if (!_isInitialized || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlayPause,
          child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          if (_isPaused)
            Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.56),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: _isExporting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDurationChip(),
              ),
              const SizedBox(width: 12),
              _nextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip() {
    final text = _isInitialized
        ? '${_formatSec(_selectedSpanSec)} selected'
        : 'Select clip';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.34),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.content_cut_rounded,
                color: _accent,
                size: 16,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return Opacity(
      opacity: _canContinue ? 1 : 0.55,
      child: GestureDetector(
        onTap: _canContinue ? _onNext : null,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Next',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.34),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (!_isInitialized) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF151518).withOpacity(0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 14),
              _buildTrimHeader(),
              const SizedBox(height: 12),
              _buildQuickDurationChips(),
              const SizedBox(height: 8),
              _buildSlider(),
              _buildRangeLabels(),
              const SizedBox(height: 12),
              _buildHelpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildTrimHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Select clip duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _accent.withOpacity(0.26),
            ),
          ),
          child: const Text(
            'Max 30 sec',
            style: TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDurationChips() {
    return Row(
      children: [
        _durationChip(seconds: 10),
        const SizedBox(width: 8),
        _durationChip(seconds: 15),
        const SizedBox(width: 8),
        _durationChip(seconds: 30),
        const Spacer(),
        Text(
          '${_formatSec(_videoDurationSec)} total',
          style: TextStyle(
            color: Colors.white.withOpacity(0.42),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _durationChip({required int seconds}) {
    final isDisabled = _videoDurationSec < _minTrimSec;
    final isSelected = _selectedSpanSec.round() == seconds ||
        (_videoDurationSec < seconds && _selectedSpanSec == _videoDurationSec);

    return GestureDetector(
      onTap: isDisabled ? null : () => _applyQuickDuration(seconds),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.16)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: isDisabled
                ? Colors.white24
                : isSelected
                ? Colors.white
                : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 5,
        activeTrackColor: _accent,
        inactiveTrackColor: Colors.white.withOpacity(0.18),
        thumbColor: Colors.white,
        overlayColor: _accent.withOpacity(0.16),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 10,
        ),
      ),
      child: RangeSlider(
        values: _range,
        min: 0,
        max: math.max(_videoDurationSec, _minSpanSec),
        labels: RangeLabels(
          _formatSec(_range.start),
          _formatSec(_range.end),
        ),
        onChanged: _isExporting ? null : _onRangeChanged,
      ),
    );
  }

  Widget _buildRangeLabels() {
    return Row(
      children: [
        _timeLabel(
          label: 'Start',
          value: _formatSec(_range.start),
        ),
        const Spacer(),
        _timeLabel(
          label: 'Duration',
          value: _formatSec(_selectedSpanSec),
          highlight: true,
        ),
        const Spacer(),
        _timeLabel(
          label: 'End',
          value: _formatSec(_range.end),
          alignEnd: true,
        ),
      ],
    );
  }

  Widget _timeLabel({
    required String label,
    required String value,
    bool highlight = false,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: highlight ? _accent : Colors.white.withOpacity(0.78),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: Colors.white.withOpacity(0.36),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Drag the handles to choose the best part of your video.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.42),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.74),
        child: Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF17171A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Preparing your reel...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Please keep this screen open',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrimScreenGradients extends StatelessWidget {
  const _TrimScreenGradients();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.24, 0.56, 1],
                  colors: [
                    Colors.black.withOpacity(0.62),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.86),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.92,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}