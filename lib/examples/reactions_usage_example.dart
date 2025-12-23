/// Example: How to use the reactions system anywhere
/// 
/// This file is for demonstration only - can be deleted
library;

import 'package:flutter/material.dart';
import '../core/services/reactions_service.dart';
import '../features/comments/presentation/widgets/reactions_menu.dart';

class ReactionsUsageExample extends StatelessWidget {
  const ReactionsUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reactions Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Simple button with long press
            _ExampleButton1(),
            const SizedBox(height: 20),
            
            // Example 2: Show current reaction
            _ExampleButton2(),
            const SizedBox(height: 20),
            
            // Example 3: List all reactions
            _ExampleButton3(),
          ],
        ),
      ),
    );
  }
}

/// مثال 1: زر مع long press
class _ExampleButton1 extends StatelessWidget {
  void _showReactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionsMenu(
        onReact: (reactionName) {
          Navigator.pop(context);
          // Here: Send to server
          // await apiService.reactToPost(postId: 123, reaction: reactionName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
      },
      onLongPress: () => _showReactions(context),
      child: const Text('Long press to show reactions'),
    );
  }
}

/// مثال 2: عرض التفاعل الحالي
class _ExampleButton2 extends StatefulWidget {
  @override
  State<_ExampleButton2> createState() => _ExampleButton2State();
}

class _ExampleButton2State extends State<_ExampleButton2> {
  String? currentReaction;

  void _showReactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionsMenu(
        onReact: (reactionName) {
          Navigator.pop(context);
          setState(() {
            // Toggle: If it's the same reaction, remove it
            if (currentReaction == reactionName) {
              currentReaction = null;
            } else {
              currentReaction = reactionName;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reaction = currentReaction != null
        ? ReactionsService.instance.getReactionByName(currentReaction!)
        : null;

    return ElevatedButton(
      onPressed: () => _showReactions(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: reaction != null
            ? _parseColor(reaction.color)
            : null,
      ),
      child: Text(
        reaction != null ? reaction.title : 'Like',
        style: TextStyle(
          color: reaction != null ? Colors.white : null,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

/// مثال 3: عرض جميع التفاعلات المتاحة
class _ExampleButton3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final reactions = ReactionsService.instance.getReactions();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Available Reactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: reactions.map((r) {
                return ListTile(
                  title: Text(r.title),
                  subtitle: Text('${r.reaction} - ${r.color}'),
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(r.color),
                    child: Text(
                      r.order.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: const Text('Show All Reactions'),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

/// Notes:
/// 
/// 1. Usage in comments:
///    See: lib/features/comments/presentation/pages/comments_bottom_sheet.dart
///    Line ~871: _showReactionsMenu
/// 
/// 2. Usage in posts:
///    Same way - use ReactionsMenu with onReact callback
/// 
/// 3. Get a specific reaction:
///    final reaction = ReactionsService.instance.getReactionByName('love');
/// 
/// 4. Update reactions:
///    await ReactionsService.instance.loadReactions(forceRefresh: true);
