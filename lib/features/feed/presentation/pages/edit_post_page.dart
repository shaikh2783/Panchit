import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/posts_api_service.dart';
import '../../data/models/create_post_request.dart';
import '../../data/models/post.dart';
import '../../data/models/upload_file_data.dart';
import '../../data/services/post_management_api_service.dart';

/// Edit Post Page (EN, fixed layout, no scrolling)
class EditPostPage extends StatefulWidget {
  final Post post;
  final Function(Post updatedPost)? onPostUpdated;

  const EditPostPage({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late final PostManagementApiService _postService;
  late final PostsApiService _postsApiService;
  late final TextEditingController _textController;

  final _formKey = GlobalKey<FormState>();
  String _selectedPrivacy = 'public';
  bool _isLoading = false;
  bool _hasChanges = false;
  final List<File> _selectedImages = <File>[];
  File? _selectedVideo;
  bool _removeExistingMedia = false;

  final Map<String, String> _privacyOptions = const {
    'public': 'Public',
    'friends': 'Friends only',
    'private': 'Only me',
  };

  final Map<String, IconData> _privacyIcons = const {
    'public': Icons.public,
    'friends': Icons.group,
    'private': Icons.lock,
  };

  @override
  void initState() {
    super.initState();
    _postService = PostManagementApiService(
      Provider.of<ApiClient>(context, listen: false),
    );
    _postsApiService = Provider.of<PostsApiService>(context, listen: false);

    // Convert possible HTML text (e.g., <a> #hashtag </a>, <br>) to plain text for editing.
    final original = widget.post.text;
    final plain = _toPlainText(original);
    _textController = TextEditingController(text: plain);

    _selectedPrivacy = widget.post.privacy.isNotEmpty ? widget.post.privacy : 'public';

    _textController.addListener(_checkForChanges);
  }

  /// Convert simple HTML to plain text safely (no inline regex flags).
  String _toPlainText(String input) {
    var t = input;

    // 1) <br> / <br/> -> newline
    t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // 2) <a ...>inner</a> -> inner
    t = t.replaceAllMapped(
      RegExp(r'<a[^>]*>(.*?)<\/a>', caseSensitive: false, dotAll: true),
      (m) => m.group(1) ?? '',
    );

    // 3) Strip any remaining tags
    t = t.replaceAll(RegExp(r'<[^>]+>'), '');

    // 4) Decode some common entities
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return t.trimRight();
  }

  void _checkForChanges() {
    final hasTextChanged = _textController.text.trim() != _toPlainText(widget.post.text);
    final hasPrivacyChanged = _selectedPrivacy != widget.post.privacy;
    final hasMediaChanged =
        _removeExistingMedia || _selectedImages.isNotEmpty || _selectedVideo != null;
    if (mounted) {
      setState(() => _hasChanges = hasTextChanged || hasPrivacyChanged || hasMediaChanged);
    }
  }

  bool get _hasExistingPhotos =>
      (widget.post.photos?.isNotEmpty ?? false) && !_removeExistingMedia;

  bool get _hasExistingVideo =>
      (widget.post.video?.hasAnySource ?? false) && !_removeExistingMedia;

  Future<void> _pickImages() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(images.map((file) => File(file.path)));
      _selectedVideo = null;
      _removeExistingMedia = false;
    });
    _checkForChanges();
  }

  Future<void> _pickVideo() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    setState(() {
      _selectedVideo = File(video.path);
      _selectedImages.clear();
      _removeExistingMedia = false;
    });
    _checkForChanges();
  }

  void _removeMedia() {
    setState(() {
      _selectedImages.clear();
      _selectedVideo = null;
      _removeExistingMedia = true;
    });
    _checkForChanges();
  }

  void _discardNewMediaSelection() {
    setState(() {
      _selectedImages.clear();
      _selectedVideo = null;
      _removeExistingMedia = false;
    });
    _checkForChanges();
  }

  String _nextPostType({
    required bool hasNewPhotos,
    required bool hasNewVideo,
    required bool removeMedia,
  }) {
    if (hasNewPhotos) return 'photos';
    if (hasNewVideo) return widget.post.postType == 'reel' ? 'reel' : 'video';
    if (removeMedia) return 'text';
    return widget.post.postType;
  }

  Map<String, dynamic> _buildVideoPayload(UploadedFileData video) {
    return {
      'source': video.source,
      'type': video.type,
      'url': video.url,
      'category_id': '1',
      if (video.thumb != null) 'thumb': video.thumb,
      if (video.size != null) 'size': video.size,
      if (video.duration != null) 'duration': video.duration,
      if (video.width != null) 'width': video.width,
      if (video.height != null) 'height': video.height,
      if (video.extension != null) 'extension': video.extension,
      if (video.meta != null) 'meta': video.meta,
    };
  }

  Future<Post> _resolveUpdatedPost({
    List<PhotoData>? uploadedPhotos,
    Map<String, dynamic>? uploadedVideo,
    required bool removeMedia,
  }) async {
    try {
      final details = await _postService.getPostDetails(widget.post.id);
      final data = details['data'];
      Map<String, dynamic>? postJson;
      if (data is Map<String, dynamic>) {
        if (data['post'] is Map<String, dynamic>) {
          postJson = Map<String, dynamic>.from(data['post'] as Map<String, dynamic>);
        } else {
          postJson = Map<String, dynamic>.from(data);
        }
      } else if (details['post'] is Map<String, dynamic>) {
        postJson = Map<String, dynamic>.from(details['post'] as Map<String, dynamic>);
      }
      if (postJson != null && postJson.isNotEmpty) {
        return Post.fromJson(postJson);
      }
    } catch (_) {}

    final replacementPhotos = uploadedPhotos
        ?.map(
          (photo) => PostPhoto(
            id: 0,
            source: photo.source,
            blur: photo.blur == 1,
          ),
        )
        .toList();
    final replacementVideo = uploadedVideo != null
        ? PostVideo(
            originalSource: uploadedVideo['source']?.toString() ?? '',
            availableSources: const <String, String>{},
            thumbnail: uploadedVideo['thumb']?.toString() ?? '',
            categoryName: '',
          )
        : null;
    final nextType = _nextPostType(
      hasNewPhotos: replacementPhotos?.isNotEmpty ?? false,
      hasNewVideo: replacementVideo != null,
      removeMedia: removeMedia,
    );

    return widget.post.copyWith(
      text: _textController.text.trim(),
      privacy: _selectedPrivacy,
      postType: nextType,
      photos: replacementPhotos,
      video: replacementVideo,
      ogImage: replacementPhotos != null && replacementPhotos.isNotEmpty
          ? replacementPhotos.first.source
          : uploadedVideo?['thumb']?.toString(),
      clearPhotos: removeMedia || replacementVideo != null,
      clearVideo: removeMedia || (replacementPhotos?.isNotEmpty ?? false),
      clearOgImage:
          removeMedia || replacementVideo != null || (replacementPhotos?.isNotEmpty ?? false),
    );
  }

  Future<void> _saveChanges() async {
    if (_isLoading) {
      return;
    }
    
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<PhotoData>? uploadedPhotos;
      if (_selectedImages.isNotEmpty) {
        uploadedPhotos = <PhotoData>[];
        for (final image in _selectedImages) {
          final uploaded = await _postsApiService.uploadFile(
            image,
            type: FileUploadType.photo,
          );
          if (uploaded == null) {
            throw Exception('Failed to upload selected image.');
          }
          uploadedPhotos.add(
            PhotoData(
              source: uploaded.source,
              size: uploaded.size,
              extension: uploaded.extension ?? image.path.split('.').last,
              blur: uploaded.blur,
            ),
          );
        }
      }

      Map<String, dynamic>? uploadedVideo;
      if (_selectedVideo != null) {
        final uploaded = await _postsApiService.uploadFile(
          _selectedVideo!,
          type: FileUploadType.video,
        );
        if (uploaded == null) {
          throw Exception('Failed to upload selected video.');
        }
        uploadedVideo = _buildVideoPayload(uploaded);
      }

      final hasReplacementMedia =
          (uploadedPhotos?.isNotEmpty ?? false) || uploadedVideo != null;
      final shouldRemoveMedia = _removeExistingMedia && !hasReplacementMedia;
      final nextPostType = _nextPostType(
        hasNewPhotos: uploadedPhotos?.isNotEmpty ?? false,
        hasNewVideo: uploadedVideo != null,
        removeMedia: shouldRemoveMedia,
      );

      final result = await _postService.editPost(
        postId: widget.post.id,
        text: _textController.text.trim(),
        privacy: _selectedPrivacy,
        photos: uploadedPhotos,
        video: uploadedVideo,
        postType: nextPostType,
        replaceMedia: hasReplacementMedia,
        removeMedia: shouldRemoveMedia,
      );


      if (result['status'] == 'success' && mounted) {
        final updatedPost = await _resolveUpdatedPost(
          uploadedPhotos: uploadedPhotos,
          uploadedVideo: uploadedVideo,
          removeMedia: shouldRemoveMedia,
        );
        if (!mounted) return;

        widget.onPostUpdated?.call(updatedPost);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updatedPost);
      } else {
        _showError(result['message']?.toString() ?? 'Failed to update the post.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<bool> _confirmLeaveIfUnsaved() async {
    if (!_hasChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them and go back?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _openPrivacyPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Who can see this post?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            ..._privacyOptions.entries.map((e) {
              final isSelected = _selectedPrivacy == e.key;
              return RadioListTile<String>(
                value: e.key,
                groupValue: _selectedPrivacy,
                onChanged: (v) => Navigator.pop(ctx, v),
                title: Text(e.value),
                secondary: Icon(_privacyIcons[e.key], size: 22),
                selected: isSelected,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != _selectedPrivacy) {
      setState(() => _selectedPrivacy = selected);
      _checkForChanges();
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_checkForChanges);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _hasChanges && !_isLoading;

    return WillPopScope(
      onWillPop: _confirmLeaveIfUnsaved,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: () async {
              final ok = await _confirmLeaveIfUnsaved();
              if (ok && mounted) Navigator.pop(context);
            },
          ),
          title: const Text('Edit post', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            TextButton(
              onPressed: canSave ? _saveChanges : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),

        // FIXED layout (no scroll): Column + Expanded editor. Bottom bar is fixed.
        body: Form(
          key: _formKey,
          child: Column(
          children: [
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Editor card fills available height; text sticks to TOP even when empty.
                    Expanded(
                      child: _Card(
                        child: TextFormField(
                          controller: _textController,
                          // Make the field fill the card and keep text starting at TOP:
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          textAlign: TextAlign.start,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          validator: (val) {
                            final t = val?.trim() ?? '';
                            if (t.isEmpty) return 'Post text can’t be empty.';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _Card(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Iconsax.gallery, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Post media',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (_selectedImages.isNotEmpty || _selectedVideo != null)
                                TextButton(
                                  onPressed: _discardNewMediaSelection,
                                  child: const Text('Undo'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _removeExistingMedia
                                ? 'Current media will be removed when you save.'
                                : _selectedImages.isNotEmpty
                                    ? 'New photos will replace the current media.'
                                    : _selectedVideo != null
                                        ? 'New video will replace the current media.'
                                        : 'You can keep, replace, or remove the attached media.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _pickImages,
                                icon: const Icon(Iconsax.gallery_add, size: 18),
                                label: Text(
                                  _hasExistingPhotos || _selectedImages.isNotEmpty
                                      ? 'Replace photos'
                                      : 'Add photos',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _pickVideo,
                                icon: const Icon(Iconsax.video_add, size: 18),
                                label: Text(
                                  _hasExistingVideo || _selectedVideo != null
                                      ? 'Replace video'
                                      : 'Add video',
                                ),
                              ),
                              if (_hasExistingPhotos ||
                                  _hasExistingVideo ||
                                  _selectedImages.isNotEmpty ||
                                  _selectedVideo != null ||
                                  _removeExistingMedia)
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _removeMedia,
                                  icon: const Icon(Iconsax.trash, size: 18),
                                  label: const Text('Remove media'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_selectedImages.isNotEmpty)
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            )
                          else if (_selectedVideo != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.video_play, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedVideo!.path.split('/').last,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_hasExistingPhotos)
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.post.photos!.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final photo = widget.post.photos![index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      photo.source,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 92,
                                        height: 92,
                                        color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                                        alignment: Alignment.center,
                                        child: const Icon(Iconsax.gallery),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else if (_hasExistingVideo)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: widget.post.video!.thumbnail.isNotEmpty
                                        ? Image.network(
                                            widget.post.video!.thumbnail,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 72,
                                              height: 72,
                                              color: Theme.of(context)
                                                  .dividerColor
                                                  .withValues(alpha: 0.08),
                                              alignment: Alignment.center,
                                              child: const Icon(Iconsax.video_play),
                                            ),
                                          )
                                        : Container(
                                            width: 72,
                                            height: 72,
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.08),
                                            alignment: Alignment.center,
                                            child: const Icon(Iconsax.video_play),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Current video will stay unless you replace or remove it.',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
                              ),
                              child: Text(
                                'No media attached to this post.',
                                style: TextStyle(color: Theme.of(context).hintColor),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Privacy card (fixed, visible without scrolling)
                    _Card(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: ListTile(
                        leading: Icon(_privacyIcons[_selectedPrivacy], size: 22),
                        title:
                            const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_privacyOptions[_selectedPrivacy] ?? 'Public'),
                        trailing: const Icon(Iconsax.arrow_down_1, size: 18),
                        onTap: _openPrivacyPicker,
                      ),
                    ),

                    const SizedBox(height: 8),
                    if (_hasChanges)
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 6),
                          Text('You have unsaved changes',
                              style: TextStyle(color: Theme.of(context).hintColor)),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action bar (always visible)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 0.7),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final ok = await _confirmLeaveIfUnsaved();
                              if (ok && mounted) Navigator.pop(context);
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canSave ? _saveChanges : null,
                      child: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Simple reusable card with optional custom padding.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: child,
    );
  }
}
