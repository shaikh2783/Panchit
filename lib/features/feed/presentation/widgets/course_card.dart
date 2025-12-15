import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../data/models/post.dart';
import '../../data/models/post_course.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../courses/data/services/courses_api_service.dart';
import '../../../courses/presentation/pages/course_edit_page.dart';
import '../../../courses/presentation/pages/course_candidates_page.dart';
import '../pages/post_detail_page.dart';
import '../../../../core/network/api_client.dart';
/// Widget to display course information in a post
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.post,
    required this.mediaResolver,
  });
  final Post post;
  final Uri Function(String) mediaResolver;
  @override
  Widget build(BuildContext context) {
    final course = post.course;
    if (course == null) return const SizedBox.shrink();
    final isDark = Get.isDarkMode;
    // Check if current user owns this course
    final auth = context.watch<AuthNotifier>();
    final currentUserId = auth.currentUser?['user_id']?.toString();
    final isOwner = currentUserId != null && post.authorId == currentUserId;
    // Debug: Check ownership
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Cover Image
          if (course.coverImage != null && course.coverImage!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: mediaResolver(course.coverImage!).toString(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Iconsax.book,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          // Course Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Location
                if (course.location != null && course.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            course.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Date Range
                if (course.startDate != null || course.endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDateRange(course.startDate, course.endDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Price
                Row(
                  children: [
                    Icon(
                      Iconsax.money,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    if (course.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'مجاني',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      )
                    else
                      Text(
                        _formatPrice(course),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    const Spacer(),
                    // Status Badge
                    _buildStatusBadge(course),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    // Show "View Candidates" if user owns the course
                    if (isOwner) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle view candidates
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseCandidatesPage(
                                  courseId: post.id.toString(),
                                  courseTitle: course.title,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.people, size: 18),
                          label: Text('المتقدمين (${course.candidatesCount})'),
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
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          // Handle edit course
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseEditPage(post: post),
                            ),
                          );
                          // If course was updated, you might want to refresh the list
                          if (result == true) {
                            // Trigger refresh if needed
                          }
                        },
                        icon: const Icon(Iconsax.edit, size: 18),
                        label: const Text('تعديل'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Show enrollment and details for non-owners
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: course.available ? () async {
                            // Handle enrollment - show dialog to collect user info
                            final auth = context.read<AuthNotifier>();
                            final currentUser = auth.currentUser;
                            if (currentUser == null) {
                              Get.snackbar(
                                'خطأ',
                                'يجب تسجيل الدخول أولاً',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            // Pre-fill data from user profile
                            final userName = '${currentUser['user_firstname'] ?? ''} ${currentUser['user_lastname'] ?? ''}'.trim();
                            final userEmail = currentUser['user_email']?.toString().trim() ?? '';
                            // Show dialog to collect enrollment data
                            final formKey = GlobalKey<FormState>();
                            final nameCtrl = TextEditingController(text: userName);
                            final locationCtrl = TextEditingController(text: currentUser['user_current_city']?.toString().trim() ?? '');
                            final phoneCtrl = TextEditingController(text: currentUser['user_phone']?.toString().trim() ?? '');
                            final emailCtrl = TextEditingController(text: userEmail);
                            final confirmed = await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text('التسجيل في الدورة'),
                                content: SingleChildScrollView(
                                  child: Form(
                                    key: formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: nameCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'الاسم الكامل *',
                                            prefixIcon: Icon(Iconsax.user),
                                          ),
                                          validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: locationCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'الموقع *',
                                            prefixIcon: Icon(Iconsax.location),
                                            hintText: 'مثال: الرياض، السعودية',
                                          ),
                                          validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: phoneCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'رقم الهاتف *',
                                            prefixIcon: Icon(Iconsax.call),
                                            hintText: 'مثال: +966501234567',
                                          ),
                                          keyboardType: TextInputType.phone,
                                          validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: emailCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'البريد الإلكتروني *',
                                            prefixIcon: Icon(Iconsax.sms),
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (formKey.currentState?.validate() ?? false) {
                                        Get.back(result: true);
                                      }
                                    },
                                    child: const Text('تسجيل'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            final apiClient = context.read<ApiClient>();
                            final service = CoursesApiService(apiClient);
                            Get.dialog(
                              const Center(child: CircularProgressIndicator()),
                              barrierDismissible: false,
                            );
                            final result = await service.enrollInCourse(
                              post.id.toString(),
                              name: nameCtrl.text.trim(),
                              location: locationCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                            );
                            Get.back(); // Close loading dialog
                            if (result.success) {
                              Get.snackbar(
                                'نجح',
                                result.message,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar(
                                'خطأ',
                                result.message,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          } : null,
                          icon: const Icon(Iconsax.user_add, size: 18),
                          label: Text(
                            course.available ? 'التسجيل' : 'مغلق',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: course.available 
                                ? Colors.blue 
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to post details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(postId: post.id),
                            ),
                          );
                        },
                        icon: const Icon(Iconsax.eye, size: 18),
                        label: const Text('التفاصيل'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Candidates Count (only show for non-owners)
                if (!isOwner && course.candidatesCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.candidatesCount} متقدم',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusBadge(PostCourse course) {
    String text;
    Color color;
    if (!course.available) {
      text = 'مغلق';
      color = Colors.grey;
    } else if (course.hasEnded) {
      text = 'انتهى';
      color = Colors.red;
    } else if (course.isOngoing) {
      text = 'جاري';
      color = Colors.orange;
    } else if (course.hasStarted) {
      text = 'بدأ';
      color = Colors.blue;
    } else {
      text = 'قريباً';
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  String _formatPrice(PostCourse course) {
    if (course.fees == null || course.fees!.isEmpty) return 'مجاني';
    final currency = course.feesCurrency;
    if (currency == null) return course.fees!;
    if (currency.dir == 'left') {
      return '${currency.symbol}${course.fees}';
    } else {
      return '${course.fees} ${currency.symbol}';
    }
  }
  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null && endDate == null) return 'غير محدد';
    try {
      if (startDate != null && endDate != null) {
        final start = DateTime.parse(startDate);
        final end = DateTime.parse(endDate);
        return '${_formatDate(start)} - ${_formatDate(end)}';
      } else if (startDate != null) {
        final start = DateTime.parse(startDate);
        return 'يبدأ في ${_formatDate(start)}';
      } else if (endDate != null) {
        final end = DateTime.parse(endDate);
        return 'ينتهي في ${_formatDate(end)}';
      }
    } catch (e) {
      // If parsing fails, return raw dates
      if (startDate != null && endDate != null) {
        return '$startDate - $endDate';
      } else if (startDate != null) {
        return 'يبدأ في $startDate';
      } else if (endDate != null) {
        return 'ينتهي في $endDate';
      }
    }
    return 'غير محدد';
  }
  String _formatDate(DateTime date) {
    // Simple date formatting without intl
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
