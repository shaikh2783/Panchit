import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/config/app_config.dart';
import '../../data/models/group.dart';
import '../../data/models/group_privacy.dart';
import '../../data/models/group_category.dart';
import '../../data/services/groups_api_service.dart';
import '../../../../core/models/country.dart';
import '../../../../core/models/language.dart';

/// صفحة تعديل مجموعة موجودة مع Tabs (مثل الصفحات)
class EditGroupPage extends StatefulWidget {
  const EditGroupPage({super.key, required this.group});

  final Group group;

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupsApiService _apiService;

  bool _isLoading = false;
  bool _isLoadingData = true;

  // Settings Tab
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  int _selectedCategoryId = 1;
  GroupPrivacy _selectedPrivacy = GroupPrivacy.public;

  // Helper Data
  List<GroupCategory> _categories = [];
  List<Country> _countries = [];
  List<Language> _languages = [];
  String? _selectedCountryId;
  String? _selectedLanguageId;

  // Info Tab
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();

  // Pictures Tab
  final ImagePicker _picker = ImagePicker();
  File? _selectedPicture;
  File? _selectedCover;
  bool _isUploadingPicture = false;
  bool _isUploadingCover = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _apiService = GroupsApiService(context.read<ApiClient>());

    // تعبئة البيانات الحالية
    _titleController.text = widget.group.groupTitle;
    _usernameController.text = widget.group.groupName;
    _selectedCategoryId = widget.group.category.categoryId;
    _selectedPrivacy = widget.group.groupPrivacy;
    _descriptionController.text = widget.group.groupDescription ?? '';

