import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/app_controller.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../data/services/auth_service.dart';
import '../controllers/forgot_password_controller.dart';
import '../controllers/login_controller.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final sessionController = Get.find<SessionController>();

    return Obx(() {
      final busy =
          controller.isSubmitting.value ||
          sessionController.isApplyingTimelineBridge.value;

      return PopScope<void>(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: palette.canvas,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 52).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: AutofillGroup(
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _LoginHeader(),
                                const SizedBox(height: 32),
                                Obx(() {
                                  if (!sessionController
                                      .hasTimelineBridgeSession
                                      .value) {
                                    return const SizedBox.shrink();
                                  }
                                  final loginBusy =
                                      controller.isSubmitting.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 22),
                                    child: _TimelineSessionRow(
                                      sessionController: sessionController,
                                      enabled: !loginBusy,
                                    ),
                                  );
                                }),
                                Obx(() {
                                  final busy =
                                      controller.isSubmitting.value ||
                                      sessionController
                                          .isApplyingTimelineBridge
                                          .value;
                                  return TextFormField(
                                    controller: controller.identifierController,
                                    validator: controller.validateIdentifier,
                                    enabled: !busy,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                      labelText: AppTranslations
                                          .loginIdentifierLabel
                                          .tr,
                                      hintText: AppTranslations
                                          .loginIdentifierHint
                                          .tr,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                                Obx(() {
                                  final busy =
                                      controller.isSubmitting.value ||
                                      sessionController
                                          .isApplyingTimelineBridge
                                          .value;
                                  return TextFormField(
                                    controller: controller.passwordController,
                                    validator: controller.validatePassword,
                                    enabled: !busy,
                                    obscureText:
                                        controller.isPasswordHidden.value,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onFieldSubmitted: (_) {
                                      if (!busy) {
                                        controller.submit();
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText:
                                          AppTranslations.passwordLabel.tr,
                                      hintText: AppTranslations.passwordHint.tr,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: busy
                                            ? null
                                            : controller
                                                  .togglePasswordVisibility,
                                        icon: Icon(
                                          controller.isPasswordHidden.value
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Obx(() {
                                    final busy =
                                        controller.isSubmitting.value ||
                                        sessionController
                                            .isApplyingTimelineBridge
                                            .value;
                                    return TextButton(
                                      onPressed: busy
                                          ? null
                                          : _openForgotPassword,
                                      child: Text(
                                        AppTranslations.forgotPassword.tr,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 10),
                                Obx(() {
                                  final submitting =
                                      controller.isSubmitting.value;
                                  final busy =
                                      submitting ||
                                      sessionController
                                          .isApplyingTimelineBridge
                                          .value;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: busy
                                          ? null
                                          : controller.submit,
                                      child: submitting
                                          ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(AppTranslations.signIn.tr),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        AppTranslations.dontHaveAccount.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: palette.muted),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Obx(() {
                                      final busy =
                                          controller.isSubmitting.value ||
                                          sessionController
                                              .isApplyingTimelineBridge
                                              .value;
                                      return TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const RegisterPage(),
                                                ),
                                              ),
                                        child: Text(
                                          AppTranslations.createAccount.tr,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _openForgotPassword() {
    Get.to(
      () => const ForgotPasswordPage(),
      binding: BindingsBuilder(() {
        Get.put(ForgotPasswordController(Get.find<AuthService>()));
      }),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final palette = MessengerDesign.of(context);

    return Obx(() {
      final appName = appController.appDisplayName.value.trim().isEmpty
          ? AppTranslations.appName.tr
          : appController.appDisplayName.value.trim();
      final logoUrl = appController.appDisplayLogo.value.trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BrandMark(imageUrl: logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MessengerDesign.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            AppTranslations.loginHeadline.tr,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            AppTranslations.loginSubtitle.tr,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: palette.muted),
          ),
        ],
      );
    });
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.divider, width: 0.7),
      ),
      child: imageUrl.isEmpty
          ? _fallbackLogo()
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => _fallbackLogo(),
              errorWidget: (_, _, _) => _fallbackLogo(),
            ),
    );
  }

  Widget _fallbackLogo() {
    return Image.asset(
      'assets/branding/app-icon-source.png',
      package: 'chat_module',
      fit: BoxFit.cover,
    );
  }
}

class _TimelineSessionRow extends StatelessWidget {
  const _TimelineSessionRow({
    required this.sessionController,
    required this.enabled,
  });

  final SessionController sessionController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name = sessionController.pendingTimelineUserName.value.trim();
      final picture = sessionController.pendingTimelineUserPicture.value.trim();
      final applying = sessionController.isApplyingTimelineBridge.value;

      return MessengerSection(
        margin: EdgeInsets.zero,
        child: MessengerRow(
          title: name.isEmpty ? AppTranslations.loginWithTimeline.tr : name,
          subtitle: name.isEmpty
              ? AppTranslations.loginWithTimelineSubtitle.tr
              : AppTranslations.loginWithTimeline.tr,
          leading: MessengerAvatar(name: name, imageUrl: picture, radius: 21),
          trailing: applying
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.login_rounded, color: MessengerDesign.primary),
          enabled: enabled && !applying,
          onTap: enabled && !applying ? _applySession : null,
        ),
      );
    });
  }

  Future<void> _applySession() async {
    final applied = await sessionController.applyTimelineBridgeSession();
    if (applied) {
      return;
    }
    Get.snackbar(
      AppTranslations.loginFailed.tr,
      AppTranslations.loginFailed.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
