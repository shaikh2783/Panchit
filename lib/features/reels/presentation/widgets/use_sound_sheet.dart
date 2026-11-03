import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_camera_screen.dart';

/// Bottom sheet opened from the sound line of a reel: shows the sound and
/// lets the user record a new reel with it ("use this sound"). Requires
/// [Post.soundUrl] — callers should only offer this when it is present.
Future<void> showUseSoundSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1a1a1a),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _UseSoundSheetBody(post: post),
  );
}

class _UseSoundSheetBody extends StatefulWidget {
  const _UseSoundSheetBody({required this.post});

  final Post post;

  @override
  State<_UseSoundSheetBody> createState() => _UseSoundSheetBodyState();
}

class _UseSoundSheetBodyState extends State<_UseSoundSheetBody> {
  bool _isDownloading = false;

  Future<void> _useSound() async {
    final post = widget.post;
    final soundUrl = post.soundUrl;
    if (soundUrl == null || _isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final file = await DefaultCacheManager().getSingleFile(soundUrl);
      if (!mounted) return;

      final musicService = context.read<MusicApiService>();
      final selected = SelectedMusic(
        music: Music(
          id: post.soundId,
          title: post.soundTitle,
          sound: soundUrl,
        ),
        audioStartMS: 0,
        downloadedURL: file.path,
      );

      Navigator.of(context).pop(); // close the sheet
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReelCameraScreen(
          musicService: musicService,
          initialMusic: selected,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('sound_download_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandPink.withOpacity(0.8),
                        AppColors.brandPink.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.music_note,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.soundTitle ??
                            'Original audio • ${post.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _useSound,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.videocam),
                label: Text('use_this_sound'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