    // إضافة listener لتحديث UI عند تغيير التبويب
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // جلب البيانات المساعدة
    _loadHelperData();
  }

  Future<void> _loadHelperData() async {
    try {
      final results = await Future.wait([
        _apiService.getGroupCategories(),
        _apiService.getCountries(),
        _apiService.getLanguages(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<GroupCategory>;
          _countries = results[1] as List<Country>;
          _languages = results[2] as List<Language>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentSection() async {
    setState(() => _isLoading = true);

    try {
      bool success = false;

      // البكند يطلب جميع الحقول الإلزامية دائماً
      // لذلك نرسلها مع كل update بغض النظر عن التبويب
      success = await _apiService.updateGroup(
        groupId: widget.group.groupId,
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        privacy: _selectedPrivacy.toServerString(),
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        countryId: _selectedCountryId != null
            ? int.tryParse(_selectedCountryId!)
            : null,
        languageId: _selectedLanguageId != null
            ? int.tryParse(_selectedLanguageId!)
            : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_save_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_save_failed'.tr),
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_group_delete_title'.tr),
        content: Text(
          'edit_group_delete_message'.trParams({'title': widget.group.groupTitle}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('edit_group_delete_permanently'.tr),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.deleteGroup(widget.group.groupId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_delete_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'deleted');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_delete_failed'.tr),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_group_title'.tr),
        elevation: 0,
        actions: [
          if (_isLoading)
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
          else if (_tabController.index != 2 && _tabController.index != 3)
            TextButton.icon(
              onPressed: _saveCurrentSection,
              icon: const Icon(Iconsax.tick_circle),
              label: Text('save'.tr),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Iconsax.setting_2), text: 'edit_group_tab_settings'.tr),
            Tab(icon: const Icon(Iconsax.info_circle), text: 'edit_group_tab_info'.tr),
            Tab(icon: const Icon(Iconsax.gallery), text: 'edit_group_tab_pictures'.tr),
            Tab(icon: const Icon(Iconsax.danger), text: 'edit_group_tab_danger'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(),
          _buildInfoTab(),
          _buildPicturesTab(),
          _buildDangerTab(),
        ],
      ),
    );
  }

  // ===================== Settings Tab =====================
  Widget _buildSettingsTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // عنوان المجموعة
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'edit_group_title_label'.tr,
            hintText: 'edit_group_title_hint'.tr,
            prefixIcon: const Icon(Iconsax.text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // اسم المستخدم
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'edit_group_username_label'.tr,
            hintText: 'edit_group_username_hint'.tr,
            prefixIcon: const Icon(Iconsax.user),
            helperText: 'edit_group_username_helper'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // الفئة
        DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'edit_group_category_label'.tr,
            prefixIcon: const Icon(Iconsax.category),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _categories.isEmpty
              ? [DropdownMenuItem(value: 1, child: Text('edit_group_loading'.tr))]
              : _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.categoryId,
                    child: Text(cat.categoryName),
                  );
                }).toList(),
          onChanged: (value) {
            if (_categories.isNotEmpty) {
              setState(() => _selectedCategoryId = value ?? 1);
            }
          },
        ),
        const SizedBox(height: 16),

        // الدولة
        DropdownButtonFormField<String?>(
          value: _selectedCountryId,
          decoration: InputDecoration(
            labelText: 'edit_group_country_label'.tr,
            prefixIcon: const Icon(Iconsax.global),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('edit_group_country_placeholder'.tr),
            ),
            ..._countries.map((country) {
              return DropdownMenuItem(
                value: country.countryId,
                child: Text(country.countryName),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() => _selectedCountryId = value);
          },
        ),
        const SizedBox(height: 16),

        // اللغة
        DropdownButtonFormField<String?>(
          value: _selectedLanguageId,
          decoration: InputDecoration(
            labelText: 'edit_group_language_label'.tr,
            prefixIcon: const Icon(Iconsax.language_square),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('edit_group_language_placeholder'.tr),
            ),
            ..._languages.map((lang) {
              return DropdownMenuItem(
                value: lang.languageId,
                child: Text(lang.languageName),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() => _selectedLanguageId = value);
          },
        ),
        const SizedBox(height: 24),

        // الخصوصية
        Text('edit_group_privacy_label'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildPrivacyOptions(),
      ],
    );
  }

  Widget _buildPrivacyOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PrivacyOption(
            icon: Iconsax.global,
            title: 'edit_group_privacy_public'.tr,
            description: 'edit_group_privacy_public_desc'.tr,
            value: GroupPrivacy.public,
            groupValue: _selectedPrivacy,
            onChanged: (value) {
              setState(() => _selectedPrivacy = value!);
            },
          ),
          const Divider(height: 1),
          _PrivacyOption(
            icon: Iconsax.lock,
            title: 'edit_group_privacy_closed'.tr,
            description: 'edit_group_privacy_closed_desc'.tr,
            value: GroupPrivacy.closed,
            groupValue: _selectedPrivacy,
            onChanged: (value) {
              setState(() => _selectedPrivacy = value!);
            },
          ),
          const Divider(height: 1),
          _PrivacyOption(
            icon: Iconsax.eye_slash,
            title: 'edit_group_privacy_secret'.tr,
            description: 'edit_group_privacy_secret_desc'.tr,
            value: GroupPrivacy.secret,
            groupValue: _selectedPrivacy,
            onChanged: (value) {
              setState(() => _selectedPrivacy = value!);
            },
          ),
        ],
      ),
    );
  }

  // ===================== Info Tab =====================
  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // الوصف
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'edit_group_description_label'.tr,
            hintText: 'edit_group_description_hint'.tr,
            prefixIcon: const Icon(Iconsax.document_text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 16),

        // الموقع الإلكتروني
        TextFormField(
          controller: _websiteController,
          decoration: InputDecoration(
            labelText: 'edit_group_website_label'.tr,
            hintText: 'https://example.com',
            prefixIcon: const Icon(Iconsax.global),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),

        // الموقع
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'edit_group_location_label'.tr,
            hintText: 'edit_group_location_hint'.tr,
            prefixIcon: const Icon(Iconsax.location),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ===================== Pictures Tab =====================
  Widget _buildPicturesTab() {
    final mediaAsset = context.read<AppConfig>().mediaAsset;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المجموعة
          _buildPictureSection(
            title: 'edit_group_picture_section_title',
            subtitle: 'edit_group_picture_section_subtitle',
            currentImage: widget.group.groupPicture ?? '',
            selectedImage: _selectedPicture,
            isUploading: _isUploadingPicture,
            onPickImage: () => _pickImage(isPicture: true),
            onUpload: _uploadPicture,
            aspectRatio: 1.0,
            mediaAsset: mediaAsset,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // صورة الغلاف
          _buildPictureSection(
            title: 'edit_group_cover_section_title',
            subtitle: 'edit_group_cover_section_subtitle',
            currentImage: widget.group.groupCover ?? '',
            selectedImage: _selectedCover,
            isUploading: _isUploadingCover,
            onPickImage: () => _pickImage(isPicture: false),
            onUpload: _uploadCover,
            aspectRatio: 16 / 9,
            mediaAsset: mediaAsset,
          ),
        ],
      ),
    );
  }

  Widget _buildPictureSection({
    required String title,
    required String subtitle,
    required String currentImage,
    required File? selectedImage,
    required bool isUploading,
    required VoidCallback onPickImage,
    required VoidCallback onUpload,
    required double aspectRatio,
    required Uri Function(String) mediaAsset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.tr,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subtitle.tr, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),

        // عرض الصورة
        GestureDetector(
          onTap: onPickImage,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: selectedImage != null
                    ? DecorationImage(
                        image: FileImage(selectedImage),
                        fit: BoxFit.cover,
                      )
                    : (currentImage.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                mediaAsset(currentImage).toString(),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null),
              ),
              child: selectedImage == null && currentImage.isEmpty
                  ? Icon(Iconsax.gallery_add, size: 48, color: Colors.grey[600])
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // أزرار الإجراءات
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Iconsax.gallery),
                label: Text('edit_group_pick_image'.tr),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (selectedImage != null && !isUploading)
                    ? onUpload
                    : null,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.arrow_up),
                label: Text(isUploading ? 'edit_group_uploading'.tr : 'edit_group_upload'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        if (isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _uploadProgress),
        ],
      ],
    );
  }

  // ===================== Danger Tab =====================
  Widget _buildDangerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Iconsax.danger, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'منطقة الخطر',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الإجراءات في هذا القسم خطيرة ولا يمكن التراجع عنها',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // معلومات المجموعة
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit_group_info_section'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'edit_group_members'.tr,
                  value: '${widget.group.groupMembers}',
                ),
                _InfoRow(label: 'edit_group_creation_date'.tr, value: widget.group.groupDate),
                _InfoRow(
                  label: 'edit_group_privacy'.tr,
                  value: widget.group.groupPrivacy.displayName,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // زر الحذف
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _deleteGroup,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Iconsax.trash),
            label: Text(
              _isLoading ? 'edit_group_deleting'.tr : 'edit_group_delete_button'.tr,
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== Helper Methods =====================

  /// إعادة تحميل بيانات المجموعة من السيرفر
  Future<void> _reloadGroupData() async {
    try {
      final updatedGroup = await _apiService.getGroupDetails(
        widget.group.groupId,
      );
      if (updatedGroup != null && mounted) {
        // تحديث widget.group ليس ممكن لأنه final
        // لكن يمكننا إرجاع النتيجة للصفحة السابقة
        Navigator.pop(context, true); // true = تم التحديث
      }
    } catch (e) {
    }
  }

  Future<void> _pickImage({required bool isPicture}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isPicture ? 800 : 1920,
        maxHeight: isPicture ? 800 : 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isPicture) {
            _selectedPicture = File(image.path);
          } else {
            _selectedCover = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_image_pick_error'.trParams({'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPicture() async {
    if (_selectedPicture == null) return;

    setState(() {
      _isUploadingPicture = true;
      _uploadProgress = 0.0;
    });

    try {
      final apiClient = context.read<ApiClient>();

      setState(() => _uploadProgress = 0.3);

      final response = await apiClient.multipartPost(
        '/data/groups/${widget.group.groupId}/picture',
        body: {},
        filePath: _selectedPicture!.path,
        fileFieldName: 'picture',
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.3 + (sent / total * 0.7);
            });
          }
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'فشل رفع الصورة');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_picture_upload_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedPicture = null);

        // إعادة تحميل بيانات المجموعة لعرض الصورة الجديدة
        await _reloadGroupData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPicture = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _uploadCover() async {
    if (_selectedCover == null) return;

    setState(() {
      _isUploadingCover = true;
      _uploadProgress = 0.0;
    });

    try {
      final apiClient = context.read<ApiClient>();

      setState(() => _uploadProgress = 0.3);

      final response = await apiClient.multipartPost(
        '/data/groups/${widget.group.groupId}/cover',
        body: {},
        filePath: _selectedCover!.path,
        fileFieldName: 'cover',
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.3 + (sent / total * 0.7);
            });
          }
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'فشل رفع الصورة');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_group_cover_upload_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedCover = null);

        // إعادة تحميل بيانات المجموعة لعرض الصورة الجديدة
        await _reloadGroupData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCover = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}

// ===================== Helper Widgets =====================
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
