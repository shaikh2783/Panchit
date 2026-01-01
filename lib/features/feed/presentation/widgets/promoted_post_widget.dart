import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/services/promoted_posts_service.dart';
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';

/// Widget ثابت يعرض المنشور المدفوع في أعلى الصفحة الرئيسية
class PromotedPostWidget extends StatefulWidget {
  final VoidCallback? onRefresh;
  final void Function(VoidCallback)? onRefreshCallback;

  const PromotedPostWidget({
    super.key,
    this.onRefresh,
    this.onRefreshCallback,
  });

  @override
  State<PromotedPostWidget> createState() => _PromotedPostWidgetState();
}

class _PromotedPostWidgetState extends State<PromotedPostWidget> {
  late PromotedPostsService _promotedPostsService;
  late PostManagementApiService _postManagementService;
  Post? _promotedPost;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _promotedPostsService = PromotedPostsService(context.read<ApiClient>());
    _postManagementService = PostManagementApiService(context.read<ApiClient>());
    _loadPromotedPost();
    
    // تمرير دالة التحديث إلى الصفحة الأب
    widget.onRefreshCallback?.call(refreshPromotedPost);
  }

  /// تحميل منشور مدفوع عشوائي
  Future<void> _loadPromotedPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {

      final promotedPost = await _promotedPostsService.getRandomPromotedPost();
      
      if (mounted) {
        setState(() {
          _promotedPost = promotedPost;
          _isLoading = false;
        });
        
        if (promotedPost != null) {

          // مسح ذاكرة الصور المؤقتة عند تحميل منشور جديد
          PaintingBinding.instance.imageCache.clear();
        } else {

        }
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// تحديث المنشور المدفوع (يستدعى عند Pull to Refresh)
  Future<void> refreshPromotedPost() async {

    // مسح ذاكرة الصور المؤقتة لضمان تحديث الصور
    PaintingBinding.instance.imageCache.clear();
    
    await _loadPromotedPost();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان يتم التحميل للمرة الأولى
    if (_isLoading && _promotedPost == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        height: 200,
        child: Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading promoted content...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // إذا حدث خطأ ولا يوجد محتوى مسبق
    if (_error != null && _promotedPost == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load promoted content',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadPromotedPost,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // إذا لم يوجد منشور مدفوع متاح
    if (_promotedPost == null) {
      return const SizedBox.shrink();
    }

    // عرض المنشور المدفوع
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.05),
            Colors.orange.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // المنشور الأصلي مع key ثابت لتجنب إعادة بناء غير ضرورية
          PostCard(
            key: ValueKey('promoted-post-${_promotedPost!.id}'),
            post: _promotedPost!,
            onReactionChanged: (postId, reaction) async {

              // تحديث حالة المنشور المدفوع محلياً (Optimistic Update)
              if (_promotedPost != null) {
                final updatedPost = _promotedPost!.copyWithReaction(
                  reaction == 'remove' ? null : reaction
                );
                
                // تحديث فقط إذا تغير شيء فعلياً
                if (updatedPost.myReaction != _promotedPost!.myReaction) {
                  setState(() {
                    _promotedPost = updatedPost;
                  });
                }
                
                // إرسال التفاعل للخادم
                try {
                  final postIdInt = int.parse(postId);
                  final isReacting = reaction != 'remove';
                  
                  await _postManagementService.reactToPost(
                    postId: postIdInt,
                    reaction: reaction == 'remove' ? 'like' : reaction, // استخدام like كقيمة افتراضية عند الإزالة
                    isReacting: isReacting,
                  );

                } catch (e) {

                  // في حالة الخطأ، نعيد الحالة السابقة (Revert)
                  if (_promotedPost != null) {
                    final originalReaction = _promotedPost!.myReaction;
                    setState(() {
                      _promotedPost = _promotedPost!.copyWithReaction(originalReaction);
                    });
                  }
                }
              }
            },
            onPostUpdated: (updatedPost) {
              setState(() {
                _promotedPost = updatedPost;
              });
            },
          ),
          // شارة "Promoted" وزر التحديث في الزاوية اليمنى العلوية
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تحديث المنشور المدفوع
                Tooltip(
                  message: 'تحديث المنشور المدفوع',
                  child: GestureDetector(
                    onTap: _isLoading ? null : refreshPromotedPost,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // شارة "Promoted"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Promoted',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}