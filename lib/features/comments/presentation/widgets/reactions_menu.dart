import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/reaction_model.dart';
import '../../../../core/services/reactions_service.dart';
/// قائمة التفاعلات المتعددة (مثل فيسبوك)
/// تعرض التفاعلات المحملة من الكاش
class ReactionsMenu extends StatelessWidget {
  const ReactionsMenu({
    super.key,
    required this.onReact,
  });
  final Function(String reactionName) onReact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reactions = ReactionsService.instance.getReactions();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactions.map((reaction) {
            return _ReactionButton(
              reaction: reaction,
              onTap: () => onReact(reaction.reaction),
            );
          }).toList(),
        ),
      ),
    );
  }
}
/// زر تفاعل واحد
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.reaction,
    required this.onTap,
  });
  final ReactionModel reaction;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الصورة من السيرفر مع Cache
            CachedNetworkImage(
              imageUrl: reaction.imageUrl,
              width: 32,
              height: 32,
              placeholder: (context, url) => SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: reaction.colorValue,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.emoji_emotions,
                size: 32,
                color: reaction.colorValue,
              ),
            ),
            const SizedBox(height: 4),
            // العنوان
            Text(
              reaction.title,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
