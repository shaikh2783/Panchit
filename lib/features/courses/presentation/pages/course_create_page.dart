import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/config/app_config.dart';

/// صفحة إنشاء دورة جديدة
class CourseCreatePage extends StatefulWidget {
  const CourseCreatePage({super.key});

  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFree = true;
  bool _isAvailable = true;
  bool _submitting = false;
  int _feesCurrencyId = 1; // Default to currency ID 1 (usually main currency)
  int _categoryId = 1; // Default category ID

  String? _coverSource;
  String? _coverUrl;
  bool _uploadingCover = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _uploadingCover = true;
        _uploadProgress = 0;
      });

      final client = context.read<ApiClient>();
      final response = await client.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: picked.path,
        fileFieldName: 'file',
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() => _uploadProgress = total == 0 ? 0 : sent / total);
        },
      );

      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _coverSource = data['source'];
          _coverUrl = (data['url'] ?? '') as String?;
        });
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'course_cover_upload_fail'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  void _removeCover() {
    setState(() {
      _coverSource = null;
      _coverUrl = null;
      _uploadProgress = 0;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? tomorrow)
          : (_endDate ?? tomorrow.add(const Duration(days: 30))),
      firstDate: isStartDate ? tomorrow : (_startDate ?? tomorrow),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isFree && _feesCtrl.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'course_fees_required'.tr);
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = context.read<ApiClient>();
      
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'fees': _isFree ? '0' : _feesCtrl.text.trim(),
        'fees_currency': _feesCurrencyId.toString(),
        'category': _categoryId.toString(),
        'available': _isAvailable ? '1' : '0',
        if (_startDate != null) 'start_date': _startDate!.toIso8601String().split('T')[0],
        if (_endDate != null) 'end_date': _endDate!.toIso8601String().split('T')[0],
        if (_coverSource != null) 'cover_image': _coverSource,
      };

      final response = await client.post(configCfgP('courses_create'), body: body);

      if (response['api_status'] == 200 || response['status'] == 'success') {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('course_create_success'.tr)),
          );
        }
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'course_create_failed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final mediaResolver = context.read<AppConfig>().mediaAsset;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'course_create_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            _buildCoverSection(isDark, mediaResolver),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'course_title_label'.tr,
                hintText: 'course_title_hint'.tr,
                prefixIcon: const Icon(Iconsax.book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'field_required'.tr : null,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: 'course_description_label'.tr,
                hintText: 'course_description_hint'.tr,
                prefixIcon: const Icon(Iconsax.document_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'field_required'.tr : null,
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: 'course_location_label'.tr,
                hintText: 'course_location_hint'.tr,
                prefixIcon: const Icon(Iconsax.location),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'field_required'.tr : null,
            ),
            const SizedBox(height: 16),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: 'course_start_date'.tr,
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: 'course_end_date'.tr,
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Free Course Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.money,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'course_free_toggle'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isFree,
                    onChanged: (v) => setState(() => _isFree = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fees (if not free)
            if (!_isFree)
              TextFormField(
                controller: _feesCtrl,
                decoration: InputDecoration(
                  labelText: 'course_fees_label'.tr,
                  hintText: 'course_fees_hint'.tr,
                  prefixIcon: const Icon(Iconsax.money_recive),
                  suffixText: 'course_currency_sar'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_isFree && (v?.trim().isEmpty ?? true)) return 'field_required'.tr;
                  return null;
                },
              ),
            if (!_isFree) const SizedBox(height: 16),

            // Available Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.status,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'course_available_title'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _isAvailable
                              ? 'course_available_open'.tr
                              : 'course_available_closed'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'course_create_button'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSection(bool isDark, Uri Function(String) mediaResolver) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Iconsax.gallery,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'course_cover_label'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (_coverUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: mediaResolver(_coverUrl!).toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _removeCover,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: _uploadingCover ? null : _pickCover,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _uploadingCover
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.camera,
                                size: 48,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'course_cover_tap'.tr,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isDark = Get.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                    date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'course_select_date'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date != null
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
