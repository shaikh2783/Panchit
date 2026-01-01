import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// حقل إدخال الرسائل
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback? onImageTap;
  final VoidCallback? onVoiceTap;
  final bool isRecording;
  final int recordingDuration;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.onImageTap,
    this.onVoiceTap,
    this.isRecording = false,
    this.recordingDuration = 0,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;

    // Default to end of text if selection is invalid (e.g., field unfocused).
    final rawStart = selection.isValid ? selection.start : text.length;
    final rawEnd = selection.isValid ? selection.end : text.length;
    final start = rawStart.clamp(0, text.length).toInt();
    final end = rawEnd.clamp(0, text.length).toInt();

    final newText = text.replaceRange(start, end < start ? start : end, emoji.emoji);

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + emoji.emoji.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    // إذا كان التسجيل قيد التشغيل، عرض واجهة التسجيل
    if (widget.isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border(top: BorderSide(color: Colors.red.withOpacity(0.3))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // أيقونة الميكروفون النابضة
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 20),
              ),
              
              const SizedBox(width: 16),
              
              // النص ومدة التسجيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'recording'.tr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.recordingDuration),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر إيقاف وإرسال
              ElevatedButton.icon(
                onPressed: widget.onVoiceTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.send, size: 18),
                label: Text('send'.tr),
              ),
            ],
          ),
        ),
      );
    }
    
    // الواجهة العادية
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
            // زر الصور
            IconButton(
              icon: const Icon(Icons.image),
              color: isDark ? Colors.greenAccent : Colors.green,
              onPressed: widget.onImageTap,
            ),
            
            // حقل الإدخال
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'type_message'.tr,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                      ),
                    ),
                    // زر الرموز التعبيرية
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                      ),
                      color: _showEmojiPicker
                          ? Theme.of(context).primaryColor
                          : (isDark ? Colors.white70 : Colors.grey[600]),
                      onPressed: _toggleEmojiPicker,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // زر الإرسال أو التسجيل الصوتي
            _hasText
                ? CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _handleSend,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: widget.onVoiceTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  columns: 7,
                  emojiSizeMax: 28,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  gridPadding: EdgeInsets.zero,
                  buttonMode: ButtonMode.MATERIAL,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  iconColor: isDark ? Colors.white70 : Colors.grey,
                  iconColorSelected: Theme.of(context).primaryColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  categoryIcons: const CategoryIcons(),
                  initCategory: Category.RECENT,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  buttonColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!,
                  buttonIconColor: isDark ? Colors.white70 : Colors.grey,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  buttonIconColor: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
