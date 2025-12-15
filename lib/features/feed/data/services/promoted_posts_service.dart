import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/main.dart' show configCfgP;
/// خدمة المنشورات المدفوعة (Promoted Posts)
/// تجلب منشور مدفوع واحد عشوائي في كل مرة
class PromotedPostsService {
  final ApiClient _apiClient;
  PromotedPostsService(this._apiClient);
  /// جلب منشور مدفوع عشوائي واحد
  Future<Post?> getRandomPromotedPost() async {
    try {
      final data = await _apiClient.get(configCfgP('posts_promoted'));
      if (data['status'] == 'success') {
        final posts = data['data']['posts'] as List;
        if (posts.isNotEmpty) {
          // تحويل البيانات إلى نموذج Post
          final postData = posts.first as Map<String, dynamic>;
          // تحويل post_id إلى id لتوافق مع نموذجنا
          postData['id'] = postData['post_id'];
          postData['type'] = postData['post_type'];
          postData['time_text'] = postData['time'];
          // إضافة معلومات المؤلف
          if (postData['author'] != null) {
            final author = postData['author'] as Map<String, dynamic>;
            postData['user_id'] = author['user_id']?.toString();
            postData['username'] = author['username'];
            // استخدام الاسم الكامل بشكل صحيح
            final fullname = author['fullname']?.toString() ?? '';
            if (fullname.isNotEmpty) {
              final nameParts = fullname.split(' ');
              postData['user_firstname'] = nameParts.first; // تغيير إلى user_firstname
              postData['user_lastname'] = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            } else {
              // استخدام الحقول المنفصلة إذا كانت متوفرة
              postData['user_firstname'] = author['first_name']?.toString() ?? '';
              postData['user_lastname'] = author['last_name']?.toString() ?? '';
            }
            postData['avatar'] = author['picture'];
            postData['user_picture'] = author['picture']; // إضافة user_picture أيضاً
            postData['user_verified'] = author['verified'];
            postData['user_type'] = author['user_type'];
          }
          // إضافة الإحصائيات
          if (postData['stats'] != null) {
            final stats = postData['stats'] as Map<String, dynamic>;
            postData['reactions'] = {'count': stats['reactions']};
            postData['reactions_total_count'] = stats['reactions'];
            postData['comments'] = stats['comments'];
            postData['shares'] = stats['shares'];
          }
          // إضافة تفاعل المستخدم
          if (postData['user_reaction'] != null) {
            final userReaction = postData['user_reaction'] as Map<String, dynamic>;
            if (userReaction['reacted'] == true) {
              postData['i_reaction'] = userReaction['reaction'];
            }
          }
          // إضافة معلومات السياق (Page/Group)
          if (postData['page_context'] != null) {
            final pageContext = postData['page_context'] as Map<String, dynamic>;
            postData['page'] = {
              'page_id': pageContext['page_id'],
              'page_name': pageContext['page_name'],
              'page_title': pageContext['page_title'],
            };
          }
          if (postData['group_context'] != null) {
            final groupContext = postData['group_context'] as Map<String, dynamic>;
            postData['group'] = {
              'group_id': groupContext['group_id'],
              'group_name': groupContext['group_name'],
              'group_title': groupContext['group_title'],
            };
          }
          // إضافة معلومات الحدث إذا كان المنشور من نوع event
          if (postData['post_type'] == 'event' && postData['event'] != null) {
            postData['in_event'] = true;
            // الحدث موجود بالفعل في postData['event']
          }
          // إضافة فلاج المنشور المدفوع
          postData['is_promoted'] = true;
          postData['boosted'] = postData['is_boosted'];
          return Post.fromJson(postData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  /// التحقق من وجود منشورات مدفوعة متاحة
  Future<bool> hasAvailablePromotedPosts() async {
    try {
      final data = await _apiClient.get(configCfgP('posts_promoted'));
      if (data['status'] == 'success') {
        final pagination = data['data']['pagination'] as Map<String, dynamic>;
        final totalBoosted = pagination['total_boosted'] ?? 0;
        return totalBoosted > 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
