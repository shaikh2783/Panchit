import 'dart:io';
import 'dart:math' as math;

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/theme_controller.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/reel_upload_service.dart';
import 'package:snginepro/features/reels/presentation/widgets/color_filter_picker.dart';
import 'package:video_player/video_player.dart';

class ReelPublishPage extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;
  final SelectedMusic? selectedMusic;
  final List<double>? filterMatrix;
  final String? filterName;

  const ReelPublishPage({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
    this.selectedMusic,
    this.filterMatrix,
    this.filterName,
  });

  @override
  State<ReelPublishPage> createState() => _ReelPublishPageState();
}

class _ReelPublishPageState extends State<ReelPublishPage> {
  static const Color _reelPink = Color(0xFFE1306C);
  static const int _captionMaxLength = 2200;

  final TextEditingController _descriptionController = TextEditingController();
  final ThemeController _themeController = Get.find();

  CachedVideoPlayerPlus? _videoController;

  bool _isPublishing = false;
  bool _isPreviewLoading = true;
  bool _allowComments = true;
  bool _shareToFeed = true;

  ReelUploadStage? _stage;
  double _stageProgress = 0;
  String? _error;

  bool get _hasVideoUploadProgress =>
      _stage == ReelUploadStage.uploadingVideo && _stageProgress > 0;

  bool get _isPreviewReady {
    final videoController = _videoController;
    return videoController != null && videoController.isInitialized;
  }

  bool get _canPublish => !_isPublishing && _isPreviewReady;

