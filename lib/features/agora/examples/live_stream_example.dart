import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/live_stream_providers.dart';
import '../presentation/widgets/live_chat_api_widget.dart';
import '../bloc/live_comments_bloc.dart';

/// مثال شامل لاستخدام نظام التعليقات المباشرة مع API
class LiveStreamExamplePage extends StatefulWidget {
  final String liveId;
  final String liveTitle;

  const LiveStreamExamplePage({
    Key? key,
    required this.liveId,
    required this.liveTitle,
  }) : super(key: key);

  @override
  State<LiveStreamExamplePage> createState() => _LiveStreamExamplePageState();
}

class _LiveStreamExamplePageState extends State<LiveStreamExamplePage>
    with LiveStreamBlocsMixin {
  bool _showChat = true;

  @override
  void initState() {
    super.initState();
    // Initialize live stream data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startLiveComments(context, widget.liveId);
      startLiveStats(context, widget.liveId);
    });
  }

  @override
  void dispose() {
    // Clean up when leaving
    stopLiveComments(context);
    stopLiveStats(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiveStreamBlocProvider(
      liveId: widget.liveId,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            widget.liveTitle,
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'مباشر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main video area (placeholder for now)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'منطقة الفيديو\n(سيتم دمجها مع Agora)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Stats overlay
            Positioned(
              top: 20,
              left: 20,
              child: _buildStatsOverlay(),
            ),

            // Chat toggle button
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showChat = !_showChat;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _showChat ? Icons.chat : Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Chat widget
            if (_showChat)
              Positioned(
                bottom: 20,
                right: 20,
                width: 300,
                child: LiveChatApiWidget(liveId: widget.liveId),
              ),

            // Bottom controls
            Positioned(
              bottom: 20,
              left: 20,
              right: _showChat ? 340 : 20,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return BlocBuilder<LiveStatsBloc, LiveStatsState>(
      builder: (context, state) {
        if (state is LiveStatsLoaded) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(state.stats.currentViewers)} مشاهد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(state.stats.totalComments)} تعليق',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(state.stats.totalReactions)} تفاعل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Quick reaction buttons
        _buildQuickReactionButton('👍', 'like'),
        _buildQuickReactionButton('❤️', 'love'),
        _buildQuickReactionButton('😂', 'haha'),
        _buildQuickReactionButton('😮', 'wow'),
        
        // More actions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  // Share functionality
                  _showShareDialog();
                },
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  // Settings or more options
                  _showOptionsDialog();
                },
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReactionButton(String emoji, String reactionType) {
    return GestureDetector(
      onTap: () {
        // Send quick reaction to the live stream
        _sendQuickReaction(reactionType);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  void _sendQuickReaction(String reactionType) {
    // You can implement quick reactions to the live stream here
    // For now, we'll show a simple feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال تفاعل: ${_getReactionIcon(reactionType)}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black87,
      ),
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

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'مشاركة البث',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'مشاركة هذا البث المباشر مع أصدقائك',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement share functionality
            },
            child: const Text('مشاركة'),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'خيارات البث',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text(
                'الإبلاغ عن البث',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text(
                'حظر المستخدم',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement block functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}ك';
    }
    return number.toString();
  }
}

/// Widget مبسط لعرض قائمة البثوث المباشرة
class LiveStreamListExample extends StatelessWidget {
  const LiveStreamListExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample live streams data
    final liveStreams = [
      {
        'id': 'live_1',
        'title': 'بث مباشر: تطوير التطبيقات',
        'broadcaster': 'أحمد محمد',
        'viewers': 1250,
      },
      {
        'id': 'live_2',
        'title': 'جلسة أسئلة وأجوبة',
        'broadcaster': 'سارة علي',
        'viewers': 850,
      },
      {
        'id': 'live_3',
        'title': 'ورشة عمل البرمجة',
        'broadcaster': 'محمد خالد',
        'viewers': 2100,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('البثوث المباشرة'),
      ),
      body: ListView.builder(
        itemCount: liveStreams.length,
        itemBuilder: (context, index) {
          final stream = liveStreams[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam, size: 30),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'مباشر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(stream['title'] as String),
              subtitle: Text('${stream['broadcaster']} • ${stream['viewers']} مشاهد'),
              trailing: const Icon(Icons.play_circle_filled, color: Colors.red),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveStreamExamplePage(
                      liveId: stream['id'] as String,
                      liveTitle: stream['title'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}