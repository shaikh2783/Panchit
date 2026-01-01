import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui';
import '../../data/models/post_audio.dart';

/// Widget احترافي لعرض وتشغيل الملفات الصوتية
class PostAudioWidget extends StatefulWidget {
  const PostAudioWidget({
    super.key,
    required this.audio,
    required this.authorName,
    required this.mediaResolver,
    this.showWaveform = true,
    this.showProgress = true,
    this.autoPlay = false,
  });

  final PostAudio audio;
  final String authorName;
  final Uri Function(String) mediaResolver;
  final bool showWaveform;
  final bool showProgress;
  final bool autoPlay;

  @override
  State<PostAudioWidget> createState() => _PostAudioWidgetState();
}

class _PostAudioWidgetState extends State<PostAudioWidget>
    with TickerProviderStateMixin {
  late AnimationController _playAnimationController;
  late AnimationController _waveAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  late AudioPlayer _audioPlayer;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false; // ✅ لمعرفة هل وصل للنهاية

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();

    _playAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _playAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.autoPlay) {
      _initializeAndPlay();
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state == PlayerState.playing;
        // لا نستخدم stopped كـ loading
      });

      if (_isPlaying) {
        _playAnimationController.forward();
        if (!_waveAnimationController.isAnimating) {
          _waveAnimationController.repeat();
        }
      } else {
        _playAnimationController.reverse();
        _waveAnimationController.stop();
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _isCompleted = true;                 // ✅ وصل للنهاية
        _currentPosition = _totalDuration;   // خلي الشريط على النهاية
      });

      _playAnimationController.reverse();
      _waveAnimationController.stop();
    });
  }

  @override
  void dispose() {
    _playAnimationController.dispose();
    _waveAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAndPlay() async {
    try {
      final audioUri = widget.mediaResolver(widget.audio.source);
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _isCompleted = false;
      });

      await _audioPlayer.play(UrlSource(audioUri.toString()));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });

    }
  }

  Future<void> _initializeAudioOnly() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final audioUri = widget.mediaResolver(widget.audio.source);
      await _audioPlayer.setSourceUrl(audioUri.toString());

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isCompleted = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });

    }
  }

  Future<void> _togglePlayPause() async {
    if (_hasError) {
      await _initializeAudioOnly();
      if (_hasError) return;
    }

    try {
      if (_isPlaying) {
        /// إيقاف مؤقت
        await _audioPlayer.pause();
      } else {
        // ✅ لو كان مكتمل و المستخدم ضغط تشغيل
        if (_isCompleted) {
          // لو الشريط رجع لورا عن النهاية → شغل من مكانه
          final restartFrom =
              _currentPosition < _totalDuration && _currentPosition > Duration.zero
                  ? _currentPosition
                  : Duration.zero;

          final audioUri = widget.mediaResolver(widget.audio.source);
          setState(() {
            _isLoading = true;
          });

          await _audioPlayer.play(UrlSource(audioUri.toString()));
          if (restartFrom > Duration.zero) {
            await _audioPlayer.seek(restartFrom);
          }

          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isCompleted = false;
          });
          return;
        }

        // ✅ حالة عادية (ليس مكتمل)
        if (!_isPlaying) {
          final audioUri = widget.mediaResolver(widget.audio.source);
          setState(() {
            _isLoading = true;
          });

          await _audioPlayer.play(UrlSource(audioUri.toString()));

          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isCompleted = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });

    }
  }

  Future<void> _restartAudio() async {
    try {
      final audioUri = widget.mediaResolver(widget.audio.source);
      setState(() {
        _isLoading = true;
      });

      await _audioPlayer.play(UrlSource(audioUri.toString()));
      await _audioPlayer.seek(Duration.zero);

      if (!mounted) return;
      setState(() {
        _currentPosition = Duration.zero;
        _isCompleted = false;
        _isLoading = false;
      });
    } catch (e) {

    }
  }

  /// ✅ هذه أهم دالة: السحب على شريط التقدم
  Future<void> _onSeek(double position) async {
    try {
      final newPosition = Duration(milliseconds: position.round());

      // نحرك المؤشر للمكان الجديد
      await _audioPlayer.seek(newPosition);

      if (!mounted) return;
      setState(() {
        _currentPosition = newPosition;

        // لو رجعنا لقبل النهاية نلغي حالة الاكتمال
        if (newPosition < _totalDuration) {
          _isCompleted = false;
        }
      });

      // ✅ الحالة الحرّاجة: كنا في حالة مكتمل، والمستخدم حرّك الشريط
      if (_isCompleted) {
        final audioUri = widget.mediaResolver(widget.audio.source);

        setState(() {
          _isLoading = true;
        });

        await _audioPlayer.play(UrlSource(audioUri.toString()));
        await _audioPlayer.seek(newPosition);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isCompleted = false;
        });
      }

      // ملاحظة: لما يكون الصوت متوقف بسبب pause (مش completed)،
      // ما نشغّله تلقائيًا هنا، يخليه مثل سبوتيفاي: تقدر تحرك الشريط وهو متوقف.
    } catch (e) {

    }
  }

  String _formatTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1a1a2e).withValues(alpha: 0.9),
                  const Color(0xFF16213e).withValues(alpha: 0.7),
                ]
              : [
                  const Color(0xFFf8f9fa),
                  const Color(0xFFe9ecef),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, isDark),
            const SizedBox(height: 16),

            if (_hasError) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'فشل في تحميل الملف الصوتي. اضغط على زر التشغيل للمحاولة مرة أخرى.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                _buildPlayButton(theme),
                const SizedBox(width: 8),
                _buildRestartButton(theme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showWaveform) ...[
                        _buildWaveform(theme),
                        const SizedBox(height: 8),
                      ],
                      if (widget.showProgress) _buildProgressBar(theme),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildTimeDisplay(theme),
              ],
            ),

            const SizedBox(height: 12),
            _buildFooter(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getAudioIcon(),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.audio.title ?? 'audio_file'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Iconsax.user,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showAudioMenu(context),
          icon: Icon(
            Iconsax.more,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildPlayButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _hasError || _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hasError
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_hasError
                            ? Colors.red
                            : theme.colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildPlayButtonIcon(theme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButtonIcon(ThemeData theme) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        ),
      );
    }

    if (_hasError) {
      return const Icon(
        Iconsax.refresh,
        color: Colors.white,
        size: 20,
      );
    }

    return Icon(
      _isPlaying ? Iconsax.pause : Iconsax.play,
      color: Colors.white,
      size: 24,
    );
  }

  Widget _buildRestartButton(ThemeData theme) {
    return GestureDetector(
      onTap: _hasError || _isLoading ? null : _restartAudio,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Iconsax.refresh_circle,
          color: _hasError || _isLoading
              ? theme.colorScheme.onSurface.withOpacity(0.3)
              : theme.colorScheme.onSurface.withOpacity(0.7),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildWaveform(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(30, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              final progress = _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds /
                      _totalDuration.inMilliseconds
                  : 0.0;
              final barProgress = index / 30;
              final isActive = barProgress <= progress;
              final animationOffset = (index * 0.2) % 1.0;

              final baseHeight =
                  0.3 + (index % 4) * 0.15;
              final animatedHeight = _isPlaying
                  ? baseHeight +
                      ((_waveAnimation.value + animationOffset) % 1.0) * 0.4
                  : baseHeight;

              return Container(
                width: 2.5,
                height: 40 * animatedHeight.clamp(0.2, 1.0),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.25),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final currentMs = _currentPosition.inMilliseconds.toDouble();
    final totalMs = _totalDuration.inMilliseconds.toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor:
            theme.colorScheme.onSurface.withOpacity(0.2),
        thumbColor: theme.colorScheme.primary,
      ),
      child: Slider(
        value: totalMs > 0 ? currentMs.clamp(0.0, totalMs) : 0.0,
        max: totalMs > 0 ? totalMs : 1.0,
        onChanged: widget.showProgress ? _onSeek : null,
      ),
    );
  }

  Widget _buildTimeDisplay(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTime(_currentPosition),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          _formatTime(_totalDuration),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Row(
      children: [
        if (widget.audio.formattedSize.isNotEmpty) ...[
          Icon(
            Iconsax.document_text,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            widget.audio.formattedSize,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (widget.audio.fileExtension != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.audio.fileExtension!.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Icon(
          Iconsax.headphone,
          size: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          widget.audio.views.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  IconData _getAudioIcon() {
    if (widget.audio.isMP3) return Iconsax.music_circle;
    if (widget.audio.isWAV) return Iconsax.music_square;
    if (widget.audio.isM4A) return Iconsax.music_square_add;
    return Iconsax.microphone;
  }

  void _showAudioMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Iconsax.refresh),
              title: Text('restart_from_beginning'.tr),
              onTap: () {
                Navigator.pop(context);
                _restartAudio();
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.import_2),
              title: Text('download_button'.tr),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement download
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title: Text('share_button_action'.tr),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.info_circle),
              title: Text('audio_info_button'.tr),
              onTap: () {
                Navigator.pop(context);
                _showAudioInfo(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAudioInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('audio_information_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Duration', widget.audio.formattedDuration),
            if (widget.audio.formattedSize.isNotEmpty)
              _InfoRow('Size', widget.audio.formattedSize),
            if (widget.audio.fileExtension != null)
              _InfoRow('Format', widget.audio.fileExtension!.toUpperCase()),
            _InfoRow('Plays', '${widget.audio.views}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close_button'.tr),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
