import 'package:flutter/material.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/widgets/wave_slider.dart';

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
  late final WaveSliderController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = WaveSliderController(
      selectedMusic: widget.selectedMusic,
      videoDurationMs: widget.videoDurationSec * 1000,
    );
    _init();
  }

  Future<void> _init() async {
    await _ctrl.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDone() {
    Navigator.of(context).pop(_ctrl.buildResult());
  }

  @override
  Widget build(BuildContext context) {
    final music = widget.selectedMusic.music;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music?.title ?? 'Selected Sound',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (music?.artist?.isNotEmpty == true)
                        Text(
                          music!.artist!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1306C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Drag to choose which part of the song plays',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (!_ready)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: Color(0xFFE1306C)),
            )
          else
            WaveSlider(controller: _ctrl),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
