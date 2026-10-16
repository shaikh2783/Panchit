import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/app_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends GetView<ForgotPasswordController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final appController = Get.find<AppController>();

    return Obx(() {
      final runtimeName = appController.appDisplayName.value.trim();
      final appName = runtimeName.isEmpty
          ? AppTranslations.appName.tr
          : runtimeName;
      final stage = controller.stage.value;
      final isSubmitting = controller.isSubmitting.value;
      final isPasswordHidden = controller.isPasswordHidden.value;
      final isConfirmPasswordHidden = controller.isConfirmPasswordHidden.value;
      final canLeave =
          stage == ForgotPasswordStage.requestCode && !isSubmitting;

      return PopScope<void>(
        canPop: canLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !isSubmitting) {
            _goBack(stage);
          }
        },
        child: Scaffold(
          backgroundColor: palette.canvas,
          appBar: MessengerAppBar(
            title: appName,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: isSubmitting ? null : () => _handleBack(stage),
              icon: const BackButtonIcon(),
            ),
            showDivider: false,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RecoveryProgress(stage: stage),
                        const SizedBox(height: 24),
                        Text(
                          AppTranslations.forgotPasswordTitle.tr,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.forgotPasswordSubtitle.tr,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: palette.muted),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _stageTitle(stage),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppTranslations.forgotPasswordResetHelp.tr,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.muted),
                        ),
                        if (stage != ForgotPasswordStage.requestCode) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
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
                              children: [
                                Icon(
                                  Icons.alternate_email_rounded,
                                  size: 19,
                                  color: MessengerDesign.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.currentIdentifier,
                                    textDirection: TextDirection.ltr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (stage == ForgotPasswordStage.requestCode)
                          _RequestCodeForm(
                            controller: controller,
                            isSubmitting: isSubmitting,
                          ),
                        if (stage == ForgotPasswordStage.verifyCode)
                          _VerifyCodeForm(
                            controller: controller,
                            isSubmitting: isSubmitting,
                            onRequestAnotherCode: _requestAnotherCode,
                          ),
                        if (stage == ForgotPasswordStage.resetPassword)
                          _ResetPasswordForm(
                            controller: controller,
                            isSubmitting: isSubmitting,
                            isPasswordHidden: isPasswordHidden,
                            isConfirmPasswordHidden: isConfirmPasswordHidden,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _handleBack(ForgotPasswordStage stage) {
    if (stage == ForgotPasswordStage.requestCode) {
      Get.back<void>();
      return;
    }
    _goBack(stage);
  }

  Future<void> _requestAnotherCode() async {
    controller.isSubmitting.value = true;
    try {
      controller.codeController.clear();
      controller.stage.value = ForgotPasswordStage.requestCode;
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      controller.isSubmitting.value = false;
    }
    if (controller.requestFormKey.currentState == null) {
      return;
    }
    await controller.submitRequestCode();
  }

  void _goBack(ForgotPasswordStage stage) {
    switch (stage) {
      case ForgotPasswordStage.requestCode:
        Get.back<void>();
      case ForgotPasswordStage.verifyCode:
        controller.stage.value = ForgotPasswordStage.requestCode;
      case ForgotPasswordStage.resetPassword:
        controller.stage.value = ForgotPasswordStage.verifyCode;
    }
  }

  String _stageTitle(ForgotPasswordStage stage) {
    switch (stage) {
      case ForgotPasswordStage.requestCode:
        return AppTranslations.forgotPasswordRequestAction.tr;
      case ForgotPasswordStage.verifyCode:
        return AppTranslations.forgotPasswordVerifyAction.tr;
      case ForgotPasswordStage.resetPassword:
        return AppTranslations.forgotPasswordResetAction.tr;
    }
  }
}

class _RecoveryProgress extends StatelessWidget {
  const _RecoveryProgress({required this.stage});

  final ForgotPasswordStage stage;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final currentStep = stage.index;

    return Semantics(
      label: '${currentStep + 1} / 3',
      child: Row(
        children: List.generate(3, (index) {
          final active = index <= currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 7),
              decoration: BoxDecoration(
                color: active ? MessengerDesign.primary : palette.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RequestCodeForm extends StatelessWidget {
  const _RequestCodeForm({
    required this.controller,
    required this.isSubmitting,
  });

  final ForgotPasswordController controller;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.requestFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: controller.identifierController,
            validator: controller.validateIdentifier,
            enabled: !isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            onFieldSubmitted: (_) {
              if (!isSubmitting) {
                controller.submitRequestCode();
              }
            },
            decoration: InputDecoration(
              labelText: AppTranslations.forgotPasswordIdentifierLabel.tr,
              hintText: AppTranslations.forgotPasswordIdentifierHint.tr,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 18),
          _SubmitButton(
            label: AppTranslations.forgotPasswordRequestAction.tr,
            isSubmitting: isSubmitting,
            onPressed: controller.submitRequestCode,
          ),
        ],
      ),
    );
  }
}

class _VerifyCodeForm extends StatelessWidget {
  const _VerifyCodeForm({
    required this.controller,
    required this.isSubmitting,
    required this.onRequestAnotherCode,
  });

  final ForgotPasswordController controller;
  final bool isSubmitting;
  final VoidCallback onRequestAnotherCode;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.verifyFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: controller.codeController,
            validator: controller.validateCode,
            enabled: !isSubmitting,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [LengthLimitingTextInputFormatter(12)],
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) {
              if (!isSubmitting) {
                controller.submitVerifyCode();
              }
            },
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: AppTranslations.forgotPasswordCodeLabel.tr,
              hintText: AppTranslations.forgotPasswordCodeHint.tr,
              prefixIcon: const Icon(Icons.verified_user_outlined),
            ),
          ),
          const SizedBox(height: 18),
          _SubmitButton(
            label: AppTranslations.forgotPasswordVerifyAction.tr,
            isSubmitting: isSubmitting,
            onPressed: controller.submitVerifyCode,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isSubmitting ? null : onRequestAnotherCode,
            child: Text(AppTranslations.resendCode.tr),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm({
    required this.controller,
    required this.isSubmitting,
    required this.isPasswordHidden,
    required this.isConfirmPasswordHidden,
  });

  final ForgotPasswordController controller;
  final bool isSubmitting;
  final bool isPasswordHidden;
  final bool isConfirmPasswordHidden;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.resetFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: controller.passwordController,
            validator: controller.validateNewPassword,
            enabled: !isSubmitting,
            obscureText: isPasswordHidden,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppTranslations.forgotPasswordNewPasswordLabel.tr,
              hintText: AppTranslations.forgotPasswordNewPasswordHint.tr,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: isSubmitting
                    ? null
                    : controller.togglePasswordVisibility,
                icon: Icon(
                  isPasswordHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.confirmPasswordController,
            validator: controller.validateConfirmPassword,
            enabled: !isSubmitting,
            obscureText: isConfirmPasswordHidden,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) {
              if (!isSubmitting) {
                controller.submitResetPassword();
              }
            },
            decoration: InputDecoration(
              labelText: AppTranslations.forgotPasswordConfirmPasswordLabel.tr,
              hintText: AppTranslations.forgotPasswordConfirmPasswordHint.tr,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: isSubmitting
                    ? null
                    : controller.toggleConfirmPasswordVisibility,
                icon: Icon(
                  isConfirmPasswordHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SubmitButton(
            label: AppTranslations.forgotPasswordResetAction.tr,
            isSubmitting: isSubmitting,
            onPressed: controller.submitResetPassword,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
  });

  final String label;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSubmitting ? null : onPressed,
        child: isSubmitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
