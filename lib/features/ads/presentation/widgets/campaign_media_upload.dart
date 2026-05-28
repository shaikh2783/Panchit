import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class CampaignMediaUpload extends StatefulWidget {
  const CampaignMediaUpload({
    super.key,
    required this.mediaType,
    required this.imageUrl,
    required this.videoUrl,
    required this.onMediaTypeChanged,
    required this.onImagePicked,
    required this.onVideoPicked,
    required this.onUploadImage,
    required this.onUploadVideo,
    this.isUploading = false,
  });

  final String mediaType; // 'image' or 'video'
  final String? imageUrl;
  final String? videoUrl;
  final Function(String) onMediaTypeChanged;
  final Function(File) onImagePicked;
  final Function(File) onVideoPicked;
  final VoidCallback onUploadImage;
  final VoidCallback onUploadVideo;
  final bool isUploading;

  @override
  State<CampaignMediaUpload> createState() => _CampaignMediaUploadState();
}

class _CampaignMediaUploadState extends State<CampaignMediaUpload> {
  VideoPlayerController? _videoController;
  File? _localVideoFile;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(CampaignMediaUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController?.dispose();
    _videoController = null;

    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    } else if (_localVideoFile != null) {
      _videoController = VideoPlayerController.file(_localVideoFile!)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      widget.onImagePicked(File(image.path));
      widget.onUploadImage();
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      _localVideoFile = File(video.path);
      _initializeVideo();
      widget.onVideoPicked(File(video.path));
      widget.onUploadVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine what media we have
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final hasVideo = (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) || 
                     _localVideoFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ads_campaign_media'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              hasImage || hasVideo ? '' : 'required'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Media preview container
        Container(
          width: Get.width,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.cardColor.withOpacity(0.5),
                      theme.cardColor.withOpacity(0.3),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _buildMediaPreview(theme),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Media type selection buttons
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                context: context,
                theme: theme,
                icon: Iconsax.gallery,
                label: 'image'.tr,
                onTap: _pickImage,
                isSelected: hasImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                context: context,
                theme: theme,
                icon: Iconsax.video,
                label: 'video'.tr,
                onTap: _pickVideo,
                isSelected: hasVideo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreview(ThemeData theme) {
    // Show video if available
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Play/Pause overlay
          Center(
            child: IconButton(
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              icon: Icon(
                _videoController!.value.isPlaying 
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          // Edit button
          Positioned(
            top: 12,
            right: 12,
            child: _buildEditButton(theme, isVideo: true),
          ),
          if (widget.isUploading) _buildUploadingOverlay(theme),
        ],
      );
    }
    
    // Show image if available
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _buildEditButton(theme, isVideo: false),
          ),
          if (widget.isUploading) _buildUploadingOverlay(theme),
        ],
      );
    }
    
    // Show placeholder if no media
    return _buildUploadPlaceholder(theme);
  }

  Widget _buildEditButton(ThemeData theme, {required bool isVideo}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isVideo ? _pickVideo : _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Iconsax.edit_2,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'uploading'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Iconsax.gallery,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_upload,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'upload_image_or_video'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'select_media_below'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected 
          ? theme.colorScheme.primary 
          : theme.colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? Colors.white 
                    : theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? Colors.white 
                      : theme.colorScheme.onSurface,
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
