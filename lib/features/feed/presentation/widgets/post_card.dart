import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
// <-- 💡 1. إضافة الحزمة الاحترافية
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/widgets/html_text_widget.dart';
import 'package:snginepro/core/utils/time_ago.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/models/post_link.dart';
import 'package:snginepro/features/feed/data/models/post_event.dart';
import 'package:snginepro/features/feed/data/models/post_funding.dart';
import 'package:snginepro/features/feed/data/models/post_offer.dart';
import 'package:snginepro/features/feed/data/models/post_colored_pattern.dart';
import 'package:snginepro/features/feed/data/models/post_live.dart';
import 'package:snginepro/features/feed/data/services/adult_content_service.dart'; // 🆕 خدمة محتوى البالغين
import 'package:snginepro/features/feed/presentation/widgets/course_card.dart';
import 'package:snginepro/features/events/presentation/pages/event_detail_page.dart';
import 'package:snginepro/features/funding/domain/funding_repository.dart';
import 'package:snginepro/features/offers/presentation/pages/offer_detail_page.dart';
import 'package:snginepro/features/funding/presentation/pages/funding_detail_page.dart';
import 'package:snginepro/features/funding/presentation/pages/funding_donate_page.dart';
import '../../../agora/presentation/pages/live_stream_viewer_page.dart';
import 'package:snginepro/features/feed/presentation/widgets/adaptive_video_player.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_audio_widget.dart';
import 'package:snginepro/core/theme/widgets/elevated_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snginepro/features/comments/presentation/pages/comments_bottom_sheet.dart';
import 'package:snginepro/core/services/reactions_service.dart';
import 'package:snginepro/core/models/reaction_model.dart';
import 'package:snginepro/features/feed/presentation/widgets/reaction_users_bottom_sheet.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../pages/presentation/pages/page_profile_page.dart';
import '../../../pages/data/models/page.dart' as page_model;
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_menu_bottom_sheet.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/feed/presentation/pages/edit_post_page.dart';
import 'package:snginepro/features/ads/data/services/ads_tracking_service.dart';
import 'package:snginepro/features/boost/domain/boost_repository.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_packages_page.dart';
import 'package:snginepro/features/blog/presentation/pages/blog_post_page.dart';
import 'package:snginepro/features/feed/presentation/widgets/share_post_dialog.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_reviews_bottom_sheet.dart';

