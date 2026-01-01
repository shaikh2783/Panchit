import 'package:flutter/material.dart';
import '../presentation/pages/live_stream_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// مثال لكيفية استخدام LiveStreamViewerPage مع API integration
class LiveStreamUsageExample {
  
  /// مثال 1: انتقال لمشاهدة بث مباشر مع API integration
  static void navigateToLiveStream(
    BuildContext context, {
    required String channelName,
    required String token,
    required String broadcasterName,
    String? postId, // معرف البوست (مطلوب للـ API)
    String? broadcasterAvatar,
    String? thumbnailUrl,
    bool isVerified = false,
    int viewersCount = 0,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          // معلومات Agora الأساسية
          channelName: channelName,
          token: token,
          broadcasterName: broadcasterName,
          uid: 0, // عادة 0 للمشاهدين
          
          // معلومات إضافية
          broadcasterAvatar: broadcasterAvatar,
          thumbnailUrl: thumbnailUrl,
          isVerified: isVerified,
          viewersCount: viewersCount,
          
          // معرف البث للـ API - هذا مهم!
          postId: postId,
        ),
      ),
    );
  }

  /// مثال 2: مشاهدة بث مباشر بدون API (البيانات التجريبية فقط)
  static void navigateToLiveStreamDemo(
    BuildContext context, {
    required String channelName,
    required String token,
    required String broadcasterName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          channelName: channelName,
          token: token,
          broadcasterName: broadcasterName,
          uid: 0,
          // عدم تمرير liveId = استخدام البيانات التجريبية
        ),
      ),
    );
  }

  /// مثال 3: الحصول على بيانات البث من API ثم فتح المشاهدة
  static Future<void> joinLiveStreamFromAPI(
    BuildContext context, {
    required String postId, // معرف البوست
  }) async {
    try {
      // إظهار loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // هنا يجب استدعاء API للحصول على بيانات البث
      // مثال على الاستجابة المتوقعة:
      final mockApiResponse = {
        'status': 'success',
        'data': {
          'live_id': 'live_123',
          'agora_channel_name': 'live_123_1700000000',
          'agora_audience_token': 'your_agora_token_here',
          'agora_audience_uid': 55,
          'broadcaster_name': 'أحمد محمد',
          'broadcaster_avatar': 'https://example.com/avatar.jpg',
          'is_verified': true,
          'current_viewers': 1250,
          'live_ended': false,
        }
      };

      // إغلاق loader
      Navigator.pop(context);

      if (mockApiResponse['status'] == 'success') {
        final data = mockApiResponse['data'] as Map<String, dynamic>;
        
        // التأكد من أن البث لم ينته
        if (data['live_ended'] == true) {
          _showErrorDialog(context, 'هذا البث المباشر قد انتهى');
          return;
        }

        // فتح صفحة المشاهدة مع البيانات المستلمة
        navigateToLiveStream(
          context,
          postId: data['post_id'], // استخدام post_id بدلاً من live_id
          channelName: data['agora_channel_name'],
          token: data['agora_audience_token'],
          broadcasterName: data['broadcaster_name'],
          broadcasterAvatar: data['broadcaster_avatar'],
          isVerified: data['is_verified'] ?? false,
          viewersCount: data['current_viewers'] ?? 0,
        );
      } else {
        _showErrorDialog(context, 'فشل في الانضمام للبث المباشر');
      }
    } catch (e) {
      // إغلاق loader في حالة الخطأ
      Navigator.pop(context);
      _showErrorDialog(context, 'حدث خطأ: ${e.toString()}');
    }
  }

  /// مثال 4: قائمة البثوث المباشرة النشطة
  static Widget buildActiveLiveStreamsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // هنا يجب استدعاء API للحصول على البثوث النشطة
      future: _fetchActiveLiveStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل البثوث: ${snapshot.error}'),
          );
        }

        final liveStreams = snapshot.data ?? [];
        
        if (liveStreams.isEmpty) {
          return const Center(
            child: Text('لا توجد بثوث مباشرة حالياً'),
          );
        }

        return ListView.builder(
          itemCount: liveStreams.length,
          itemBuilder: (context, index) {
            final stream = liveStreams[index];
            return _buildLiveStreamCard(context, stream);
          },
        );
      },
    );
  }

  /// مساعد: بناء كارد البث المباشر
  static Widget _buildLiveStreamCard(
    BuildContext context, 
    Map<String, dynamic> stream,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: stream['broadcaster_avatar'] != null
                  ? CachedNetworkImageProvider(stream['broadcaster_avatar'])
                  : null,
              child: stream['broadcaster_avatar'] == null
                  ? Text(stream['broadcaster_name'][0] ?? '?')
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                stream['title'] ?? 'بث مباشر',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (stream['is_verified'] == true)
              const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stream['broadcaster_name'] ?? 'مجهول'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.visibility, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${stream['current_viewers'] ?? 0} مشاهد',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'مباشر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // الانضمام للبث
          joinLiveStreamFromAPI(
            context,
            postId: stream['post_id'],
          );
        },
      ),
    );
  }

  /// مساعد: جلب البثوث المباشرة النشطة (mock)
  static Future<List<Map<String, dynamic>>> _fetchActiveLiveStreams() async {
    // محاكاة استدعاء API
    await Future.delayed(const Duration(seconds: 2));
    
    return [
      {
        'post_id': '123',
        'live_id': 'live_123',
        'title': 'تطوير تطبيقات Flutter',
        'broadcaster_name': 'أحمد محمد',
        'broadcaster_avatar': 'https://example.com/avatar1.jpg',
        'is_verified': true,
        'current_viewers': 1250,
        'thumbnail_url': 'https://example.com/thumb1.jpg',
      },
      {
        'post_id': '124',
        'live_id': 'live_124',
        'title': 'ورشة عمل React Native',
        'broadcaster_name': 'سارة أحمد',
        'broadcaster_avatar': 'https://example.com/avatar2.jpg',
        'is_verified': false,
        'current_viewers': 890,
        'thumbnail_url': 'https://example.com/thumb2.jpg',
      },
    ];
  }

  /// مساعد: عرض رسالة خطأ
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

/// مثال صفحة لعرض البثوث المباشرة
class LiveStreamsPage extends StatelessWidget {
  const LiveStreamsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البثوث المباشرة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // إعادة تحميل البثوث
            },
          ),
        ],
      ),
      body: LiveStreamUsageExample.buildActiveLiveStreamsList(),
    );
  }
}