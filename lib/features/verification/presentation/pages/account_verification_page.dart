import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../data/services/verification_service.dart';

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});

  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _pageIdController = TextEditingController();
  final _businessWebsiteController = TextEditingController();
  final _businessAddressController = TextEditingController();

  String _nodeType = 'user';
  File? _photoFile;
  File? _passportFile;
  bool _submitting = false;
  bool _loadingStatus = true;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _loadStatus(initial: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pageIdController.dispose();
    _businessWebsiteController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus({bool initial = false}) async {
    setState(() => _loadingStatus = true);
    try {
      final apiClient = context.read<ApiClient>();
      final service = VerificationService(apiClient);
      final res = await service.getStatus(
        nodeType: initial ? 'user' : _nodeType,
        nodeId: (_nodeType == 'page' && _pageIdController.text.isNotEmpty)
            ? int.tryParse(_pageIdController.text)
            : null,
      );
      setState(() => _statusData = res['data']);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _pickImage(ImageSource source, bool isPassport) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        if (isPassport) {
          _passportFile = File(picked.path);
        } else {
          _photoFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoFile == null || _passportFile == null) {
      Get.snackbar(
        'alert'.tr,
        'attach_photo_passport'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.1;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final service = VerificationService(apiClient);

      // 1. Upload Photo
      String? photoPath;
      final respPhoto = await apiClient.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: _photoFile!.path,
        fileFieldName: 'file',
      );
      if (respPhoto['status'] == 'success') {
        photoPath = respPhoto['data']['source'] ?? respPhoto['data']['url'];
      }
      setState(() => _uploadProgress = 0.5);

      // 2. Upload Passport
      String? passportPath;
      final respPassport = await apiClient.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: _passportFile!.path,
        fileFieldName: 'file',
      );
      if (respPassport['status'] == 'success') {
        passportPath =
            respPassport['data']['source'] ?? respPassport['data']['url'];
      }
      setState(() => _uploadProgress = 0.8);

      // 3. Final Submission
      final res = await service.requestVerification(
        nodeType: _nodeType,
        nodeId: _nodeType == 'page'
            ? int.tryParse(_pageIdController.text)
            : null,
        photo: photoPath,
        passport: passportPath,
        message: _messageController.text.trim(),
        businessWebsite: _businessWebsiteController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
      );

      Get.snackbar(
        'success'.tr,
        res['message'] ?? 'request_sent_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _loadStatus(); // Refresh status after submission
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _isVerified() {
    final status = _statusData?['request_status']?.toString() ?? 'not_sent';
    final verified = _statusData?['verified'] == true;
    return verified || status == 'verified';
  }

  bool _isPending() => _statusData?['request_status'] == 'pending';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'verification_center'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 24),
                  if (!_isVerified() && !_isPending()) _buildFormSection(),
                  if (_isPending()) _buildPendingView(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    final isVerified = _isVerified();
    final isPending = _isPending();

    Color bgColor = Colors.blue.withOpacity(0.08);
    Color borderColor = Colors.blue.withOpacity(0.2);
    Color iconColor = Colors.blue;
    IconData icon = Icons.security_outlined;
    String title = 'identity_verification_request'.tr;
    String subtitle = 'get_blue_checkmark'.tr;

    if (isVerified) {
      bgColor = Colors.green.withOpacity(0.08);
      borderColor = Colors.green.withOpacity(0.2);
      iconColor = Colors.green;
      icon = Icons.verified;
      title = 'account_is_verified'.tr;
      subtitle = 'enjoy_verified_features'.tr;
    } else if (isPending) {
      bgColor = Colors.amber.withOpacity(0.08);
      borderColor = Colors.amber.withOpacity(0.2);
      iconColor = Colors.amber[700]!;
      icon = Icons.hourglass_top_rounded;
      title = 'request_under_review'.tr;
      subtitle = 'team_reviewing_info'.tr;
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'what_to_verify'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTypeToggle(),
          const SizedBox(height: 24),
          _buildCustomField(
            controller: _messageController,
            label: 'request_message'.tr,
            hint: 'why_verified'.tr,
            icon: Icons.chat_bubble_outline,
            maxLines: 3,
          ),
          if (_nodeType == 'page') ...[
            const SizedBox(height: 16),
            _buildCustomField(
              controller: _pageIdController,
              label: 'page_id'.tr,
              hint: 'enter_page_id'.tr,
              icon: Icons.grid_view_rounded,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildCustomField(
              controller: _businessWebsiteController,
              label: 'business_website'.tr,
              hint: 'website_placeholder'.tr,
              icon: Icons.language,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'identity_documents'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildImagePickerBox(
                  'personal_photo'.tr,
                  _photoFile,
                  false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImagePickerBox('passport'.tr, _passportFile, true),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    final isDark = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typeItem('user', 'personal_account'.tr, Icons.person_outline),
          _typeItem('page', 'public_page'.tr, Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _typeItem(String type, String label, IconData icon) {
    bool isSelected = _nodeType == type;
    final isDark = Get.isDarkMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _nodeType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.grey[800] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.blue
                      : (isDark ? Colors.grey[500] : Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.blue
                      : (isDark ? Colors.grey[500] : Colors.grey),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    final isDark = Get.isDarkMode;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'field_required'.tr : null,
    );
  }

  Widget _buildImagePickerBox(String title, File? file, bool isPassport) {
    final isDark = Get.isDarkMode;
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery, isPassport),
      child: Stack(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: file != null
                    ? Colors.blue
                    : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: file != null ? 2 : 1.5,
              ),
              image: file != null
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
              boxShadow: file != null
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 10,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
          ),
          if (file != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        if (_submitting)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'uploading'.tr,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      "${(_uploadProgress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              shadowColor: Colors.blue.withOpacity(0.4),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    'send_verification_request'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingView() {
    final isDark = Get.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.hourglass_bottom_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'request_under_review_message'.tr,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.blue[300] : Colors.blue[900],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
