import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/services/general_data_service.dart';
import 'package:snginepro/core/models/country.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';

/// 🚀 Getting Started Page - Complete User Profile Setup
class GettingStartedPage extends StatefulWidget {
  const GettingStartedPage({super.key});

  @override
  State<GettingStartedPage> createState() => _GettingStartedPageState();
}

class _GettingStartedPageState extends State<GettingStartedPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _workController = TextEditingController();
  final _educationController = TextEditingController();
  
  int _currentStep = 0;
  bool _isSubmitting = false;
  
  List<Country> _countries = [];
  bool _loadingCountries = true;
  String? _selectedCountryId;

  late AnimationController _backgroundController;
  late AnimationController _formController;

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

  @override
  void dispose() {
    _workController.dispose();
    _educationController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate current step
    if (_currentStep == 0) {
      if (_selectedCountryId == null || _selectedCountryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select your country'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // Move to next step or finish
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      await _handleFinish();
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
    return Container(
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
              if (_currentStep == 0) _buildLocationStep(isDark),
              if (_currentStep == 1) _buildWorkStep(isDark),
              if (_currentStep == 2) _buildEducationStep(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 64,
          color: const Color(0xFF5B86E5).withOpacity(0.8),
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
              labelText: 'location'.tr,
              hintText: 'Select your country',
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

  Widget _buildWorkStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.work_rounded,
          size: 64,
          color: const Color(0xFF5B86E5).withOpacity(0.8),
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
            labelText: 'work'.tr,
            hintText: 'Software Engineer',
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

  Widget _buildEducationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.school_rounded,
          size: 64,
          color: const Color(0xFF5B86E5).withOpacity(0.8),
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
            labelText: 'education'.tr,
            hintText: 'Computer Science',
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
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          // Skip button
          TextButton(
            onPressed: _isSubmitting ? null : _handleSkip,
            child: Text(
              'skip'.tr,
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF4A5568),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Progress indicator
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index <= _currentStep
                        ? const Color(0xFF5B86E5)
                        : (isDark 
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE2E8F0)),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next/Finish button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B86E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [
                Text(
                  _currentStep < 2 ? 'next'.tr : 'finish'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isSubmitting) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
