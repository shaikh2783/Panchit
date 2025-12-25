import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:async';

class LiveChatWidget extends StatefulWidget {
  const LiveChatWidget({
    super.key,
    required this.channelName,
    this.isVisible = true,
    this.onToggleVisibility,
  });

  final String channelName;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  
  // قائمة الرسائل التجريبية - سيتم استبدالها بـ API لاحقاً
  final List<ChatMessage> _messages = [
    ChatMessage(
      username: 'أحمد محمد',
      message: 'مرحباً بكم في البث المباشر! 👋',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isVerified: false,
    ),
    ChatMessage(
      username: 'سارة علي',
      message: 'جودة الفيديو ممتازة! 🔥',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isVerified: true,
    ),
    ChatMessage(
      username: 'محمد خالد',
      message: 'شكراً لك على هذا المحتوى الرائع',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isVerified: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.isVisible) {
      _animationController.forward();
    }
    
    // محاكاة رسائل جديدة كل 10 ثوان للعرض التوضيحي
    _simulateNewMessages();
  }

  void _simulateNewMessages() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && widget.isVisible) {
        final demoMessages = [
          'رائع جداً! 🔥',
          'متابعينك معك دائماً ❤️',
          'جودة ممتازة',
          'شكراً لك 🙏',
          'أحبك في الله',
          'ما شاء الله عليك',
          'استمر 💪',
        ];
        
        final demoNames = [
          'فاطمة أحمد',
          'عبدالله محمد',
          'نور الدين',
          'ريم سالم',
          'خالد العلي',
          'مريم حسن',
        ];
        
        setState(() {
          _messages.add(ChatMessage(
            username: demoNames[DateTime.now().millisecond % demoNames.length],
            message: demoMessages[DateTime.now().millisecond % demoMessages.length],
            timestamp: DateTime.now(),
            isVerified: DateTime.now().millisecond % 3 == 0,
          ));
        });
        
        _scrollToBottom();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(LiveChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          username: 'أنت', // يجب تغييرها لاسم المستخدم الحقيقي
          message: message,
          timestamp: DateTime.now(),
          isVerified: false,
          isOwnMessage: true,
        ));
      });
      
      _messageController.clear();
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _animationController.value) * 300, 0),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              width: 280,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(theme),
                    
                    // Messages
                    Expanded(
                      child: _buildMessagesList(theme),
                    ),
                    
                    // Input
                    _buildMessageInput(theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.message_2,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'المحادثة المباشرة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_messages.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onToggleVisibility,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, theme);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: message.isOwnMessage 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // Username and time
          if (!message.isOwnMessage)
            Row(
              children: [
                Text(
                  message.username,
                  style: TextStyle(
                    color: message.isVerified ? Colors.blue : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message.isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Iconsax.verify,
                    color: Colors.blue,
                    size: 12,
                  ),
                ],
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 2),
          
          // Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isOwnMessage
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          
          // Time for own messages
          if (message.isOwnMessage) ...[
            const SizedBox(height: 2),
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.send_1,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes == 0) {
      return 'الآن';
    } else if (difference.inHours == 0) {
      return '${difference.inMinutes}د';
    } else {
      return '${difference.inHours}س';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;
  final bool isVerified;
  final bool isOwnMessage;

  ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
    this.isVerified = false,
    this.isOwnMessage = false,
  });
}