import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:snginepro/App_Settings.dart';
import 'package:snginepro/core/theme/panchit_auth_ui.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:snginepro/features/auth/presentation/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.addAccountMode = false,
  });

  final bool addAccountMode;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  late AnimationController _formController;

  String get _deviceType =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'I' : 'A';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? AppSettings.googleClientIdIOS
        : null,
  );

  @override
  void initState() {
    super.initState();

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _formController.forward();
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    _formController.dispose();

    super.dispose();
  }

  String _translate({
    required String key,
    required String fallback,
  }) {
    final translated = key.tr;

    return translated == key ? fallback : translated;
  }

  Future<void> _handleLogin() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authNotifier = context.read<AuthNotifier>();

    final AuthResponse? response = await authNotifier.signIn(
      identity: _identityController.text.trim(),
      password: _passwordController.text,
      deviceType: _deviceType,
    );

    if (!mounted) return;

    if (response != null) {
      final displayName = response.userDisplayName;

      final message = displayName != null
          ? 'welcome_back_user'.trParams({
        'name': displayName,
      })
          : (response.message ?? 'login_success'.tr);

      PanchitSnackBar.showSuccess(context, message);

      if (widget.addAccountMode) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }

      return;
    }

    final error =
        authNotifier.errorMessage ?? 'login_failed'.tr;

    PanchitSnackBar.showError(context, error);
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
    if (!AppSettings.enableGoogleSignIn) {
      PanchitSnackBar.showError(
        context,
        'تسجيل الدخول عبر Google معطل حالياً',
      );

      return;
    }

    final validationError =
    AppSettings.validateGoogleSignInConfig();

    if (validationError != null) {
      PanchitSnackBar.showError(context, validationError);

      return;
    }

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final serverAuthCode = googleUser.serverAuthCode;

      if ((idToken == null || idToken.isEmpty) &&
          (serverAuthCode == null || serverAuthCode.isEmpty)) {
        throw PlatformException(
          code: 'google_sign_in_missing_token',
          message:
          'Google Sign-In did not return an ID token on this device.',
        );
      }

      if (!mounted) return;

      final authNotifier = context.read<AuthNotifier>();

      final AuthResponse? response =
      await authNotifier.signInWithGoogle(
        googleId: googleUser.id,
        email: googleUser.email,
        firstName:
        googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName
            ?.split(' ')
            .skip(1)
            .join(' '),
        picture: googleUser.photoUrl,
        idToken: idToken ?? serverAuthCode,
        deviceType: _deviceType,
      );

      if (!mounted) return;

      if (response != null) {
        final displayName = response.userDisplayName;

        final message = displayName != null
            ? 'Welcome back, $displayName! 🎉'
            : (response.message ??
            'Successfully logged in.');

        PanchitSnackBar.showSuccess(context, message);

        if (widget.addAccountMode) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }

        return;
      }

      final error = authNotifier.errorMessage ??
          'Login failed. Please try again.';

      PanchitSnackBar.showError(context, error);
    } catch (error) {
      if (!mounted) return;

      PanchitSnackBar.showError(
        context,
        'Google Sign-In failed: $error',
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final credential =
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userId = credential.userIdentifier;

      if (userId == null) {
        if (!mounted) return;

        PanchitSnackBar.showError(
          context,
          'Apple Sign-In did not return a valid user.',
        );

        return;
      }

      final identityToken = credential.identityToken;

      if (identityToken == null ||
          identityToken.isEmpty) {
        if (!mounted) return;

        PanchitSnackBar.showError(
          context,
          'Apple Sign-In did not return an identity token.',
        );

        return;
      }

      if (!mounted) return;

      final authNotifier = context.read<AuthNotifier>();

      final AuthResponse? response =
      await authNotifier.signInWithApple(
        appleId: userId,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
        identityToken: identityToken,
        deviceType: 'I',
        deviceName: 'iPhone',
      );

      if (!mounted) return;

      if (response != null) {
        final displayName = response.userDisplayName;

        final message = displayName != null
            ? 'Welcome back, $displayName! 🎉'
            : (response.message ??
            'Successfully logged in.');

        PanchitSnackBar.showSuccess(context, message);

        if (widget.addAccountMode) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }

        return;
      }

      final error = authNotifier.errorMessage ??
          'Login failed. Please try again.';

      PanchitSnackBar.showError(context, error);
    } catch (error) {
      if (!mounted) return;

      PanchitSnackBar.showError(
        context,
        'Apple Sign-In failed: $error',
      );
    }
  }

  void _openSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpPage(
          addAccountMode: widget.addAccountMode,
        ),
      ),
    );
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>();

    final isLoading = authState.isLoading;
    final errorMessage = authState.errorMessage;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final showGoogle =
        AppSettings.enableGoogleSignIn;

    final showApple =
        defaultTargetPlatform == TargetPlatform.iOS;

    final showSocialLogin =
        showGoogle || showApple;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: PanchitAuthColors.background(isDark),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _formController,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _formController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          _buildLogo(),

                          const SizedBox(height: 30),

                          _buildHeader(isDark),

                          const SizedBox(height: 28),

                          if (errorMessage != null) ...[
                            PanchitErrorBanner(
                              message: errorMessage,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 18),
                          ],

                          _buildForm(isDark),

                          const SizedBox(height: 22),

                          _buildLoginButton(isLoading),

                          const SizedBox(height: 12),

                          _buildSignUpButton(
                            isDark: isDark,
                            isLoading: isLoading,
                          ),

                          if (showSocialLogin) ...[
                            const SizedBox(height: 24),

                            _buildDivider(isDark),

                            const SizedBox(height: 18),

                            _buildSocialButtons(
                              isLoading: isLoading,
                              isDark: isDark,
                              showGoogle: showGoogle,
                              showApple: showApple,
                            ),
                          ],

                          const SizedBox(height: 24),

                          _buildBottomHint(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(
          milliseconds: 550,
        ),
        tween: Tween(
          begin: 0.85,
          end: 1,
        ),
        curve: Curves.easeOutBack,
        builder: (
            context,
            value,
            child,
            ) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Image.asset(
          'assets/app_icon.png',
          width: 62,
          height: 62,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          widget.addAccountMode
              ? _translate(
            key: 'add_another_account',
            fallback: 'Add another account',
          )
              : _translate(
            key: 'login_welcome_title',
            fallback:
            'Welcome to\nPanchit 👋',
          ),
          style: TextStyle(
            color: PanchitAuthColors.textPrimary(isDark),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          widget.addAccountMode
              ? _translate(
            key: 'add_account_description',
            fallback:
            'Sign in to add another account.',
          )
              : _translate(
            key: 'login_welcome_description',
            fallback:
            'Connect with people around the world and share your moments.',
          ),
          style: TextStyle(
            color: PanchitAuthColors.textSecondary(isDark),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          PanchitTextField(
            controller: _identityController,
            label: 'email_username'.tr,
            hint: 'enter_email_username'.tr,
            keyboardType:
            TextInputType.emailAddress,
            textInputAction:
            TextInputAction.next,
            validator: _validateIdentity,
            onChanged: (_) {
              context
                  .read<AuthNotifier>()
                  .clearError();
            },
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          PanchitTextField(
            controller: _passwordController,
            label: 'password'.tr,
            hint: 'enter_password'.tr,
            obscureText: _obscurePassword,
            textInputAction:
            TextInputAction.done,
            validator: _validatePassword,
            onChanged: (_) {
              context
                  .read<AuthNotifier>()
                  .clearError();
            },
            onFieldSubmitted: (_) {
              _handleLogin();
            },
            isDark: isDark,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword =
                  !_obscurePassword;
                });
              },
              splashRadius: 20,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: PanchitAuthColors.textMuted(isDark),
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Align(
            alignment:
            AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _openForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: PanchitAuthColors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'forgot_password'.tr,
                style: TextStyle(
                  color: PanchitAuthColors.linkAccent(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(
      bool isLoading,
      ) {
    return PanchitPrimaryButton(
      label: 'sign_in'.tr,
      onPressed: _handleLogin,
      isLoading: isLoading,
    );
  }

  Widget _buildSignUpButton({
    required bool isDark,
    required bool isLoading,
  }) {
    return PanchitOutlinedButton(
      label: widget.addAccountMode
          ? _translate(
        key: 'create_another_account',
        fallback: 'Create another account',
      )
          : _translate(
        key: 'create_account',
        fallback: 'Sign Up',
      ),
      onPressed: isLoading ? null : _openSignUp,
      isDark: isDark,
    );
  }

  Widget _buildDivider(bool isDark) {
    return PanchitDivider(
      text: _translate(
        key: 'or_continue_with',
        fallback: 'or continue with',
      ),
      isDark: isDark,
    );
  }

  Widget _buildSocialButtons({
    required bool isLoading,
    required bool isDark,
    required bool showGoogle,
    required bool showApple,
  }) {
    return Row(
      children: [
        if (showGoogle)
          Expanded(
            child: _buildGoogleSignInButton(
              isLoading,
              isDark,
            ),
          ),

        if (showGoogle && showApple)
          const SizedBox(width: 12),

        if (showApple)
          Expanded(
            child: _buildAppleSignInButton(
              isLoading,
              isDark,
            ),
          ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(
      bool isLoading,
      bool isDark,
      ) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          foregroundColor: isDark
              ? Colors.white
              : const Color(0xFF202027),
          backgroundColor: isDark
              ? PanchitAuthColors.surfaceDark
              : Colors.white,
          side: BorderSide(
            color: PanchitAuthColors.border(isDark),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFFDB4437),
                    Color(0xFFF4B400),
                    Color(0xFF0F9D58),
                  ],
                ).createShader(bounds);
              },
              child: const Icon(
                Iconsax.google_1,
                color: Colors.white,
                size: 19,
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                'Google',
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton(
      bool isLoading,
      bool isDark,
      ) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed:
        isLoading ? null : _handleAppleSignIn,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          foregroundColor: isDark
              ? Colors.white
              : const Color(0xFF202027),
          backgroundColor: isDark
              ? PanchitAuthColors.surfaceDark
              : Colors.white,
          side: BorderSide(
            color: PanchitAuthColors.border(isDark),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apple,
              color: isDark
                  ? Colors.white
                  : Colors.black,
              size: 20,
            ),

            const SizedBox(width: 7),

            const Flexible(
              child: Text(
                'Apple',
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomHint(bool isDark) {
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _translate(
                key: 'panchit_auth_footer',
                fallback:
                'Connect • Share • Belong',
              ),
              style: TextStyle(
                color: PanchitAuthColors.textMuted(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}