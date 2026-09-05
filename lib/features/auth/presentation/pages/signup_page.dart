import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/theme/panchit_auth_ui.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/data/models/gender.dart';
import 'package:snginepro/features/auth/data/datasources/gender_api_service.dart';
import 'package:snginepro/features/auth/presentation/pages/login_page.dart';
import 'package:snginepro/features/auth/presentation/pages/getting_started_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    this.addAccountMode = false,
  });

  final bool addAccountMode;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedGender;
  DateTime? _selectedBirthdate;

  static const String _deviceType = 'A';

  List<Gender> _genders = [];
  bool _loadingGenders = true;

  late AnimationController _formController;

  @override
  void initState() {
    super.initState();

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _formController.forward();

    _fetchGenders();
  }

  Future<void> _fetchGenders() async {
    try {
      final apiClient = context.read<ApiClient>();
      final genderService = GenderApiService(apiClient);

      final genders = await genderService.getGenders();

      if (mounted) {
        setState(() {
          _genders = genders;
          _loadingGenders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGenders = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _formController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Existing functional logic - unchanged
  // ---------------------------------------------------------------------------

  Future<void> _handleSignUp() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_agree_to_terms'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authNotifier = context.read<AuthNotifier>();

    final AuthResponse? response = await authNotifier.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      gender: _selectedGender,
      birthdate: _selectedBirthdate,
      deviceType: _deviceType,
    );

    if (!mounted) return;

    if (response != null) {
      PanchitSnackBar.showSuccess(
        context,
        'account_created_successfully'.tr,
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GettingStartedPage(
            addAccountMode: widget.addAccountMode,
          ),
        ),
      );
    } else {
      final error =
          authNotifier.errorMessage ??
              'registration_failed'.tr;

      PanchitSnackBar.showError(context, error);
    }
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'first_name_required'.tr;
    }

    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'last_name_required'.tr;
    }

    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'username_required'.tr;
    }

    final usernameRegex = RegExp(
      r'^[a-zA-Z0-9_]+$',
    );

    if (!usernameRegex.hasMatch(value.trim())) {
      return 'username_alphanumeric'.tr;
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr;
    }

    final emailRegex = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'invalid_email'.tr;
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

  String? _validateConfirmPassword(
      String? value,
      ) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }

    if (value != _passwordController.text) {
      return 'passwords_not_match'.tr;
    }

    return null;
  }

  Future<void> _selectBirthdate() async {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
            isDark
                ? const ColorScheme.dark(
              primary: PanchitAuthColors.purple,
              surface: PanchitAuthColors.inputDark,
              onSurface:
              Colors.white,
            )
                : const ColorScheme.light(
              primary: PanchitAuthColors.purple,
              surface: Colors.white,
              onSurface:
              Color(0xFF15151D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState =
    context.watch<AuthNotifier>();

    final isLoading = authState.isLoading;
    final errorMessage =
        authState.errorMessage;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: PanchitAuthColors.background(isDark),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              padding:
              const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                26,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _formController,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                      Tween<Offset>(
                        begin:
                        const Offset(
                          0,
                          0.025,
                        ),
                        end:
                        Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent:
                          _formController,
                          curve: Curves
                              .easeOutCubic,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                        children: [
                          _buildTopBrand(),

                          const SizedBox(
                            height: 24,
                          ),

                          _buildHeader(
                            isDark,
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          if (errorMessage !=
                              null) ...[
                            PanchitErrorBanner(
                              message: errorMessage,
                              isDark: isDark,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                          ],

                          _buildForm(
                            isDark,
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          _buildSignUpButton(
                            isLoading,
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          _buildDivider(
                            isDark,
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          _buildFooter(
                            isDark,
                            isLoading,
                          ),
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

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildTopBrand() {
    return Align(
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        duration:
        const Duration(
          milliseconds: 500,
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
          width: 52,
          height: 52,
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
              ? 'Create another account'
              : 'Create Your\nAccount',
          style: TextStyle(
            color: PanchitAuthColors.textPrimary(isDark),
            fontSize: 28,
            fontWeight:
            FontWeight.w700,
            height: 1.08,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          widget.addAccountMode
              ? 'Create another account with a new token'
              : 'start_journey'.tr,
          style: TextStyle(
            color: PanchitAuthColors.textSecondary(isDark),
            fontSize: 13.5,
            fontWeight:
            FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildResponsiveRow(
            first: PanchitTextField(
              isDark: isDark,
              controller:
              _firstNameController,
              label: 'first_name'.tr,
              hint:
              'enter_first_name'.tr,
              validator:
              _validateFirstName,
              onChanged: (_) =>
                  context
                      .read<
                      AuthNotifier
                  >()
                      .clearError(),
            ),
            second: PanchitTextField(
              isDark: isDark,
              controller:
              _lastNameController,
              label: 'last_name'.tr,
              hint:
              'enter_last_name'.tr,
              validator:
              _validateLastName,
              onChanged: (_) =>
                  context
                      .read<
                      AuthNotifier
                  >()
                      .clearError(),
            ),
          ),

          const SizedBox(height: 15),

          PanchitTextField(
            isDark: isDark,
            controller:
            _usernameController,
            label: 'username'.tr,
            hint: 'enter_username'.tr,
            validator:
            _validateUsername,
            onChanged: (_) =>
                context
                    .read<AuthNotifier>()
                    .clearError(),
          ),

          const SizedBox(height: 15),

          PanchitTextField(
            isDark: isDark,
            controller: _emailController,
            label: 'email'.tr,
            hint: 'enter_email'.tr,
            keyboardType:
            TextInputType
                .emailAddress,
            validator: _validateEmail,
            onChanged: (_) =>
                context
                    .read<AuthNotifier>()
                    .clearError(),
          ),

          const SizedBox(height: 15),

          PanchitTextField(
            isDark: isDark,
            controller:
            _passwordController,
            label: 'password'.tr,
            hint: 'enter_password'.tr,
            obscureText:
            _obscurePassword,
            validator:
            _validatePassword,
            onChanged: (_) =>
                context
                    .read<AuthNotifier>()
                    .clearError(),
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
                    ? Icons
                    .visibility_off_outlined
                    : Icons
                    .visibility_outlined,
                color:
                isDark
                    ? const Color(
                  0xFF858796,
                )
                    : const Color(
                  0xFF777984,
                ),
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 15),

          PanchitTextField(
            isDark: isDark,
            controller:
            _confirmPasswordController,
            label:
            'confirm_password'.tr,
            hint:
            'confirm_your_password'
                .tr,
            obscureText:
            _obscureConfirmPassword,
            validator:
            _validateConfirmPassword,
            onChanged: (_) =>
                context
                    .read<AuthNotifier>()
                    .clearError(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword =
                  !_obscureConfirmPassword;
                });
              },
              splashRadius: 20,
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons
                    .visibility_off_outlined
                    : Icons
                    .visibility_outlined,
                color:
                isDark
                    ? const Color(
                  0xFF858796,
                )
                    : const Color(
                  0xFF777984,
                ),
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 15),

          _buildResponsiveRow(
            first:
            _buildGenderDropdown(
              isDark,
            ),
            second:
            _buildBirthdateField(
              isDark,
            ),
          ),

          const SizedBox(height: 20),

          _buildTermsCheckbox(
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        if (constraints.maxWidth <
            350) {
          return Column(
            children: [
              first,

              const SizedBox(
                height: 15,
              ),

              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(child: first),

            const SizedBox(width: 12),

            Expanded(child: second),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Gender
  // ---------------------------------------------------------------------------

  Widget _buildGenderDropdown(
      bool isDark,
      ) {
    if (_loadingGenders) {
      return _buildLoadingDropdown(
        isDark,
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          '${'gender'.tr} (${'optional'.tr})',
          style: TextStyle(
            color:
            isDark
                ? const Color(
              0xFFE5E5EC,
            )
                : const Color(
              0xFF282832,
            ),
            fontSize: 11.5,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: Icon(
            Icons
                .keyboard_arrow_down_rounded,
            size: 20,
            color:
            isDark
                ? const Color(
              0xFF858796,
            )
                : const Color(
              0xFF777984,
            ),
          ),
          decoration: panchitFieldDecoration(
            isDark: isDark,
            hint: '',
          ),
          dropdownColor:
          isDark
              ? PanchitAuthColors.inputDark
              : Colors.white,
          style: TextStyle(
            color:
            isDark
                ? Colors.white
                : const Color(
              0xFF17171E,
            ),
            fontSize: 13,
            fontWeight:
            FontWeight.w400,
          ),
          items:
          _genders.isEmpty
              ? null
              : _genders.map((
              gender,
              ) {
            return DropdownMenuItem<
                String
            >(
              value: gender.id,
              child: Text(
                gender.name,
                overflow:
                TextOverflow
                    .ellipsis,
              ),
            );
          }).toList(),
          onChanged:
          _genders.isEmpty
              ? null
              : (value) {
            setState(() {
              _selectedGender =
                  value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoadingDropdown(
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          '${'gender'.tr} (${'optional'.tr})',
          style: TextStyle(
            color:
            isDark
                ? const Color(
              0xFFE5E5EC,
            )
                : const Color(
              0xFF282832,
            ),
            fontSize: 11.5,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        Container(
          height: 46,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          decoration: BoxDecoration(
            color:
            isDark
                ? PanchitAuthColors.inputDark
                : Colors.white,
            borderRadius:
            BorderRadius.circular(8),
            border: Border.all(
              color:
              isDark
                  ? PanchitAuthColors.borderDark
                  : PanchitAuthColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'gender'.tr,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                    isDark
                        ? const Color(
                      0xFF606271,
                    )
                        : const Color(
                      0xFFA0A1AA,
                    ),
                    fontSize: 12.5,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const SizedBox(
                width: 15,
                height: 15,
                child:
                CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor:
                  AlwaysStoppedAnimation<
                      Color
                  >(
                    PanchitAuthColors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Birth date
  // ---------------------------------------------------------------------------

  Widget _buildBirthdateField(
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          '${'birthdate'.tr} (${'optional'.tr})',
          style: TextStyle(
            color:
            isDark
                ? const Color(
              0xFFE5E5EC,
            )
                : const Color(
              0xFF282832,
            ),
            fontSize: 11.5,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        InkWell(
          onTap: _selectBirthdate,
          borderRadius:
          BorderRadius.circular(8),
          child: Container(
            height: 46,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 13,
            ),
            decoration: BoxDecoration(
              color:
              isDark
                  ? PanchitAuthColors.inputDark
                  : Colors.white,
              borderRadius:
              BorderRadius.circular(8),
              border: Border.all(
                color:
                isDark
                    ? PanchitAuthColors.borderDark
                    : PanchitAuthColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedBirthdate ==
                        null
                        ? 'select_birthdate'
                        .tr
                        : '${_selectedBirthdate!.year}-'
                        '${_selectedBirthdate!.month.toString().padLeft(2, '0')}-'
                        '${_selectedBirthdate!.day.toString().padLeft(2, '0')}',
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style: TextStyle(
                      color:
                      _selectedBirthdate ==
                          null
                          ? isDark
                          ? const Color(
                        0xFF606271,
                      )
                          : const Color(
                        0xFFA0A1AA,
                      )
                          : isDark
                          ? Colors.white
                          : const Color(
                        0xFF17171E,
                      ),
                      fontSize: 12.5,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 17,
                  color:
                  isDark
                      ? const Color(
                    0xFF858796,
                  )
                      : const Color(
                    0xFF777984,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Terms
  // ---------------------------------------------------------------------------

  Widget _buildTermsCheckbox(
      bool isDark,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreeToTerms,
            activeColor: PanchitAuthColors.purple,
            side: BorderSide(
              color:
              isDark
                  ? const Color(
                0xFF555767,
              )
                  : const Color(
                0xFFB8B9C1,
              ),
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                4,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _agreeToTerms =
                    value ?? false;
              });
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: PanchitAuthColors.textSecondary(isDark),
                fontSize: 11.5,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: 'i_agree_to'.tr,
                ),

                WidgetSpan(
                  alignment:
                  PlaceholderAlignment
                      .middle,
                  child:
                  GestureDetector(
                    onTap:
                        () =>
                        _launchURL(
                          'https://www.panchit.com/static/terms',
                        ),
                    child: const Text(
                      ' ',
                    ),
                  ),
                ),

                WidgetSpan(
                  alignment:
                  PlaceholderAlignment
                      .middle,
                  child:
                  GestureDetector(
                    onTap:
                        () =>
                        _launchURL(
                          'https://www.panchit.com/static/terms',
                        ),
                    child: Text(
                      'terms_and_conditions'
                          .tr,
                      style:
                      const TextStyle(
                        color:
                        PanchitAuthColors.purple,
                        fontSize:
                        11.5,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ),
                ),

                TextSpan(
                  text:
                  ' ${'and'.tr} ',
                ),

                WidgetSpan(
                  alignment:
                  PlaceholderAlignment
                      .middle,
                  child:
                  GestureDetector(
                    onTap:
                        () =>
                        _launchURL(
                          'https://www.panchit.com/static/privacy',
                        ),
                    child: Text(
                      'privacy_policy'.tr,
                      style:
                      const TextStyle(
                        color:
                        PanchitAuthColors.purple,
                        fontSize:
                        11.5,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CTA
  // ---------------------------------------------------------------------------

  Widget _buildSignUpButton(
      bool isLoading,
      ) {
    return PanchitPrimaryButton(
      label: 'create_account'.tr,
      onPressed: _handleSignUp,
      isLoading: isLoading,
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildDivider(bool isDark) {
    return PanchitDivider(
      text: 'or'.tr,
      isDark: isDark,
    );
  }

  Widget _buildFooter(
      bool isDark,
      bool isLoading,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'already_have_account'.tr,
            style: TextStyle(
              color: PanchitAuthColors.textSecondary(isDark),
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(width: 4),

        TextButton(
          onPressed:
          isLoading
              ? null
              : () {
            Navigator
                .pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (
                    context,
                    ) =>
                    LoginPage(
                      addAccountMode:
                      widget
                          .addAccountMode,
                    ),
              ),
            );
          },
          style:
          TextButton.styleFrom(
            foregroundColor:
            PanchitAuthColors.purple,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 2,
              vertical: 2,
            ),
            minimumSize:
            Size.zero,
            tapTargetSize:
            MaterialTapTargetSize
                .shrinkWrap,
          ),
          child: Text(
            'sign_in'.tr,
            style:
            const TextStyle(
              color: PanchitAuthColors.purple,
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Existing URL logic - unchanged
  // ---------------------------------------------------------------------------

  Future<void> _launchURL(
      String urlString,
      ) async {
    final Uri url =
    Uri.parse(urlString);

    if (!await launchUrl(
      url,
      mode:
      LaunchMode
          .externalApplication,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not launch the link',
          ),
        ),
      );
    }
  }
}