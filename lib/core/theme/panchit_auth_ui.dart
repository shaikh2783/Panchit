import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared widgets for the onboarding / auth flow (OnboardingPage, LoginPage,
/// SignUpPage), built on the color tokens in [PanchitAuthColors]
/// (see app_colors.dart). Keeping these in one place ensures every screen
/// in that flow uses the same gradient button, text field and
/// error/divider styling.
///
/// Centralized success/error snackbar used across the onboarding/auth flow.
class PanchitSnackBar {
  PanchitSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, PanchitAuthColors.success, duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, PanchitAuthColors.error, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    Duration? duration,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}

/// The primary gradient CTA button (Next / Get Started, Sign In, Create
/// Account) shared by the onboarding and auth pages.
class PanchitPrimaryButton extends StatelessWidget {
  const PanchitPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 50,
    this.borderRadius = 10,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: PanchitAuthColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: PanchitAuthColors.purple.withOpacity(0.17),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: trailingIcon != null ? 48 : 16,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              if (trailingIcon != null && !isLoading)
                PositionedDirectional(
                  end: 18,
                  child: Icon(
                    trailingIcon,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The secondary outlined button (e.g. "Sign Up" on the login page) sharing
/// the same border/foreground treatment as the rest of the flow.
class PanchitOutlinedButton extends StatelessWidget {
  const PanchitOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isDark,
    this.height = 49,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? Colors.white : PanchitAuthColors.purple,
          disabledForegroundColor: isDark
              ? Colors.white.withOpacity(0.4)
              : PanchitAuthColors.purple.withOpacity(0.4),
          side: BorderSide(
            color: PanchitAuthColors.border(isDark),
          ),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// The labeled text field shared by the login and sign-up forms.
class PanchitTextField extends StatelessWidget {
  const PanchitTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PanchitAuthColors.textPrimary(isDark)
                .withOpacity(isDark ? 0.9 : 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          cursorColor: PanchitAuthColors.purple,
          style: TextStyle(
            color: PanchitAuthColors.textFieldValue(isDark),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: panchitFieldDecoration(
            isDark: isDark,
            hint: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Standalone decoration factory reused by [PanchitTextField] and other
/// form controls (e.g. dropdowns, date pickers) so borders/fills match.
InputDecoration panchitFieldDecoration({
  required bool isDark,
  required String hint,
  Widget? suffixIcon,
}) {
  final borderColor = PanchitAuthColors.border(isDark);

  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: PanchitAuthColors.inputFill(isDark),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    hintStyle: TextStyle(
      color: PanchitAuthColors.textFieldHint(isDark),
      fontSize: 13,
      fontWeight: FontWeight.w400,
    ),
    errorStyle: const TextStyle(
      color: PanchitAuthColors.error,
      fontSize: 11,
      height: 1.3,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: PanchitAuthColors.purple,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: PanchitAuthColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: PanchitAuthColors.error,
        width: 1.4,
      ),
    ),
  );
}

/// The inline error banner shown above the form on login/sign-up.
class PanchitErrorBanner extends StatelessWidget {
  const PanchitErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: PanchitAuthColors.error.withOpacity(isDark ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: PanchitAuthColors.error.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: PanchitAuthColors.error,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark
                    ? PanchitAuthColors.errorTextDark
                    : PanchitAuthColors.errorTextLight,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "or continue with" / "or" divider shared by login and sign-up.
class PanchitDivider extends StatelessWidget {
  const PanchitDivider({
    super.key,
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? const Color(0xFF252839)
        : const Color(0xFFE6E6EC);

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dividerColor,
            thickness: 1,
            height: 1,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              color: PanchitAuthColors.textMuted(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        Expanded(
          child: Divider(
            color: dividerColor,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}
