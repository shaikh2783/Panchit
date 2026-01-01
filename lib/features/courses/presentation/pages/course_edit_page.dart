import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/config/app_config.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/data/models/post_course.dart';

/// صفحة تعديل دورة موجودة
class CourseEditPage extends StatefulWidget {
  const CourseEditPage({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  State<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends State<CourseEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _feesCtrl;

  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isFree;
  late bool _isAvailable;
  bool _submitting = false;
  int _feesCurrencyId = 1;
  int _categoryId = 1;

  String? _coverSource;
  String? _coverUrl;
  bool _uploadingCover = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    
    final course = widget.post.course!;
    
    // Initialize with existing course data
    _titleCtrl = TextEditingController(text: course.title);
    _descriptionCtrl = TextEditingController(text: widget.post.text);
    _locationCtrl = TextEditingController(text: course.location ?? '');
    _feesCtrl = TextEditingController(
      text: course.fees != null && course.fees != '0' ? course.fees! : '',
    );
    
    _isFree = course.isFree;
    _isAvailable = course.available;
    _startDate = course.startDate != null ? DateTime.tryParse(course.startDate!) : null;
    _endDate = course.endDate != null ? DateTime.tryParse(course.endDate!) : null;
    _coverSource = course.coverImage;
    _coverUrl = course.coverImage;
    _feesCurrencyId = course.feesCurrency?.currencyId != null 
        ? int.tryParse(course.feesCurrency!.currencyId.toString()) ?? 1 
        : 1;
  }

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
        if (mounted) {
          Get.snackbar('خطأ', response['message'] ?? 'فشل رفع الصورة');
        }
      }
    } catch (e) {

      if (mounted) {
        Get.snackbar('خطأ', 'فشل رفع الصورة');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingCover = false;
          _uploadProgress = 0;
        });
      }
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

    // Validate description length
    final description = _descriptionCtrl.text.trim();
    if (description.length < 32) {
      Get.snackbar(
        'خطأ',
        'الوصف قصير جداً. يجب أن يكون ${32 - description.length} حرف إضافي على الأقل (الحد الأدنى 32 حرف)',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (description.length > 1000) {
      Get.snackbar(
        'خطأ',
        'الوصف طويل جداً. يجب حذف ${description.length - 1000} حرف (الحد الأقصى 1000 حرف)',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (!_isFree && _feesCtrl.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رسوم الدورة');
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = context.read<ApiClient>();
      
      final body = <String, dynamic>{
        'post_id': widget.post.id,
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

      final response = await client.post(
        configCfgP('courses_edit'),
        body: body,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        Get.snackbar(
          'نجح',
          'تم تعديل الدورة بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.pop(context, true);
      } else {
        Get.snackbar(
          'خطأ',
          response['message'] ?? 'فشل تعديل الدورة',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {

      if (mounted) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء تعديل الدورة',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final appConfig = context.read<AppConfig>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الدورة'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image Section
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  if (_coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _coverUrl!.startsWith('http')
                            ? _coverUrl!
                            : appConfig.mediaAsset(_coverUrl!).toString(),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Iconsax.gallery,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  
                  if (_uploadingCover)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (_coverUrl != null)
                          IconButton(
                            onPressed: _removeCover,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _uploadingCover ? null : _pickCover,
                          icon: const Icon(Iconsax.camera),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'عنوان الدورة *',
                hintText: 'أدخل عنوان الدورة',
                prefixIcon: const Icon(Iconsax.book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: 'الوصف *',
                hintText: 'أدخل وصف الدورة',
                prefixIcon: const Icon(Iconsax.note_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 8,
              maxLength: 1000,
              keyboardType: TextInputType.multiline,
              validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 16),

            // Location Field
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: 'الموقع *',
                hintText: 'أدخل موقع الدورة',
                prefixIcon: const Icon(Iconsax.location),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Free/Paid Switch
            SwitchListTile(
              title: const Text('دورة مجانية'),
              value: _isFree,
              onChanged: (val) => setState(() => _isFree = val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),

            if (!_isFree) ...[
              const SizedBox(height: 16),
              
              // Fees Field
              TextFormField(
                controller: _feesCtrl,
                decoration: InputDecoration(
                  labelText: 'الرسوم *',
                  hintText: 'أدخل رسوم الدورة',
                  prefixIcon: const Icon(Iconsax.dollar_circle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => !_isFree && (v?.trim().isEmpty ?? true)
                    ? 'مطلوب'
                    : null,
              ),
            ],

            const SizedBox(height: 16),

            // Available Switch
            SwitchListTile(
              title: const Text('متاحة للتسجيل'),
              value: _isAvailable,
              onChanged: (val) => setState(() => _isAvailable = val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Iconsax.calendar),
                    label: Text(
                      _startDate == null
                          ? 'تاريخ البدء'
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Iconsax.calendar),
                    label: Text(
                      _endDate == null
                          ? 'تاريخ الانتهاء'
                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

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
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
