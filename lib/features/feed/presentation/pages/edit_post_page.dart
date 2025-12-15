import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/post.dart';
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
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String _selectedPrivacy = 'public';
  bool _isLoading = false;
  bool _hasChanges = false;
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
    // Convert possible HTML text (e.g., <a> #hashtag </a>, <br>) to plain text for editing.
    final original = widget.post.text ?? '';
    final plain = _toPlainText(original);
    _textController = TextEditingController(text: plain);
    _selectedPrivacy =
        (widget.post.privacy?.isNotEmpty ?? false) ? widget.post.privacy : 'public';
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
    final hasTextChanged = _textController.text.trim() != _toPlainText(widget.post.text ?? '');
    final hasPrivacyChanged = _selectedPrivacy != (widget.post.privacy ?? 'public');
    if (mounted) setState(() => _hasChanges = hasTextChanged || hasPrivacyChanged);
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
      final result = await _postService.editPost(
        postId: widget.post.id,
        text: _textController.text.trim(),
        privacy: _selectedPrivacy,
      );
      if (result['status'] == 'success' && mounted) {
        final updatedPost = Post(
          id: widget.post.id,
          authorName: widget.post.authorName,
          publishedAt: widget.post.publishedAt,
          text: _textController.text.trim(),
          postType: widget.post.postType,
          authorAvatarUrl: widget.post.authorAvatarUrl,
          authorId: widget.post.authorId,
          authorUsername: widget.post.authorUsername,
          authorType: widget.post.authorType,
          pageId: widget.post.pageId,
          pageName: widget.post.pageName,
          pageTitle: widget.post.pageTitle,
          commentsCount: widget.post.commentsCount,
          reactionsCount: widget.post.reactionsCount,
          sharesCount: widget.post.sharesCount,
          isVerified: widget.post.isVerified,
          myReaction: widget.post.myReaction,
          privacy: _selectedPrivacy,
          reactionBreakdown: widget.post.reactionBreakdown,
          permalink: widget.post.permalink,
          video: widget.post.video,
          photos: widget.post.photos,
          poll: widget.post.poll,
          isSaved: widget.post.isSaved,
          isPinned: widget.post.isPinned,
          isHidden: widget.post.isHidden,
          commentsDisabled: widget.post.commentsDisabled,
        );
        widget.onPostUpdated?.call(updatedPost);
        Navigator.pop(context, updatedPost);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully'), backgroundColor: Colors.green),
        );
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
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: child,
    );
  }
}
