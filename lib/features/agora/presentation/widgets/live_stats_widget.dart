import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/live_comments_bloc.dart';
class LiveStatsWidget extends StatefulWidget {
  final String liveId;
  const LiveStatsWidget({
    Key? key,
    required this.liveId,
  }) : super(key: key);
  @override
  State<LiveStatsWidget> createState() => _LiveStatsWidgetState();
}
class _LiveStatsWidgetState extends State<LiveStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countAnimation;
  int _previousViewerCount = 0;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    _countAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.bounceOut,
    ));
    _pulseController.repeat(reverse: true);
  }
  @override
  void dispose() {
    _pulseController.dispose();
    _countController.dispose();
    super.dispose();
  }
  void _animateCountChange(int newCount) {
    if (newCount != _previousViewerCount) {
      _previousViewerCount = newCount;
      _countController.forward(from: 0);
    }
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
      builder: (context, state) {
        int viewerCount = 0;
        int commentsCount = 0;
        if (state is LiveCommentsLoaded) {
          viewerCount = state.metadata.liveCount ?? 0;
          commentsCount = state.comments.length;
          _animateCountChange(viewerCount);
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live indicator
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Viewer count
              AnimatedBuilder(
                animation: _countAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _countAnimation.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$viewerCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Comments count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$commentsCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}