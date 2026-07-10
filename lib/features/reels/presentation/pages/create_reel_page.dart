import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/create_post_request.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';
import 'package:snginepro/features/reels/presentation/pages/reel_camera_screen.dart';
import 'package:video_player/video_player.dart';

/// Reels creation page.
///
/// Recording uses [ReelCameraScreen] (`camera` plugin); `image_picker` is
/// only used for choosing an existing video from the gallery.
///
/// Permissions (already declared in this project):
///  - Android (AndroidManifest.xml): CAMERA, RECORD_AUDIO,
///    READ_EXTERNAL_STORAGE (gallery on API <= 32).
///  - iOS (Info.plist): NSCameraUsageDescription,
///    NSMicrophoneUsageDescription, NSPhotoLibraryUsageDescription.
///    Podfile enables PERMISSION_CAMERA / PERMISSION_MICROPHONE macros.
///
/// TODO(reels): real sound library picker (see showMusicSheet), effect
/// rendering, video compression, client-side thumbnail generation
/// (video_thumbnail), trim editor and final audio mixing.
class CreateReelPage extends StatefulWidget {
  const CreateReelPage({super.key});

  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}

class _CreateReelPageState extends State<CreateReelPage> {
  static const int _maxVideoBytes = 50 * 1024 * 1024; // 50MB
  static const List<int> _durationOptions = [15, 30, 60];

  final _picker = ImagePicker();
  final _captionController = TextEditingController();

  File? _videoFile;
  CachedVideoPlayerPlus? _videoController;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Reels customization state — placeholders until the sound library and
  // effect pickers are integrated with the API.
  int _selectedDuration = 15;
  String? _selectedSoundId;
  String? _selectedSoundTitle;
  String? _selectedEffectId;

  @override
  void dispose() {
    _captionController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    final player = _videoController;
    if (player == null) return;
    final controller = player.controller;
    if (controller.value.isInitialized && controller.value.isPlaying) {
      controller.pause();
    }
    player.dispose();
    _videoController = null;
  }

