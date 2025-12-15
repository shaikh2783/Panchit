import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../data/api_service/live_stream_api_service.dart';
import '../presentation/pages/live_stream_viewer_page.dart';
/// صفحة لإنشاء بث مباشر جديد للاختبار
class CreateLiveTestPage extends StatefulWidget {
  const CreateLiveTestPage({Key? key}) : super(key: key);
  @override
  State<CreateLiveTestPage> createState() => _CreateLiveTestPageState();
}
class _CreateLiveTestPageState extends State<CreateLiveTestPage> {
  late LiveStreamApiService _liveApiService;
  bool _isCreating = false;
  String? _createdLiveId;
  String? _channelName;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _liveApiService = LiveStreamApiService(context.read<ApiClient>());
  }
  Future<void> _createNewLiveStream() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });
    try {
      final result = await _liveApiService.createLiveStream(
        agoraChannelName: 'test_live_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['status'] == 'success') {
        final data = result['data'];
        setState(() {
          _createdLiveId = data['post_id']?.toString();
          _channelName = data['channel_name'];
          _isCreating = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'فشل في إنشاء البث';
          _isCreating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في إنشاء البث: $e';
        _isCreating = false;
      });
    }
  }
  void _joinCreatedLiveStream() {
    if (_createdLiveId == null || _channelName == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerPage(
          channelName: _channelName!,
          token: '', // سيتم جلبه من API
          broadcasterName: 'مختبر البث',
          postId: _createdLiveId, // تمرير post_id كـ postId
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء بث مباشر للاختبار'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختبار نظام البث المباشر',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'هذه الصفحة تنشئ بث مباشر جديد لاختبار زيادة عدد المشاهدين',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // زر إنشاء بث جديد
            ElevatedButton(
              onPressed: _isCreating ? null : _createNewLiveStream,
              child: _isCreating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('جاري إنشاء البث...'),
                      ],
                    )
                  : const Text('إنشاء بث مباشر جديد'),
            ),
            const SizedBox(height: 20),
            // عرض النتيجة
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_createdLiveId != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ تم إنشاء البث بنجاح!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('معرف البث: $_createdLiveId'),
                    Text('اسم القناة: $_channelName'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _joinCreatedLiveStream,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'الانضمام للبث الجديد',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• بعد إنشاء البث، انضم إليه لاختبار زيادة عدد المشاهدين'),
                  Text('• يجب أن يزداد live_count من 0 إلى 1 عند الانضمام'),
                  Text('• يمكنك إضافة تعليقات واختبار النظام كاملاً'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}