import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';

/// صفحة تحديث صورة الملف الشخصي والغلاف للصفحة
class PageUpdatePicturesPage extends StatefulWidget {
  const PageUpdatePicturesPage({super.key, required this.page});

  final PageModel page;

  @override
  State<PageUpdatePicturesPage> createState() => _PageUpdatePicturesPageState();
}

class _PageUpdatePicturesPageState extends State<PageUpdatePicturesPage> {
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedAvatar;
  File? _selectedCover;
  
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('update_page_pictures_title'.tr),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Section
            _buildPictureSection(
              title: 'Profile Picture',
              subtitle: 'Upload your page profile picture',
              currentImage: widget.page.picture,
              selectedImage: _selectedAvatar,
              isUploading: _isUploadingAvatar,
              onPickImage: () => _pickImage(isAvatar: true),
              onUpload: _uploadAvatar,
              aspectRatio: 1.0,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            // Cover Photo Section
            _buildPictureSection(
              title: 'Cover Photo',
              subtitle: 'Upload your page cover photo',
              currentImage: widget.page.cover,
              selectedImage: _selectedCover,
              isUploading: _isUploadingCover,
              onPickImage: () => _pickImage(isAvatar: false),
              onUpload: _uploadCover,
              aspectRatio: 16 / 9,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureSection({
    required String title,
    required String subtitle,
    required String currentImage,
    required File? selectedImage,
    required bool isUploading,
    required VoidCallback onPickImage,
    required VoidCallback onUpload,
    required double aspectRatio,
  }) {
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Image Preview
        GestureDetector(
          onTap: onPickImage,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            selectedImage,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : currentImage.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: mediaAsset(currentImage).toString(),
                                fit: BoxFit.cover,
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.camera,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(
                              Iconsax.gallery_add,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Upload Progress
        if (isUploading)
          Column(
            children: [
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Iconsax.gallery),
                label: Text('choose_photo_button'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (selectedImage != null && !isUploading) ? onUpload : null,
                icon: const Icon(Iconsax.tick_circle),
                label: Text('upload_button'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: isAvatar ? 1000 : 1920,
        maxHeight: isAvatar ? 1000 : 1080,
      );

      if (image != null) {
        setState(() {
          if (isAvatar) {
            _selectedAvatar = File(image.path);
          } else {
            _selectedCover = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedAvatar == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload directly using multipart (like profile picture)
      final apiClient = context.read<ApiClient>();
      final repo = context.read<PagesRepository>();
      
      setState(() => _uploadProgress = 0.3);
      
      final response = await apiClient.multipartPost(
        '/data/pages/${widget.page.id}/picture',
        body: {},
        filePath: _selectedAvatar!.path,
        fileFieldName: 'picture',
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.3 + (sent / total * 0.7);
            });
          }
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Upload failed');
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selection and return
        setState(() {
          _selectedAvatar = null;
        });
        
        // Return to previous page with refresh flag
        Navigator.pop(context, true);
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _uploadCover() async {
    if (_selectedCover == null) return;

    setState(() {
      _isUploadingCover = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload directly using multipart (like profile cover)
      final apiClient = context.read<ApiClient>();
      final repo = context.read<PagesRepository>();
      
      setState(() => _uploadProgress = 0.3);
      
      final response = await apiClient.multipartPost(
        '/data/pages/${widget.page.id}/cover',
        body: {},
        filePath: _selectedCover!.path,
        fileFieldName: 'cover',
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.3 + (sent / total * 0.7);
            });
          }
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Upload failed');
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cover photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selection and return
        setState(() {
          _selectedCover = null;
        });
        
        // Return to previous page with refresh flag
        Navigator.pop(context, true);
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCover = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
