import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/live_comments_bloc.dart';
import '../../data/models/live_stream_models.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget للتعليقات المباشرة مع API
class LiveChatApiWidget extends StatefulWidget {
  final String liveId;

  const LiveChatApiWidget({
    Key? key,
    required this.liveId,
  }) : super(key: key);

  @override
  State<LiveChatApiWidget> createState() => _LiveChatApiWidgetState();
}

class _LiveChatApiWidgetState extends State<LiveChatApiWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load initial comments and start polling
    context.read<LiveCommentsBloc>().add(LoadLiveComments(postId: widget.liveId));
    context.read<LiveCommentsBloc>().add(StartLiveCommentsPolling(postId: widget.liveId));
  }

  @override
  void dispose() {
    // Stop polling when widget is disposed
    context.read<LiveCommentsBloc>().add(StopLiveCommentsPolling());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<LiveCommentsBloc>().add(
        AddLiveComment(
          postId: widget.liveId,
          text: message,
        ),
      );
      _messageController.clear();
    }
  }

  void _reactToComment(String commentId, String reactionType) {
    context.read<LiveCommentsBloc>().add(
      ReactToLiveComment(
        commentId: commentId,
        reactionType: reactionType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'التعليقات المباشرة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
                  builder: (context, state) {
                    if (state is LiveCommentsLoaded && state.isPolling) {
                      return const Icon(
                        Icons.wifi,
                        color: Colors.green,
                        size: 16,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
              builder: (context, state) {
                if (state is LiveCommentsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                } else if (state is LiveCommentsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<LiveCommentsBloc>().add(
                              LoadLiveComments(postId: widget.liveId),
                            );
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                } else if (state is LiveCommentsLoaded || state is LiveCommentAdding) {
                  List<LiveCommentModel> comments = [];
                  
                  if (state is LiveCommentsLoaded) {
                    comments = state.comments;
                  } else if (state is LiveCommentAdding) {
                    comments = state.currentComments;
                  }

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد تعليقات بعد\nكن أول من يعلق!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Scroll to bottom when new comments are loaded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    key: ValueKey('api_comments_${comments.length}'),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _buildCommentItem(comment);
                    },
                  );
                }
                
                return const Center(
                  child: Text(
                    'ابدأ محادثة!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
                  builder: (context, state) {
                    final isLoading = state is LiveCommentAdding;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: isLoading ? null : _sendMessage,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(LiveCommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? CachedNetworkImageProvider(comment.userAvatar)
                : null,
            backgroundColor: Colors.grey[600],
            child: comment.userAvatar.isEmpty
                ? Text(
                    comment.userName.isNotEmpty 
                        ? comment.userName[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Name
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTime(comment.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Comment Text
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                
                // Image if exists
                if (comment.imageUrl != null && 
                    comment.imageUrl!.isNotEmpty && 
                    comment.imageUrl!.startsWith('http')) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      comment.imageUrl!,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                // Reactions
                if (comment.reactions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReactionsRow(comment),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(LiveCommentModel comment) {
    final reactions = comment.reactions.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        ...reactions.take(3).map((entry) {
          final icon = _getReactionIcon(entry.key);
          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => _reactToComment(comment.commentId, entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        
        // Add reaction button
        GestureDetector(
          onTap: () => _showReactionPicker(comment.commentId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getReactionIcon(String reactionType) {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }

  void _showReactionPicker(String commentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر تفاعلك',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionOption('like', '👍', commentId),
                _buildReactionOption('love', '❤️', commentId),
                _buildReactionOption('haha', '😂', commentId),
                _buildReactionOption('wow', '😮', commentId),
                _buildReactionOption('sad', '😢', commentId),
                _buildReactionOption('angry', '😡', commentId),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionOption(String type, String icon, String commentId) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _reactToComment(commentId, type);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else {
      return '${difference.inDays}ي';
    }
  }
}