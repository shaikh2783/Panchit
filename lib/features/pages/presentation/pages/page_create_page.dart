import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/pages/data/models/page_category.dart';
import 'package:snginepro/core/data/models/country.dart';
import 'package:snginepro/core/data/models/language.dart';
import 'package:snginepro/core/network/api_exception.dart';

class PageCreatePage extends StatefulWidget {
  const PageCreatePage({super.key});

  @override
  State<PageCreatePage> createState() => _PageCreatePageState();
}

class _PageCreatePageState extends State<PageCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedCategory;
  int? _selectedCountry;
  int? _selectedLanguage;

  bool _isLoading = false;

  // Dynamic data from API
  List<PageCategory> _categories = [];
  bool _isLoadingCategories = false;
  
  List<Country> _countries = [];
  bool _isLoadingCountries = false;
  
  List<Language> _languages = [];
  bool _isLoadingLanguages = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
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
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories.first.categoryId;
          }
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
          if (_countries.isNotEmpty && _selectedCountry == null) {
            _selectedCountry = _countries.first.countryId;
          }
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
          if (_languages.isNotEmpty && _selectedLanguage == null) {
            _selectedLanguage = _languages.first.languageId;
          }
          _isLoadingLanguages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLanguages = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category. If categories are still loading, please wait.');
      return;
    }
    if (_selectedCountry == null) {
      _showError('Please select a country. If countries are still loading, please wait.');
      return;
    }
    if (_selectedLanguage == null) {
      _showError('Please select a language. If languages are still loading, please wait.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = context.read<PagesRepository>();
      final page = await repository.createPage(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        category: _selectedCategory!,
        country: _selectedCountry!,
        language: _selectedLanguage!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (!mounted) return;

      Get.back(result: page);
      Get.snackbar(
        'Success',
        'Page created successfully!',
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
      _showError('Failed to create page: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
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
        title: Text('create_page_title'.tr),
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
            TextButton(
              onPressed: _createPage,
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Page Title *',
                hintText: 'Enter page title',
                prefixIcon: const Icon(Iconsax.document_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username *',
                hintText: 'Enter unique username',
                prefixIcon: const Icon(Iconsax.user),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                helperText: 'Lowercase letters, numbers, and underscores only',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value.trim())) {
                  return 'Only lowercase letters, numbers, and underscores';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Category
            _isLoadingCategories
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading categories...'),
                      ],
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: const Icon(Iconsax.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                    ),
                    hint: Text('select_category_placeholder'.tr),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.categoryId,
                        child: Text(category.categoryName),
                      );
                    }).toList(),
                    onChanged: _categories.isEmpty ? null : (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
            const SizedBox(height: 16),

            // Country
            _isLoadingCountries
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading countries...'),
                      ],
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedCountry,
                    decoration: InputDecoration(
                      labelText: 'Country *',
                      prefixIcon: const Icon(Iconsax.global),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                    ),
                    hint: Text('select_country_placeholder'.tr),
                    items: _countries.map((country) {
                      return DropdownMenuItem<int>(
                        value: country.countryId,
                        child: Text(country.countryName),
                      );
                    }).toList(),
                    onChanged: _countries.isEmpty ? null : (value) {
                      setState(() => _selectedCountry = value);
                    },
                  ),
            const SizedBox(height: 16),

            // Language
            _isLoadingLanguages
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading languages...'),
                      ],
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Language *',
                      prefixIcon: const Icon(Iconsax.language_square),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
                    ),
                    hint: Text('select_language_placeholder'.tr),
                    items: _languages.map((language) {
                      return DropdownMenuItem<int>(
                        value: language.languageId,
                        child: Text(language.languageName),
                      );
                    }).toList(),
                    onChanged: _languages.isEmpty ? null : (value) {
                      setState(() => _selectedLanguage = value);
                    },
                  ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Tell people what your page is about',
                prefixIcon: const Icon(Iconsax.message_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
              ),
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.info_circle, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your page will be created immediately. You can edit details, add cover photo, and customize it later.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
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
