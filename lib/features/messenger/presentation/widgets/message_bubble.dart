import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/message_model.dart';

/// فقاعة الرسالة
class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool showTimestamp;
  final VoidCallback? onDelete;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showTimestamp = false,
    this.onDelete,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // الاستماع لتغييرات حالة المشغل
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.message.voiceNote == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _audioPlayer.play(UrlSource(widget.message.voiceNote!));
        setState(() => _isPlaying = true);
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'failed_to_play_audio'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.message.isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (widget.showTimestamp) _buildTimestamp(context),
        GestureDetector(
          onLongPress: _handleLongPress,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.message.isMe ? 64 : 0,
              right: widget.message.isMe ? 0 : 64,
              bottom: 4,
            ),
            child: _buildMessageContent(context),
          ),
        ),
      ],
    );
  }

  void _handleLongPress() {
    if (widget.onDelete == null) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete'.tr),
        content: Text('are_you_sure'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              widget.onDelete?.call();
            },
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeago.format(
              widget.message.sentAt.toLocal(),
              locale: (Get.locale?.languageCode ?? 'en').startsWith('ar')
                  ? 'ar'
                  : 'en',
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.messageType) {
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.voice:
        return _buildVoiceMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.message.isMe
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: widget.message.isMe
              ? const Radius.circular(20)
              : const Radius.circular(4),
          bottomRight: widget.message.isMe
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.message.messageText.isNotEmpty
                ? widget.message.messageText
                : '(${'empty_message'.tr})',
            style: TextStyle(
              color: widget.message.isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(widget.message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: widget.message.isMe
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
              if (widget.message.isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.message.isSeen ? Icons.done_all : Icons.done,
                  size: 14,
                  color: widget.message.isSeen
                      ? Colors.blue[300]
                      : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    final imageUrl = widget.message.image;


    return Container(
      constraints: const BoxConstraints(maxWidth: 250, minHeight: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 250,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'failed_to_load_image'.tr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          imageUrl,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'no_image_url'.tr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 4,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.message.sentAt),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    if (widget.message.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message.isSeen ? Icons.done_all : Icons.done,
                        size: 14,
                        color: widget.message.isSeen
                            ? Colors.blue[300]
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(BuildContext context) {
    final voiceUrl = widget.message.voiceNote;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 200),
      decoration: BoxDecoration(
        color: widget.message.isMe
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.message.isMe
                        ? Colors.white24
                        : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                    color: widget.message.isMe ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // شريط التقدم
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: widget.message.isMe
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        inactiveTrackColor: widget.message.isMe
                            ? Colors.white24
                            : Colors.grey[400],
                        thumbColor: widget.message.isMe
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds.toDouble()
                            : 0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: (value) async {
                          await _audioPlayer.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                      ),
                    ),
                    // الوقت
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.message.isMe
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.message.isMe
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // أيقونات الحالة
              Column(
                children: [
                  if (widget.message.isMe)
                    Icon(
                      widget.message.isSeen ? Icons.done_all : Icons.done,
                      size: 14,
                      color: widget.message.isSeen
                          ? Colors.blue[300]
                          : Colors.white70,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.message.thumbnailUrl != null)
              Image.network(
                widget.message.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.video_library, color: Colors.grey[600]),
                  );
                },
              )
            else
              Container(
                color: Colors.grey[300],
                child: Icon(Icons.video_library, color: Colors.grey[600]),
              ),
            const Icon(Icons.play_circle_fill, size: 50, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.message.isMe
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                color: widget.message.isMe ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'file.pdf',
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(widget.message.sentAt),
            style: TextStyle(
              fontSize: 11,
              color: widget.message.isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  var hour = dateTime.hour % 12;
  if (hour == 0) {
    hour = 12;
  }
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minutes $period';
}

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
