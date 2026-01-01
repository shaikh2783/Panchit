import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/models/profile_update_models.dart';
import '../../../profile/data/services/profile_update_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late final ProfileUpdateService _profileUpdateService;

  @override
  void initState() {
    super.initState();
    _profileUpdateService = ProfileUpdateService(Get.find<ApiClient>());
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if new password and confirm match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('passwords_do_not_match'.tr, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = PasswordUpdateRequest(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      final response = await _profileUpdateService.updatePassword(request);

      if (response.success) {
        _showSnackBar(response.message);
        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Go back after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('failed_change_password'.tr, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'change_password_title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Header Card
              _buildHeroHeader(theme, isDark),
              const SizedBox(height: 40),

              // Security Tips Card
              _buildSecurityTips(theme),
              const SizedBox(height: 32),

              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'current_password'.tr,
                hint: 'enter_current_password'.tr,
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () => setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_current_password'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'new_password'.tr,
                hint: 'enter_new_password'.tr,
                icon: Icons.vpn_key_rounded,
                obscureText: _obscureNewPassword,
                onToggleVisibility: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_new_password'.tr;
                  }
                  if (value.length < 6) {
                    return 'password_min_6_chars'.tr;
                  }
                  if (value == _currentPasswordController.text) {
                    return 'new_password_different'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'confirm_new_password'.tr,
                hint: 'reenter_new_password'.tr,
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_confirm_new_password'.tr;
                  }
                  if (value != _newPasswordController.text) {
                    return 'passwords_do_not_match'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Password Strength Indicator
              _buildPasswordStrengthIndicator(theme),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(theme),
              const SizedBox(height: 24),

              // Password Requirements
              _buildPasswordRequirements(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'secure_your_account'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'secure_account_description'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'security_tip'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'never_share_password'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: theme.iconTheme.color?.withOpacity(0.6),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFB74D), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final newPassword = _newPasswordController.text;
    int strength = 0;
    String strengthText = 'weak'.tr;
    Color strengthColor = Colors.red;

    if (newPassword.isNotEmpty) {
      if (newPassword.length >= 6) strength++;
      if (newPassword.length >= 8) strength++;
      if (RegExp(r'[A-Z]').hasMatch(newPassword)) strength++;
      if (RegExp(r'[0-9]').hasMatch(newPassword)) strength++;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) strength++;

      if (strength <= 1) {
        strengthText = 'weak'.tr;
        strengthColor = Colors.red;
      } else if (strength <= 3) {
        strengthText = 'medium'.tr;
        strengthColor = Colors.orange;
      } else {
        strengthText = 'strong'.tr;
        strengthColor = Colors.green;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'password_strength'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              strengthText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: newPassword.isEmpty ? 0 : strength / 5,
            backgroundColor: theme.dividerColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB74D),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0xFFF57C00).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'update_password'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'password_requirements'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementItem(
            theme,
            'at_least_6_chars'.tr,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildRequirementItem(
            theme,
            'mix_upper_lower'.tr,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildRequirementItem(
            theme,
            'include_numbers_symbols'.tr,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildRequirementItem(
            theme,
            'avoid_common_passwords'.tr,
            Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(ThemeData theme, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
