import 'package:flutter/material.dart';
import '../presentation/pages/live_stream_viewer_page.dart';
/// مثال لاختبار Live Stream API integration
class LiveStreamTestPage extends StatefulWidget {
  const LiveStreamTestPage({Key? key}) : super(key: key);
  @override
  State<LiveStreamTestPage> createState() => _LiveStreamTestPageState();
}
class _LiveStreamTestPageState extends State<LiveStreamTestPage> {
  final TextEditingController _liveIdController = TextEditingController();
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _broadcasterController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // قيم تجريبية
    _liveIdController.text = 'live_123';
    _channelController.text = 'live_123_1700000000';
    _tokenController.text = 'test_token';
    _broadcasterController.text = 'أحمد محمد';
  }
  @override
  void dispose() {
    _liveIdController.dispose();
    _channelController.dispose();
    _tokenController.dispose();
    _broadcasterController.dispose();
    super.dispose();
  }
  void _openLiveStreamWithAPI() {
    if (_liveIdController.text.isEmpty || 
        _channelController.text.isEmpty || 
        _broadcasterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          channelName: _channelController.text,
          token: _tokenController.text,
          broadcasterName: _broadcasterController.text,
          uid: 0,
          // هذا مهم للـ API integration
          liveId: _liveIdController.text,
          // معلومات إضافية
          thumbnailUrl: 'https://via.placeholder.com/300x200',
          isVerified: true,
          viewersCount: 125,
        ),
      ),
    );
  }
  void _openLiveStreamDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          channelName: _channelController.text,
          token: _tokenController.text,
          broadcasterName: _broadcasterController.text,
          uid: 0,
          // عدم تمرير liveId = استخدام البيانات التجريبية
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار البث المباشر'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إعدادات البث المباشر',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // معرف البث (للـ API)
            TextField(
              controller: _liveIdController,
              decoration: const InputDecoration(
                labelText: 'Live ID (للـ API)',
                hintText: 'live_123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.live_tv),
              ),
            ),
            const SizedBox(height: 16),
            // اسم القناة
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'live_123_1700000000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.video_call),
              ),
            ),
            const SizedBox(height: 16),
            // التوكن
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Agora Token',
                hintText: 'agora_token_here',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            // اسم المذيع
            TextField(
              controller: _broadcasterController,
              decoration: const InputDecoration(
                labelText: 'اسم المذيع',
                hintText: 'أحمد محمد',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 32),
            // أزرار الاختبار
            ElevatedButton.icon(
              onPressed: _openLiveStreamWithAPI,
              icon: const Icon(Icons.api),
              label: const Text('فتح مع API (التعليقات + الإحصائيات)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openLiveStreamDemo,
              icon: const Icon(Icons.preview),
              label: const Text('فتح تجريبي (بدون API)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            // معلومات مهمة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات مهمة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• الوضع الأول (مع API): سيستخدم تعليقات مباشرة وإحصائيات حقيقية\n'
                    '• الوضع التجريبي: سيستخدم بيانات تجريبية فقط\n'
                    '• تأكد من وجود backend API endpoints للتجربة الكاملة',
                    style: TextStyle(fontSize: 14),
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