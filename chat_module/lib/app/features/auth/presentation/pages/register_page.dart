import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/controllers/app_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/utils/legal_document_links.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../controllers/sign_up_controller.dart';

class RegisterPage extends GetView<SignUpController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final appController = Get.find<AppController>();

    return Obx(() {
      final runtimeName = appController.appDisplayName.value.trim();
      final appName = runtimeName.isEmpty
          ? AppTranslations.appName.tr
          : runtimeName;
      final isSubmitting = controller.isSubmitting.value;

      return PopScope<void>(
        canPop: !isSubmitting,
        child: Scaffold(
          backgroundColor: palette.canvas,
          appBar: MessengerAppBar(
            title: appName,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).maybePop(),
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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AutofillGroup(
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.registerTitle.tr,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslations.registerSubtitle.tr,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: palette.muted),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: controller.firstNameController,
                            validator: controller.validateFirstName,
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: InputDecoration(
                              labelText:
                                  AppTranslations.signUpFirstNameLabel.tr,
                              hintText: AppTranslations.signUpFirstNameHint.tr,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: controller.lastNameController,
                            validator: controller.validateLastName,
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: InputDecoration(
                              labelText: AppTranslations.signUpLastNameLabel.tr,
                              hintText: AppTranslations.signUpLastNameHint.tr,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: controller.usernameController,
                            validator: controller.validateUsername,
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.newUsername],
                            decoration: InputDecoration(
                              labelText: AppTranslations.signUpUsernameLabel.tr,
                              hintText: AppTranslations.signUpUsernameHint.tr,
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: controller.emailController,
                            validator: controller.validateEmail,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: AppTranslations.signUpEmailLabel.tr,
                              hintText: AppTranslations.signUpEmailHint.tr,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${AppTranslations.signUpGenderLabel.tr} · ${AppTranslations.optionalLabel.tr}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: _GenderChoice(
                                    label: AppTranslations.signUpGenderMale.tr,
                                    value: 'male',
                                    selected:
                                        controller.selectedGender.value ==
                                        'male',
                                    enabled: !isSubmitting,
                                    onSelected: controller.setGender,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _GenderChoice(
                                    label:
                                        AppTranslations.signUpGenderFemale.tr,
                                    value: 'female',
                                    selected:
                                        controller.selectedGender.value ==
                                        'female',
                                    enabled: !isSubmitting,
                                    onSelected: controller.setGender,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(
                            () => TextFormField(
                              controller: controller.passwordController,
                              validator: controller.validatePassword,
                              enabled: !isSubmitting,
                              obscureText: controller.isPasswordHidden.value,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: AppTranslations.passwordLabel.tr,
                                hintText: AppTranslations.passwordHint.tr,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : controller.togglePasswordVisibility,
                                  icon: Icon(
                                    controller.isPasswordHidden.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ConfirmPasswordField(
                            controller: controller,
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 18),
                          _TermsAgreement(
                            controller: controller,
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 24),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: controller.isSubmitting.value
                                    ? null
                                    : controller.submit,
                                child: controller.isSubmitting.value
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(AppTranslations.createAccount.tr),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  AppTranslations.alreadyHaveAccount.tr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: palette.muted),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                child: Text(AppTranslations.signIn.tr),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class _ConfirmPasswordField extends StatefulWidget {
  const _ConfirmPasswordField({
    required this.controller,
    required this.enabled,
  });

  final SignUpController controller;
  final bool enabled;

  @override
  State<_ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<_ConfirmPasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller.confirmPasswordController,
      validator: widget.controller.validateConfirmPassword,
      enabled: widget.enabled,
      obscureText: _isHidden,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      enableSuggestions: false,
      autocorrect: false,
      onFieldSubmitted: (_) {
        if (widget.enabled) {
          widget.controller.submit();
        }
      },
      decoration: InputDecoration(
        labelText: AppTranslations.signUpConfirmPasswordLabel.tr,
        hintText: AppTranslations.signUpConfirmPasswordHint.tr,
        prefixIcon: const Icon(Icons.lock_reset_rounded),
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _isHidden = !_isHidden)
              : null,
          icon: Icon(
            _isHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.label,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      child: InkWell(
        onTap: enabled ? () => onSelected(value) : null,
        borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? palette.primarySoft : palette.field,
            borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
            border: Border.all(
              color: selected ? MessengerDesign.primary : palette.divider,
              width: selected ? 1.2 : 0.7,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 19,
                color: selected ? MessengerDesign.primary : palette.subtle,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? MessengerDesign.primary : palette.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.controller, required this.enabled});

  final SignUpController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);

    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: controller.hasAcceptedTerms.value,
            onChanged: enabled ? controller.setTermsAccepted : null,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                runSpacing: 2,
                children: [
                  Text(
                    AppTranslations.signUpAgreementPrefix.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                  _LegalLink(
                    label: AppTranslations.signUpTermsOfUse.tr,
                    uri: LegalDocumentLinks.termsOfUse,
                  ),
                  Text(
                    AppTranslations.signUpAgreementAnd.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                  _LegalLink(
                    label: AppTranslations.signUpPrivacyPolicy.tr,
                    uri: LegalDocumentLinks.privacyPolicy,
                  ),
                  Text(
                    AppTranslations.signUpAgreementSuffix.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
      ),
      child: Text(label),
    );
  }
}
