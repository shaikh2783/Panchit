import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/network/api_client.dart';

/// Forgot Password Page
/// 
/// Allows users to reset their password through email verification.
/// Steps:
/// 1. Enter email/username
/// 2. Receive verification code
/// 3. Verify code
/// 4. Create new password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _userEmail = '';
  String _resetKey = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setEmail(String email) {
    setState(() => _userEmail = email);
  }

  void _setResetKey(String key) {
    setState(() => _resetKey = key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('forgot_password'.tr),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1EnterEmail(
            tabController: _tabController,
            onEmailSet: _setEmail,
          ),
          _Step2VerifyCode(
            tabController: _tabController,
            userEmail: _userEmail,
            onResetKeySet: _setResetKey,
          ),
          _Step3ResetPassword(
            tabController: _tabController,
            userEmail: _userEmail,
            resetKey: _resetKey,
          ),
        ],
      ),
    );
  }
}

/// Step 1: Enter Email/Username
class _Step1EnterEmail extends StatefulWidget {
  final TabController tabController;
  final Function(String) onEmailSet;

  const _Step1EnterEmail({
    required this.tabController,
    required this.onEmailSet,
  });

  @override
  State<_Step1EnterEmail> createState() => _Step1EnterEmailState();
}

class _Step1EnterEmailState extends State<_Step1EnterEmail> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post(
        '/auth/forget_password',
        body: {'email': _emailController.text.trim()},
      );

      if (mounted) {
        if (response['status'] == 'success') {
          // Store email for next steps
          widget.onEmailSet(_emailController.text.trim());
          // Move to step 2
          widget.tabController.animateTo(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Verification code sent'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to send code';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'enter_email_username'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'we_will_send_verification_code'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'email_or_username'.tr,
                prefixIcon: const Icon(Iconsax.sms),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'this_field_is_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('send_code'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: Verify Code
class _Step2VerifyCode extends StatefulWidget {
  final TabController tabController;
  final String userEmail;
  final Function(String) onResetKeySet;

  const _Step2VerifyCode({
    required this.tabController,
    required this.userEmail,
    required this.onResetKeySet,
  });

  @override
  State<_Step2VerifyCode> createState() => _Step2VerifyCodeState();
}

class _Step2VerifyCodeState extends State<_Step2VerifyCode> {
  late List<TextEditingController> _codeControllers;
  bool _isLoading = false;
  String? _errorMessage;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(6, (_) => TextEditingController());
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _errorMessage = 'enter_all_digits'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post(
        '/auth/forget_password_confirm',
        body: {
          'email': widget.userEmail,
          'reset_key': code,
        },
      );

      if (mounted) {
        if (response['status'] == 'success') {
          // Store reset_key for next step
          widget.onResetKeySet(code);
          widget.tabController.animateTo(2);
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Invalid code';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _startResendTimer();

    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.post(
        '/auth/forget_password',
        body: {'email': widget.userEmail},
      );
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'enter_verification_code'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'we_sent_code_to_your_email'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Code Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 50,
                height: 60,
                child: TextFormField(
                  controller: _codeControllers[index],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Resend Code
          Center(
            child: Column(
              children: [
                if (!_canResend)
                  Text(
                    '${'resend_code_in'.tr} $_secondsRemaining ${'seconds'.tr}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  TextButton(
                    onPressed: _resendCode,
                    child: Text('resend_code'.tr),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('verify_code'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 3: Reset Password
class _Step3ResetPassword extends StatefulWidget {
  final TabController tabController;
  final String userEmail;
  final String resetKey;

  const _Step3ResetPassword({
    required this.tabController,
    required this.userEmail,
    required this.resetKey,
  });

  @override
  State<_Step3ResetPassword> createState() => _Step3ResetPasswordState();
}

class _Step3ResetPasswordState extends State<_Step3ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'passwords_do_not_match'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post(
        '/auth/forget_password_reset',
        body: {
          'email': widget.userEmail,
          'reset_key': widget.resetKey,
          'password': _passwordController.text,
          'confirm': _confirmPasswordController.text,
        },
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Password reset successful'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to reset password';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'create_new_password'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'enter_strong_password'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // New Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'new_password'.tr,
                prefixIcon: const Icon(Iconsax.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'this_field_is_required'.tr;
                }
                if (value.length < 8) {
                  return 'password_too_short'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'confirm_password'.tr,
                prefixIcon: const Icon(Iconsax.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () {
                    setState(
                      () =>
                          _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'this_field_is_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('reset_password'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
