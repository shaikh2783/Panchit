import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../data/api/api_exception.dart';
import '../../data/services/auth_service.dart';

class SignUpController extends GetxController {
  SignUpController(this._authService, this._sessionController);

  final AuthService _authService;
  final SessionController _sessionController;

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final selectedGender = RxnString();
  final hasAcceptedTerms = false.obs;
  final isPasswordHidden = true.obs;
  final isSubmitting = false.obs;

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.toggle();
  }

  void setGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    selectedGender.value = selectedGender.value == normalized
        ? null
        : normalized;
  }

  void setTermsAccepted(bool? value) {
    hasAcceptedTerms.value = value ?? false;
  }

  String? validateUsername(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return AppTranslations.signUpUsernameRequired.tr;
    }
    if (normalized.length < 3) {
      return AppTranslations.signUpUsernameTooShort.tr;
    }
    return null;
  }

  String? validateEmail(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return AppTranslations.signUpEmailRequired.tr;
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(normalized)) {
      return AppTranslations.signUpEmailInvalid.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return AppTranslations.passwordRequired.tr;
    }
    if (normalized.length < 6) {
      return AppTranslations.signUpPasswordTooShort.tr;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.signUpConfirmPasswordRequired.tr;
    }
    if (value != passwordController.text) {
      return AppTranslations.signUpPasswordsDoNotMatch.tr;
    }
    return null;
  }

  String? validateFirstName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.signUpFirstNameRequired.tr;
    }
    return null;
  }

  String? validateLastName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.signUpLastNameRequired.tr;
    }
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!hasAcceptedTerms.value) {
      Get.snackbar(
        AppTranslations.signUpTermsRequiredTitle.tr,
        AppTranslations.signUpTermsRequiredMessage.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    isSubmitting.value = true;

    try {
      final result = await _authService.signUp(
        username: usernameController.text,
        email: emailController.text,
        password: passwordController.text,
        firstname: firstNameController.text,
        lastname: lastNameController.text,
        gender: selectedGender.value,
      );
      await _sessionController.applyLoginResult(result);
      if (_sessionController.state.value != SessionViewState.banned &&
          Get.key.currentState?.canPop() == true) {
        Get.key.currentState?.popUntil((route) => route.isFirst);
      }
    } on ApiException catch (error) {
      Get.snackbar(
        AppTranslations.signUpFailed.tr,
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.signUpFailed.tr,
        AppTranslations.signUpFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
