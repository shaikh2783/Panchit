import 'package:flutter/material.dart';
import '../features/profile/presentation/pages/profile_page.dart';

class ProfileWithFriendButtonExample extends StatelessWidget {
  const ProfileWithFriendButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile with Friend Button Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Text(
              'يظهر زر إضافة الصديق في الملف الشخصي\n'
              'سيظهر الزر المناسب بناءً على حالة العلاقة:\n'
              '• إضافة صديق - للمستخدمين الجدد\n'
              '• طلب مرسل - بعد إرسال طلب صداقة\n'
              '• قبول الطلب - عند وجود طلب واردة\n'
              '• أصدقاء - عند تأكيد الصداقة\n'
              '• تحرير الملف الشخصي - للمستخدم الحالي',
              style: TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ProfilePage(
              // يمكنك تمرير userId أو username للاختبار
              userId: 123, // مستخدم وهمي للاختبار
            ),
          ),
        ],
      ),
    );
  }
}