import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../../core/utils/video_cache_warmer.dart';
import '../../data/models/chat_shared_content.dart';

class SharedMediaViewerPage extends StatelessWidget {
  const SharedMediaViewerPage({
    super.key,
    required this.item,
    required this.title,
  });

  final ChatSharedItemModel item;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return _SharedVideoViewer(item: item, title: title);
    }
    if (item.isAudio) {
      return _SharedAudioViewer(item: item, title: title);
    }
    return _SharedImageViewer(item: item, title: title);
  }
}

class _SharedImageViewer extends StatelessWidget {
  const _SharedImageViewer({required this.item, required this.title});

  final ChatSharedItemModel item;
  final String title;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.bestUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _MediaLoadError(),
          ),
        ),
      ),
    );
  }
}

class _SharedVideoViewer extends StatefulWidget {
  const _SharedVideoViewer({required this.item, required this.title});

  final ChatSharedItemModel item;
  final String title;

  @override
  State<_SharedVideoViewer> createState() => _SharedVideoViewerState();
}

class _SharedVideoViewerState extends State<_SharedVideoViewer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;
  bool _controlsVisible = true;
  bool _isMuted = false;
  bool _isFillMode = false;
  double _playbackSpeed = 1.0;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = await VideoCacheWarmer.createController(
        widget.item.bestUrl,
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.setPlaybackSpeed(_playbackSpeed);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
        _failed = false;
      });
      _scheduleControlsHide();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    final controller = _controller;
    if (!_controlsVisible ||
        controller == null ||
        !controller.value.isPlaying) {
      return;
    }
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleControlsHide();
  }

  Future<void> _seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final duration = controller.value.duration;
    final target = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    await controller.seekTo(target);
    _scheduleControlsHide();
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await _seekTo(controller.value.position + delta);
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final nextMuted = !_isMuted;
    await controller.setVolume(nextMuted ? 0 : 1);
    if (!mounted) {
      return;
    }
    setState(() {
      _isMuted = nextMuted;
    });
    _scheduleControlsHide();
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.setPlaybackSpeed(speed);
    if (!mounted) {
      return;
    }
    setState(() {
      _playbackSpeed = speed;
    });
    _scheduleControlsHide();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.white))
          : _failed || controller == null
          ? const _MediaLoadError()
          : ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final duration = value.duration;
                final position = value.position > duration
                    ? duration
                    : value.position;
                final totalMs = duration.inMilliseconds <= 0
                    ? 1
                    : duration.inMilliseconds;
                final positionMs = position.inMilliseconds
                    .clamp(0, totalMs)
                    .toDouble();

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        minScale: 1,
                        maxScale: 3.5,
                        child: Center(
                          child: ClipRect(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final videoWidth = value.size.width <= 0
                                    ? 16.0
                                    : value.size.width;
                                final videoHeight = value.size.height <= 0
                                    ? 9.0
                                    : value.size.height;
                                return FittedBox(
                                  fit: _isFillMode
                                      ? BoxFit.cover
                                      : BoxFit.contain,
                                  child: SizedBox(
                                    width: _isFillMode
                                        ? constraints.maxWidth
                                        : videoWidth,
                                    height: _isFillMode
                                        ? constraints.maxHeight
                                        : videoHeight,
                                    child: VideoPlayer(controller),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (value.isBuffering)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.50),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.68),
                                    ],
                                    stops: const [0, 0.45, 1],
                                  ),
                                ),
                              ),
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).maybePop(),
                                            icon: const Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              widget.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          PopupMenuButton<double>(
                                            initialValue: _playbackSpeed,
                                            tooltip: AppTranslations
                                                .mediaPlaybackSpeed
                                                .tr,
                                            color: const Color(0xFF121212),
                                            onSelected: _setPlaybackSpeed,
                                            itemBuilder: (context) {
                                              const speeds = [
                                                0.5,
                                                1.0,
                                                1.25,
                                                1.5,
                                                2.0,
                                              ];
                                              return speeds
                                                  .map(
                                                    (
                                                      speed,
                                                    ) => PopupMenuItem<double>(
                                                      value: speed,
                                                      child: Text(
                                                        '${speed}x',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${_playbackSpeed}x',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _VideoControlButton(
                                            icon: Icons.replay_10_rounded,
                                            onPressed: () => _seekRelative(
                                              const Duration(seconds: -10),
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          _VideoPrimaryControlButton(
                                            icon: value.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            onPressed: _togglePlayback,
                                          ),
                                          const SizedBox(width: 18),
                                          _VideoControlButton(
                                            icon: Icons.forward_10_rounded,
                                            onPressed: () => _seekRelative(
                                              const Duration(seconds: 10),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 26),
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          12,
                                          14,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.36,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.10,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                    trackHeight: 4,
                                                    thumbShape:
                                                        const RoundSliderThumbShape(
                                                          enabledThumbRadius: 6,
                                                        ),
                                                    overlayShape:
                                                        SliderComponentShape
                                                            .noOverlay,
                                                    activeTrackColor:
                                                        AppColors.primary,
                                                    inactiveTrackColor: Colors
                                                        .white
                                                        .withValues(
                                                          alpha: 0.22,
                                                        ),
                                                    thumbColor: Colors.white,
                                                  ),
                                              child: Slider(
                                                value: positionMs,
                                                max: totalMs.toDouble(),
                                                onChanged: (newValue) {
                                                  _seekTo(
                                                    Duration(
                                                      milliseconds: newValue
                                                          .round(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  _formatDuration(position),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatDuration(duration),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                _VideoToggleChip(
                                                  icon: _isMuted
                                                      ? Icons.volume_off_rounded
                                                      : Icons.volume_up_rounded,
                                                  label: _isMuted
                                                      ? AppTranslations
                                                            .mediaMuted
                                                            .tr
                                                      : AppTranslations
                                                            .mediaSoundOn
                                                            .tr,
                                                  onTap: _toggleMute,
                                                ),
                                                const SizedBox(width: 10),
                                                _VideoToggleChip(
                                                  icon: _isFillMode
                                                      ? Icons.fit_screen_rounded
                                                      : Icons.crop_free_rounded,
                                                  label: _isFillMode
                                                      ? AppTranslations
                                                            .mediaFill
                                                            .tr
                                                      : AppTranslations
                                                            .mediaFit
                                                            .tr,
                                                  onTap: () {
                                                    setState(() {
                                                      _isFillMode =
                                                          !_isFillMode;
                                                    });
                                                    _scheduleControlsHide();
                                                  },
                                                ),
                                                const Spacer(),
                                                Text(
                                                  value.isLooping
                                                      ? AppTranslations
                                                            .mediaLoopOn
                                                            .tr
                                                      : AppTranslations
                                                            .mediaLoopOff
                                                            .tr,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _VideoPrimaryControlButton extends StatelessWidget {
  const _VideoPrimaryControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white, size: 44),
        ),
      ),
    );
  }
}

class _VideoControlButton extends StatelessWidget {
  const _VideoControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _VideoToggleChip extends StatelessWidget {
  const _VideoToggleChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedAudioViewer extends StatefulWidget {
  const _SharedAudioViewer({required this.item, required this.title});

  final ChatSharedItemModel item;
  final String title;

  @override
  State<_SharedAudioViewer> createState() => _SharedAudioViewerState();
}

class _SharedAudioViewerState extends State<_SharedAudioViewer> {
  late final AudioPlayer _player;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _player.setUrl(widget.item.bestUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Scaffold(
      backgroundColor: palette.groupedCanvas,
      appBar: MessengerAppBar(title: widget.title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(
                MessengerDesign.sectionRadius,
              ),
              border: Border.all(color: palette.divider, width: 0.7),
            ),
            child: _loading
                ? const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _failed
                ? const SizedBox(
                    height: 180,
                    child: _MediaLoadError(onDark: false),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.primary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.item.message.trim().isEmpty
                            ? AppTranslations.mediaAudio.tr
                            : widget.item.message,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final total = _player.duration ?? Duration.zero;
                          final maxMs = total.inMilliseconds <= 0
                              ? 1
                              : total.inMilliseconds;
                          final value = position.inMilliseconds
                              .clamp(0, maxMs)
                              .toDouble();

                          return Column(
                            children: [
                              Slider(
                                value: value,
                                max: maxMs.toDouble(),
                                onChanged: (newValue) {
                                  _player.seek(
                                    Duration(milliseconds: newValue.round()),
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position)),
                                  Text(_formatDuration(total)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return FilledButton.icon(
                            onPressed: () {
                              if (playing) {
                                _player.pause();
                              } else {
                                _player.play();
                              }
                            },
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              playing
                                  ? AppTranslations.mediaPause.tr
                                  : AppTranslations.mediaPlay.tr,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final totalHours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (totalHours > 0) {
    return '$totalHours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

class _MediaLoadError extends StatelessWidget {
  const _MediaLoadError({this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppTranslations.mediaLoadError.tr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: onDark ? Colors.white : MessengerDesign.of(context).muted,
          ),
        ),
      ),
    );
  }
}
