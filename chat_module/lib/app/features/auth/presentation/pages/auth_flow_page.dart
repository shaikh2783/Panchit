import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/app_controller.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../data/models/auth_flow_state_model.dart';
import '../../data/services/auth_service.dart';

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  late final SessionController _sessionController;
  late final AuthService _authService;
  late final ChatAppPreferences _preferences;
  late final TextEditingController _codeController;

  bool _verifying = false;
  bool _resending = false;
  bool _refreshing = false;
  bool _preparingSession = false;
  bool _signingOut = false;
  Future<void>? _sessionPreparation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sessionController = Get.find<SessionController>();
    _authService = Get.find<AuthService>();
    _preferences = Get.find<ChatAppPreferences>();
    _codeController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      try {
        await _ensureSessionPrepared();
      } catch (_) {
        // The visible refresh action retries session preparation with feedback.
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _ensureSessionPrepared() {
    if (!mounted) {
      return Future<void>.value();
    }
    final activePreparation = _sessionPreparation;
    if (activePreparation != null) {
      return activePreparation;
    }

    late final Future<void> trackedPreparation;
    if (!_preparingSession) {
      setState(() => _preparingSession = true);
    }
    trackedPreparation = _prepareSessionForFlow().whenComplete(() {
      if (identical(_sessionPreparation, trackedPreparation)) {
        _sessionPreparation = null;
        if (mounted) {
          setState(() => _preparingSession = false);
        } else {
          _preparingSession = false;
        }
      }
    });
    _sessionPreparation = trackedPreparation;
    return trackedPreparation;
  }

  Future<void> _prepareSessionForFlow() async {
    if (!_preferences.hasPendingSession()) {
      return;
    }
    final step = _currentStep;
    if (step == 'two_factor') {
      return;
    }
    await _sessionController.promotePendingSession();
  }

  String get _currentStep =>
      _sessionController.authFlowState.value?.resolvedNextStep ?? '';

  bool get _busy =>
      _verifying ||
      _resending ||
      _refreshing ||
      _preparingSession ||
      _signingOut;

  Future<void> _signOut() async {
    if (_busy) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await _sessionController.signOut();
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Future<void> _verifyTwoFactor() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = AppTranslations.verificationCodeRequired.tr;
      });
      return;
    }

    final userId = _preferences.getPendingUserId() ?? 0;
    if (userId <= 0) {
      setState(() {
        _errorMessage = AppTranslations.authUnableToLoadState.tr;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.verifyTwoFactorCode(
        userId: userId,
        code: code,
      );
      await _sessionController.applyLoginResult(result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppTranslations.authUnableToVerifyCode.tr;
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resendActivationCode() async {
    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      final state = await _authService.resendEmailActivationCode(
        authToken:
            _preferences.getAuthToken() ?? _preferences.getPendingAuthToken(),
      );
      if (!mounted) {
        return;
      }
      await _sessionController.applyAuthFlowState(state);
      Get.snackbar(
        AppTranslations.activationCodeSent.tr,
        AppTranslations.activationCodeSent.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppTranslations.authUnableToResendCode.tr;
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  Future<void> _verifyActivationCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = AppTranslations.verificationCodeRequired.tr;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final state = await _authService.verifyEmailActivationCode(
        code: code,
        authToken:
            _preferences.getAuthToken() ?? _preferences.getPendingAuthToken(),
      );
      if (state.resolvedNextStep != 'activation' &&
          _preferences.hasPendingSession()) {
        await _sessionController.promotePendingSession();
      }
      await _sessionController.applyAuthFlowState(state);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppTranslations.authUnableToVerifyCode.tr;
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  Future<void> _refreshAuthState() async {
    setState(() {
      _refreshing = true;
      _errorMessage = null;
    });

    try {
      await _ensureSessionPrepared();
      if (!mounted) {
        return;
      }
      final state = await _authService.fetchAuthState();
      if (!mounted) {
        return;
      }
      await _sessionController.applyAuthFlowState(state);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppTranslations.authUnableToLoadState.tr;
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final appController = Get.find<AppController>();

    return Obx(() {
      final runtimeName = appController.appDisplayName.value.trim();
      final appName = runtimeName.isEmpty
          ? AppTranslations.appName.tr
          : runtimeName;
      final flowState = _sessionController.authFlowState.value;
      final config = _configFor(flowState);

      return PopScope<void>(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: palette.canvas,
          appBar: MessengerAppBar(
            title: appName,
            showDivider: false,
            actions: [
              IconButton(
                tooltip: AppTranslations.backToLogin.tr,
                onPressed: _busy ? null : _signOut,
                icon: _signingOut
                    ? const _ButtonSpinner()
                    : const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 32),
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(config.icon, color: config.color, size: 26),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        config.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        config.description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: palette.muted),
                      ),
                      if ((flowState?.email ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.field,
                            borderRadius: BorderRadius.circular(
                              MessengerDesign.compactRadius,
                            ),
                            border: Border.all(
                              color: palette.divider,
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: MessengerDesign.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  flowState!.email,
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_showsCodeField(config.step)) ...[
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _codeController,
                          enabled: !_busy,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.characters,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                          ],
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          onFieldSubmitted: (_) {
                            if (_busy) {
                              return;
                            }
                            if (config.step == 'two_factor') {
                              _verifyTwoFactor();
                            } else {
                              _verifyActivationCode();
                            }
                          },
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w700,
                              ),
                          decoration: InputDecoration(
                            labelText: AppTranslations.verificationCode.tr,
                            hintText: AppTranslations.verificationCodeHint.tr,
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                          ),
                        ),
                      ],
                      if (_errorMessage != null &&
                          _errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _InlineError(message: _errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      _AuthFlowActions(
                        step: config.step,
                        verifying: _verifying,
                        resending: _resending,
                        refreshing: _refreshing,
                        preparing: _preparingSession,
                        signingOut: _signingOut,
                        onVerifyTwoFactor: _verifyTwoFactor,
                        onVerifyActivation: _verifyActivationCode,
                        onResendActivation: _resendActivationCode,
                        onRefresh: _refreshAuthState,
                        onBackToLogin: _signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _showsCodeField(String step) {
    return step == 'activation' || step == 'two_factor';
  }

  _AuthFlowConfig _configFor(AuthFlowStateModel? state) {
    final step = state?.resolvedNextStep ?? '';
    switch (step) {
      case 'two_factor':
        return _AuthFlowConfig(
          step: step,
          title: AppTranslations.authTwoFactorTitle.tr,
          description: state?.message.trim().isNotEmpty == true
              ? state!.message
              : AppTranslations.authTwoFactorDescription.tr,
          icon: Icons.verified_user_rounded,
          color: MessengerDesign.primary,
        );
      case 'activation':
        return _AuthFlowConfig(
          step: step,
          title: AppTranslations.authActivationTitle.tr,
          description: AppTranslations.authActivationDescription.tr,
          icon: Icons.mark_email_unread_outlined,
          color: MessengerDesign.primary,
        );
      case 'approval':
        return _AuthFlowConfig(
          step: step,
          title: AppTranslations.authApprovalTitle.tr,
          description: AppTranslations.authApprovalDescription.tr,
          icon: Icons.hourglass_top_rounded,
          color: MessengerDesign.warning,
        );
      case 'getting_started':
        return _AuthFlowConfig(
          step: step,
          title: AppTranslations.authGettingStartedTitle.tr,
          description: AppTranslations.authGettingStartedDescription.tr,
          icon: Icons.auto_awesome_outlined,
          color: MessengerDesign.primary,
        );
      default:
        return _AuthFlowConfig(
          step: step,
          title: AppTranslations.authFlowHeadline.tr,
          description: AppTranslations.authFlowDescription.trParams({
            'step': step,
          }),
          icon: Icons.security_rounded,
          color: MessengerDesign.primary,
        );
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: MessengerDesign.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MessengerDesign.compactRadius),
        border: Border.all(
          color: MessengerDesign.destructive.withValues(alpha: 0.22),
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 19,
              color: MessengerDesign.destructive,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MessengerDesign.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFlowActions extends StatelessWidget {
  const _AuthFlowActions({
    required this.step,
    required this.verifying,
    required this.resending,
    required this.refreshing,
    required this.preparing,
    required this.signingOut,
    required this.onVerifyTwoFactor,
    required this.onVerifyActivation,
    required this.onResendActivation,
    required this.onRefresh,
    required this.onBackToLogin,
  });

  final String step;
  final bool verifying;
  final bool resending;
  final bool refreshing;
  final bool preparing;
  final bool signingOut;
  final VoidCallback onVerifyTwoFactor;
  final VoidCallback onVerifyActivation;
  final VoidCallback onResendActivation;
  final VoidCallback onRefresh;
  final VoidCallback onBackToLogin;

  bool get _busy =>
      verifying || resending || refreshing || preparing || signingOut;

  @override
  Widget build(BuildContext context) {
    if (step == 'activation') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : onVerifyActivation,
              child: verifying
                  ? const _ButtonSpinner(light: true)
                  : Text(AppTranslations.verifyAndContinue.tr),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : onResendActivation,
            child: resending
                ? const _ButtonSpinner()
                : Text(AppTranslations.resendCode.tr),
          ),
        ],
      );
    }

    if (step == 'two_factor') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : onVerifyTwoFactor,
              child: verifying
                  ? const _ButtonSpinner(light: true)
                  : Text(AppTranslations.verifyAndContinue.tr),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : onBackToLogin,
            child: signingOut
                ? const _ButtonSpinner()
                : Text(AppTranslations.backToLogin.tr),
          ),
        ],
      );
    }

    if (step == 'approval') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _busy ? null : onRefresh,
              child: refreshing || preparing
                  ? const _ButtonSpinner()
                  : Text(AppTranslations.retry.tr),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : onBackToLogin,
            child: signingOut
                ? const _ButtonSpinner()
                : Text(AppTranslations.backToLogin.tr),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _busy ? null : onBackToLogin,
        child: signingOut
            ? const _ButtonSpinner()
            : Text(AppTranslations.backToLogin.tr),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: light ? Colors.white : MessengerDesign.primary,
      ),
    );
  }
}

class _AuthFlowConfig {
  const _AuthFlowConfig({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String step;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