  /// Validates and prepares [file] for preview. Shared by the gallery picker
  /// and the custom reel camera.
  Future<void> _prepareVideoFile(File file) async {
    setState(() => _isLoading = true);
    try {
      final fileSize = await file.length();
      if (fileSize > _maxVideoBytes) {
        if (mounted) _showErrorSnackBar('video_file_too_large_max_50mb'.tr);
        return;
      }

      _disposeVideoController();
      final player = CachedVideoPlayerPlus.file(file);
      await player.initialize();
      await player.controller.setLooping(true);

      if (!mounted) {
        player.dispose();
        return;
      }
      setState(() {
        _videoController = player;
        _videoFile = file;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) _showErrorSnackBar('${'failed_to_load_video'.tr} $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (pickedFile == null || !mounted) return;
    await _prepareVideoFile(File(pickedFile.path));
  }

  Future<void> _openReelCamera() async {
    final granted = await _ensureCameraPermissions();
    if (!mounted) return;
    if (!granted) {
      _showErrorSnackBar('camera_mic_permission_required'.tr);
      return;
    }

    final recordedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ReelCameraScreen(
          musicService: context.read<MusicApiService>(),
          popOnFinish: true,
          initialDurationSec: _selectedDuration,
        ),
      ),
    );
    if (recordedPath == null || !mounted) return;
    await _prepareVideoFile(File(recordedPath));
  }

  Future<bool> _ensureCameraPermissions() async {
    final statuses =
        await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((status) => status.isGranted);
  }

  void _removeSelectedVideo() {
    setState(() {
      _disposeVideoController();
      _videoFile = null;
    });
  }

  void _togglePlayback() {
    final controller = _videoController?.controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _showVideoSourceDialog() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'select_video_source'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _VideoSourceOption(
                icon: Iconsax.video,
                title: 'record_video'.tr,
                subtitle: 'record_a_new_video'.tr,
                gradient: const [Color(0xFFEF5350), Color(0xFFE53935)],
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openReelCamera();
                },
              ),
              const SizedBox(height: 12),
              _VideoSourceOption(
                icon: Iconsax.gallery,
                title: 'choose_from_gallery'.tr,
                subtitle: 'select_existing_video'.tr,
                gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickVideoFromGallery();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReel() async {
    final videoFile = _videoFile;
    if (videoFile == null) {
      _showErrorSnackBar('please_add_reel_video'.tr);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthNotifier>();
      if (!auth.isAuthenticated || auth.authToken == null) {
        throw Exception('must_be_logged_in_create_reel'.tr);
      }

      final apiClient = Get.find<ApiClient>();
      apiClient.updateAuthToken(auth.authToken);
      final postsService = PostsApiService(apiClient);

      final uploadedVideo = await postsService.uploadFile(
        videoFile,
        type: FileUploadType.video,
        onProgress: (sent, total) {
          // TODO(reels): surface upload progress in the UI.
        },
      );
      if (uploadedVideo == null) {
        throw Exception('failed_to_upload_video'.tr);
      }

      await _createReelPost(postsService, uploadedVideo);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('reel_published_success'.tr)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('${'failed_to_create_reel'.tr}: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Creates the reel post from the uploaded video, following the reel
  /// contract in docs/reels_backend_api.md (sound merging is server-side —
  /// only ids are sent). For the full pipeline with original-sound
  /// extraction and retries, see ReelUploadService.
  Future<void> _createReelPost(
    PostsApiService postsService,
    UploadedFileData uploadedVideo,
  ) async {
    final thumb = _relativeThumbPath(uploadedVideo.thumb);
    final request = CreatePostRequest(
      handle: 'me',
      privacy: 'public',
      message: _captionController.text.trim(),
      reel: {
        'source': uploadedVideo.source,
        if (thumb != null) 'thumb': thumb,
        // TODO(reels): send real ids once the sound/effect pickers are wired.
        if (_selectedSoundId != null) 'sound_id': _selectedSoundId,
        if (_selectedEffectId != null) 'effect_id': _selectedEffectId,
      },
      reelThumbnail: thumb,
    );

    final response = await postsService.createPostAdvanced(request);
    if (!response.isSuccess) {
      throw Exception(response.message ?? 'failed_to_create_reel'.tr);
    }
  }

  /// Thumbnail is stored relative to `/content/uploads/` per the contract.
  String? _relativeThumbPath(String? thumbUrl) {
    if (thumbUrl == null) return null;
    if (thumbUrl.contains('/content/uploads/')) {
      return thumbUrl.split('/content/uploads/').last;
    }
    return thumbUrl;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('feature_coming_soon'.trParams({'feature': feature}))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'create_reel'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_videoFile == null)
                  _buildAddVideoBox(theme)
                else
                  _buildVideoPreview(theme),
                const SizedBox(height: 24),
                _buildDurationSelector(theme),
                const SizedBox(height: 16),
                _buildCustomizationTile(
                  theme,
                  icon: Iconsax.music,
                  label: _selectedSoundTitle ?? 'add_sound'.tr,
                  // TODO(reels): open the sound library (showMusicSheet) and
                  // set _selectedSoundId / _selectedSoundTitle.
                  onTap: () => _showComingSoon('sound_library'.tr),
                ),
                const SizedBox(height: 12),
                _buildCustomizationTile(
                  theme,
                  icon: Iconsax.magicpen,
                  label: _selectedEffectId ?? 'add_effect'.tr,
                  // TODO(reels): effect picker; set _selectedEffectId.
                  onTap: () => _showComingSoon('effects'.tr),
                ),
                const SizedBox(height: 16),
                _buildCaptionField(theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildSubmitButton(theme),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAddVideoBox(ThemeData theme) {
    return InkWell(
      onTap: _showVideoSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.video_add,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'tap_to_add_video'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'max_2_minutes_50mb'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    final controller = _videoController?.controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isReady
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (controller?.value.isPlaying ?? false)
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _removeSelectedVideo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recording_length'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _durationOptions.map((seconds) {
            final selected = _selectedDuration == seconds;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text('${seconds}s'),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedDuration = seconds),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomizationTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyLarge),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'caption'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'write_a_caption'.tr,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReel,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'publish_reel'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

// Video source option row for the bottom sheet.
class _VideoSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _VideoSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}