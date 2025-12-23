import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class LiveReactionsWidget extends StatefulWidget {
  const LiveReactionsWidget({
    super.key,
    this.onReactionSent,
  });

  final Function(String reaction)? onReactionSent;

  @override
  State<LiveReactionsWidget> createState() => _LiveReactionsWidgetState();
}

class _LiveReactionsWidgetState extends State<LiveReactionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _panelAnimationController;
  late AnimationController _heartAnimationController;
  
  bool _isPanelVisible = false;
  final List<AnimatedReaction> _activeReactions = [];

  final List<ReactionType> _reactions = [
    ReactionType(emoji: '❤️', name: 'love', color: Colors.red),
    ReactionType(emoji: '😍', name: 'heart_eyes', color: Colors.pink),
    ReactionType(emoji: '👏', name: 'clap', color: Colors.amber),
    ReactionType(emoji: '🔥', name: 'fire', color: Colors.orange),
    ReactionType(emoji: '😂', name: 'laugh', color: Colors.yellow),
    ReactionType(emoji: '🤩', name: 'star_struck', color: Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // محاكاة تفاعلات عشوائية من المشاهدين الآخرين
    _startRandomReactions();
  }

  void _startRandomReactions() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addRandomReaction();
        _startRandomReactions();
      }
    });
  }

  void _addRandomReaction() {
    final random = math.Random();
    final reaction = _reactions[random.nextInt(_reactions.length)];
    
    setState(() {
      _activeReactions.add(
        AnimatedReaction(
          emoji: reaction.emoji,
          color: reaction.color,
          startPosition: Offset(
            random.nextDouble() * 200 + 50, // x: 50-250
            MediaQuery.of(context).size.height - 200,
          ),
        ),
      );
    });
    
    // إزالة التفاعل بعد انتهاء الحركة
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _activeReactions.isNotEmpty) {
        setState(() {
          _activeReactions.removeAt(0);
        });
      }
    });
  }

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
    
    if (_isPanelVisible) {
      _panelAnimationController.forward();
    } else {
      _panelAnimationController.reverse();
    }
  }

  void _sendReaction(ReactionType reaction) {
    // إرسال التفاعل
    widget.onReactionSent?.call(reaction.name);
    
    // إضافة تفاعل محلي فوري
    setState(() {
      _activeReactions.add(
        AnimatedReaction(
          emoji: reaction.emoji,
          color: reaction.color,
          startPosition: Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height - 150,
          ),
          isOwn: true,
        ),
      );
    });
    
    // تشغيل حركة القلب للتفاعلات المحبوبة
    if (reaction.name == 'love') {
      _heartAnimationController.forward().then((_) {
        _heartAnimationController.reset();
      });
    }
    
    // إخفاء اللوحة بعد الإرسال
    _togglePanel();
    
    // إزالة التفاعل بعد انتهاء الحركة
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _activeReactions.isNotEmpty) {
        setState(() {
          _activeReactions.removeWhere((r) => r.isOwn);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // التفاعلات العائمة
        ..._buildFloatingReactions(),
        
        // زر التفاعل
        Positioned(
          bottom: 120,
          right: 16,
          child: _buildReactionButton(),
        ),
        
        // لوحة التفاعلات
        if (_isPanelVisible)
          Positioned(
            bottom: 120,
            right: 70,
            child: _buildReactionsPanel(),
          ),
      ],
    );
  }

  List<Widget> _buildFloatingReactions() {
    return _activeReactions.map((reaction) {
      return _FloatingReaction(
        key: ValueKey(reaction.hashCode),
        reaction: reaction,
      );
    }).toList();
  }

  Widget _buildReactionButton() {
    return AnimatedBuilder(
      animation: _heartAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_heartAnimationController.value * 0.3),
          child: GestureDetector(
            onTap: _togglePanel,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isPanelVisible 
                    ? Colors.red.withOpacity(0.9)
                    : Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _isPanelVisible ? Iconsax.close_circle : Iconsax.heart,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionsPanel() {
    return AnimatedBuilder(
      animation: _panelAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _panelAnimationController.value,
          child: Opacity(
            opacity: _panelAnimationController.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _reactions.map((reaction) {
                  return GestureDetector(
                    onTap: () => _sendReaction(reaction),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: reaction.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: reaction.color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          reaction.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }
}

class _FloatingReaction extends StatefulWidget {
  const _FloatingReaction({
    super.key,
    required this.reaction,
  });

  final AnimatedReaction reaction;

  @override
  State<_FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<_FloatingReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _moveAnimation = Tween<double>(
      begin: 0.0,
      end: -300.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.reaction.startPosition.dx,
          top: widget.reaction.startPosition.dy + _moveAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.reaction.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.reaction.color.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.reaction.color.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.reaction.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ReactionType {
  final String emoji;
  final String name;
  final Color color;

  ReactionType({
    required this.emoji,
    required this.name,
    required this.color,
  });
}

class AnimatedReaction {
  final String emoji;
  final Color color;
  final Offset startPosition;
  final bool isOwn;

  AnimatedReaction({
    required this.emoji,
    required this.color,
    required this.startPosition,
    this.isOwn = false,
  });
}