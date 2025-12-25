import 'dart:convert';
import 'package:http/http.dart' as http;

/// سكريبت اختبار تتابع البث المباشر - نفس curl commands
class LiveStreamTestScript {
  static const String baseUrl = 'https://sngine.fluttercrafters.com/apis/php';
  static const String sessionCookie = 'YOUR_PHPSESSID_HERE'; // ضع session token هنا
  
  /// Test 1: إنشاء بث مباشر
  static Future<Map<String, dynamic>?> createLiveStream() async {
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/data/live/create'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'PHPSESSID=$sessionCookie',
        },
        body: jsonEncode({
          'title': 'تجربة بث',
          'description': 'بوست مباشر للاختبار',
          'tips_enabled': false,
          'for_subscriptions': false,
          'is_paid': false,
          'post_price': 0,
        }),
      );
      
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // التحقق من الرد المتوقع (البنية الجديدة المحدثة)
        if (data['status'] == 'success' && data['data'] != null) {
          
          // التحقق من وجود agora_token مباشرة
          if (data['data']['post'] != null && 
              data['data']['post']['agora_config'] != null) {
            final agoraConfig = data['data']['post']['agora_config'];
          }
          
          return data['data'];
        } else if (data['post_id'] != null) {
          return {'post_id': data['post_id'], 'backend_fixed': false};
        }
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }
  
  /// Test 2: طلب Agora Token
  static Future<Map<String, dynamic>?> getAgoraToken(int liveId) async {
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data/live/agora-token?live_id=$liveId&role=publisher'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'PHPSESSID=$sessionCookie',
        },
      );
      
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          return data['data'];
        }
      } else if (response.statusCode == 500) {
        return {'error': 'live_stream_not_found', 'live_id': liveId};
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }
  
  /// Test 3: إحصائيات البث (للتأكد)
  static Future<Map<String, dynamic>?> getLiveStats(int postId) async {
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data/live/stats?post_id=$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'PHPSESSID=$sessionCookie',
        },
      );
      
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }
  
  /// تشغيل التتابع الكامل
  static Future<void> runCompleteFlow() async {
    
    // Step 1: إنشاء البث
    final createData = await createLiveStream();
    if (createData == null) {
      return;
    }
    
    // التحقق إذا كان Backend تم إصلاحه
    if (createData['backend_fixed'] == false) {
      final postId = createData['post_id'];
      
      // محاولة استخدام post_id كـ live_id (سيفشل غالباً)
      await getAgoraToken(postId);
      await getLiveStats(postId);
      
    } else {
      // Backend تم إصلاحه - استخدام البيانات الصحيحة
      final liveId = createData['live_id'];
      final postId = createData['post_id'];
      
      // Step 2: طلب Agora Token
      final tokenData = await getAgoraToken(liveId);
      
      // Step 3: إحصائيات البث
      await getLiveStats(postId);
      
      if (tokenData != null && tokenData['error'] == null) {
      }
    }
    
  }
}

/// دالة للاختبار السريع
void main() async {
  
  await LiveStreamTestScript.runCompleteFlow();
}
