import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/blog_post.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArticleCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Get.isDarkMode;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UI.rLg),
      child: Container(
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(UI.rLg),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with gradient overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: post.cover.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withOpacity(0.2),
                                scheme.secondary.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Iconsax.document_text, size: 48, color: scheme.primary.withOpacity(0.3)),
                          ),
                        )
                      : Image.network(
                          post.cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [scheme.primary.withOpacity(0.2), scheme.secondary.withOpacity(0.2)],
                              ),
                            ),
                          ),
                        ),
                ),
                // Bottom gradient for readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: UI.md, vertical: UI.xs + 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.category_2_copy, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          post.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(UI.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: UI.md),
                  
                  // Snippet
                  Text(
                    post.textSnippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UI.subtleText(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: UI.lg),
                  
                  // Author & Date row
                  Row(
                    children: [
                      // Author avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [scheme.primary.withOpacity(0.2), scheme.secondary.withOpacity(0.2)],
                          ),
                          border: Border.all(color: scheme.primary.withOpacity(0.3), width: 1.5),
                        ),
                        child: post.author.userPicture.isEmpty
                            ? Icon(Iconsax.user, size: 16, color: scheme.primary)
                            : ClipOval(
                                child: Image.network(
                                  post.author.userPicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Iconsax.user, size: 16, color: scheme.primary),
                                ),
                              ),
                      ),
                      const SizedBox(width: UI.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Iconsax.clock_copy, size: 12, color: UI.subtleText(context)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    post.createdTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: UI.subtleText(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Read more icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.arrow_right_3_copy,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags if available
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: UI.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: post.tags.take(3).map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: UI.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.hashtag_copy, size: 10, color: scheme.primary),
                              const SizedBox(width: 2),
                              Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
