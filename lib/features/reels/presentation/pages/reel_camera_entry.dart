import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_camera_screen.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_gallery_trim_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

/// Entry point — shows a bottom sheet letting the user choose
/// "Record with camera" or "Upload from gallery".
Future<void> showReelCameraEntry(BuildContext context) async {
  final musicService = context.read<MusicApiService>();

  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ReelEntrySheet(
      musicService: musicService,
      parentContext: context,
    ),
  );
}

class _ReelEntrySheet extends StatelessWidget {
  final MusicApiService musicService;

  /// Context of the page that opened the sheet. Navigation after the sheet
  /// is popped must use this — the sheet's own context is unmounted by then.
  final BuildContext parentContext;

  const _ReelEntrySheet({
    required this.musicService,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _option(
              context,
              icon: Icons.videocam_rounded,
              label: 'record_video'.tr,
              subtitle: 'use_camera_music_filters'.tr,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(parentContext).push(MaterialPageRoute(
                  builder: (_) => ReelCameraScreen(
                    musicService: musicService,
                  ),
                ));
              },
            ),
            const SizedBox(height: 12),
            _option(
              context,
              icon: Icons.photo_library_rounded,
              label: 'upload_from_gallery'.tr,
              subtitle: 'choose_video_from_library'.tr,
              onTap: () async {
                Navigator.of(context).pop();
                await _pickFromGallery(parentContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !context.mounted) return;

      // Thumbnail failure is non-fatal — the edit screen handles null.
      String? thumb;
      try {
        thumb = await vt.VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: vt.ImageFormat.JPEG,
          quality: 75,
        );
      } catch (_) {
        thumb = null;
      }

      if (!context.mounted) return;

      // Trim step first (max 30s clip); it forwards the trimmed video to
      // ReelEditScreen itself.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReelGalleryTrimScreen(
          videoPath: file.path,
          thumbnailPath: thumb,
          selectedMusic: null,
        ),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_to_pick_video'.tr}: $e')),
      );
    }
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPink.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandPink, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
