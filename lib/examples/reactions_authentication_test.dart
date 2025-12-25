import 'package:flutter/material.dart';
import 'package:snginepro/core/services/reactions_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/config/app_config.dart';

/// مثال سريع لاختبار إصلاح مشكلة Authentication
/// 
/// الاستخدام:
/// ```dart
/// final tester = ReactionsAuthenticationTester();
/// await tester.testReactionsApi();
/// ```
class ReactionsAuthenticationTester {
  
  /// اختبار استدعاء API التفاعلات مع الإصلاح الجديد
  Future<void> testReactionsApi() async {
    try {
      
      // إنشاء API Client بدون تسجيل دخول
      final apiClient = ApiClient(config: appConfig);
      // لا نضع auth token عمدًا لاختبار public endpoint
      // apiClient.updateAuthToken(null);
      
      final reactionsService = ReactionsApiService(apiClient: apiClient);
      
      final reactions = await reactionsService.fetchReactions();
      
      if (reactions.isNotEmpty) {
        for (final reaction in reactions) {
        }
      } else {
      }
      
    } catch (e) {
      if (e.toString().contains('You are not logged in')) {
      } else {
      }
    }
  }
  
  /// اختبار مقارنة بين endpoint قديم وجديد
  Future<void> compareEndpoints() async {
    
    try {
      final apiClient = ApiClient(config: appConfig);
      
      // اختبار بدون تسجيل دخول
      final reactionsService = ReactionsApiService(apiClient: apiClient);
      final publicReactions = await reactionsService.fetchReactions();
      
      // اختبار مع تسجيل دخول (إذا متوفر)
      // للاختبار فقط - استبدل بـ token حقيقي
      apiClient.updateAuthToken('test-token-123');
      
      try {
        // استدعاء endpoint القديم للمقارنة
        final response = await apiClient.get('/data/reactions');
      } catch (e) {
      }
      
    } catch (e) {
    }
  }
}

/// Widget لاختبار التفاعلات في التطبيق
class ReactionsTestPage extends StatefulWidget {
  const ReactionsTestPage({super.key});

  @override
  State<ReactionsTestPage> createState() => _ReactionsTestPageState();
}

class _ReactionsTestPageState extends State<ReactionsTestPage> {
  String _testResult = 'لم يتم الاختبار بعد';
  bool _isLoading = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري الاختبار...';
    });

    try {
      final tester = ReactionsAuthenticationTester();
      await tester.testReactionsApi();
      
      setState(() {
        _testResult = 'تم الاختبار بنجاح! تحقق من Console للتفاصيل';
      });
    } catch (e) {
      setState(() {
        _testResult = 'فشل الاختبار: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار التفاعلات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختبار إصلاح مشكلة Authentication للتفاعلات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('تشغيل الاختبار'),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'تعليمات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. اضغط "تشغيل الاختبار"\n'
              '2. راقب Console للتفاصيل\n'
              '3. إذا نجح - لن تظهر رسالة "You are not logged in"\n'
              '4. إذا فشل - تحقق من إعدادات Backend',
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function للوصول السريع
void showReactionsTest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ReactionsTestPage(),
    ),
  );
}
