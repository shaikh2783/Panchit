import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/comment.dart';
import '../../application/comments_notifier.dart';
import '../../application/replies_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.isReply = false,
    this.onReplyTap,
  });
  final CommentModel comment;
  final bool isReply;
  final VoidCallback? onReplyTap;
  @override
  State<CommentCard> createState() => _CommentCardState();
}
class _CommentCardState extends State<CommentCard> {
  bool _isEditing = false;
  late TextEditingController _editController;
  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.textPlain);
  }
  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }
  String _formatTime(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      timeago.setLocaleMessages('en', timeago.EnMessages());
      return timeago.format(dateTime, locale: 'en');
    } catch (e) {
      return timeStr;
    }
  }
  Future<void> _handleReaction(String reaction) async {
    if (widget.isReply) {
      final repliesNotifier = context.read<RepliesNotifier>();
      await repliesNotifier.reactToReply(
        parentCommentId: widget.comment.nodeId,
        replyId: widget.comment.commentId,
        reaction: reaction,
      );
    } else {
      final commentsNotifier = context.read<CommentsNotifier>();
      await commentsNotifier.reactToComment(
        commentId: widget.comment.commentId,
        reaction: reaction,
      );
    }
  }
  Future<void> _handleEdit() async {
    final newText = _editController.text.trim();
    if (newText.isEmpty) return;
    bool success;
    if (widget.isReply) {
      final repliesNotifier = context.read<RepliesNotifier>();
      success = await repliesNotifier.editReply(
        parentCommentId: widget.comment.nodeId,
        replyId: widget.comment.commentId,
        newText: newText,
      );
    } else {
      final commentsNotifier = context.read<CommentsNotifier>();
      success = await commentsNotifier.editComment(
        commentId: widget.comment.commentId,
        newText: newText,
      );
    }
    if (success && mounted) {
      setState(() => _isEditing = false);
    }
  }
  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (widget.isReply) {
        final repliesNotifier = context.read<RepliesNotifier>();
        await repliesNotifier.deleteReply(
          parentCommentId: widget.comment.nodeId,
          replyId: widget.comment.commentId,
        );
      } else {
        final commentsNotifier = context.read<CommentsNotifier>();
        await commentsNotifier.deleteComment(widget.comment.commentId);
      }
    }
  }
  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a Reaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ReactionButton(
                  emoji: '👍',
                  label: 'Like',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('like');
                  },
                ),
                _ReactionButton(
                  emoji: '❤️',
                  label: 'Love',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('love');
                  },
                ),
                _ReactionButton(
                  emoji: '😂',
                  label: 'Haha',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('haha');
                  },
                ),
                _ReactionButton(
                  emoji: '🎉',
                  label: 'Celebrate',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('yay');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ReactionButton(
                  emoji: '😮',
                  label: 'Wow',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('wow');
                  },
                ),
                _ReactionButton(
                  emoji: '😢',
                  label: 'Sad',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('sad');
                  },
                ),
                _ReactionButton(
                  emoji: '😡',
                  label: 'Angry',
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction('angry');
                  },
                ),
                if (widget.comment.iReact)
                  _ReactionButton(
                    emoji: '❌',
                    label: 'إلغاء',
                    onTap: () {
                      Navigator.pop(context);
                      _handleReaction('remove');
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    return Container(
      margin: EdgeInsets.only(
        left: widget.isReply ? 48 : 8,
        right: 8,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(
                  mediaAsset(widget.comment.authorPicture).toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.authorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.comment.authorVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTime(widget.comment.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.comment.canEdit || widget.comment.canDelete)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      setState(() => _isEditing = true);
                    } else if (value == 'delete') {
                      _handleDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.comment.canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                    if (widget.comment.canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment text or edit field
          if (_isEditing) ...[
            TextField(
              controller: _editController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _editController.text = widget.comment.textPlain;
                    });
                  },
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleEdit,
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ] else ...[
            Text(
              widget.comment.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            if (widget.comment.image != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaAsset(widget.comment.image!).toString(),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          // Action buttons
          Row(
            children: [
              // Reaction button
              InkWell(
                onTap: _showReactionPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.comment.iReact
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: widget.comment.iReact
                            ? _getReactionColor(widget.comment.iReaction)
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      if (widget.comment.reactionsTotalCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          widget.comment.reactionsTotalCount.toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Reply button (only for top-level comments)
              if (!widget.isReply)
                InkWell(
                  onTap: widget.onReplyTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        if (widget.comment.repliesCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            widget.comment.repliesCount.toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Color _getReactionColor(String? reaction) {
    switch (reaction) {
      case 'like':
        return Colors.blue;
      case 'love':
        return Colors.red;
      case 'haha':
        return Colors.amber;
      case 'yay':
        return Colors.purple;
      case 'wow':
        return Colors.orange;
      case 'sad':
        return Colors.blueGrey;
      case 'angry':
        return Colors.red[900]!;
      default:
        return Colors.blue;
    }
  }
}
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