  String get _stageLabel {
    switch (_stage) {
      case ReelUploadStage.extractingSound:
        return 'preparing_sound'.tr;
      case ReelUploadStage.uploadingSound:
        return 'uploading_sound'.tr;
      case ReelUploadStage.uploadingVideo:
        return '${'uploading_video'.tr} ${(_stageProgress * 100).toInt()}%';
      case ReelUploadStage.publishing:
        return 'publishing_reel'.tr;
      default:
        return 'publishing_reel'.tr;
    }
  }

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    try {
      final previewController = CachedVideoPlayerPlus.file(
        File(widget.videoPath),
      );

      await previewController.initialize();

      if (!mounted) {
        previewController.dispose();
        return;
      }

      previewController.controller.setLooping(true);
      previewController.controller.play();

      setState(() {
        _videoController = previewController;
        _isPreviewLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isPreviewLoading = false;
        _error = 'video_preview_failed'.tr;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (_isPublishing) return false;

    final hasCaption = _descriptionController.text.trim().isNotEmpty;
    if (!hasCaption) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('discard_reel_question'.tr),
          content: Text('discard_caption_warning'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'discard'.tr,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handleClose() async {
    final canClose = await _confirmDiscardIfNeeded();

    if (!mounted || !canClose) return;
    Navigator.pop(context);
  }

  Future<void> _publish() async {
    if (!_canPublish) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isPublishing = true;
      _error = null;
      _stage = null;
      _stageProgress = 0;
    });

    try {
      await context.read<ReelUploadService>().publishReel(
        videoPath: widget.videoPath,
        message: _descriptionController.text.trim(),
        selectedMusic: widget.selectedMusic,
        onProgress: (stage, progress) {
          if (!mounted) return;

          setState(() {
            _stage = stage;
            _stageProgress = progress.clamp(0.0, 1.0).toDouble();
          });
        },
      );

      if (!mounted) return;

      // Close the whole creation flow (publish/edit/trim/camera) and land
      // back on the home shell at the root route.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reel_published_success'.tr),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPublishing = false;
        _error = e is ReelUploadException ? '${e.cause}' : '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF0F0F10) : Colors.white;

    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _buildPreviewSection(isDark),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      _buildErrorBanner(isDark),
                      const SizedBox(height: 14),
                    ],
                    _buildCaptionCard(isDark),
                    const SizedBox(height: 14),
                    _buildMediaDetailsCard(isDark),
                    const SizedBox(height: 14),
                    _buildPublishOptionsCard(isDark),
                  ],
                ),
              ),
              if (_isPublishing) _buildPublishingBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F10) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF242428) : const Color(0xFFEDEDED),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isPublishing ? null : _handleClose,
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'new_reel'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: _canPublish ? _publish : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _reelPink,
                disabledBackgroundColor:
                isDark ? Colors.grey[800] : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                _error != null ? 'retry'.tr : 'share'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final previewWidth = math.min(screenWidth * 0.68, 270.0);

    return Column(
      children: [
        Text(
          'preview'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: previewWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildVideoPreview(isDark),
                    _buildPreviewTopOverlay(),
                    _buildPreviewBottomOverlay(),
                    if (_isPublishing) _buildPreviewProgressOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(bool isDark) {
    final videoController = _videoController;

    if (videoController != null && videoController.isInitialized) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(
          widget.filterMatrix ?? kDefaultFilter,
        ),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoController.controller.value.size.width,
            height: videoController.controller.value.size.height,
            child: VideoPlayer(videoController.controller),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
      child: Center(
        child: _isPreviewLoading
            ? CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.white : Colors.black,
          ),
        )
            : Icon(
          Icons.error_outline,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildPreviewTopOverlay() {
    final filterName = widget.filterName;

    if (filterName == null || filterName.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              filterName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBottomOverlay() {
    final musicTitle = widget.selectedMusic?.music?.title;

    if (musicTitle == null || musicTitle.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                musicTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewProgressOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LinearProgressIndicator(
        value: _hasVideoUploadProgress ? _stageProgress : null,
        backgroundColor: Colors.black38,
        valueColor: const AlwaysStoppedAnimation<Color>(_reelPink),
        minHeight: 3,
      ),
    );
  }

  Widget _buildCaptionCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'caption'.tr,
            subtitle: 'write_something_for_reel'.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                isDark ? const Color(0xFF2A2A2E) : const Color(0xFFEDEDED),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  enabled: !_isPublishing,
                  maxLines: 4,
                  maxLength: _captionMaxLength,
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    hintText: 'write_a_caption'.tr,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaDetailsCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          _buildMediaRow(
            isDark: isDark,
            icon: Icons.image_outlined,
            title: 'cover'.tr,
            subtitle: widget.thumbnailPath != null
                ? 'custom_cover_selected'.tr
                : 'default_video_cover'.tr,
            trailing: _buildThumbnailPreview(isDark),
            onTap: _isPublishing ? null : () {},
          ),
          _buildDivider(isDark),
          _buildMediaRow(
            isDark: isDark,
            icon: Icons.music_note_outlined,
            title: 'music'.tr,
            subtitle: widget.selectedMusic?.music?.title ?? 'original_audio'.tr,
            onTap: _isPublishing ? null : () {},
          ),
          if (widget.filterName != null && widget.filterName!.trim().isNotEmpty) ...[
            _buildDivider(isDark),
            _buildMediaRow(
              isDark: isDark,
              icon: Icons.auto_awesome_outlined,
              title: 'filter'.tr,
              subtitle: widget.filterName!,
              onTap: null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublishOptionsCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          // _buildMediaRow(
          //   isDark: isDark,
          //   icon: Icons.people_alt_outlined,
          //   title: 'Tag people',
          //   subtitle: 'Add people to this reel',
          //   onTap: _isPublishing ? null : () {},
          // ),
          // _buildDivider(isDark),
          // _buildMediaRow(
          //   isDark: isDark,
          //   icon: Icons.location_on_outlined,
          //   title: 'Add location',
          //   subtitle: 'Let people know where this was taken',
          //   onTap: _isPublishing ? null : () {},
          // ),
          // _buildDivider(isDark),
          // _buildMediaRow(
          //   isDark: isDark,
          //   icon: Icons.public,
          //   title: 'Audience',
          //   subtitle: 'Public',
          //   onTap: _isPublishing ? null : () {},
          // ),
          // _buildDivider(isDark),
          _buildSwitchRow(
            isDark: isDark,
            icon: Icons.chat_bubble_outline,
            title: 'allow_comments'.tr,
            value: _allowComments,
            onChanged: _isPublishing
                ? null
                : (value) {
              setState(() {
                _allowComments = value;
              });
            },
          ),
          _buildDivider(isDark),
          _buildSwitchRow(
            isDark: isDark,
            icon: Icons.grid_on_outlined,
            title: 'share_to_feed'.tr,
            value: _shareToFeed,
            onChanged: _isPublishing
                ? null
                : (value) {
              setState(() {
                _shareToFeed = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${'reel_publish_failed'.tr}: $_error',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishingBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF242428) : const Color(0xFFEDEDED),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: _hasVideoUploadProgress ? _stageProgress : null,
              strokeWidth: 2.4,
              valueColor: const AlwaysStoppedAnimation<Color>(_reelPink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _stageLabel,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _hasVideoUploadProgress ? '${(_stageProgress * 100).toInt()}%' : '',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFEFEF),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final iconBackground =
    isDark ? const Color(0xFF242428) : const Color(0xFFFFFFFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing,
            ] else if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242428) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: _reelPink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview(bool isDark) {
    final thumbnailPath = widget.thumbnailPath;

    if (thumbnailPath == null || thumbnailPath.trim().isEmpty) {
      return Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey[600] : Colors.grey[500],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(thumbnailPath),
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 42,
            height: 42,
            color: isDark ? const Color(0xFF242428) : const Color(0xFFEDEDED),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 18,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, top: 10, bottom: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFEFEF),
      ),
    );
  }
}