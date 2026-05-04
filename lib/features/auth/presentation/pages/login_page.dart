import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:snginepro/App_Settings.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/presentation/pages/signup_page.dart';
import 'package:snginepro/features/auth/presentation/pages/forgot_password_page.dart';

/// 🎨 Ultra Modern Login Page - Complete Redesign
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.addAccountMode = false});

  final bool addAccountMode;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String get _deviceType =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'I' : 'A';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],

  );

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
          ? 'welcome_back_user'.trParams({'name': displayName})
          : (response.message ?? 'login_success'.tr);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (widget.addAccountMode) {
        Navigator.of(context).pop(true);
      }
    } else {
      final error =
          authNotifier.errorMessage ?? 'login_failed'.tr;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String? _validateIdentity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_username_required'.tr;
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

  Future<void> _handleGoogleSignIn() async {
    // التحقق من تفعيل الميزة
    if (!AppSettings.enableGoogleSignIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تسجيل الدخول عبر Google معطل حالياً'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // التحقق من اكتمال الإعدادات
    final validationError = AppSettings.validateGoogleSignInConfig();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      // تسجيل الخروج أولاً لإظهار قائمة الحسابات في كل مرة
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled sign in
        return;
      }

      // الحصول على ID Token / Server Auth Code من Google
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final serverAuthCode = googleUser.serverAuthCode; // قد يكون موجود بدلاً من idToken
      
      
      if (!mounted) return;
      final authNotifier = context.read<AuthNotifier>();
      print('idToken: ${googleUser.email}');
      print('serverAuthCode: $serverAuthCode');
      final AuthResponse? response = await authNotifier.signInWithGoogle(
        googleId: googleUser.id,
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
        picture: googleUser.photoUrl,
        idToken: idToken ?? serverAuthCode, // استخدم serverAuthCode إذا لم يكن idToken متاح
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (widget.addAccountMode) {
          Navigator.of(context).pop(true);
        }
      } else {
        final error =
            authNotifier.errorMessage ?? 'Login failed. Please try again.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (error) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $error'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userId = credential.userIdentifier;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Apple Sign-In did not return a valid user.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Apple Sign-In did not return an identity token.',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      if (!mounted) return;
      final authNotifier = context.read<AuthNotifier>();
      final AuthResponse? response = await authNotifier.signInWithApple(
        appleId: userId,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
        identityToken: identityToken,
        deviceType: 'I',
        deviceName: 'iPhone',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (widget.addAccountMode) {
          Navigator.of(context).pop(true);
        }
      } else {
        final error =
            authNotifier.errorMessage ?? 'Login failed. Please try again.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple Sign-In failed: $error'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>();
    final isLoading = authState.isLoading;
    final errorMessage = authState.errorMessage;
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

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
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
              ),
            ),
          ),

          // ✨ Floating Particles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final offset =
                    (_backgroundController.value + index * 0.125) % 1;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: FadeTransition(
                  opacity: _formController,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _formController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
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

                                if (AppSettings.enableGoogleSignIn &&
                                    defaultTargetPlatform ==
                                        TargetPlatform.android) ...[
                                  _buildDivider(),
                                  const SizedBox(height: 20),
                                  _buildGoogleSignInButton(isLoading),
                                  const SizedBox(height: 20),
                                ] else if (isIOS) ...[
                                  _buildDivider(),
                                  const SizedBox(height: 20),
                                  _buildAppleSignInButton(isLoading),
                                  const SizedBox(height: 20),
                                ],

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
              Image.asset('assets/app_icon.png',height: 100,width: 100),
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
          'welcome_back'.tr,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A202C),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.addAccountMode ? 'Add another account' : 'sign_in_continue'.tr,
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
            label: 'email_username'.tr,
            hint: 'enter_email_username'.tr,
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateIdentity,
            onChanged: (_) => context.read<AuthNotifier>().clearError(),
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'password'.tr,
            hint: 'enter_password'.tr,
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 12),

          // Forgot Password
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'forgot_password'.tr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
        fillColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF5B86E5) : const Color(0xFF5B86E5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        errorStyle: TextStyle(
          color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'sign_in'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
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

  // 🔵 Google Sign-In Button
  Widget _buildGoogleSignInButton(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A202C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFF4285F4), // Blue
                        Color(0xFFDB4437), // Red
                        Color(0xFFF4B400), // Yellow
                        Color(0xFF0F9D58), // Green
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Icon(
                    Iconsax.google_1,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'sign_in_with_google'.tr,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.white : Colors.black;
    final foregroundColor = isDark ? Colors.black : Colors.white;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleAppleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apple,
                  color: foregroundColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'sign_in_with_apple'.tr,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
            'or'.tr,
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
              MaterialPageRoute(
                builder: (context) =>
                    SignUpPage(addAccountMode: widget.addAccountMode),
              ),
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
            widget.addAccountMode ? 'Create another account' : 'create_account'.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 Panchit. All rights reserved.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : const Color(0xFF718096),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
