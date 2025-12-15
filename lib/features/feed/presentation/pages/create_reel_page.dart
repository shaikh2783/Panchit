import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/theme/theme_controller.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/features/feed/data/models/create_post_request.dart';
import 'package:snginepro/features/feed/data/services/post_management_api_service.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
class CreateReelPage extends StatefulWidget {
  const CreateReelPage({super.key});
  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}
class _CreateReelPageState extends State<CreateReelPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ThemeController _themeController = Get.find();
  File? _videoFile;
  CachedVideoPlayerPlus? _videoController;
  UploadedFileData? _uploadedVideo;
  bool _isUploading = false;
  bool _isCreating = false;
  double _uploadProgress = 0.0;
  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.controller.dispose();
    super.dispose();
  }
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? videoFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (videoFile != null) {
      setState(() {
        _videoFile = File(videoFile.path);
      });
      // Initialize video player for preview
      _videoController = CachedVideoPlayerPlus.file(
        _videoFile!,
      );
      await _videoController!.initialize();
      setState(() {});
      _videoController!.controller.setLooping(true);
      _videoController!.controller.play();
      // Auto-upload video
      await _uploadVideo();
    }
  }
  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    try {
      final postsService = PostsApiService(
        context.read<ApiClient>(),
      );
      final result = await postsService.uploadFile(
        _videoFile!,
        type: FileUploadType.video,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );
      setState(() {
        _uploadedVideo = result;
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم رفع الفيديو بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل رفع الفيديو: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _createReel() async {
    if (_uploadedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار فيديو أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isCreating = true;
    });
    try {
      // Extract relative path from thumb URL
      String? thumbPath;
      if (_uploadedVideo?.thumb != null) {
        final thumbUrl = _uploadedVideo!.thumb!;
        if (thumbUrl.contains('/content/uploads/')) {
          thumbPath = thumbUrl.split('/content/uploads/').last;
        } else {
          thumbPath = thumbUrl;
        }
      }
      final reelData = {
        'source': _uploadedVideo!.source,
        if (thumbPath != null) 'thumb': thumbPath,
      };
      final request = CreatePostRequest(
        handle: 'me',
        privacy: 'public',
        message: _descriptionController.text.trim(),
        reel: reelData,
        reelThumbnail: thumbPath,
      );
      final postsService = PostsApiService(
        context.read<ApiClient>(),
      );
      final response = await postsService.createPostAdvanced(request);
      if (response.isSuccess) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to refresh reels
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 تم نشر الريل بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.message ?? 'فشل إنشاء الريل');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل نشر الريل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إنشاء ريل',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_uploadedVideo != null && !_isCreating)
            TextButton(
              onPressed: _createReel,
              child: const Text(
                'نشر',
                style: TextStyle(
                  color: Color(0xFFE1306C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE1306C)),
                ),
              ),
            ),
        ],
      ),
      body: _videoFile == null
          ? _buildSelectVideoScreen(isDark)
          : _buildPreviewScreen(isDark),
    );
  }
  Widget _buildSelectVideoScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_rounded,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'اختر فيديو للريل',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('اختيار فيديو'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPreviewScreen(bool isDark) {
    return Column(
      children: [
        // Video Preview
        Expanded(
          child: Stack(
            children: [
              if (_videoController != null && _videoController!.controller.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.controller.value.aspectRatio,
                    child: VideoPlayer(_videoController!.controller),
                  ),
                )
              else
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              // Upload progress overlay
              if (_isUploading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _uploadProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE1306C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاري رفع الفيديو... ${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Change video button
              if (!_isUploading && _uploadedVideo != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Description input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'أضف وصف للريل...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