/// Reusable Post Card widget that can be used in any feed (posts or ads)
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onReactionChanged,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  final Post post;
  final Function(String postId, String reaction)? onReactionChanged;
  final Function(Post updatedPost)? onPostUpdated;
  final Function(String postId)? onPostDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with AutomaticKeepAliveClientMixin {
  late PostManagementApiService _postService;
  late AdsTrackingService _adsTrackingService;
  late AdultContentService _adultContentService; // 🆕 خدمة محتوى البالغين
  late Post _currentPost;
  bool _adViewTracked = false; // لتتبع المشاهدة مرة واحدة فقط
  bool _isBoostLoading = false;
  bool _isBoosted = false;

  @override
  bool get wantKeepAlive => true; // الحفاظ على حالة الـ widget

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _isBoosted = _currentPost.isPromoted;

    // Initialize services
    final apiClient = context.read<ApiClient>();
    _postService = PostManagementApiService(apiClient);
    _adultContentService = AdultContentService(apiClient); // 🆕 تهيئة الخدمة

    // Track ad view if it's a view-based ad
    if (_currentPost.isAd &&
        _currentPost.campaignBidding == 'view' &&
        _currentPost.campaignId != null &&
        !_adViewTracked) {
      _adViewTracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _trackAdView();
      });
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      final newPost = widget.post;
      final isDifferentPost = newPost.id != oldWidget.post.id;
      final shouldTrackAdView =
          isDifferentPost &&
          newPost.isAd &&
          newPost.campaignBidding == 'view' &&
          newPost.campaignId != null;

      setState(() {
        _currentPost = newPost;
        if (isDifferentPost) {
          _adViewTracked = false;
        }
      });

      if (shouldTrackAdView && !_adViewTracked) {
        _adViewTracked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _trackAdView();
          }
        });
      }
    }
  }

  // Track ad view
  Future<void> _trackAdView() async {
    if (_currentPost.campaignId == null) return;

    final apiClient = context.read<ApiClient>();
    _adsTrackingService = AdsTrackingService(apiClient);

    await _adsTrackingService.trackAdView(_currentPost.campaignId!);
  }

  // Track ad click
  Future<void> _trackAdClick() async {
    if (_currentPost.campaignId == null) return;

    final apiClient = context.read<ApiClient>();
    _adsTrackingService = AdsTrackingService(apiClient);

    await _adsTrackingService.trackAdClick(_currentPost.campaignId!);
  }

  void _onAuthorTap(BuildContext context) {
    // إذا كان المنشور من صفحة، افتح صفحة الـ Page
    if (_currentPost.isPagePost) {
      final pageModel = page_model.PageModel(
        id: int.tryParse(_currentPost.pageId!) ?? 0,
        name: _currentPost.pageName ?? _currentPost.pageTitle ?? '',
        title: _currentPost.pageTitle ?? _currentPost.pageName ?? '',
        description: '',
        picture: _currentPost.authorAvatarUrl ?? '',
        cover: '',
        category: '0',
        likes: 0,
        verified: false,
        boosted: false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PageProfilePage(page: pageModel),
        ),
      );
      return;
    }

    // إذا كان من مستخدم عادي، افتح الملف الشخصي
    if (_currentPost.authorId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfilePage(userId: int.tryParse(_currentPost.authorId!)),
        ),
      );
    } else if (_currentPost.authorUsername != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfilePage(username: _currentPost.authorUsername),
        ),
      );
    }
  }

  // Groups module removed; show info instead of navigation
  Future<void> _onGroupTap(BuildContext context) async {
    if (!_currentPost.isGroupPost || _currentPost.groupId == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('groups_no_longer_available'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تحقق من كون المستخدم الحالي هو مالك المنشور
  bool _isOwner(Post post) {
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final currentUser = auth.currentUser;
      if (currentUser == null) return false;

      String? currentUserId;
      if (currentUser['user_id'] != null) {
        currentUserId = currentUser['user_id'].toString();
      } else if (currentUser['id'] != null) {
        currentUserId = currentUser['id'].toString();
      } else if (currentUser['userID'] != null) {
        currentUserId = currentUser['userID'].toString();
      }

      if (currentUserId == null || currentUserId.isEmpty) return false;

      // If post is authored by a user -> compare authorId
      if (post.authorType == 'user') {
        return post.authorId != null && post.authorId == currentUserId;
      }

      // If post is from a page try matching pageId or authorId as a fallback
      if (post.isPagePost) {
        if (post.pageId != null && post.pageId == currentUserId) return true;
        if (post.authorId != null && post.authorId == currentUserId)
          return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// عرض قائمة خيارات المنشور
  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          PostMenuBottomSheet(post: _currentPost, onAction: _handlePostAction),
    );
  }

  /// عرض Reviews المنشور
  void _showReviewsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostReviewsBottomSheet(
        post: _currentPost,
        onCountChanged: (newCount) {
          setState(() {
            _currentPost = _currentPost.copyWith(reviewsCount: newCount);
          });
          widget.onPostUpdated?.call(_currentPost);
        },
      ),
    );
  }

  /// عرض Tip للمنشور
  void _showTipBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // عنوان
            Row(
              children: [
                Icon(Iconsax.dollar_circle, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Send a Tip',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // معلومات المؤلف
            Row(
              children: [
                _Avatar(
                  url: _currentPost.authorAvatarUrl != null
                      ? context
                            .read<AppConfig>()
                            .mediaAsset(_currentPost.authorAvatarUrl!)
                            .toString()
                      : null,
                  radius: 20,
                  showOnlineIndicator: _currentPost.authorType == 'user',
                  isOnline: _currentPost.authorIsOnline,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send a tip to ${_currentPost.authorName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Show your appreciation for this content',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // محتوى Tip (مؤقت)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.dollar_circle, size: 64, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      'Tip feature coming soon!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re working on implementing the tipping system to support content creators.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء أيقونات التفاعلات المفصلة
  List<Widget> _buildReactionIcons() {
    final icons = <Widget>[];
    final sortedReactions = _currentPost.reactionBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // ترتيب حسب العدد

    // عرض أهم 3 تفاعلات فقط
    for (int i = 0; i < sortedReactions.length && i < 3; i++) {
      final entry = sortedReactions[i];
      if (entry.value > 0) {
        icons.add(_ReactionIcon(type: entry.key, size: 18));
        if (i < sortedReactions.length - 1 && i < 2) {
          icons.add(const SizedBox(width: 2));
        }
      }
    }

    return icons;
  }

  /// معالجة تعليم المنشور كـ للبالغين
  Future<void> _handleAdultContentAction(PostAction action) async {
    final isMarkingAsAdult = action == PostAction.markAsAdult;

    // تأكيد من المستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isMarkingAsAdult
              ? 'adult_confirm_mark_title'.tr
              : 'adult_confirm_remove_title'.tr,
        ),
        content: Text(
          isMarkingAsAdult
              ? 'This will:\n'
                    '• Add 18+ label to your post\n'
                    '• Apply blur to all photos\n'
                    '• Require age verification to view'
              : 'This will:\n'
                    '• Remove 18+ label\n'
                    '• Remove blur from photos\n'
                    '• Make content visible to everyone',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isMarkingAsAdult ? Colors.orange : Colors.blue,
            ),
            child: Text(isMarkingAsAdult ? 'adult_confirm_action_mark'.tr : 'adult_confirm_action_remove'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // إظهار مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(
                  isMarkingAsAdult
                      ? 'Marking as adult content...'
                      : 'Removing 18+ label...',
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // استدعاء API
      final result = await _adultContentService.markPostAsAdult(
        postId: _currentPost.id,
        adult: isMarkingAsAdult,
      );

      if (result['status'] == 'success') {
        // تحديث الحالة المحلية
        setState(() {
          // سنحتاج إلى تحديث Post model ليشمل تحديث forAdult و blur للصور
          // في الوقت الحالي، سنقوم بإعادة تحميل المنشور
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isMarkingAsAdult
                          ? '✅ Post marked as 18+ and photos blurred'
                          : '✅ 18+ label removed',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // إعادة تحميل المنشور للحصول على التحديثات
          // أو يمكننا تحديثه محلياً إذا أضفنا copyWith method
          widget.onPostUpdated?.call(_currentPost);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text('${'error'.tr}: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// التعامل مع إجراءات المنشور
  Future<void> _handlePostAction(PostAction action) async {

    // معالجة خاصة لتعديل المنشور
    if (action == PostAction.editPost) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPostPage(
            post: _currentPost,
            onPostUpdated: (updatedPost) {
              setState(() {
                _currentPost = updatedPost;
              });
              widget.onPostUpdated?.call(updatedPost);

              // تحديث PostsBloc للتأكد من تحديث جميع الواجهات
              if (mounted) {
                context.read<PostsBloc>().add(UpdatePostEvent(updatedPost));
              }
            },
          ),
        ),
      );
      return;
    }

    // معالجة خاصة لتعليم المنشور كـ للبالغين
    if (action == PostAction.markAsAdult ||
        action == PostAction.unmarkAsAdult) {
      await _handleAdultContentAction(action);
      return;
    }

    // تحديث فوري للواجهة (Optimistic Update)
    final oldPost = _currentPost;
    final updatedPost = _updatePostState(_currentPost, action);

    setState(() {
      _currentPost = updatedPost;
    });

    try {
      final result = await _postService.managePost(
        postId: _currentPost.id,
        action: action,
      );

      if (result['status'] == 'success' && result['data']?['success'] == true) {

        // إشعار الكاتب الرئيسي بالتحديث
        widget.onPostUpdated?.call(_currentPost);

        // تحديث PostsBloc للتأكد من تحديث جميع الواجهات
        if (mounted) {
          context.read<PostsBloc>().add(UpdatePostEvent(_currentPost));
        }

        // في حالة الحذف، إشعار الكاتب الرئيسي وحذف من PostsBloc
        if (action == PostAction.deletePost) {
          widget.onPostDeleted?.call(_currentPost.id.toString());
          if (mounted) {
            context.read<PostsBloc>().add(DeletePostEvent(_currentPost.id));
            // لا نعمل pop هنا لأن القائمة قد تكون مغلقة بالفعل
            // أو قد نكون في صفحة Reels حيث لا يوجد dialog/bottomsheet مفتوح
          }
        }

        // عرض رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessage(action)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // إذا فشل API، أعد الحالة القديمة
        setState(() {
          _currentPost = oldPost;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'operation_failed'.tr}: ${action.value}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // إذا حدث خطأ، أعد الحالة القديمة
      setState(() {
        _currentPost = oldPost;
      });

      // عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// تحديث حالة المنشور بعد الإجراء
  Post _updatePostState(Post currentPost, PostAction action) {
    switch (action) {
      case PostAction.savePost:
        return currentPost.copyWith(isSaved: true);
      case PostAction.unsavePost:
        return currentPost.copyWith(isSaved: false);
      case PostAction.pinPost:
        return currentPost.copyWith(isPinned: true);
      case PostAction.unpinPost:
        return currentPost.copyWith(isPinned: false);
      case PostAction.hidePost:
        return currentPost.copyWith(isHidden: true);
      case PostAction.unhidePost:
        return currentPost.copyWith(isHidden: false);
      case PostAction.disableComments:
        return currentPost.copyWith(commentsDisabled: true);
      case PostAction.enableComments:
        return currentPost.copyWith(commentsDisabled: false);
      default:
        return currentPost;
    }
  }

  /// رسالة النجاح بناءً على الإجراء
  String _getSuccessMessage(PostAction action) {
    switch (action) {
      case PostAction.savePost:
        return 'post_saved_successfully'.tr;
      case PostAction.unsavePost:
        return 'post_removed_from_saved'.tr;
      case PostAction.pinPost:
        return 'post_pinned_to_profile'.tr;
      case PostAction.unpinPost:
        return 'post_unpinned_from_profile'.tr;
      case PostAction.hidePost:
        return 'post_hidden_from_timeline'.tr;
      case PostAction.unhidePost:
        return 'post_unhidden_on_timeline'.tr;
      case PostAction.deletePost:
        return 'post_deleted_successfully'.tr;
      case PostAction.editPost:
        return 'post_updated_successfully'.tr;
      case PostAction.disableComments:
        return 'comments_disabled'.tr;
      case PostAction.enableComments:
        return 'comments_enabled'.tr;
      default:
        return 'action_completed_successfully'.tr;
    }
  }
  // --- نهاية التحسين ---

  String _getEventActionText(Post post) {
    if (post.postType == 'event') {
      return 'event_action_created'.tr;
    } else if (post.postType == 'event_cover') {
      return 'event_action_updated_cover'.tr;
    } else if (post.inEvent && post.event != null) {
      // منشور عادي في الحدث
      return 'event_action_posted_in'.trParams({
        'event': post.event!.eventTitle,
      });
    }
    return '';
  }

  String _getLiveActionText(Post post) {
    if (post.postType == 'live') {
      if (post.isActiveLive) {
        return 'live_action_is_live'.tr;
      } else {
        return 'live_action_was_live'.tr;
      }
    }
    return '';
  }

  /// تحديد الأيقونة المناسبة للشعور بناءً على نوع الـ action
  IconData _getFeelingIcon(String feelingAction) {
    switch (feelingAction.toLowerCase()) {
      case 'feeling':
        return Iconsax.happyemoji;
      case 'listening to':
        return Iconsax.headphone;
      case 'watching':
        return Iconsax.eye;
      case 'playing':
        return Iconsax.game;
      case 'eating':
        return Iconsax.cake;
      case 'drinking':
        return Iconsax.coffee;
      case 'traveling to':
        return Iconsax.airplane;
      case 'reading':
        return Iconsax.book;
      case 'attending':
        return Iconsax.calendar;
      case 'celebrating':
        return Iconsax.gift;
      case 'looking for':
        return Iconsax.search_normal;
      default:
        return Iconsax.happyemoji;
    }
  }

  // 📢 Handle Ad Click - Navigate based on ad type
  Future<void> _handleAdClick(BuildContext context) async {
    // Track click if it's a click-based ad
    if (_currentPost.campaignBidding == 'click' &&
        _currentPost.campaignId != null) {
      await _trackAdClick();
    }

    final adsType = _currentPost.adsType;


    if (adsType == 'page' && _currentPost.adPageId != null) {
      // Navigate to page
      final pageModel = page_model.PageModel(
        id: _currentPost.adPageId!,
        name: _currentPost.targetName ?? '',
        title: _currentPost.campaignTitle ?? _currentPost.targetName ?? '',
        description: _currentPost.campaignDescription ?? '',
        picture: _currentPost.adsImage ?? '',
        cover: '',
        category: '0',
        likes: 0,
        verified: false,
        boosted: false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PageProfilePage(page: pageModel),
        ),
      );
    } else if (adsType == 'group' && _currentPost.adGroupId != null) {
      // Navigate to group
    } else if (adsType == 'event' && _currentPost.adEventId != null) {
      // Navigate to event
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EventDetailPage(eventId: _currentPost.adEventId!),
        ),
      );
    } else if (adsType == 'url' &&
        _currentPost.campaignUrl != null &&
        _currentPost.campaignUrl!.isNotEmpty) {
      final raw = _currentPost.campaignUrl!.trim();
      await _openAdUrl(raw);
    }
  }

  Future<void> _openAdUrl(String rawUrl) async {
    try {
      // Ensure scheme exists to avoid launch failures
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        Get.snackbar('error'.tr, 'invalid_url'.tr);
        return;
      }

      final normalized = uri.hasScheme ? uri : Uri.parse('https://$rawUrl');

      if (!await launchUrl(normalized, mode: LaunchMode.externalApplication)) {
        Get.snackbar('error'.tr, 'could_not_open_url'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr,
          'could_not_open_url_with_error'.trParams({'error': e.toString()}));
    }
  }

  // 📢 Build Ad Card - Professional & Unique Design
  Widget _buildAdCard(
    BuildContext context,
    ThemeData theme,
    Function mediaAsset,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: ValueKey('ad_card_${_currentPost.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface,
                ]
              : [Colors.white, theme.colorScheme.surfaceContainerLowest],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ad Badge with Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.tertiary.withOpacity(0.15),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.star,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sponsored',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ),
            ),

            // Ad Image with Overlay
            if (_currentPost.adsImage != null &&
                _currentPost.adsImage!.isNotEmpty)
              GestureDetector(
                onTap: () => _handleAdClick(context),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _currentPost.adsImage!,
                      fit: BoxFit.cover,
                      height: 280,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surfaceContainerHighest,
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surfaceContainerHighest,
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Iconsax.gallery,
                            size: 56,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    // Gradient Overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Ad Type Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAdTypeIcon(),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getAdTypeLabel(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Ad Content with Modern Layout
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Info (Page/Group name and picture)
                  if (_currentPost.targetName != null &&
                      _currentPost.targetName!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Target Picture
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  _currentPost.targetPicture != null &&
                                      _currentPost.targetPicture!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _currentPost.targetPicture!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          _getAdTypeIcon(),
                                          size: 24,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              _getAdTypeIcon(),
                                              size: 24,
                                              color: theme.colorScheme.outline,
                                            ),
                                          ),
                                    )
                                  : Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(
                                        _getAdTypeIcon(),
                                        size: 24,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Target Name and Type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPost.targetName!,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      _getAdTypeIcon(),
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getAdTypeLabel(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Arrow Icon
                          Icon(
                            Iconsax.arrow_right_3,
                            size: 20,
                            color: theme.colorScheme.primary.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),

                  // Campaign Title with Icon
                  if (_currentPost.campaignTitle != null &&
                      _currentPost.campaignTitle!.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentPost.campaignTitle!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Campaign Description
                  if (_currentPost.campaignDescription != null &&
                      _currentPost.campaignDescription!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _currentPost.campaignDescription!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Action Button with Modern Design
                  if (_currentPost.actionButtonText != null &&
                      _currentPost.actionButtonText!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleAdClick(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPost.actionButtonText!,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Iconsax.arrow_right_1,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  // Get icon based on ad type
  IconData _getAdTypeIcon() {
    switch (_currentPost.adsType) {
      case 'page':
        return Iconsax.document;
      case 'group':
        return Iconsax.people;
      case 'event':
        return Iconsax.calendar;
      case 'post':
        return Iconsax.note;
      default:
        return Iconsax.link;
    }
  }

  // Get label based on ad type
  String _getAdTypeLabel() {
    switch (_currentPost.adsType) {
      case 'page':
        return 'ad_type_page'.tr;
      case 'group':
        return 'ad_type_group'.tr;
      case 'event':
        return 'ad_type_event'.tr;
      case 'post':
        return 'ad_type_post'.tr;
      default:
        return 'ad_type_link'.tr;
    }
  }

  // Handle boost/unboost action
  Future<void> _handleBoost(BuildContext context) async {
    if (_isBoostLoading) return;

    setState(() {
      _isBoostLoading = true;
    });

    try {
      final boostRepository = context.read<BoostRepository>();
      final result = _isBoosted
          ? await boostRepository.unboostPost(_currentPost.id)
          : await boostRepository.boostPost(_currentPost.id);

      if (result.success) {
        setState(() {
          _isBoosted = result.boosted ?? false;
          _currentPost = _currentPost.copyWith(
            isPromoted: result.boosted ?? false,
          );
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // التحقق من نوع الخطأ
        final errorMessage = e.toString();
        final isSubscriptionRequired =
            errorMessage.contains('SUBSCRIPTION_REQUIRED') ||
            errorMessage.contains('You need to subscribe') ||
            errorMessage.contains('Error: SUBSCRIPTION_REQUIRED');

        if (isSubscriptionRequired) {
          // عرض dialog مع خيار الذهاب للباقات
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('subscription_required'.tr),
              content: Text('need_subscription_to_boost'.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('cancel_action'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // إغلاق الـ dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletPackagesPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1306C),
                  ),
                  child: Text('show_packages_button'.tr),
                ),
              ],
            ),
          );
        } else {
          // عرض رسالة الخطأ العادية
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBoostLoading = false;
        });
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    // If this is an ad, show the ad card
    if (_currentPost.isAd) {
      return _buildAdCard(context, theme, mediaAsset);
    }

    // Otherwise, show the post card

    // إخفاء المنشور إذا كان مخفي (إلا إذا كان المالك)
    if (_currentPost.isHidden && !_isOwner(_currentPost)) {
      return const SizedBox.shrink();
    }

    return ElevatedCard(
      key: ValueKey('post_card_${_currentPost.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _onAuthorTap(context),
                  child: _Avatar(
                    url: _currentPost.authorAvatarUrl != null
                        ? mediaAsset(_currentPost.authorAvatarUrl!).toString()
                        : null,
                    radius: 22,
                    showOnlineIndicator: _currentPost.authorType == 'user',
                    isOnline: _currentPost.authorIsOnline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onAuthorTap(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _currentPost.authorName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // إضافة علامة التحقق إذا كان المستخدم محقق
                            if (_currentPost.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Iconsax.verify,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                            // إضافة تسمية "18+" للمحتوى للبالغين
                            if (_currentPost.forAdult) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '18+',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // إضافة نوع المنشور للأحداث
                        if (_currentPost.inEvent &&
                            _currentPost.event != null) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              // Navigate to event detail page
                              final eventId = int.tryParse(
                                _currentPost.event!.eventId,
                              );
                              if (eventId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailPage(eventId: eventId),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _currentPost.postType == 'event'
                                      ? Icons.event_available
                                      : _currentPost.postType == 'event_cover'
                                      ? Icons.photo_camera
                                      : Icons.event,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _getEventActionText(_currentPost),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // إضافة نص البث المباشر
                        if (_currentPost.isLivePost) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                _currentPost.isActiveLive
                                    ? Iconsax.record_circle
                                    : Iconsax.video,
                                size: 12,
                                color: _currentPost.isActiveLive
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _getLiveActionText(_currentPost),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _currentPost.isActiveLive
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // إضافة اسم المجموعة إذا كان المنشور في مجموعة
                        if (_currentPost.isGroupPost &&
                            _currentPost.groupTitle != null) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _onGroupTap(context),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.arrow_right_1,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _currentPost.groupTitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // إضافة الـ Feelings إذا كانت موجودة
                        if (_currentPost.feelingAction != null &&
                            _currentPost.feelingValue != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  _getFeelingIcon(_currentPost.feelingAction!),
                                  size: 12,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${_currentPost.feelingAction} ${_currentPost.feelingValue}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              TimeAgo.formatFromString(
                                _currentPost.publishedAt,
                                isEnglish: true,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _privacyIcon(_currentPost.privacy),
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            // إضافة مؤشر المنشور المثبت
                            if (_currentPost.isPinned) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.bookmark,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                            // إضافة مؤشر البث المباشر
                            if (_currentPost.isLivePost) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentPost.isActiveLive
                                      ? Colors.red
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentPost.isActiveLive)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(right: 2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      _currentPost.isActiveLive
                                          ? 'live_status_live'.tr
                                          : 'live_status_ended'.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // إضافة مؤشر المنشور المشارك
                            if (_currentPost.isSharedPost) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.share,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                            // إضافة مؤشر المقال
                            if (_currentPost.isArticlePost) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.document_text,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                            // إضافة مؤشر Tip
                            if (_currentPost.tipsEnabled) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.dollar_circle,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ],
                            // إضافة مؤشر المنشور المدفوع/المروج
                            if (_currentPost.isPromoted) ...[
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.flash,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'post_promoted'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            // إضافة مؤشر المنشور المدفوع (إزالة هذا القسم)
                            /*if (_currentPost.isPaid) ...[
                              const SizedBox(width: 6),
                              Text('·',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5))),
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.dollar_circle,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ],*/
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostMenu(context),
                  splashRadius: 20,
                  icon: Icon(
                    Iconsax.more,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          if (_currentPost.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _currentPost.hasColoredPattern
                  ? RepaintBoundary(
                      child: _ColoredTextWidget(
                        key: ValueKey('colored_${_currentPost.id}'),
                        htmlContent: _currentPost.text,
                        coloredPattern: _currentPost.coloredPattern!,
                      ),
                    )
                  : HtmlTextWidget(
                      htmlContent: _currentPost.text,
                      maxLength: 300,
                    ),
            ),
          // عرض المقال إذا كان المنشور من نوع article
          if (_currentPost.isArticlePost) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ArticleWidget(
                post: _currentPost,
                mediaResolver: mediaAsset,
              ),
            ),
          ],
          // عرض المنشور المشارك إذا كان من نوع shared
          if (_currentPost.isSharedPost) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SharedPostWidget(originPost: _currentPost.originPost!),
            ),
          ],
          // عرض الفيديو فقط إذا لم يكن المنشور من نوع مقال أو دورة (لأن لهم card خاص)
          if (_currentPost.isVideoPost &&
              !_currentPost.isArticlePost &&
              !_currentPost.isCoursePost) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdaptiveVideoPlayer(
                isFullscreen: false,
                startMuted: false,
                autoplayWhenVisible: true,
                video: _currentPost.video!,
                mediaResolver: context.read<AppConfig>().mediaAsset,
              ),
            ),
          ],
          // عرض البث المباشر
          if (_currentPost.isLivePost && _currentPost.live != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LiveWidget(
                live: _currentPost.live!,
                authorName: _currentPost.authorName,
                mediaResolver: mediaAsset,
                postId: _currentPost.id.toString(), // إضافة postId
              ),
            ),
          ],
          if (_currentPost.hasPhotos &&
              !_currentPost.isOfferPost &&
              !_currentPost.isFundingPost &&
              !_currentPost.isArticlePost &&
              !_currentPost.isCoursePost &&
              !_currentPost.isVideoPost) ...[
            Builder(
              builder: (context) {
                return const SizedBox(height: 12);
              },
            ),
            _PhotosGrid(
              photos: _currentPost.photos!,
              mediaResolver: mediaAsset,
              forAdult: _currentPost.forAdult,
            ),
          ],
          // عرض الصورة من og_image إذا لم توجد photos
          if (_currentPost.ogImage != null &&
              _currentPost.ogImage!.isNotEmpty &&
              !_currentPost.hasPhotos &&
              !_currentPost.isOfferPost &&
              !_currentPost.isFundingPost &&
              !_currentPost.isArticlePost &&
              !_currentPost.isCoursePost &&
              !_currentPost.isVideoPost) ...[
            Builder(
              builder: (context) {
                return const SizedBox(height: 12);
              },
            ),
            _PhotosGrid(
              photos: [PostPhoto(id: 0, source: _currentPost.ogImage!)],
              mediaResolver: mediaAsset,
              forAdult: _currentPost.forAdult,
            ),
          ],
          // عرض الصوت
          if (_currentPost.isAudioPost && _currentPost.audio != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PostAudioWidget(
                audio: _currentPost.audio!,
                authorName: _currentPost.authorName,
                mediaResolver: mediaAsset,
                showWaveform: true,
                showProgress: true,
                autoPlay: false,
              ),
            ),
          ],
          if (_currentPost.hasPoll) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PollWidget(poll: _currentPost.poll!),
            ),
          ],
          if (_currentPost.hasLink) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LinkWidget(link: _currentPost.link!),
            ),
          ],
          // عرض الحدث إذا كان المنشور داخل حدث أو منشور حدث (ما عدا تغيير الغلاف)
          if (_currentPost.inEvent &&
              _currentPost.event != null &&
              _currentPost.postType != 'event_cover') ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EventWidget(
                event: _currentPost.event!,
                mediaResolver: mediaAsset,
              ),
            ),
          ],
          // عرض widget التبرع
          if (_currentPost.isFundingPost && _currentPost.funding != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FundingWidget(
                funding: _currentPost.funding!,
                mediaResolver: mediaAsset,
              ),
            ),
          ],
          // عرض widget العرض
          if (_currentPost.isOfferPost && _currentPost.offer != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OfferWidget(
                offer: _currentPost.offer!,
                mediaResolver: mediaAsset,
              ),
            ),
          ],
          // عرض widget الدورة التعليمية
          if (_currentPost.isCoursePost && _currentPost.course != null) ...[
            const SizedBox(height: 12),
            CourseCard(post: _currentPost, mediaResolver: mediaAsset),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // عرض التفاعلات المفصلة
                if (_currentPost.reactionsCount > 0)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showReactionUsersSheet(
                          context: context,
                          type: 'post',
                          id: _currentPost.id,
                          reactionStats: _currentPost.reactionBreakdown.isEmpty
                              ? {'like': _currentPost.reactionsCount}
                              : _currentPost.reactionBreakdown,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // عرض أيقونات التفاعلات الرئيسية
                            if (_currentPost.reactionBreakdown.isNotEmpty) ...[
                              ..._buildReactionIcons(),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              _currentPost.reactionsCountFormatted,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const Spacer(),
                // عرض إحصائيات متقدمة - Reviews يظهر للجميع
                Text(
                  'post_reviews'.trParams({
                    'count': _currentPost.reviewsCountFormatted,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentPost.viewsCount > 0) ...[
                  Text(
                    'post_views'.trParams({
                      'count': _currentPost.viewsCountFormatted,
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  '${_currentPost.commentsCountFormatted} ${'comments'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'post_shares2'.trParams({
                    'count': _currentPost.sharesCountFormatted,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _PostAction(
                    post: _currentPost,
                    onReactionChanged: widget.onReactionChanged,
                  ),
                  const SizedBox(width: 8),
                  _SimpleActionButton(
                    icon: _currentPost.commentsDisabled
                        ? Iconsax.message_minus
                        : Iconsax.message,
                    label: _currentPost.commentsDisabled
                        ? 'disabled'.tr
                        : 'comment'.tr,
                    isDisabled: _currentPost.commentsDisabled,
                    onTap: _currentPost.commentsDisabled
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('comments_disabled_message'.tr),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CommentsBottomSheet(
                                postId: _currentPost.id,
                                commentsCount: _currentPost.commentsCount,
                              ),
                            );
                          },
                  ),
                  const SizedBox(width: 8),
                  // زر Reviews يظهر لجميع المنشورات
                  _SimpleActionButton(
                    icon: Iconsax.star,
                    label: 'action_review'.tr,
                    onTap: () => _showReviewsBottomSheet(context),
                  ),
                  const SizedBox(width: 8),
                  // زر Tip إذا كانت مفعلة
                  if (_currentPost.tipsEnabled) ...[
                    _SimpleActionButton(
                      icon: Iconsax.dollar_circle,
                      label: 'action_tip'.tr,
                      onTap: () => _showTipBottomSheet(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // زر Share يظهر دائماً
                  _SimpleActionButton(
                    icon: Iconsax.share,
                    label: 'action_share'.tr,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => SharePostDialog(
                          post: _currentPost,
                          onShareSuccess: () {
                            // تحديث عدد المشاركات
                            setState(() {
                              _currentPost = _currentPost.copyWith(
                                sharesCount: _currentPost.sharesCount + 1,
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),
                  // زر Boost يظهر فقط للمالك
                  if (_isOwner(_currentPost)) ...[
                    const SizedBox(width: 8),
                    _BoostActionButton(
                      isBoosted: _isBoosted,
                      isLoading: _isBoostLoading,
                      onTap: () => _handleBoost(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _privacyIcon(String privacy) {
    switch (privacy) {
      case 'friends':
        return Iconsax.people; // <-- 💡 1. أيقونة
      case 'private':
        return Iconsax.lock; // <-- 💡 1. أيقونة
      default:
        return Iconsax.global; // <-- 💡 1. أيقونة
    }
  }
}

// --- 💡 3. تحسين _Avatar ---
// --- 💡 3. تحسين _Avatar مع مؤشر حالة الاتصال ---
class _Avatar extends StatelessWidget {
  const _Avatar({
    this.url,
    this.radius = 20,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  final String? url;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          // استخدام CachedNetworkImageProvider
          backgroundImage: url != null
              ? CachedNetworkImageProvider(url!)
              : null,
          // أيقونة fallback
          child: url == null
              ? Icon(
                  Iconsax.user,
                  size: radius,
                  color: theme.colorScheme.primary,
                )
              : null,
        ),
        // مؤشر حالة الاتصال
        if (showOnlineIndicator && isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.4, // حجم نسبي
              height: radius * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: radius * 0.05, // سمك نسبي
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
// --- نهاية التحسين ---

class _PostAction extends StatefulWidget {
  const _PostAction({required this.post, this.onReactionChanged});

  final Post post;
  final Function(String postId, String reaction)? onReactionChanged;

  @override
  State<_PostAction> createState() => _PostActionState();
}

class _PostActionState extends State<_PostAction>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  bool _isProcessing = false; // منع الاستدعاءات المتعددة
  String? _lastProcessedReaction; // تتبع آخر تفاعل تمت معالجته

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showReactionsPicker() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    // تحقق من الاتجاه RTL للحصول على الموضع المناسب
    final localizationController = Get.find<LocalizationController>();
    final isRTL = localizationController.isRTL;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                // في RTL: عرض على اليسار، في LTR: عرض على اليسار كالمعتاد
                left: isRTL ? 16 : offset.dx, // في RTL نضعها على اليسار تماماً
                right: isRTL
                    ? null
                    : null, // لا نستخدم right في كلا الحالتين هنا
                bottom: MediaQuery.of(context).size.height - offset.dy,
                child: GestureDetector(
                  onTap: () {},
                  child: ReactionPicker(
                    onSelected: (reaction) {
                      _handleReaction(reaction);
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleReaction(String reaction) {
    // منع الاستدعاءات المتعددة
    if (_isProcessing) {
      return;
    }

    // منع إرسال نفس التفاعل مرتين متتاليتين
    if (_lastProcessedReaction == reaction) {
      return;
    }

    _isProcessing = true;
    _lastProcessedReaction = reaction;


    // بدء animation للتأكيد البصري
    _animationController.forward();

    if (widget.onReactionChanged != null) {
      widget.onReactionChanged!(widget.post.id.toString(), reaction);
    } else {
      final postsBloc = context.read<PostsBloc>();
      postsBloc.add(ReactToPostEvent(widget.post.id, reaction));
    }

    // إعادة تعيين animation والـ flag
    _animationController.reverse();

    // السماح بالاستدعاء التالي بعد فترة قصيرة
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isProcessing = false;
        // إعادة تعيين _lastProcessedReaction بعد فترة أطول للسماح بتغيير التفاعل
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _lastProcessedReaction = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.post;
    final reactionModel = postData.myReaction != null
        ? ReactionsService.instance.getReactionByName(postData.myReaction!)
        : null;

    final String actionLabel =
      reactionModel?.title ?? 'like'.tr; // استخدام الترجمة الافتراضية
    final Color actionColor =
        reactionModel?.colorValue ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.65);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animationController.value * 0.1), // تأثير نبض خفيف
          child: InkWell(
            onTap: () {
              // إذا كان هناك تفاعل حالياً، قم بإزالته، وإلا أضف like
              final currentReaction = postData.myReaction;

              if (currentReaction != null) {
                _handleReaction('remove'); // إزالة التفاعل الحالي
              } else {
                _handleReaction('like'); // إضافة إعجاب
              }
            },
            onLongPress: _showReactionsPicker,
            child: Container(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reactionModel != null)
                    CachedNetworkImage(
                      imageUrl: reactionModel.imageUrl,
                      width: 20,
                      height: 20,
                      placeholder: (context, url) => SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: actionColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Iconsax.happyemoji, // <-- 💡 1. أيقونة
                        size: 20,
                        color: actionColor,
                      ),
                    )
                  else
                    Icon(
                      Iconsax.like_1, // <-- 💡 1. أيقونة
                      color: actionColor,
                      size: 20,
                    ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: actionColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SimpleActionButton extends StatelessWidget {
  const _SimpleActionButton({
    required this.icon,
    this.label,
    this.onTap,
    this.isDisabled = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = isDisabled ? 0.4 : 0.7;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(opacity),
              size: 20,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(opacity),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReactionPicker extends StatefulWidget {
  const ReactionPicker({super.key, required this.onSelected});

  final Function(String) onSelected;

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final reactions = ReactionsService.instance.getReactions();
    for (int i = 0; i < reactions.length; i++) {
      final delay = i * 0.08;

      _scaleAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.elasticOut),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        ),
      );
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = ReactionsService.instance.getReactions();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < reactions.length; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimations[i],
                    child: ScaleTransition(
                      scale: _scaleAnimations[i],
                      child: _ReactionButton(
                        reaction: reactions[i],
                        onTap: () => widget.onSelected(reactions[i].reaction),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.reaction, required this.onTap});

  final ReactionModel reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CachedNetworkImage(
          imageUrl: reaction.imageUrl,
          width: 28,
          height: 28,
          placeholder: (context, url) => SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: reaction.colorValue,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            Iconsax.happyemoji, // <-- 💡 1. أيقونة
            size: 28,
            color: reaction.colorValue,
          ),
        ),
      ),
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({required this.type, this.size = 18});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reaction = ReactionsService.instance.getReactionByName(type);

    if (reaction != null) {
      return CachedNetworkImage(
        imageUrl: reaction.imageUrl,
        width: size,
        height: size,
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: reaction.colorValue,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Iconsax.happyemoji, // <-- 💡 1. أيقونة
          size: size,
          color: reaction.colorValue,
        ),
      );
    }

    return SizedBox(width: size, height: size);
  }
}

// --- 💡 4. تحسين _PhotosGrid ---
class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({
    required this.photos,
    required this.mediaResolver,
    this.forAdult = false,
  });

  final List<PostPhoto> photos;
  final Uri Function(String) mediaResolver;
  final bool forAdult;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    // استخدام CachedNetworkImage بدلاً من Image.network
    Widget buildImage(int index, {double? height}) {
      final imageUrl = mediaResolver(photos[index].source).toString();

      return GestureDetector(
        onTap: () => _showPhotoViewer(context, index, forAdult: forAdult),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
          placeholder: (context, url) {
            return Container(
              height: height ?? 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorWidget: (context, url, error) {
            return Container(
              height: height ?? 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.gallery_slash,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
          imageBuilder: (context, imageProvider) {
            // الاعتماد فقط على forAdult وليس على blur
            final shouldBlur = forAdult;
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (shouldBlur)
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.visibility_off,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    final count = photos.length;
    if (count == 1) {
      return buildImage(0, height: 300);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: buildImage(0, height: 200),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: buildImage(1, height: 200),
            ),
          ),
        ],
      );
    }

    // تصميم لـ 3 صور (1 كبيرة، 2 صغيرتين)
    if (count == 3) {
      return SizedBox(
        height: 204,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: buildImage(0, height: 204),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0, bottom: 2.0),
                      child: buildImage(1, height: 100),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0, top: 2.0),
                      child: buildImage(2, height: 100),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // تصميم لـ 4 صور (شبكة 2x2)
    if (count == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0, bottom: 2.0),
                  child: buildImage(0, height: 150),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.0, bottom: 2.0),
                  child: buildImage(1, height: 150),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0, top: 2.0),
                  child: buildImage(2, height: 150),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.0, top: 2.0),
                  child: buildImage(3, height: 150),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // تصميم لـ 5 صور أو أكثر (1 كبيرة، 4 صغيرات + عداد)
    if (count >= 5) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: buildImage(0, height: 200),
          ),
          Row(
            children: photos.sublist(1, 5).asMap().entries.map((entry) {
              final index = entry.key; // 0..3
              final photoIndex = index + 1; // 1..4
              final bool isLast = index == 3 && count > 5;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 2.0,
                    right: index == 3 ? 0 : 2.0,
                    top: 2.0,
                  ),
                  child: GestureDetector(
                    onTap: () => _showPhotoViewer(
                      context,
                      photoIndex,
                      forAdult: forAdult,
                    ),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        buildImage(photoIndex, height: 80),
                        if (isLast)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Text(
                                  '+${count - 5}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return const SizedBox.shrink(); // للحالات غير المتوقعة
  }

  // --- 💡 4. تحسين _showPhotoViewer (معرض صور احترافي) ---
  void _showPhotoViewer(
    BuildContext context,
    int initialIndex, {
    bool forAdult = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final shouldBlur = forAdult;
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: mediaResolver(
                            photos[index].source,
                          ).toString(),
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Iconsax.gallery_slash,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (shouldBlur)
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    Icons.visibility_off,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Iconsax.close_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// --- نهاية التحسين ---

// --- 💡 5. تحسين _PollWidget ---
class _PollWidget extends StatelessWidget {
  const _PollWidget({required this.poll});

  final PostPoll poll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes = poll.votes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...poll.options.map((option) {
          final percentage = totalVotes > 0 ? (option.votes / totalVotes) : 0.0;
          final percentageText = (percentage * 100).toStringAsFixed(1);
          final isSelected = option.checked;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () {
                // TODO: Implement voting
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                clipBehavior: Clip.antiAlias, // لقص شريط النسبة
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Layer 1: شريط النسبة
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 44, // ارتفاع ثابت لضمان التناسق
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    // Layer 2: المحتوى
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Icon(
                              Iconsax.tick_circle, // <-- 💡 1. أيقونة
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          if (isSelected) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$percentageText%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          '$totalVotes ${totalVotes == 1 ? 'vote_singular'.tr : 'vote_plural'.tr}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Widget لعرض الروابط المرفقة بالمنشور
class _LinkWidget extends StatelessWidget {
  const _LinkWidget({required this.link});

  final PostLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // صورة الرابط - قابلة للنقر
          if (link.sourceThumbnail != null && link.sourceThumbnail!.isNotEmpty)
            GestureDetector(
              onTap: () => _onLinkTap(context),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: link.sourceThumbnail!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Iconsax.link,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Iconsax.link,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // محتوى الرابط - قابل للنقر
          GestureDetector(
            onTap: () => _onLinkTap(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان الرابط
                  Text(
                    link.sourceTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (link.sourceText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      link.sourceText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // URL الرابط
                  Row(
                    children: [
                      Icon(
                        Iconsax.link,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          link.sourceHost.isNotEmpty
                              ? link.sourceHost
                              : Uri.parse(link.sourceUrl).host,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onLinkTap(BuildContext context) {
    // فتح الرابط في المتصفح
    // يمكنك استخدام url_launcher أو WebView
    try {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => WebViewPage(url: link.sourceUrl),
      //   ),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في فتح الرابط: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget لعرض محتوى المقال
class _ArticleWidget extends StatelessWidget {
  const _ArticleWidget({required this.post, required this.mediaResolver});

  final Post post;
  final Uri Function(String) mediaResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blog = post.blog!;

    return GestureDetector(
      onTap: () {
        // الانتقال إلى صفحة المقال
        try {
          final articleId = int.parse(blog.articleId);
          Get.to(() => BlogPostPage(postId: articleId));
        } catch (e) {
          // لا نعرض رسالة خطأ للمستخدم لأن المقال قد يكون محذوفاً
          // صفحة BlogPostPage ستتعامل مع خطأ 404 وتعرض رسالة مناسبة
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عرض الفيديو إذا كان موجوداً، وإلا عرض صورة الغلاف
            if (post.hasVideo)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AdaptiveVideoPlayer(
                  isFullscreen: false,
                  startMuted: false,
                  autoplayWhenVisible: true,
                  video: post.video!,
                  mediaResolver: mediaResolver,
                ),
              )
            else if (blog.cover != null && blog.cover!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: blog.cover!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Iconsax.document_text,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Iconsax.document_text,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // محتوى المقال
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان المقال
                  Text(
                    blog.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (blog.textSnippet != null &&
                      blog.textSnippet!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      blog.textSnippet!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // تصنيف المقال
                  Row(
                    children: [
                      Icon(
                        Iconsax.document_text,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        blog.categoryName ?? 'Article',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget لعرض المنشور المشارك
class _SharedPostWidget extends StatelessWidget {
  const _SharedPostWidget({required this.originPost});

  final Post originPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المؤلف الأصلي
            Row(
              children: [
                _Avatar(
                  url: originPost.authorAvatarUrl != null
                      ? mediaAsset(originPost.authorAvatarUrl!).toString()
                      : null,
                  radius: 16,
                  showOnlineIndicator: originPost.authorType == 'user',
                  isOnline: originPost.authorIsOnline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              originPost.authorName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (originPost.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Iconsax.verify,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        TimeAgo.formatFromString(
                          originPost.publishedAt,
                          isEnglish: true,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (originPost.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              HtmlTextWidget(htmlContent: originPost.text, maxLength: 200),
            ],
            // محتوى إضافي للمنشور الأصلي
            if (originPost.hasPhotos) ...[
              const SizedBox(height: 8),
              _PhotosGrid(
                photos: originPost.photos!,
                mediaResolver: mediaAsset,
                forAdult: originPost.forAdult,
              ),
            ],
            if (originPost.hasLink) ...[
              const SizedBox(height: 8),
              _LinkWidget(link: originPost.link!),
            ],
            if (originPost.isEventPost && originPost.event != null) ...[
              const SizedBox(height: 8),
              _EventWidget(event: originPost.event!, mediaResolver: mediaAsset),
            ],
            // عرض widget التبرع للمنشور المشترك
            if (originPost.isFundingPost && originPost.funding != null) ...[
              const SizedBox(height: 8),
              _FundingWidget(
                funding: originPost.funding!,
                mediaResolver: mediaAsset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventWidget extends StatelessWidget {
  const _EventWidget({required this.event, required this.mediaResolver});

  final PostEvent event;
  final Uri Function(String) mediaResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigate to event detail page
        final eventId = int.tryParse(event.eventId);
        if (eventId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: eventId),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة غلاف الحدث
            if (event.eventCover != null) ...[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: mediaResolver(event.eventCover!).toString(),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.event, size: 48)),
                    ),
                  ),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // أيقونة الحدث والعنوان
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          event.eventIsOnline ? Icons.videocam : Icons.event,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.eventTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.eventLocation != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.eventLocation!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // تاريخ ووقت الحدث
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333333) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatEventDate(event.eventStartDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (event.eventStartDate !=
                                  event.eventEndDate) ...[
                                Text(
                                  'to ${_formatEventDate(event.eventEndDate)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // وصف الحدث
                  if (event.eventDescription != null &&
                      event.eventDescription!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      event.eventDescription!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // إحصائيات الحدث
                  Row(
                    children: [
                      _EventStat(
                        icon: Icons.star_outline,
                        label: 'interested_button_event'.tr,
                        count: event.formattedInterestedCount,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _EventStat(
                        icon: Icons.check_circle_outline,
                        label: 'going_button_event'.tr,
                        count: event.formattedGoingCount,
                        color: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // أزرار الحدث
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: تنفيذ عرض تفاصيل الحدث
                          },
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: Text('details_button'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: تنفيذ الانضمام/إلغاء الانضمام
                          },
                          icon: Icon(
                            event.iJoined
                                ? Icons.check_circle
                                : Icons.star_outline,
                            size: 18,
                          ),
                          label: Text(event.iJoined ? 'Joined' : 'Interested'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDate = DateTime(date.year, date.month, date.day);

      if (eventDate == today) {
        return '${'time_today'.tr} ${_formatTime(date)}';
      } else if (eventDate == today.add(const Duration(days: 1))) {
        return '${'time_tomorrow'.tr} ${_formatTime(date)}';
      } else {
        return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'time_period_pm'.tr : 'time_period_am'.tr;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _EventStat extends StatelessWidget {
  const _EventStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget لعرض حملة التبرع
class _FundingWidget extends StatelessWidget {
  const _FundingWidget({required this.funding, required this.mediaResolver});

  final PostFunding funding;
  final Uri Function(String) mediaResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.green.shade900.withOpacity(0.2),
                  Colors.green.shade800.withOpacity(0.1),
                ]
              : [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.green.withOpacity(0.4)
              : Colors.green.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.green.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        funding.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Goal: \$${_formatMoney(funding.amount)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? Colors.green.shade400
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Raised: \$${_formatMoney(funding.raisedAmount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.grey.shade800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.shade800
                            : Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${funding.completionPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: funding.completionPercentage / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LinearGradient(
                          colors: [
                            Colors.green.shade500,
                            Colors.green.shade600,
                          ],
                        ).colors.first,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _FundingStatCard(
                    icon: Icons.people_rounded,
                    value: funding.totalDonations.toString(),
                    label: funding.totalDonations == 1 ? 'Backer' : 'Backers',
                    color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FundingStatCard(
                    icon: Icons.monetization_on_rounded,
                    value: '\$${_formatMoney(funding.remainingAmount)}',
                    label: 'remaining_label'.tr,
                    color: isDark
                        ? Colors.orange.shade400
                        : Colors.orange.shade600,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: funding.isGoalReached
                    ? () {
                        // Navigate to funding detail page if goal reached
                        final postIdInt = int.tryParse(funding.postId);
                        if (postIdInt != null) {
                          Get.to(() => FundingDetailPage(fundingId: postIdInt));
                        }
                      }
                    : () async {
                        // Navigate to donate page if goal not reached
                        final postIdInt = int.tryParse(funding.postId);
                        if (postIdInt != null) {
                          // First get full funding details using postId
                          try {
                            final repo = Provider.of<FundingRepository>(
                              context,
                              listen: false,
                            );
                            final fullFunding = await repo.getFundingById(
                              postIdInt,
                            );
                            await Get.to(
                              () => FundingDonatePage(funding: fullFunding),
                            );
                          } catch (e) {
                            Get.snackbar('error'.tr, e.toString());
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.green.shade700
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isDark ? 8 : 4,
                  shadowColor: Colors.green.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      funding.isGoalReached
                          ? Icons.check_circle_rounded
                          : Icons.favorite_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      funding.isGoalReached ? 'Goal Reached!' : 'Donate Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Goal reached banner
            if (funding.isGoalReached) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.shade800.withOpacity(0.3)
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.green.shade600
                        : Colors.green.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: isDark
                          ? Colors.green.shade400
                          : Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thank you to all supporters!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.green.shade400
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

/// Widget لعرض إحصائية في حملة التبرع
class _FundingStatCard extends StatelessWidget {
  const _FundingStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? theme.colorScheme.onSurface : color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget لعرض العرض (Offer)
class _OfferWidget extends StatelessWidget {
  const _OfferWidget({required this.offer, required this.mediaResolver});

  final PostOffer offer;
  final Uri Function(String) mediaResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return GestureDetector(
      onTap: () {
        // Navigate to offer detail page
        final offerIdInt = int.tryParse(offer.offerId);
        if (offerIdInt != null) {
          Get.to(() => OfferDetailPage(offerId: offerIdInt));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.orange.shade900.withOpacity(0.2),
                    Colors.orange.shade800.withOpacity(0.1),
                  ]
                : [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.orange.withOpacity(0.4)
                : Colors.orange.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail if available and non-empty to avoid invalid image data
            if (offer.thumbnail != null &&
                offer.thumbnail!.trim().isNotEmpty) ...[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: mediaResolver(offer.thumbnail!).toString(),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Iconsax.gallery_slash,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(Iconsax.tag, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.orange.shade300
                                    : Colors.orange.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (offer.price != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '\$${offer.price!.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? Colors.orange.shade400
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Discount badge
                  if (offer.hasDiscount) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade800
                            : Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.ticket_discount,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getDiscountText(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(
                          () => OfferDetailPage(
                            offerId: int.parse(offer.offerId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.orange.shade700
                            : Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDark ? 8 : 4,
                        shadowColor: Colors.orange.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.shopping_bag, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'View Offer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDiscountText() {
    if (offer.isPercentDiscount && offer.discountPercent != null) {
      return '${offer.discountPercent}% OFF';
    } else if (offer.isAmountDiscount && offer.discountAmount != null) {
      return '\$${offer.discountAmount!.toStringAsFixed(0)} OFF';
    } else if (offer.isBuyGetDiscount &&
        offer.buyX != null &&
        offer.getY != null) {
      return 'offer_discount_buy_get'.trParams({
        'buy': offer.buyX.toString(),
        'get': offer.getY.toString(),
      });
    } else if (offer.isSpendGetOff &&
        offer.spendX != null &&
        offer.amountY != null) {
      return 'offer_discount_spend_get'.trParams({
        'spend': offer.spendX!.toStringAsFixed(0),
        'amount': offer.amountY!.toStringAsFixed(0),
      });
    } else if (offer.isFreeShipping) {
      return 'FREE SHIPPING';
    }
    return 'offer_special'.tr;
  }
}

/// Widget لعرض النص مع خلفية ملونة أو منقوشة
class _ColoredTextWidget extends StatefulWidget {
  const _ColoredTextWidget({
    super.key,
    required this.htmlContent,
    required this.coloredPattern,
  });

  final String htmlContent;
  final PostColoredPattern coloredPattern;

  @override
  State<_ColoredTextWidget> createState() => _ColoredTextWidgetState();
}

class _ColoredTextWidgetState extends State<_ColoredTextWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // منع rebuild غير ضروري

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    // استخدام LayoutBuilder لمنع layout shifts
    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب حجم ثابت بناء على constraints
        final calculatedSize = (constraints.maxWidth * 0.85).clamp(
          250.0,
          400.0,
        );

        return Container(
          width: calculatedSize,
          height: calculatedSize,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // إضافة shadow خفيف
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
            // خلفية الصورة أو اللون
            image: widget.coloredPattern.isImagePattern
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      widget.coloredPattern.backgroundImage!.full,
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
            // خلفية متدرجة إذا كان هناك لونين
            gradient:
                widget.coloredPattern.hasGradient &&
                    !widget.coloredPattern.isImagePattern
                ? LinearGradient(
                    colors: [
                      _parseColor(
                        widget.coloredPattern.backgroundColors!.primary,
                      ),
                      _parseColor(
                        widget.coloredPattern.backgroundColors!.secondary!,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            // لون واحد إذا لم يكن هناك تدرج
            color:
                widget.coloredPattern.isColorPattern &&
                    !widget.coloredPattern.hasGradient
                ? _parseColor(
                    widget.coloredPattern.backgroundColors?.primary ??
                        '#4A90E2',
                  )
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
              crossAxisAlignment: CrossAxisAlignment.center, // توسيط أفقي
              children: [_buildCenteredText()],
            ),
          ),
        );
      },
    );
  }

  /// بناء النص مع محاذاة مركزية مثالية
  Widget _buildCenteredText() {
    return Container(
      width: double.infinity,
      child: HtmlTextWidget(
        htmlContent: widget.htmlContent,
        maxLength: 500, // طول أكبر للنصوص الملونة
        fontSize: _calculateFontSize(widget.htmlContent),
        lineHeight: 1.3,
        textColor: widget.coloredPattern.textColor != null
            ? _parseColor(widget.coloredPattern.textColor!)
            : Colors.white,
        textAlign: TextAlign.center, // محاذاة مركزية مع دعم الهاشتاغ والمنشن
      ),
    );
  }

  /// حساب حجم الخط بناءً على طول النص (مثل Facebook)
  double _calculateFontSize(String text) {
    final textLength = text.replaceAll(RegExp(r'<[^>]*>'), '').trim().length;

    if (textLength <= 30) {
      return 32; // نص قصير جداً - خط كبير جداً
    } else if (textLength <= 60) {
      return 28; // نص قصير - خط كبير
    } else if (textLength <= 100) {
      return 24; // نص متوسط - خط متوسط
    } else if (textLength <= 150) {
      return 20; // نص طويل - خط أصغر
    } else {
      return 18; // نص طويل جداً - خط صغير
    }
  }

  /// تحويل النص إلى لون
  Color _parseColor(String colorString) {
    try {
      // إزالة # إذا كانت موجودة
      String cleanColor = colorString.replaceAll('#', '');

      // إضافة FF للشفافية إذا كان اللون 6 أحرف فقط
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }

      // تحويل إلى int ثم إلى Color
      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      // لون افتراضي في حالة الخطأ
      return Colors.blue;
    }
  }
}

/// Widget لعرض البث المباشر
class _LiveWidget extends StatelessWidget {
  const _LiveWidget({
    required this.live,
    required this.authorName,
    required this.mediaResolver,
    required this.postId, // إضافة postId
  });

  final PostLive live;
  final String authorName;
  final Uri Function(String) mediaResolver;
  final String postId; // إضافة postId

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.red.shade900.withOpacity(0.3),
                  Colors.red.shade800.withOpacity(0.1),
                ]
              : [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: live.isActive
              ? Colors.red.withOpacity(0.6)
              : Colors.grey.withOpacity(0.3),
          width: live.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: live.isActive
                ? Colors.red.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المعاينة مع الحالة المباشرة
          Stack(
            children: [
              // صورة المعاينة
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: live.videoThumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: mediaResolver(
                            live.videoThumbnail!,
                          ).toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Iconsax.video,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Iconsax.close_circle,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Iconsax.video,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ),

              // شارة LIVE أو ENDED
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: live.isActive ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (live.isActive)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        live.isActive ? 'LIVE' : 'ENDED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // زر التشغيل
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      live.isActive ? Iconsax.play : Iconsax.video_play,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // معلومات البث
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان والحالة
                Row(
                  children: [
                    Icon(
                      live.isActive ? Iconsax.record_circle : Iconsax.video,
                      size: 20,
                      color: live.isActive
                          ? Colors.red
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        live.isActive
                            ? '$authorName is live now'
                            : '$authorName was live',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: live.isActive ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // معرف القناة (مخفي للمستخدمين العاديين)
                if (live.isActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Channel: ${live.agoraChannelName.substring(0, 8)}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],

                // زر المشاهدة
                if (live.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinLiveStream(context),
                      icon: const Icon(Iconsax.video_play),
                      label: Text('watch_live_button'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: live.liveRecorded
                          ? () => _watchRecording(context)
                          : null,
                      icon: Icon(
                        live.liveRecorded
                            ? Iconsax.video_play
                            : Iconsax.close_circle,
                      ),
                      label: Text(
                        live.liveRecorded
                            ? 'Watch Recording'
                            : 'Recording Unavailable',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _joinLiveStream(BuildContext context) {
    // فتح صفحة مشاهدة البث المباشر مع API integration
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          channelName: live.agoraChannelName,
          token: live.agoraAudienceToken ?? '',
          broadcasterName: authorName,
          uid: int.tryParse(live.agoraAudienceUid ?? '0') ?? 0,
          thumbnailUrl: live.videoThumbnail != null
              ? mediaResolver(live.videoThumbnail!).toString()
              : null,
          // إضافة postId للتكامل مع API - استخدام postId المُمرر
          postId: postId,
          // إبقاء liveId للتوافق مع النسخة السابقة
          liveId: live.liveId.toString(),
        ),
      ),
    );
  }

  void _watchRecording(BuildContext context) {
    // TODO: تنفيذ مشاهدة التسجيل

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('recording_coming_soon'.tr),
        backgroundColor: Colors.blue,
      ),
    );

    // يمكن هنا فتح مشغل الفيديو للتسجيل
    // if (live.agoraFile != null) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => VideoPlayerPage(
    //         videoUrl: live.agoraFile!,
    //       ),
    //     ),
    //   );
    // }
  }
}

/// Simple Boost Action Button
class _BoostActionButton extends StatelessWidget {
  final bool isBoosted;
  final bool isLoading;
  final VoidCallback onTap;

  const _BoostActionButton({
    required this.isBoosted,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  isBoosted ? Iconsax.star_1 : Iconsax.star,
                  size: 18,
                  color: isBoosted
                      ? const Color(0xFFFF8C00) // Orange for boosted
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              const SizedBox(width: 4),
              Text(
                isBoosted ? 'boosted'.tr : 'boost_post'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isBoosted
                      ? const Color(0xFFFF8C00)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isBoosted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- نهاية التحسين ---
