import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/network/api_client.dart';
import '../../data/models/group_privacy.dart';
import '../../data/services/groups_api_service.dart';

/// صفحة إنشاء مجموعة جديدة
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late GroupsApiService _apiService;
  bool _isCreating = false;

  GroupPrivacy _selectedPrivacy = GroupPrivacy.public;
  int _selectedCategoryId = 1; // افتراضي

  @override
  void initState() {
    super.initState();
    _apiService = GroupsApiService(context.read<ApiClient>());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final result = await _apiService.createGroup(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        privacy: _selectedPrivacy.toServerString(),
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المجموعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // العودة مع إشارة للتحديث
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء المجموعة، حاول مرة أخرى'),
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
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء مجموعة'),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _createGroup,
              icon: const Icon(Iconsax.tick_circle),
              label: const Text('إنشاء'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // أيقونة وشعار
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.people,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // عنوان المجموعة
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'عنوان المجموعة *',
                hintText: 'مثال: مطوري Flutter في الإمارات',
                prefixIcon: const Icon(Iconsax.text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'العنوان مطلوب';
                }
                if (value.trim().length < 3) {
                  return 'العنوان يجب أن يكون 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // اسم المستخدم
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم *',
                hintText: 'مثال: flutter_devs_uae',
                prefixIcon: Icon(Iconsax.add),
                helperText: 'حروف إنجليزية وأرقام وشرطة سفلية فقط',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم المستخدم مطلوب';
                }
                if (value.trim().length < 3) {
                  return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return 'حروف إنجليزية وأرقام وشرطة سفلية فقط';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // الوصف
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'الوصف (اختياري)',
                hintText: 'اكتب وصف للمجموعة...',
                prefixIcon: const Icon(Iconsax.document_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),

            // الخصوصية
            Text('الخصوصية *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PrivacyOption(
                    icon: Iconsax.global,
                    title: 'عامة',
                    description: 'يمكن لأي شخص رؤية المجموعة والمنشورات',
                    value: GroupPrivacy.public,
                    groupValue: _selectedPrivacy,
                    onChanged: (value) {
                      setState(() => _selectedPrivacy = value!);
                    },
                  ),
                  const Divider(height: 1),
                  _PrivacyOption(
                    icon: Iconsax.lock,
                    title: 'مغلقة',
                    description:
                        'يمكن لأي شخص رؤية المجموعة، الأعضاء فقط يرون المنشورات',
                    value: GroupPrivacy.closed,
                    groupValue: _selectedPrivacy,
                    onChanged: (value) {
                      setState(() => _selectedPrivacy = value!);
                    },
                  ),
                  const Divider(height: 1),
                  _PrivacyOption(
                    icon: Iconsax.eye_slash,
                    title: 'سرية',
                    description:
                        'الأعضاء المعتمدون فقط يمكنهم رؤية المجموعة والمنشورات',
                    value: GroupPrivacy.secret,
                    groupValue: _selectedPrivacy,
                    onChanged: (value) {
                      setState(() => _selectedPrivacy = value!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // الفئة
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'الفئة *',
                prefixIcon: const Icon(Iconsax.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('تقنية')),
                DropdownMenuItem(value: 2, child: Text('رياضة')),
                DropdownMenuItem(value: 3, child: Text('تعليم')),
                DropdownMenuItem(value: 4, child: Text('ترفيه')),
                DropdownMenuItem(value: 5, child: Text('أخرى')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoryId = value ?? 1);
              },
            ),
            const SizedBox(height: 32),

            // زر الإنشاء
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createGroup,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.add_circle),
                label: Text(
                  _isCreating ? 'جاري الإنشاء...' : 'إنشاء المجموعة',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ملاحظة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.info_circle, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ستصبح مشرف المجموعة تلقائياً بعد إنشائها',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Privacy Option Widget =====================
class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final GroupPrivacy value;
  final GroupPrivacy groupValue;
  final ValueChanged<GroupPrivacy?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return RadioListTile<GroupPrivacy>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4, right: 28),
        child: Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
