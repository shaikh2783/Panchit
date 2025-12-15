import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/friends/data/services/friends_api_service.dart';
import '../core/network/api_client.dart';
class FriendsSystemTestPage extends StatefulWidget {
  const FriendsSystemTestPage({super.key});
  @override
  State<FriendsSystemTestPage> createState() => _FriendsSystemTestPageState();
}
class _FriendsSystemTestPageState extends State<FriendsSystemTestPage> {
  late FriendsApiService _friendsService;
  List<Map<String, dynamic>> _friendRequests = [];
  Map<String, dynamic>? _relationshipStatus;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _friendsService = FriendsApiService(apiClient);
  }
  Future<void> _testSendFriendRequest() async {
    setState(() => _isLoading = true);
    final result = await _friendsService.sendFriendRequest(123);
    setState(() => _isLoading = false);
    _showResult('إرسال طلب الصداقة', result.message, result.success);
  }
  Future<void> _testFollowUser() async {
    setState(() => _isLoading = true);
    final result = await _friendsService.followUser(123);
    setState(() => _isLoading = false);
    _showResult('متابعة المستخدم', result.message, result.success);
  }
  Future<void> _testGetFriendRequests() async {
    setState(() => _isLoading = true);
    final requests = await _friendsService.getFriendRequests();
    setState(() {
      _friendRequests = requests;
      _isLoading = false;
    });
    _showResult('جلب طلبات الصداقة', 'تم جلب ${requests.length} طلب', true);
  }
  Future<void> _testGetRelationshipStatus() async {
    setState(() => _isLoading = true);
    final status = await _friendsService.getUserRelationshipStatus(123);
    setState(() {
      _relationshipStatus = status;
      _isLoading = false;
    });
    if (status != null) {
      final isLoggedIn = status['viewer_logged_in'] ?? false;
      _showResult('حالة العلاقة', 'مسجل دخول: $isLoggedIn', true);
    } else {
      _showResult('حالة العلاقة', 'فشل في جلب البيانات', false);
    }
  }
  void _showResult(String title, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام الأصدقاء والمتابعة'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات النظام
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظام الأصدقاء والمتابعة المُحدث',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ تم التحديث حسب API الجديد'),
                    const Text('✅ دعم الزوار والمسجلين'),
                    const Text('✅ خدمة موحدة للأصدقاء والمتابعة'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // أزرار الاختبار
            Text(
              'اختبار الوظائف:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSendFriendRequest,
              icon: const Icon(Icons.person_add),
              label: const Text('اختبار إرسال طلب صداقة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFollowUser,
              icon: const Icon(Icons.notifications),
              label: const Text('اختبار متابعة مستخدم'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetFriendRequests,
              icon: const Icon(Icons.inbox),
              label: const Text('جلب طلبات الصداقة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetRelationshipStatus,
              icon: const Icon(Icons.info),
              label: const Text('🌍 اختبار API عام - حالة العلاقة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            if (_isLoading) 
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 20),
            // عرض النتائج
            if (_friendRequests.isNotEmpty) ...[
              Text(
                'طلبات الصداقة (${_friendRequests.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _friendRequests.length,
                  itemBuilder: (context, index) {
                    final request = _friendRequests[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(request['user_firstname'] ?? 'Unknown'),
                      subtitle: Text('@${request['user_name'] ?? 'unknown'}'),
                      trailing: Text('ID: ${request['user_id']}'),
                    );
                  },
                ),
              ),
            ],
            if (_relationshipStatus != null) ...[
              const SizedBox(height: 10),
              Text(
                'معلومات العلاقة:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مسجل دخول: ${_relationshipStatus!['viewer_logged_in']}'),
                      if (_relationshipStatus!['relationship'] != null) ...[
                        const SizedBox(height: 4),
                        Text('أصدقاء: ${_relationshipStatus!['relationship']['we_friends']}'),
                        Text('أتابع: ${_relationshipStatus!['relationship']['i_follow']}'),
                        Text('أرسل طلب: ${_relationshipStatus!['relationship']['i_request']}'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}