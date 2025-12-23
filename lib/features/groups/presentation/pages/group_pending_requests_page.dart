import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/network/api_client.dart';
import '../../data/models/group.dart';
import '../../data/models/group_member_request.dart';
import '../../data/services/groups_api_service.dart';

/// صفحة إدارة طلبات الانضمام للمجموعة (للمشرف فقط)
class GroupPendingRequestsPage extends StatefulWidget {
  const GroupPendingRequestsPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupPendingRequestsPage> createState() =>
      _GroupPendingRequestsPageState();
}

class _GroupPendingRequestsPageState extends State<GroupPendingRequestsPage> {
  late GroupsApiService _apiService;
  List<GroupMemberRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _processingUsers = {}; // تتبع المستخدمين قيد المعالجة

  @override
  void initState() {
    super.initState();
    _apiService = GroupsApiService(context.read<ApiClient>());
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _apiService.getPendingRequests(
        widget.group.groupId,
      );

      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل الطلبات: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptRequest(GroupMemberRequest request) async {
    setState(() => _processingUsers.add(request.userId));

    try {
      final success = await _apiService.acceptMemberRequest(
        widget.group.groupId,
        request.userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قبول ${request.fullname} في المجموعة'),
            backgroundColor: Colors.green,
          ),
        );

        // إزالة الطلب من القائمة
        setState(() {
          _requests.removeWhere((r) => r.userId == request.userId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل قبول الطلب، حاول مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _processingUsers.remove(request.userId));
      }
    }
  }

  Future<void> _declineRequest(GroupMemberRequest request) async {
    // تأكيد الرفض
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Text('هل تريد رفض طلب ${request.fullname} للانضمام للمجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingUsers.add(request.userId));

    try {
      final success = await _apiService.declineMemberRequest(
        widget.group.groupId,
        request.userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض طلب ${request.fullname}'),
            backgroundColor: Colors.orange,
          ),
        );

        // إزالة الطلب من القائمة
        setState(() {
          _requests.removeWhere((r) => r.userId == request.userId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفض الطلب، حاول مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _processingUsers.remove(request.userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الانضمام'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadRequests,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(isDark, mediaAsset),
    );
  }

  Widget _buildBody(bool isDark, Uri Function(String) mediaAsset) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.info_circle, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Iconsax.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.task_square, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات معلقة',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الطلبات تمت معالجتها',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _requests[index];
          final isProcessing = _processingUsers.contains(request.userId);

          return Card(
            elevation: 0,
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات المستخدم
                  Row(
                    children: [
                      // صورة المستخدم
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: request.picture.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  mediaAsset(request.picture).toString(),
                                )
                              : null,
                          child: request.picture.isEmpty
                              ? const Icon(Iconsax.user, size: 28)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // الاسم واليوزر
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    request.fullname,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (request.verified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Iconsax.verify,
                                    size: 18,
                                    color: Colors.lightBlueAccent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${request.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // تاريخ الطلب
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Iconsax.clock, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'تاريخ الطلب: ${request.requestDate}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      // زر القبول
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _acceptRequest(request),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Iconsax.tick_circle, size: 20),
                          label: const Text('قبول'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // زر الرفض
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _declineRequest(request),
                          icon: const Icon(Iconsax.close_circle, size: 20),
                          label: const Text('رفض'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
          );
        },
      ),
    );
  }
}
