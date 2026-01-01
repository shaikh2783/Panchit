import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/services/general_data_service.dart';
import 'package:snginepro/core/models/country.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/profile/data/services/profile_update_service.dart';

/// 🚀 Getting Started Page - Complete User Profile Setup (Enhanced)
class GettingStartedPage extends StatefulWidget {
  const GettingStartedPage({super.key});

  @override
  State<GettingStartedPage> createState() => _GettingStartedPageState();
}

class _GettingStartedPageState extends State<GettingStartedPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _workController = TextEditingController();
  final _educationController = TextEditingController();
  
  // Total steps: 0=Photo, 1=Bio, 2=Location, 3=Work, 4=Education
  int _currentStep = 0;
  static const int _totalSteps = 5;
  bool _isSubmitting = false;
  
  // Profile picture
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _uploadingPhoto = false;
  
  List<Country> _countries = [];
  bool _loadingCountries = true;
  String? _selectedCountryId;

  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _stepController;
  late ProfileUpdateService _profileService;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _profileService = ProfileUpdateService(context.read<ApiClient>());
    
    _formController.forward();
    _fetchCountries();
  }
  
  Future<void> _fetchCountries() async {
    try {
      final apiClient = context.read<ApiClient>();
      final dataService = GeneralDataService(apiClient);
      final countries = await dataService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _loadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_picking_image'.tr),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D3748) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'choose_photo_source'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: Text('camera'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: Text('gallery'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;
    
    setState(() => _uploadingPhoto = true);
    try {
      await _profileService.uploadProfilePicture(_selectedImage!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('photo_uploaded_successfully'.tr),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_uploading_photo'.tr),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _workController.dispose();
    _educationController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate current step
    if (_currentStep == 2) {
      if (_selectedCountryId == null || _selectedCountryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_select_country'.tr),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // Upload profile picture if selected
    if (_currentStep == 0 && _selectedImage != null) {
      await _uploadProfilePicture();
    }

    // Animate step transition
    await _stepController.forward();
    
    // Move to next step or finish
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _stepController.reset();
    } else {
      await _handleFinish();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleFinish() async {
    setState(() => _isSubmitting = true);

    try {
      final authNotifier = context.read<AuthNotifier>();
      
      // Send all data in one API call
      await authNotifier.updateGettingStarted(
        countryId: _selectedCountryId,
        work: _workController.text.trim().isNotEmpty ? _workController.text.trim() : null,
        education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
      );
      
      // Call finish API
      await authNotifier.finishGettingStarted();

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile_setup_complete'.tr),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      
      // Navigate to main app
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSkip() async {
    try {
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.finishGettingStarted();
      
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      // If finish fails, just navigate anyway
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(isDark),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),
                
                // Stepper
                Expanded(
                  child: _buildStepper(isDark),
                ),
                
                // Actions
                _buildActions(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A202C), const Color(0xFF2D3748)]
              : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
        ),
      ),
      child: Stack(
        children: List.generate(8, (index) {
          return AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              final angle = _backgroundController.value * 2 * math.pi + index;
              return Positioned(
                left: 50 + math.cos(angle) * 150,
                top: 100 + math.sin(angle) * 150 + (index * 80),
                child: Container(
                  width: 60 + (index % 3) * 20,
                  height: 60 + (index % 3) * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'getting_started'.tr,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'complete_profile'.tr,
            style: TextStyle(
              fontSize: 16,
              color: isDark 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentStep),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_currentStep == 0) _buildProfilePhotoStep(isDark),
                if (_currentStep == 1) _buildBioStep(isDark),
                if (_currentStep == 2) _buildLocationStep(isDark),
                if (_currentStep == 3) _buildWorkStep(isDark),
                if (_currentStep == 4) _buildEducationStep(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step 0: Profile Picture
  Widget _buildProfilePhotoStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5B86E5).withOpacity(0.1),
                const Color(0xFF36D1DC).withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            size: 48,
            color: const Color(0xFF5B86E5).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'add_profile_photo'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'profile_photo_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Profile Picture Preview
        GestureDetector(
          onTap: _uploadingPhoto ? null : _showImageSourceDialog,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _selectedImage == null
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF5B86E5).withOpacity(0.2),
                            const Color(0xFF36D1DC).withOpacity(0.2),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: const Color(0xFF5B86E5).withOpacity(0.3),
                    width: 3,
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 64,
                        color: isDark 
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF5B86E5).withOpacity(0.5),
                      )
                    : null,
              ),
              
              // Upload indicator
              if (_uploadingPhoto)
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              
              // Edit badge
              if (!_uploadingPhoto)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF2D3748) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        Text(
          'tap_to_change_photo'.tr,
          style: TextStyle(
            fontSize: 12,
            color: isDark 
                ? Colors.white.withOpacity(0.5)
                : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  /// Step 1: Bio/About
  Widget _buildBioStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6A11CB).withOpacity(0.1),
                const Color(0xFF2575FC).withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.edit_note_rounded,
            size: 48,
            color: const Color(0xFF6A11CB).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'tell_us_about_yourself'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'bio_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: 'bio'.tr,
            hintText: 'write_something_about_yourself'.tr,
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 64),
              child: Icon(Icons.format_quote_rounded),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: Location
  Widget _buildLocationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D976C).withOpacity(0.1),
                const Color(0xFF93F9B9).withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: 48,
            color: const Color(0xFF1D976C).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'where_do_you_live'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'location_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 24),
        if (_loadingCountries)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCountryId,
            decoration: InputDecoration(
              labelText: 'country'.tr,
              hintText: 'select_your_country'.tr,
              prefixIcon: const Icon(Icons.pin_drop_rounded),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF1A202C) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A202C),
              fontSize: 15,
            ),
            items: _countries.map((country) {
              return DropdownMenuItem<String>(
                value: country.countryId,
                child: Text(country.countryName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountryId = value;
              });
            },
          ),
      ],
    );
  }

  /// Step 3: Work
  Widget _buildWorkStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A66C2).withOpacity(0.1),
                const Color(0xFF084E99).withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.work_rounded,
            size: 48,
            color: const Color(0xFF0A66C2).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'what_do_you_do'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'work_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _workController,
          decoration: InputDecoration(
            labelText: 'job_title'.tr,
            hintText: 'job_title_hint'.tr,
            prefixIcon: const Icon(Icons.business_center_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// Step 4: Education
  Widget _buildEducationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD66D75).withOpacity(0.1),
                const Color(0xFFE29587).withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school_rounded,
            size: 48,
            color: const Color(0xFFD66D75).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'what_did_you_study'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'education_description'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _educationController,
          decoration: InputDecoration(
            labelText: 'field_of_study'.tr,
            hintText: 'field_of_study_hint'.tr,
            prefixIcon: const Icon(Icons.menu_book_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalSteps, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: isActive || isCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                          )
                        : null,
                    color: !isActive && !isCompleted
                        ? (isDark 
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE2E8F0))
                        : null,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Step indicator text
            Text(
              '${'step'.tr} ${_currentStep + 1} ${'of'.tr} $_totalSteps',
              style: TextStyle(
                fontSize: 12,
                color: isDark 
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF718096),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons row
            Row(
              children: [
                // Back/Skip button
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _handleBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF4A5568),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark 
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text('back'.tr),
                      ],
                    ),
                  )
                else
                  TextButton(
                    onPressed: _isSubmitting ? null : _handleSkip,
                    child: Text(
                      'skip_all'.tr,
                      style: TextStyle(
                        color: isDark 
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF4A5568),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // Next/Finish button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B86E5).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _uploadingPhoto) ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isSubmitting || _uploadingPhoto) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          _currentStep < _totalSteps - 1 ? 'next'.tr : 'finish'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isSubmitting && !_uploadingPhoto) ...[
                          const SizedBox(width: 6),
                          Icon(
                            _currentStep < _totalSteps - 1 
                                ? Icons.arrow_forward_ios_rounded 
                                : Icons.check_rounded,
                            size: 16,
                          ),
                        ],
                      ],
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
}
