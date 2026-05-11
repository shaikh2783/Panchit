import 'dart:io';

import 'package:flutter/material.dart';
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
  });

  final CompetitionModel competition;

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
        'This competition accepts ${competition.allowedMediaType.label.toLowerCase()} entries only.',
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
        'This competition accepts ${competition.allowedMediaType.label.toLowerCase()} entries only.',
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
      _showMessage(
        'Competition registration is no longer open.',
        isError: true,
      );
      return;
    }

    if (!_hasValidEntry) {
      _showMessage(
        'Add text, image, or video before submitting your entry.',
        isError: true,
      );
      return;
    }

    if (!_validateRestrictions()) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassPopupDialog(
        title: 'Confirm Entry',
        message:
            '${formatMoney(competition.entryFee, competition.currencySymbol)} will be deducted from your wallet after submission. Your entry will be published as a competition post.\n\n${_buildSummaryText()}',
        icon: Icons.verified,
        secondaryLabel: 'Cancel',
        primaryLabel: 'Submit Entry',
      ),
    );

    if (confirmed != true || !mounted) {
      return;
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
            throw Exception('Image upload failed.');
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
          throw Exception('Video upload failed.');
        }
        uploadedVideo = _mapVideo(uploaded);
      }

      final request = CompetitionSubmitRequest(
        message: _textController.text.trim(),
        photos: uploadedPhotos,
        video: uploadedVideo,
        mediaType: _selectedMediaTypeLabel(),
      );

      final result = await competitionApi.submitCompetitionEntry(
        competitionId: competition.id,
        request: request,
      );

      if (!mounted) return;
      try {
        context.read<WalletOverviewBloc>().add(const RefreshWalletOverview());
      } catch (_) {
        // Wallet bloc is not always mounted in this route tree.
      }
      _showMessage(result.message ?? 'Competition entry submitted successfully.');
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
          _showMessage(
            'Video entries are not allowed for this competition.',
            isError: true,
          );
          return false;
        }
        if (_images.isEmpty) {
          _showMessage(
            'Please select at least one image for this competition.',
            isError: true,
          );
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.videoOnly:
        if (_images.isNotEmpty) {
          _showMessage(
            'Image entries are not allowed for this competition.',
            isError: true,
          );
          return false;
        }
        if (_video == null) {
          _showMessage(
            'Please select a video for this competition.',
            isError: true,
          );
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.textOnly:
        if (_images.isNotEmpty || _video != null) {
          _showMessage(
            'Only text entries are allowed for this competition.',
            isError: true,
          );
          return false;
        }
        if (_textController.text.trim().isEmpty) {
          _showMessage(
            'Please enter your text submission before continuing.',
            isError: true,
          );
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
      return 'Selected media: 1 video';
    }
    if (_images.isNotEmpty) {
      return 'Selected media: ${_images.length} image(s)';
    }
    return 'Selected entry: text submission';
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
        title: const Text('Competition Entry'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          CompetitionCard(
            competition: competition,
            primaryButtonLabel: 'View Details',
            onPrimaryTap: () => Navigator.of(context).maybePop(),
            showCountdown: true,
            secondaryChild: Text(
              'Allowed media: ${competition.allowedMediaType.label}',
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
            child: Text(_isSubmitting ? 'Submitting...' : 'Submit Entry'),
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
              'Create your competition entry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _textController,
              enabled: _canUseText && !_isSubmitting,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your caption or text entry',
                border: OutlineInputBorder(),
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
                  label: const Text('Add Images'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSubmitting || !_canPickVideo ? null : _pickVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Add Video'),
                ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              Text('Selected images: ${_images.length}'),
            ],
            if (_video != null) ...[
              const SizedBox(height: Spacing.md),
              Text('Selected video: ${_video!.path.split('/').last}'),
            ],
          ],
        ),
      ),
    );
  }
}
