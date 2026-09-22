import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_event.dart';

class CompetitionEntryPage extends StatefulWidget {
  const CompetitionEntryPage({
    super.key,
    required this.competition,
    this.existingEntry,
  });

  final CompetitionModel competition;
  final CompetitionEntryModel? existingEntry;

  @override
  State<CompetitionEntryPage> createState() => _CompetitionEntryPageState();
}

class _CompetitionEntryPageState extends State<CompetitionEntryPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final List<File> _images = <File>[];
  File? _video;
  bool _isSubmitting = false;
  double _uploadProgress = 0;

  CompetitionModel get competition => widget.competition;
  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _textController.text = widget.existingEntry!.postText ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canPickImages => competition.allowedMediaType.allowsImages;

  bool get _canPickVideo => competition.allowedMediaType.allowsVideo;

  bool get _canUseText => competition.allowedMediaType.allowsText;

  bool get _hasValidEntry {
    final hasText = _textController.text.trim().isNotEmpty;
    return _images.isNotEmpty || _video != null || hasText;
  }

  Future<void> _pickImages() async {
    if (!_canPickImages) {
      _showMessage(
        'entry_media_type_only'.trParams({'type': competition.allowedMediaType.label.toLowerCase()}),
        isError: true,
      );
      return;
    }

    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;

    setState(() {
      _images
        ..clear()
        ..addAll(files.map((file) => File(file.path)));
      _video = null;
    });
  }

  Future<void> _pickVideo() async {
    if (!_canPickVideo) {
      _showMessage(
        'entry_media_type_only'.trParams({'type': competition.allowedMediaType.label.toLowerCase()}),
        isError: true,
      );
      return;
    }

    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _video = File(file.path);
      _images.clear();
    });
  }

  Future<void> _submit() async {
    if (!competition.isRegistrationOpen) {
      _showMessage('entry_registration_closed'.tr, isError: true);
      return;
    }

    if (!_hasValidEntry) {
      _showMessage('entry_no_content'.tr, isError: true);
      return;
    }

    if (!_validateRestrictions()) {
      return;
    }

    if (!_isEditMode) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => GlassPopupDialog(
          title: 'entry_confirm_title'.tr,
          message:
              '${formatMoney(competition.entryFee, competition.currencySymbol)} ${'entry_deduction_msg'.tr}\n\n${_buildSummaryText()}',
          icon: Icons.verified,
          secondaryLabel: 'cancel'.tr,
          primaryLabel: 'entry_submit'.tr,
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    try {
      final postsApi = context.read<PostsApiService>();
      final competitionApi = context.read<CompetitionApiService>();

      final List<Map<String, dynamic>> uploadedPhotos = <Map<String, dynamic>>[];
      if (_images.isNotEmpty) {
        for (final image in _images) {
          final uploaded = await postsApi.uploadFile(
            image,
            type: FileUploadType.photo,
          );
          if (uploaded == null) {
            throw Exception('entry_image_upload_failed'.tr);
          }
          uploadedPhotos.add(_mapPhoto(uploaded));
        }
      }

      Map<String, dynamic>? uploadedVideo;
      if (_video != null) {
        final uploaded = await postsApi.uploadFile(
          _video!,
          type: FileUploadType.video,
          onProgress: (sent, total) {
            if (!mounted || total <= 0) return;
            setState(() {
              _uploadProgress = sent / total;
            });
          },
        );
        if (uploaded == null) {
          throw Exception('entry_video_upload_failed'.tr);
        }
        uploadedVideo = _mapVideo(uploaded);
      }

      final request = CompetitionSubmitRequest(
        message: _textController.text.trim(),
        photos: uploadedPhotos,
        video: uploadedVideo,
        mediaType: _selectedMediaTypeLabel(),
      );

      if (_isEditMode) {
        await competitionApi.updateCompetitionEntry(
          competitionId: competition.id,
          entryId: widget.existingEntry!.id,
          request: request,
        );
      } else {
        final result = await competitionApi.submitCompetitionEntry(
          competitionId: competition.id,
          request: request,
        );
        if (!mounted) return;
        try {
          context.read<WalletOverviewBloc>().add(const RefreshWalletOverview());
        } catch (_) {}
        _showMessage(result.message ?? 'competition_entry_submitted'.tr);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  bool _validateRestrictions() {
    switch (competition.allowedMediaType) {
      case CompetitionAllowedMediaType.imageOnly:
        if (_video != null) {
          _showMessage('entry_video_not_allowed'.tr, isError: true);
          return false;
        }
        if (_images.isEmpty) {
          _showMessage('entry_image_required'.tr, isError: true);
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.videoOnly:
        if (_images.isNotEmpty) {
          _showMessage('entry_image_not_allowed'.tr, isError: true);
          return false;
        }
        if (_video == null) {
          _showMessage('entry_video_required'.tr, isError: true);
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.textOnly:
        if (_images.isNotEmpty || _video != null) {
          _showMessage('entry_text_only'.tr, isError: true);
          return false;
        }
        if (_textController.text.trim().isEmpty) {
          _showMessage('entry_text_required'.tr, isError: true);
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.all:
        return true;
    }
  }

  String _selectedMediaTypeLabel() {
    if (_video != null) return 'video';
    if (_images.isNotEmpty) return 'image';
    return 'text';
  }

  String _buildSummaryText() {
    if (_video != null) {
      return 'entry_summary_video'.tr;
    }
    if (_images.isNotEmpty) {
      return 'entry_summary_images'.trParams({'count': '${_images.length}'});
    }
    return 'entry_summary_text'.tr;
  }

  Map<String, dynamic> _mapPhoto(UploadedFileData file) {
    return {
      'source': file.source,
      'blur': file.blur,
      if (file.extension != null) 'extension': file.extension,
      if (file.size != null) 'size': file.size,
    };
  }

  Map<String, dynamic> _mapVideo(UploadedFileData file) {
    return {
      'source': file.source,
      if (file.thumb != null) 'thumb': file.thumb,
      if (file.duration != null) 'duration': file.duration,
      if (file.width != null) 'width': file.width,
      if (file.height != null) 'height': file.height,
      if (file.extension != null) 'extension': file.extension,
    };
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'entry_edit_title'.tr : 'entry_title'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          CompetitionCard(
            competition: competition,
            primaryButtonLabel: 'entry_view_details'.tr,
            onPrimaryTap: () => Navigator.of(context).maybePop(),
            showCountdown: true,
            secondaryChild: Text(
              'entry_allowed_media'.trParams({'type': competition.allowedMediaType.label}),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          _buildComposerCard(context),
          if (_isSubmitting) ...[
            const SizedBox(height: Spacing.lg),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _isSubmitting
                  ? (_isEditMode ? 'entry_updating'.tr : 'entry_submitting'.tr)
                  : (_isEditMode ? 'entry_update'.tr : 'entry_submit'.tr),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'entry_edit_create_title'.tr : 'entry_create_title'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _textController,
              enabled: _canUseText && !_isSubmitting,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'entry_caption_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSubmitting || !_canPickImages ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: Text('entry_add_images'.tr),
                ),
                OutlinedButton.icon(
                  onPressed: _isSubmitting || !_canPickVideo ? null : _pickVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text('entry_add_video'.tr),
                ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              Text('entry_selected_images'.trParams({'count': '${_images.length}'})),
            ],
            if (_video != null) ...[
              const SizedBox(height: Spacing.md),
              Text('${'entry_selected_video'.tr}: ${_video!.path.split('/').last}'),
            ],
          ],
        ),
      ),
    );
  }
}
