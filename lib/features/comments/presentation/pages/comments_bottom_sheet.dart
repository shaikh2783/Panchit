import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../application/comments_notifier.dart';
import '../../application/replies_notifier.dart';
import '../../data/models/comment.dart';
import '../../data/datasources/comments_api_service.dart';
import '../widgets/reactions_menu.dart';
import '../../../../core/services/reactions_service.dart';
class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.commentsCount,
  });
  final int postId;
  final int commentsCount;
  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}
class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  CommentModel? _replyingToComment;
  final Map<String, bool> _expandedReplies = {};
  final Map<String, int> _visibleReplies = {}; // للتحكم في "عرض المزيد"
  File? _selectedImage;
  File? _recordedAudio;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsNotifier>().fetchComments(widget.postId);
    });
  }
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedImage == null && _recordedAudio == null) return;
    String? imagePath;
    String? voiceNotePath;
    // رفع الصورة
    if (_selectedImage != null) {
      try {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Uploading'.tr)),
            );
          } catch (e, s) {
            print(s);
          }
        }
        final apiService = context.read<CommentsApiService>();
        imagePath = await apiService.uploadImage(_selectedImage!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'upload_image_failed'} $e')),
          );
        }
        return;
      }
    }
    // رفع الصوت
    if (_recordedAudio != null) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('uploading_voice'.tr)),
          );
        }
        final apiService = context.read<CommentsApiService>();
        voiceNotePath = await apiService.uploadAudio(_recordedAudio!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'upload_voice_failed'} $e')),
          );
        }
        return;
      }
    }
    if (_replyingToComment != null) {
      // إرسال رد
      final repliesNotifier = context.read<RepliesNotifier>();
      final reply = await repliesNotifier.createReply(
        commentId: int.parse(_replyingToComment!.commentId),
        text: text,
        image: imagePath,
        voiceNote: voiceNotePath,
      );
      if (reply != null) {
        context.read<CommentsNotifier>().incrementRepliesCount(
              _replyingToComment!.commentId,
            );
        setState(() {
          _expandedReplies[_replyingToComment!.commentId] = true;
          // عند أول فتح نعرض ردّين مثل فيسبوك
          _visibleReplies[_replyingToComment!.commentId] =
              (_visibleReplies[_replyingToComment!.commentId] ?? 2).clamp(2, 2);
          _replyingToComment = null;
          _selectedImage = null;
          _recordedAudio = null;
        });
      }
    } else {
      // إرسال تعليق
      final commentsNotifier = context.read<CommentsNotifier>();
      await commentsNotifier.createComment(
        postId: widget.postId,
        text: text,
        image: imagePath,
        voiceNote: voiceNotePath,
      );
      setState(() {
        _selectedImage = null;
        _recordedAudio = null;
      });
    }
    _commentController.clear();
    _commentFocus.unfocus();
  }
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        setState(() {
          _recordedAudio = File(path);
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _recordingStartTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('voice_saved'.tr)),
        );
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        try {
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final audioPath = '${tempDir.path}/comment_audio_$timestamp.m4a';
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: audioPath,
          );
          setState(() {
            _isRecording = true;
            _recordingStartTime = DateTime.now();
            _recordingDuration = Duration.zero;
          });
          _updateRecordingDuration();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${'start_recording_failed'.tr} $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('mic_permission_settings'.tr),
            ),
          );
        }
      }
    }
  }
  void _updateRecordingDuration() {
    if (_isRecording && _recordingStartTime != null) {
      setState(() {
        _recordingDuration = DateTime.now().difference(_recordingStartTime!);
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording && mounted) {
          _updateRecordingDuration();
        }
      });
    }
  }
  void _removeRecording() {
    setState(() {
      _recordedAudio = null;
    });
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  String _formatRelative(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    if (diff.inDays < 7) return '${diff.inDays} يوم';
    return '${time.year}/${time.month}/${time.day}';
  }
  void _handleReplyToComment(CommentModel comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _commentFocus.requestFocus();
  }
  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
  }
  void _toggleReplies(String commentId) {
    setState(() {
      final next = !(_expandedReplies[commentId] ?? false);
      _expandedReplies[commentId] = next;
      if (next && !_visibleReplies.containsKey(commentId)) {
        _visibleReplies[commentId] = 2; // مثل فيسبوك: عرض ردّين بدايةً
      }
    });
    if (_expandedReplies[commentId] == true) {
      final repliesNotifier = context.read<RepliesNotifier>();
      if (repliesNotifier.getReplies(commentId).isEmpty) {
        repliesNotifier.fetchReplies(int.parse(commentId));
      }
    }
  }
  void _loadMoreReplies(String commentId, int step, int total) {
    final current = _visibleReplies[commentId] ?? 2;
    setState(() {
      _visibleReplies[commentId] = (current + step).clamp(0, total);
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsNotifier = context.watch<CommentsNotifier>();
    final repliesNotifier = context.watch<RepliesNotifier>();
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, sheetScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'comments'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${commentsNotifier.commentsCount})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Comments list
              Expanded(
                child: commentsNotifier.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : commentsNotifier.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'load_comments_error'.tr,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => commentsNotifier
                                      .fetchComments(widget.postId),
                                  child:  Text('retry'.tr),
                                ),
                              ],
                            ),
                          )
                        : commentsNotifier.comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.comment_outlined,
                                      size: 64,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'no_comments'.tr,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'no_comments'.tr,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : NotificationListener<ScrollNotification>(
                                onNotification: (notif) {
                                  // pagination عندما نقترب من الأسفل
                                  if (notif.metrics.pixels >=
                                          notif.metrics.maxScrollExtent - 200 &&
                                      !commentsNotifier.isLoadingMore &&
                                      commentsNotifier.hasMore) {
                                    commentsNotifier
                                        .loadMoreComments(widget.postId);
                                  }
                                  return false;
                                },
                                child: ListView.separated(
                                  controller: sheetScrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  itemCount: commentsNotifier.comments.length +
                                      (commentsNotifier.isLoadingMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    if (index ==
                                        commentsNotifier.comments.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final comment =
                                        commentsNotifier.comments[index];
                                    final isExpanded =
                                        _expandedReplies[comment.commentId] ??
                                            false;
                                    final replies = repliesNotifier
                                        .getReplies(comment.commentId);
                                    final isLoadingReplies = repliesNotifier
                                        .isLoading(comment.commentId);
                                    final visible =
                                        _visibleReplies[comment.commentId] ??
                                            2;
                                    final total = replies.length;
                                    final showLoadMore =
                                        isExpanded && total > visible;
                                    return _CommentTile(
                                      theme: theme,
                                      comment: comment,
                                      formatRelative: _formatRelative,
                                      isReply: false,
                                      isLiked: comment.iReact,
                                      reactionsTotalCount:
                                          comment.reactionsTotalCount,
                                      onLike: () {
                                        final notifier = context.read<CommentsNotifier>();
                                        // Toggle: إرسال نفس التفاعل لإزالته
                                        notifier.reactToComment(
                                          commentId: comment.commentId,
                                          reaction: comment.iReact && comment.iReaction != null 
                                              ? comment.iReaction! 
                                              : 'like',
                                        );
                                      },
                                      onReply: () =>
                                          _handleReplyToComment(comment),
                                      // قائمة الردود
                                      repliesSection: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (comment.repliesCount > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 56),
                                              child: TextButton.icon(
                                                onPressed: () =>
                                                    _toggleReplies(comment.commentId),
                                                icon: Icon(
                                                  isExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  size: 20,
                                                ),
                                                label: Text(
                                                  isExpanded
                                                      ? 'hide_replies'.tr
                                                      : 'Show ${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply'.tr : 'replies'}',
                                                  style: theme
                                                      .textTheme.bodySmall,
                                                ),
                                              ),
                                            ),
                                          if (isExpanded)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 56, left: 8),
                                              child: Column(
                                                children: [
                                                  if (isLoadingReplies)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.all(16),
                                                      child:
                                                          CircularProgressIndicator(),
                                                    )
                                                  else ...[
                                                    for (final reply
                                                        in replies.take(visible))
                                                      _CommentTile(
                                                        theme: theme,
                                                        comment: reply,
                                                        formatRelative:
                                                            _formatRelative,
                                                        isReply: true,
                                                        isLiked: reply.iReact,
                                                        reactionsTotalCount:
                                                            reply.reactionsTotalCount,
                                                        parentCommentId: comment.commentId, // إضافة معرف التعليق الأب
                                                        onLike: () {
                                                          final notifier = context.read<RepliesNotifier>();
                                                          // Toggle: إرسال نفس التفاعل لإزالته
                                                          notifier.reactToReply(
                                                            parentCommentId: comment.commentId,
                                                            replyId: reply.commentId,
                                                            reaction: reply.iReact && reply.iReaction != null 
                                                                ? reply.iReaction! 
                                                                : 'like',
                                                          );
                                                        },
                                                        onReply: () =>
                                                            _handleReplyToComment(
                                                                comment),
                                                      ),
                                                    if (showLoadMore)
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              _loadMoreReplies(
                                                                  comment
                                                                      .commentId,
                                                                  5,
                                                                  total),
                                                          child: Text(
                                                            '${'show_more_replies'.tr} (${total - visible})',
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
              const Divider(height: 1),
              // Comment input (Facebook-like)
              Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شارة "الرد على"
                    if (_replyingToComment != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#${'replying_to'.tr} ${_replyingToComment!.authorName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _cancelReply,
                              icon: const Icon(Icons.close, size: 18),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    // معاينة صورة
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: _removeImage,
                                icon: const Icon(Icons.close, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(28, 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // معاينة الصوت
                    if (_recordedAudio != null && !_isRecording)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mic,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'voice_recording'.tr,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'ready_to_send'.tr,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _removeRecording,
                              icon: const Icon(Icons.close, size: 20),
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(28, 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // مؤشر التسجيل
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${'recording'.tr} ${_formatDuration(_recordingDuration)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // شريط الإدخال
                    Row(
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.image_outlined,
                            color: _selectedImage != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.65),
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleRecording,
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic_none,
                            color: _isRecording
                                ? Colors.red
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.65),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocus,
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _handleSendComment(),
                              decoration: InputDecoration(
                                hintText: _replyingToComment != null
                                    ? 'write_reply'.tr
                                    : 'write_comment'.tr,
                                hintStyle: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _handleSendComment,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.send, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/// عنصر تعليق/رد بأسلوب فيسبوك
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.theme,
    required this.comment,
    required this.formatRelative,
    required this.isReply,
    required this.isLiked,
    required this.reactionsTotalCount,
    required this.onLike,
    required this.onReply,
    this.repliesSection,
    this.parentCommentId, // لتمييز الردود
  });
  final ThemeData theme;
  final CommentModel comment;
  final String Function(DateTime) formatRelative;
  final bool isReply;
  final bool isLiked;
  final int reactionsTotalCount;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final Widget? repliesSection;
  final String? parentCommentId; // للردود فقط
  // عرض قائمة التفاعلات
  void _showReactionsMenu(BuildContext context, {required Function(String) onReact}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReactionsMenu(onReact: onReact),
    );
  }
  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: isReply ? 56 : 8,
        end: 8,
        top: 6,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة البروفايل
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.authorPicture.isNotEmpty
                ? CachedNetworkImageProvider(comment.authorPicture)
                : null,
            child: comment.authorPicture.isEmpty
                ? Text(
                    _initials(comment.authorName),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // فقاعة التعليق
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? cs.surfaceContainerHighest.withOpacity(0.35)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم + الوقت
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.authorName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                         comment.time,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // النص
                      if (comment.text.isNotEmpty)
                        Text(
                          comment.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      // صورة مرفقة
                      if (comment.image != null && comment.image!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              comment.image!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // مرفق صوتي بسيط (أيقونة/نص)
                      if (comment.voiceNote != null &&
                          comment.voiceNote!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'voice_message'.tr,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              // يمكن لاحقًا إضافة مشغل صوتي فعلي
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // شريط “إعجاب · ردّ” + عدّاد التفاعلات
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 6, top: 6, bottom: 2),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: onLike,
                        onLongPress: () => _showReactionsMenu(context, onReact: (reaction) {
                          Navigator.pop(context);
                          // إرسال التفاعل المحدد
                          if (isReply && parentCommentId != null) {
                            // للردود
                            context.read<RepliesNotifier>().reactToReply(
                              parentCommentId: parentCommentId!,
                              replyId: comment.commentId,
                              reaction: reaction,
                            );
                          } else {
                            // للتعليقات الرئيسية
                            context.read<CommentsNotifier>().reactToComment(
                              commentId: comment.commentId,
                              reaction: reaction,
                            );
                          }
                        }),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLiked && comment.iReaction != null)
                                _getReactionIcon(comment.iReaction!)
                              else
                                const SizedBox.shrink(),
                              if (isLiked && comment.iReaction != null)
                                const SizedBox(width: 4),
                              Text(
                                isLiked && comment.iReaction != null
                                    ? _getReactionText(comment.iReaction!)
                                    : 'like'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight:
                                      isLiked ? FontWeight.w700 : FontWeight.w500,
                                  color: isLiked ? _getReactionColor(comment.iReaction) : cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Text(
                            'reply'.tr,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (reactionsTotalCount > 0)
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              reactionsTotalCount.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (repliesSection != null) repliesSection!,
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString();
    return (parts[0].isNotEmpty ? parts[0][0] : '') +
        (parts[1].isNotEmpty ? parts[1][0] : '');
  }
  // دوال مساعدة للتفاعلات - تستخدم البيانات من API
  Widget _getReactionIcon(String reaction) {
    final reactionModel = ReactionsService.instance.getReactionByName(reaction);
    if (reactionModel != null) {
      return CachedNetworkImage(
        imageUrl: reactionModel.imageUrl,
        width: 16,
        height: 16,
        placeholder: (context, url) => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: reactionModel.colorValue,
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.emoji_emotions,
          size: 16,
          color: reactionModel.colorValue,
        ),
      );
    }
    // إذا لم يوجد في الكاش، نعرض أيقونة افتراضية
    return const Icon(Icons.thumb_up_alt, size: 16, color: Colors.blue);
  }
  String _getReactionText(String reaction) {
    final reactionModel = ReactionsService.instance.getReactionByName(reaction);
    return reactionModel?.title ?? 'like'.tr;
  }
  Color? _getReactionColor(String? reaction) {
    if (reaction == null) return Colors.blue;
    final reactionModel = ReactionsService.instance.getReactionByName(reaction);
    return reactionModel?.colorValue ?? Colors.blue;
  }
}
// قائمة التفاعلات المتعددة (مثل فيسبوك)
// الآن تستخدم البيانات المحملة من الكاش
class _ReactionsMenu extends StatelessWidget {
  const _ReactionsMenu({required this.onReact});
  final Function(String) onReact;
  @override
  Widget build(BuildContext context) {
    // استخدام ReactionsMenu الجديد
    return ReactionsMenu(onReact: onReact);
  }
}
// لم نعد بحاجة لـ _ReactionButton لأنه موجود في ReactionsMenu
