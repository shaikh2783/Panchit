import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/presentation/pages/signup_page.dart';
/// 🎨 Ultra Modern Login Page - Complete Redesign
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  static const String _deviceType = 'A';
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
  }
  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    super.dispose();
  }
  Future<void> _handleLogin() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    final authNotifier = context.read<AuthNotifier>();
    final AuthResponse? response = await authNotifier.signIn(
      identity: _identityController.text.trim(),
      password: _passwordController.text,
      deviceType: _deviceType,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (response != null) {
      final displayName = response.userDisplayName;
      final message = displayName != null
          ? 'Welcome back, $displayName! 🎉'
          : (response.message ?? 'Successfully logged in.');
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final error = authNotifier.errorMessage ?? 'Login failed. Please try again.';
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
  String? _validateIdentity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or username is required';
    }
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
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
                          const SizedBox(height: 48),
                          // 💎 Glass Card with Form
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                _buildHeader(),
                                const SizedBox(height: 32),
                                // Error Banner
                                if (errorMessage != null) ...[
                                  _buildErrorBanner(errorMessage),
                                  const SizedBox(height: 20),
                                ],
                                // Form
                                _buildForm(),
                                const SizedBox(height: 24),
                                // Login Button
                                _buildLoginButton(isLoading),
                                const SizedBox(height: 20),
                                // Divider
                                _buildDivider(),
                                const SizedBox(height: 20),
                                // Footer
                                _buildFooter(),
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 50,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Panchit',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect • Share • Inspire',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // 💎 Solid Card with Dark Mode Support
  Widget _buildGlassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            fontSize: 15,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
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
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 📋 Form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email/Username Field
          _buildTextField(
            controller: _identityController,
            label: 'Email or Username',
            hint: 'Enter your email or username',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateIdentity,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
          ),
          const SizedBox(height: 16),
          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
            onFieldSubmitted: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.7),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 12),
          // Forgot Password
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 🎨 Custom TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A202C),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF5B86E5).withOpacity(0.8),
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDark 
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF4A5568),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFF718096),
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1A202C)
            : const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF5B86E5)
                : const Color(0xFF5B86E5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        errorStyle: TextStyle(
          color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
  // 🚀 Login Button
  Widget _buildLoginButton(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF5B86E5), const Color(0xFF36D1DC)]
              : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B86E5).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  // ➖ Divider
  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF718096),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
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
  Widget _buildFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'dont_have_account'.tr,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF4A5568),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
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
            'create_account'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 Panchit All rights reserved.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : const Color(0xFF718096),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
