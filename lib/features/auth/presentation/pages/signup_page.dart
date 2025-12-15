import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/data/models/gender.dart';
import 'package:snginepro/features/auth/data/datasources/gender_api_service.dart';
import 'package:snginepro/features/auth/presentation/pages/login_page.dart';
import 'package:snginepro/features/auth/presentation/pages/getting_started_page.dart';
/// 🎨 Modern Sign Up Page with Translation Support
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}
class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  static const String _deviceType = 'A';
  List<Gender> _genders = [];
  bool _loadingGenders = true;
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
    _fetchGenders();
  }
  Future<void> _fetchGenders() async {
    try {
      final apiClient = context.read<ApiClient>();
      final genderService = GenderApiService(apiClient);
      final genders = await genderService.getGenders();
      if (mounted) {
        setState(() {
          _genders = genders;
          _loadingGenders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGenders = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    super.dispose();
  }
  Future<void> _handleSignUp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    final authNotifier = context.read<AuthNotifier>();
    final AuthResponse? response = await authNotifier.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      gender: _selectedGender,
      birthdate: _selectedBirthdate,
      deviceType: _deviceType,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (response != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('account_created_successfully'.tr),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      // Navigate to Getting Started page
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GettingStartedPage(),
        ),
      );
    } else {
      final error = authNotifier.errorMessage ?? 'registration_failed'.tr;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'first_name_required'.tr;
    }
    return null;
  }
  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'last_name_required'.tr;
    }
    return null;
  }
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'username_required'.tr;
    }
    // Username should only contain letters, numbers, and underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'username_alphanumeric'.tr;
    }
    return null;
  }
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'invalid_email'.tr;
    }
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 6) {
      return 'password_min_length'.tr;
    }
    return null;
  }
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value != _passwordController.text) {
      return 'passwords_not_match'.tr;
    }
    return null;
  }
  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? const Color(0xFF5B86E5) : const Color(0xFF5B86E5),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1A202C) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1A202C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>();
    final isLoading = authState.isLoading;
    final errorMessage = authState.errorMessage;
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Clean Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                      ]
                    : [
                        const Color(0xFF5B86E5),
                        const Color(0xFF36D1DC),
                      ],
              ),
            ),
          ),
          // ✨ Floating Particles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final offset = (_backgroundController.value + index * 0.125) % 1;
                final x = size.width * ((index * 0.125) % 1);
                final y = size.height * offset;
                final scale = 0.5 + math.sin(offset * math.pi * 2) * 0.3;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 0.15,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 3 + (index % 2) * 2,
                        height: 3 + (index % 2) * 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // 📱 Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: FadeTransition(
                  opacity: _formController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _formController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🎯 Logo & Brand
                          _buildLogo(),
                          const SizedBox(height: 40),
                          // 💎 Solid Card with Form
                          _buildSolidCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                _buildHeader(isDark),
                                const SizedBox(height: 24),
                                // Error Banner
                                if (errorMessage != null) ...[
                                  _buildErrorBanner(errorMessage),
                                  const SizedBox(height: 20),
                                ],
                                // Form
                                _buildForm(isDark),
                                const SizedBox(height: 24),
                                // Sign Up Button
                                _buildSignUpButton(isLoading),
                                const SizedBox(height: 20),
                                // Divider
                                _buildDivider(isDark),
                                const SizedBox(height: 20),
                                // Footer
                                _buildFooter(isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 🎯 Logo Section
  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 45,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sngine',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // 💎 Solid Card
  Widget _buildSolidCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF0F1419).withOpacity(0.95)
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D3748).withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: child,
    );
  }
  // 📝 Header
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'join_community'.tr,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'start_journey'.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
  // ⚠️ Error Banner
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 📋 Form
  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // First Name & Last Name Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  isDark: isDark,
                  controller: _firstNameController,
                  label: 'first_name'.tr,
                  hint: 'enter_first_name'.tr,
                  icon: Icons.person_outline_rounded,
                  validator: _validateFirstName,
                  onChanged: (_) => context.read<AuthNotifier>().clearError(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  isDark: isDark,
                  controller: _lastNameController,
                  label: 'last_name'.tr,
                  hint: 'enter_last_name'.tr,
                  icon: Icons.person_outline_rounded,
                  validator: _validateLastName,
                  onChanged: (_) => context.read<AuthNotifier>().clearError(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Username
          _buildTextField(
            isDark: isDark,
            controller: _usernameController,
            label: 'username'.tr,
            hint: 'enter_username'.tr,
            icon: Icons.alternate_email_rounded,
            validator: _validateUsername,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
          ),
          const SizedBox(height: 14),
          // Email
          _buildTextField(
            isDark: isDark,
            controller: _emailController,
            label: 'email'.tr,
            hint: 'enter_email'.tr,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
          ),
          const SizedBox(height: 14),
          // Password
          _buildTextField(
            isDark: isDark,
            controller: _passwordController,
            label: 'password'.tr,
            hint: 'enter_password'.tr,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF5B86E5).withOpacity(0.8),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          // Confirm Password
          _buildTextField(
            isDark: isDark,
            controller: _confirmPasswordController,
            label: 'confirm_password'.tr,
            hint: 'confirm_your_password'.tr,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF5B86E5).withOpacity(0.8),
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          const SizedBox(height: 14),
          // Gender & Birthdate Row (Optional)
          Row(
            children: [
              Expanded(
                child: _buildGenderDropdown(isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBirthdateField(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // 🎨 Custom TextField
  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A202C),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF5B86E5).withOpacity(0.8),
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF4A5568),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFF718096),
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1A202C)
            : const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF5B86E5)
                : const Color(0xFF5B86E5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        errorStyle: TextStyle(
          color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFEF4444),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
  // 🚻 Gender Dropdown
  Widget _buildGenderDropdown(bool isDark) {
    if (_loadingGenders) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.wc_rounded,
              size: 20,
              color: isDark 
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF5B86E5).withOpacity(0.8),
            ),
            const SizedBox(width: 12),
            Text(
              '${'gender'.tr} (${'optional'.tr})',
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF4A5568),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF5B86E5),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: '${'gender'.tr} (${'optional'.tr})',
        prefixIcon: Icon(
          Icons.wc_rounded,
          size: 20,
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF5B86E5).withOpacity(0.8),
        ),
        labelStyle: TextStyle(
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF4A5568),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1A202C)
            : const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF5B86E5),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDark ? const Color(0xFF1A202C) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A202C),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      items: _genders.isEmpty 
          ? null 
          : _genders.map((gender) {
              return DropdownMenuItem<String>(
                value: gender.id,  // Store gender_id
                child: Text(gender.name),  // Display gender_name
              );
            }).toList(),
      onChanged: _genders.isEmpty ? null : (value) {
        setState(() {
          _selectedGender = value;  // Stores gender_id
        });
      },
    );
  }
  // 📅 Birthdate Field
  Widget _buildBirthdateField(bool isDark) {
    return InkWell(
      onTap: _selectBirthdate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${'birthdate'.tr} (${'optional'.tr})',
          prefixIcon: Icon(
            Icons.cake_outlined,
            size: 20,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF5B86E5).withOpacity(0.8),
          ),
          labelStyle: TextStyle(
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF1A202C)
              : const Color(0xFFF7FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF2D3748)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF2D3748)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF5B86E5),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text(
          _selectedBirthdate == null
              ? 'select_birthdate'.tr
              : '${_selectedBirthdate!.year}-${_selectedBirthdate!.month.toString().padLeft(2, '0')}-${_selectedBirthdate!.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: _selectedBirthdate == null
                ? (isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF718096))
                : (isDark ? Colors.white : const Color(0xFF1A202C)),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  // 🚀 Sign Up Button
  Widget _buildSignUpButton(bool isLoading) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B86E5).withOpacity(0.4),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleSignUp,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'create_account'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  // ➖ Divider
  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF718096),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
      ],
    );
  }
  // 📄 Footer
  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'already_have_account'.tr,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF5B86E5),
            backgroundColor: isDark
                ? const Color(0xFF1A202C)
                : const Color(0xFFF7FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'sign_in'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '© 2025 Panchit. All rights reserved.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : const Color(0xFF718096),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
