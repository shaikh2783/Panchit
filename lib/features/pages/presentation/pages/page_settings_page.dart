import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/data/models/page_category.dart';
import 'package:snginepro/core/data/models/country.dart';
import 'package:snginepro/core/data/models/language.dart';
import 'package:snginepro/core/network/api_exception.dart';

class PageSettingsPage extends StatefulWidget {
  const PageSettingsPage({super.key, required this.page});

  final PageModel page;

  @override
  State<PageSettingsPage> createState() => _PageSettingsPageState();
}

class _PageSettingsPageState extends State<PageSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Settings Section Controllers
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  int? _selectedCategory;
  bool _pageTipsEnabled = false;

  // Info Section Controllers
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  int? _selectedCountry;
  int? _selectedLanguage;

  // Action Section Controllers
  final _actionTextController = TextEditingController();
  final _actionUrlController = TextEditingController();
  String _actionColor = 'primary';

  // Social Section Controllers
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _vkontakteController = TextEditingController();

  // Monetization Section
  bool _monetizationEnabled = false;

  // Dynamic data from API
  List<PageCategory> _categories = [];
  bool _isLoadingCategories = false;
  
  List<Country> _countries = [];
  bool _isLoadingCountries = false;
  
  List<Language> _languages = [];
  bool _isLoadingLanguages = false;

  final List<Map<String, String>> _actionColors = [
    {'value': 'light', 'name': 'Light'},
    {'value': 'primary', 'name': 'Primary'},
    {'value': 'success', 'name': 'Success'},
    {'value': 'info', 'name': 'Info'},
    {'value': 'warning', 'name': 'Warning'},
    {'value': 'danger', 'name': 'Danger'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
    _initializeData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCategories(),
      _loadCountries(),
      _loadLanguages(),
    ]);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final repo = context.read<PagesRepository>();
      final categories = await repo.getPageCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      final repo = context.read<PagesRepository>();
      final countries = await repo.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _isLoadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCountries = false);
      }
    }
  }

  Future<void> _loadLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      final repo = context.read<PagesRepository>();
      final languages = await repo.getLanguages();
      if (mounted) {
        setState(() {
          _languages = languages;
          _isLoadingLanguages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLanguages = false);
      }
    }
  }

  void _initializeData() {
    // Settings
    _titleController.text = widget.page.title;
    _usernameController.text = widget.page.name;
    _selectedCategory = int.tryParse(widget.page.category) ?? 1;

    // Info
    _descriptionController.text = widget.page.description;
    _selectedCountry = 1;
    _selectedLanguage = 1;

    // Action, Social, Monetization values would come from API
    _actionColor = 'primary';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _actionTextController.dispose();
    _actionUrlController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _vkontakteController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentSection() async {
    String section;
    Map<String, dynamic> data = {};

    switch (_tabController.index) {
      case 0: // Settings
        section = 'settings';
        data = {
          'title': _titleController.text.trim(),
          'username': _usernameController.text.trim(),
          'category': _selectedCategory,
          'page_tips_enabled': _pageTipsEnabled ? 1 : 0,
        };
        break;
      case 1: // Info
        section = 'info';
        data = {
          'country': _selectedCountry,
          'language': _selectedLanguage,
          'description': _descriptionController.text.trim(),
          'website': _websiteController.text.trim(),
          'company': _companyController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
        };
        break;
      case 2: // Action
        section = 'action';
        data = {
          'action_text': _actionTextController.text.trim(),
          'action_color': _actionColor,
          'action_url': _actionUrlController.text.trim(),
        };
        break;
      case 3: // Social
        section = 'social';
        data = {
          'facebook': _facebookController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'youtube': _youtubeController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
          'vkontakte': _vkontakteController.text.trim(),
        };
        break;
      case 4: // Monetization
        section = 'monetization';
        data = {'page_monetization_enabled': _monetizationEnabled ? 1 : 0};
        break;
      default:
        return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = context.read<PagesRepository>();
      await repository.updatePageSection(
        pageId: widget.page.id,
        section: section,
        data: data,
      );

      if (!mounted) return;

      Get.snackbar(
        'success'.tr,
        'changes_saved_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('failed_to_save_changes_with_error'.trParams({'error': e.toString()}));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('page_settings'.tr),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
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
          else
            TextButton.icon(
              onPressed: _saveCurrentSection,
              icon: const Icon(Iconsax.save_2, size: 18),
              label: Text(
                'save'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Iconsax.setting_2), text: 'settings'.tr),
            Tab(icon: const Icon(Iconsax.info_circle), text: 'info_tab'.tr),
            Tab(icon: const Icon(Iconsax.link), text: 'action_tab'.tr),
            Tab(icon: const Icon(Iconsax.share), text: 'social_tab'.tr),
            Tab(icon: const Icon(Iconsax.dollar_circle), text: 'monetization_settings'.tr),
            Tab(icon: const Icon(Iconsax.trash), text: 'delete'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(isDark),
          _buildInfoTab(isDark),
          _buildActionTab(isDark),
          _buildSocialTab(isDark),
          _buildMonetizationTab(isDark),
          _buildDeleteTab(isDark),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('basic_settings'.tr, Iconsax.setting_2),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '${'page_title'.tr} *',
            prefixIcon: const Icon(Iconsax.document_text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: '${'username'.tr} *',
            prefixIcon: const Icon(Iconsax.user),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingCategories
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('loading_categories'.tr),
                  ],
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '${'category'.tr} *',
                  prefixIcon: const Icon(Iconsax.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.categoryId,
                    child: Text(cat.categoryName),
                  );
                }).toList(),
                onChanged: _categories.isEmpty ? null : (value) => setState(() => _selectedCategory = value),
              ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('enable_page_tips_title'.tr),
          subtitle: Text('allow_users_send_tips_desc'.tr),
          value: _pageTipsEnabled,
          onChanged: (value) => setState(() => _pageTipsEnabled = value),
          secondary: const Icon(Iconsax.wallet),
        ),
      ],
    );
  }

  Widget _buildInfoTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('page_information'.tr, Iconsax.info_circle),
        const SizedBox(height: 16),
        _isLoadingCountries
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('loading_countries'.tr),
                  ],
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: '${'country'.tr} *',
                  prefixIcon: const Icon(Iconsax.global),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                ),
                items: _countries.map((country) {
                  return DropdownMenuItem<int>(
                    value: country.countryId,
                    child: Text(country.countryName),
                  );
                }).toList(),
                onChanged: _countries.isEmpty ? null : (value) => setState(() => _selectedCountry = value),
              ),
        const SizedBox(height: 16),
        _isLoadingLanguages
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('loading_languages'.tr),
                  ],
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: '${'language'.tr} *',
                  prefixIcon: const Icon(Iconsax.language_square),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                ),
                items: _languages.map((lang) {
                  return DropdownMenuItem<int>(
                    value: lang.languageId,
                    child: Text(lang.languageName),
                  );
                }).toList(),
                onChanged: _languages.isEmpty ? null : (value) => setState(() => _selectedLanguage = value),
              ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'description'.tr,
            prefixIcon: const Icon(Iconsax.message_text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: InputDecoration(
            labelText: 'profile_website'.tr,
            prefixIcon: const Icon(Iconsax.global_search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'profile_company'.tr,
            prefixIcon: const Icon(Iconsax.building),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'phone'.tr,
            prefixIcon: const Icon(Iconsax.call),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'location'.tr,
            prefixIcon: const Icon(Iconsax.location),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('call_to_action_button'.tr, Iconsax.link),
        const SizedBox(height: 16),
        TextFormField(
          controller: _actionTextController,
          decoration: InputDecoration(
            labelText: 'button_text'.tr,
            hintText: 'button_text_hint'.tr,
            prefixIcon: const Icon(Iconsax.text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _actionUrlController,
          decoration: InputDecoration(
            labelText: 'button_url'.tr,
            hintText: 'button_url_hint'.tr,
            prefixIcon: const Icon(Iconsax.link_1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _actionColor,
          decoration: InputDecoration(
            labelText: 'button_color'.tr,
            prefixIcon: const Icon(Iconsax.color_swatch),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
          items: _actionColors.map((color) {
            return DropdownMenuItem(
              value: color['value'],
              child: Text('color_${color['value']!}'.tr),
            );
          }).toList(),
          onChanged: (value) => setState(() => _actionColor = value!),
        ),
      ],
    );
  }

  Widget _buildSocialTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('social_media_links'.tr, Iconsax.share),
        const SizedBox(height: 16),
        TextFormField(
          controller: _facebookController,
          decoration: InputDecoration(
            labelText: 'facebook_link'.tr,
            prefixIcon: const Icon(Iconsax.facebook),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _twitterController,
          decoration: InputDecoration(
            labelText: 'twitter_link'.tr,
            prefixIcon: const Icon(Iconsax.share),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _youtubeController,
          decoration: InputDecoration(
            labelText: 'youtube_link'.tr,
            prefixIcon: const Icon(Iconsax.video_square),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instagramController,
          decoration: InputDecoration(
            labelText: 'instagram_link'.tr,
            prefixIcon: const Icon(Iconsax.instagram),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _linkedinController,
          decoration: InputDecoration(
            labelText: 'linkedin_link'.tr,
            prefixIcon: const Icon(Iconsax.link_2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _vkontakteController,
          decoration: InputDecoration(
            labelText: 'vkontakte_link'.tr,
            prefixIcon: const Icon(Iconsax.link_2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildMonetizationTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('monetization_settings'.tr, Iconsax.dollar_circle),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('enable_monetization_page_title'.tr),
          subtitle: Text('allow_page_earn_money_desc'.tr),
          value: _monetizationEnabled,
          onChanged: (value) => setState(() => _monetizationEnabled = value),
          secondary: const Icon(Iconsax.money),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'monetization_info_text'.tr,
                  style: TextStyle(color: Colors.blue[900], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDeleteTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200, width: 2),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.warning_2, color: Colors.red.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'delete_page'.tr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'warning_action_cannot_be_undone'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'deleting_page_will_remove'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildDeleteWarningItem('delete_page_warning_posts'.tr),
              _buildDeleteWarningItem('delete_page_warning_media'.tr),
              _buildDeleteWarningItem('delete_page_warning_members_admins'.tr),
              _buildDeleteWarningItem('delete_page_warning_likes_followers'.tr),
              _buildDeleteWarningItem('delete_page_warning_settings_info'.tr),
              const SizedBox(height: 20),
              Text(
                'delete_page_irreversible_note'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmDeletePage,
                  icon: const Icon(Iconsax.trash, size: 20),
                  label: Text(
                    'delete_page_permanently'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.close_circle, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('delete_page_confirmation_title'.tr)),
          ],
        ),
        content: Text(
          'delete_page_confirmation_message'.trParams({'title': widget.page.title}),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('delete_permanently_button'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePage();
    }
  }

  Future<void> _deletePage() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<PagesRepository>();
      await repo.deletePage(pageId: widget.page.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('page_deleted_successfully'.tr),
          backgroundColor: Colors.green,
        ),
      );

      // Go back twice (close settings and profile page)
      Navigator.pop(context, true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_delete_page_with_error'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
