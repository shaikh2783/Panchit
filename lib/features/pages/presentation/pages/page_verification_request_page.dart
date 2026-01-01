import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../data/models/page.dart';
import '../../domain/pages_repository.dart';

class PageVerificationRequestPage extends StatefulWidget {
  final PageModel page;

  const PageVerificationRequestPage({super.key, required this.page});

  @override
  State<PageVerificationRequestPage> createState() =>
      _PageVerificationRequestPageState();
}

class _PageVerificationRequestPageState
    extends State<PageVerificationRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessWebsiteController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _messageController = TextEditingController();

  File? _photoFile;
  File? _passportFile;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _businessWebsiteController.dispose();
    _businessAddressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isPassport) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isPassport) {
            _passportFile = File(pickedFile.path);
          } else {
            _photoFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _isUploadingImages = true;
      _uploadProgress = 0.0;
    });

    String? photoUrl;
    String? passportUrl;

    try {
      final apiClient = context.read<ApiClient>();
      
      // رفع صورة الصفحة إذا كانت موجودة
      if (_photoFile != null) {

        setState(() => _uploadProgress = 0.1);
        
        final photoResponse = await apiClient.multipartPost(
          configCfgP('file_upload'),
          body: {'type': 'photo'},
          filePath: _photoFile!.path,
          fileFieldName: 'file',
        );

        if (photoResponse['status'] == 'success' && photoResponse['data'] != null) {
          photoUrl = photoResponse['data']['source'] ?? photoResponse['data']['url'];

        }
      }

      setState(() => _uploadProgress = 0.5);

      // رفع صورة الجواز إذا كانت موجودة
      if (_passportFile != null) {

        final passportResponse = await apiClient.multipartPost(
          configCfgP('file_upload'),
          body: {'type': 'photo'},
          filePath: _passportFile!.path,
          fileFieldName: 'file',
        );

        if (passportResponse['status'] == 'success' && passportResponse['data'] != null) {
          passportUrl = passportResponse['data']['source'] ?? passportResponse['data']['url'];

        }
      }

      setState(() {
        _isUploadingImages = false;
        _uploadProgress = 1.0;
      });

      // إرسال طلب التوثيق مع روابط الصور
      final repo = context.read<PagesRepository>();
      final result = await repo.requestVerification(
        pageId: widget.page.id,
        photo: photoUrl,
        passport: passportUrl,
        businessWebsite: _businessWebsiteController.text.trim().isEmpty
            ? null
            : _businessWebsiteController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty
            ? null
            : _businessAddressController.text.trim(),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verification request submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {

        final errorMessage = e.toString();
        final isPending = errorMessage.contains('pending');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPending
                  ? '⏳ You already have a pending verification request'
                  : '❌ Failed to submit request: $e',
            ),
            backgroundColor: isPending ? Colors.orange : Colors.red,
            duration: Duration(seconds: isPending ? 5 : 4),
            action: isPending
                ? SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
        
        // إذا كان لديه طلب pending، أغلق الصفحة
        if (isPending) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, false);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('request_verification_title'.tr),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.page.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verify your page to get the blue checkmark',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.info_circle, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please provide the required documents to verify your page. All information will be reviewed by our team.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Photo Upload
            _buildImagePicker(
              title: 'Page Photo',
              subtitle: 'Upload a clear photo of your page/business',
              icon: Iconsax.camera,
              file: _photoFile,
              onTap: () => _showImageSourceDialog(false),
              onRemove: () => setState(() => _photoFile = null),
            ),
            const SizedBox(height: 16),

            // Passport/ID Upload
            _buildImagePicker(
              title: 'Passport/ID Document',
              subtitle: 'Upload your official identification',
              icon: Iconsax.card,
              file: _passportFile,
              onTap: () => _showImageSourceDialog(true),
              onRemove: () => setState(() => _passportFile = null),
            ),
            const SizedBox(height: 16),

            // Business Website
            TextFormField(
              controller: _businessWebsiteController,
              decoration: InputDecoration(
                labelText: 'Business Website',
                hintText: 'https://example.com',
                prefixIcon: const Icon(Iconsax.global),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Business Address
            TextFormField(
              controller: _businessAddressController,
              decoration: InputDecoration(
                labelText: 'Business Address',
                hintText: '123 Main Street, City, Country',
                prefixIcon: const Icon(Iconsax.location),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Additional Message',
                hintText: 'Tell us why you want to verify this page...',
                prefixIcon: const Icon(Iconsax.message_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Upload Progress Indicator
            if (_isUploadingImages)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading images... ${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isUploadingImages) ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.tick_circle, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: file != null ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    file != null ? Iconsax.tick_circle : icon,
                    color: file != null ? Colors.green : Colors.grey[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file != null ? 'Image selected ✓' : subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: file != null ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onRemove,
                  )
                else
                  Icon(Iconsax.arrow_right_3, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(bool isPassport) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera),
                title: Text('take_photo_button'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isPassport);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: Text('choose_from_gallery_button'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isPassport);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
