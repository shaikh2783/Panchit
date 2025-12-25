import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/config/app_config.dart';

/// صفحة عرض المتقدمين للدورة
class CourseCandidatesPage extends StatefulWidget {
  const CourseCandidatesPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  State<CourseCandidatesPage> createState() => _CourseCandidatesPageState();
}

class _CourseCandidatesPageState extends State<CourseCandidatesPage> {
  List<CourseCandidate> _candidates = [];
  bool _loading = false;
  String? _error;
  int _offset = 0;
  bool _hasMore = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadCandidates();
    }
  }

  Future<void> _loadCandidates({bool refresh = false}) async {
    
    if (refresh) {
      setState(() {
        _offset = 0;
        _hasMore = true;
        _candidates.clear();
        _loading = true;
      });
    } else {
      // Don't load if already loading or no more data
      if (_loading) {
        return;
      }
      if (!_hasMore) {
        return;
      }
      setState(() => _loading = true);
    }

    try {
      final client = context.read<ApiClient>();
      
      final uri = '${configCfgP('courses_base')}/candidates?offset=$_offset';
      
      
      final response = await client.post(
        uri,
        body: {'course_id': widget.courseId},
      );


      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final candidatesList = (data['candidates'] as List? ?? [])
            .map((json) => CourseCandidate.fromJson(json as Map<String, dynamic>))
            .toList();


        setState(() {
          _candidates.addAll(candidatesList);
          _offset += candidatesList.length;
          _hasMore = candidatesList.length >= 20; // Assuming 20 per page
          _error = null;
        });
      } else {
        final errorMsg = response['message'] ?? 'فشل تحميل المتقدمين';
        setState(() => _error = errorMsg);
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء تحميل المتقدمين');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final appConfig = context.read<AppConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('course_candidates_title'.tr),
            Text(
              widget.courseTitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          if (_candidates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_candidates.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading && _candidates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _candidates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _loadCandidates(refresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _candidates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.profile_2user,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد متقدمين حتى الآن',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadCandidates(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _candidates.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _candidates.length) {
                            if (!_loading) {
                              _loadCandidates();
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final candidate = _candidates[index];
                          return _CandidateCard(
                            candidate: candidate,
                            isDark: isDark,
                            appConfig: appConfig,
                            onCallPhone: () => _makePhoneCall(candidate.phone),
                            onSendEmail: () => _sendEmail(candidate.email),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.isDark,
    required this.appConfig,
    required this.onCallPhone,
    required this.onSendEmail,
  });

  final CourseCandidate candidate;
  final bool isDark;
  final AppConfig appConfig;
  final VoidCallback onCallPhone;
  final VoidCallback onSendEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: candidate.userPicture != null
                      ? CachedNetworkImageProvider(
                          candidate.userPicture!.startsWith('http')
                              ? candidate.userPicture!
                              : appConfig.mediaAsset(candidate.userPicture!).toString(),
                        )
                      : null,
                  child: candidate.userPicture == null
                      ? Icon(
                          Iconsax.user,
                          size: 30,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Name and verified badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              candidate.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (candidate.userVerified)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                            ),
                        ],
                      ),
                      if (candidate.userName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${candidate.userName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Applied time
                Text(
                  _formatDate(candidate.appliedTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Contact Info
            _InfoRow(
              icon: Iconsax.location,
              label: 'الموقع',
              value: candidate.location,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            
            _InfoRow(
              icon: Iconsax.call,
              label: 'الهاتف',
              value: candidate.phone,
              isDark: isDark,
              onTap: onCallPhone,
            ),
            const SizedBox(height: 12),
            
            _InfoRow(
              icon: Iconsax.sms,
              label: 'البريد',
              value: candidate.email,
              isDark: isDark,
              onTap: onSendEmail,
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCallPhone,
                    icon: const Icon(Iconsax.call, size: 18),
                    label: const Text('اتصال'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSendEmail,
                    icon: const Icon(Iconsax.sms, size: 18),
                    label: const Text('بريد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} د';
      }
      return 'منذ ${diff.inHours} س';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
          ],
        ),
      ),
    );
  }
}

/// Model class for course candidate
class CourseCandidate {
  const CourseCandidate({
    required this.applicationId,
    required this.postId,
    required this.userId,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
    required this.appliedTime,
    this.userName,
    this.userFirstname,
    this.userLastname,
    this.userGender,
    this.userPicture,
    this.userSubscribed = false,
    this.userVerified = false,
  });

  final int applicationId;
  final int postId;
  final int userId;
  final String name;
  final String location;
  final String phone;
  final String email;
  final DateTime appliedTime;
  final String? userName;
  final String? userFirstname;
  final String? userLastname;
  final String? userGender;
  final String? userPicture;
  final bool userSubscribed;
  final bool userVerified;

  factory CourseCandidate.fromJson(Map<String, dynamic> json) {
    return CourseCandidate(
      applicationId: int.parse(json['application_id']?.toString() ?? '0'),
      postId: int.parse(json['post_id']?.toString() ?? '0'),
      userId: int.parse(json['user_id']?.toString() ?? '0'),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      appliedTime: DateTime.tryParse(json['applied_time'] ?? '') ?? DateTime.now(),
      userName: json['user_name'],
      userFirstname: json['user_firstname'],
      userLastname: json['user_lastname'],
      userGender: json['user_gender'],
      userPicture: json['user_picture'],
      userSubscribed: json['user_subscribed']?.toString() == '1',
      userVerified: json['user_verified']?.toString() == '1',
    );
  }
}
