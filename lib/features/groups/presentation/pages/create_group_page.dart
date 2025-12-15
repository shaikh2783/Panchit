import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../application/bloc/groups_bloc.dart';
import '../../application/bloc/groups_events.dart';
import '../../application/bloc/groups_states.dart';
import '../../data/models/group.dart';
import 'group_page.dart';
/// صفحة إنشاء مجموعة جديدة
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}
class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  GroupPrivacy _selectedPrivacy = GroupPrivacy.public;
  GroupCategory? _selectedCategory;
  List<GroupCategory> _categories = [];
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  void _loadCategories() {
    context.read<GroupsBloc>().add(const LoadGroupCategoriesEvent());
  }
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('يرجى اختيار فئة المجموعة');
      return;
    }
    final groupsBloc = context.read<GroupsBloc>();
    groupsBloc.add(CreateGroupEvent(
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      privacy: _selectedPrivacy,
      categoryId: _selectedCategory!.categoryId,
    ));
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'إنشاء مجموعة',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Get.back(),
        ),
        actions: [
          BlocBuilder<GroupsBloc, GroupsState>(
            builder: (context, state) {
              final isLoading = state is GroupCreatingState;
              return TextButton(
                onPressed: isLoading ? null : _createGroup,
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.blue[300] : Theme.of(context).primaryColor,
                  disabledForegroundColor: isDark ? Colors.grey[600] : Colors.grey,
                ),
                child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'إنشاء',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<GroupsBloc, GroupsState>(
        listener: (context, state) {
          if (state is GroupCreatedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Get.back();
            // الانتقال إلى صفحة المجموعة الجديدة باستخدام ID فقط
            Get.to(() => GroupPage.byId(groupId: state.group.groupId));
          } else if (state is GroupActionErrorState && state.action == 'create') {
            _showError(state.message);
          } else if (state is GroupCategoriesLoadedState) {
            setState(() {
              _categories = state.categories;
              if (_categories.isNotEmpty && _selectedCategory == null) {
                _selectedCategory = _categories.first;
              }
            });
          }
        },
        child: Form(
          key: _formKey,
          child: Container(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              // معلومات أساسية
              _buildSectionHeader('المعلومات الأساسية'),
              const SizedBox(height: 16),
              // اسم المجموعة
              _buildTextField(
                controller: _nameController,
                label: 'اسم المجموعة *',
                hint: 'اكتب اسم فريد للمجموعة (بالإنجليزية)',
                icon: Iconsax.user_octagon,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'اسم المجموعة مطلوب';
                  }
                  if (value!.trim().length < 3) {
                    return 'اسم المجموعة يجب أن يكون 3 أحرف على الأقل';
                  }
                  // التحقق من أن الاسم يحتوي على أحرف إنجليزية فقط
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return 'اسم المجموعة يجب أن يحتوي على أحرف إنجليزية وأرقام فقط';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // عنوان المجموعة
              _buildTextField(
                controller: _titleController,
                label: 'عنوان المجموعة *',
                hint: 'العنوان الذي سيظهر للأعضاء',
                icon: Iconsax.text,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'عنوان المجموعة مطلوب';
                  }
                  if (value!.trim().length < 3) {
                    return 'عنوان المجموعة يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // وصف المجموعة
              _buildTextField(
                controller: _descriptionController,
                label: 'وصف المجموعة *',
                hint: 'اكتب وصفاً مفصلاً عن المجموعة',
                icon: Iconsax.document_text,
                maxLines: 4,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'وصف المجموعة مطلوب';
                  }
                  if (value!.trim().length < 10) {
                    return 'وصف المجموعة يجب أن يكون 10 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // إعدادات الخصوصية والفئة
              _buildSectionHeader('إعدادات المجموعة'),
              const SizedBox(height: 16),
              // فئة المجموعة
              _buildCategorySelector(),
              const SizedBox(height: 16),
              // مستوى الخصوصية
              _buildPrivacySelector(),
              const SizedBox(height: 32),
              // نصائح إنشاء المجموعة
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    ));
  }
  Widget _buildSectionHeader(String title) {
    final isDark = Get.isDarkMode;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isDark = Get.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          textDirection: maxLines > 1 ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon, 
              color: isDark ? Colors.grey[400] : Colors.grey[600], 
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.blue[300]! : Theme.of(context).primaryColor,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCategorySelector() {
    final isDark = Get.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'فئة المجموعة *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<GroupsBloc, GroupsState>(
          builder: (context, state) {
            if (state is GroupsLoadingState) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.blue[300]! : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري تحميل الفئات...',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (_categories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2, 
                      color: Colors.orange[600], 
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'لا توجد فئات متاحة',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownButtonFormField<GroupCategory>(
              initialValue: _selectedCategory,
              dropdownColor: isDark ? Colors.grey[850] : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'اختر فئة المجموعة',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                prefixIcon: Icon(
                  Iconsax.category_2, 
                  color: isDark ? Colors.grey[400] : Colors.grey[600], 
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.blue[300]! : Theme.of(context).primaryColor,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<GroupCategory>(
                  value: category,
                  child: Text(
                    category.categoryName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'يرجى اختيار فئة المجموعة';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
  Widget _buildPrivacySelector() {
    final isDark = Get.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مستوى الخصوصية *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            color: isDark ? Colors.grey[850] : Colors.grey[50],
          ),
          child: Column(
            children: [
              _buildPrivacyOption(
                privacy: GroupPrivacy.public,
                title: 'مجموعة عامة',
                subtitle: 'يمكن لأي شخص رؤية المجموعة والمحتوى والأعضاء',
                icon: Iconsax.global,
                iconColor: Colors.green,
              ),
              _buildDivider(),
              _buildPrivacyOption(
                privacy: GroupPrivacy.closed,
                title: 'مجموعة مغلقة',
                subtitle: 'يمكن لأي شخص رؤية المجموعة لكن المحتوى للأعضاء فقط',
                icon: Iconsax.lock,
                iconColor: Colors.orange,
              ),
              _buildDivider(),
              _buildPrivacyOption(
                privacy: GroupPrivacy.secret,
                title: 'مجموعة سرية',
                subtitle: 'لا يمكن العثور على المجموعة إلا عبر الدعوة',
                icon: Iconsax.eye_slash,
                iconColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPrivacyOption({
    required GroupPrivacy privacy,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedPrivacy == privacy;
    final isDark = Get.isDarkMode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPrivacy = privacy;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark 
                  ? Colors.blue[800]!.withValues(alpha: 0.3)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1))
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? (isDark ? Colors.blue[300] : Theme.of(context).primaryColor)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.tick_circle,
                color: isDark ? Colors.blue[300] : Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDivider() {
    final isDark = Get.isDarkMode;
    return Container(
      height: 1,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
  Widget _buildTipsSection() {
    final isDark = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.lamp_on, 
                color: isDark ? Colors.blue[300] : Colors.blue[600], 
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح لإنشاء مجموعة ناجحة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.blue[300] : Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('اختر اسماً فريداً وسهل التذكر للمجموعة'),
          _buildTip('اكتب وصفاً واضحاً يشرح هدف المجموعة'),
          _buildTip('حدد مستوى الخصوصية المناسب لنوع المجموعة'),
          _buildTip('اختر الفئة المناسبة لسهولة اكتشاف المجموعة'),
        ],
      ),
    );
  }
  Widget _buildTip(String text) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.blue[300] : Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blue[200] : Colors.blue[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}