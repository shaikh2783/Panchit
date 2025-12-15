import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/stories/application/bloc/stories_bloc.dart';
class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});
  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}
class _CreateStoryPageState extends State<CreateStoryPage> {
  XFile? _mediaFile;
  CachedVideoPlayerPlus? _videoController;
  bool _isLoading = false;
  bool _isVideo = false;
  /// اختيار صورة من المعرض أو الكاميرا
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    setState(() {
      _mediaFile = pickedFile;
      _isVideo = false;
    });
  }
  /// اختيار فيديو من المعرض أو الكاميرا
  Future<void> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (pickedFile == null) return;
    // تهيئة video player للمعاينة
    final videoFile = File(pickedFile.path);
    final controller = CachedVideoPlayerPlus.file(videoFile);
    try {
      await controller.initialize();
      controller.controller.setLooping(true);
      controller.controller.play();
      setState(() {
        _mediaFile = pickedFile;
        _isVideo = true;
        _videoController = controller;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الفيديو: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _createStory() async {
    if (_mediaFile == null) return;
    setState(() { _isLoading = true; });
    try {
      final path = _mediaFile!.path;
      context.read<StoriesBloc>().add(
        CreateStoryEvent(
          imagePath: _isVideo ? null : path,
          videoPath: _isVideo ? path : null,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isVideo ? '✅ تم إنشاء قصة الفيديو بنجاح' : '✅ تم إنشاء قصة الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إنشاء القصة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
        if(mounted) {
            setState(() { _isLoading = false; });
        }
    }
  }
  @override
  void dispose() {
    _videoController?.controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  Widget _buildMediaPreview() {
    if (_isVideo && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.controller.value.aspectRatio,
        child: VideoPlayer(_videoController!.controller),
      );
    }
    return Image.file(
      File(_mediaFile!.path),
      fit: BoxFit.contain,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // المحتوى الرئيسي
          if (_mediaFile == null)
            _buildEmptyState(context)
          else
            _buildPreviewWithControls(context),
          // شريط العلوي
          _buildTopBar(context),
          // مؤشر التحميل
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Publishing...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر الإغلاق
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Iconsax.close_circle, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // زر المشاركة
            if (_mediaFile != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey.shade600, Colors.grey.shade700]
                        : [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _createStory,
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isVideo ? Iconsax.video : Iconsax.send_2,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Share',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة رئيسية
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.camera,
                  color: Theme.of(context).primaryColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 32),
              // العنوان
              Text(
                'Add to Your Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your moments with friends',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              // بطاقة الصور
              _buildMediaCard(
                context: context,
                icon: Iconsax.gallery,
                title: 'Photo',
                subtitle: 'Share a photo from gallery or take a new one',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                onGalleryTap: () => _pickImage(ImageSource.gallery),
                onCameraTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              // بطاقة الفيديو
              _buildMediaCard(
                context: context,
                icon: Iconsax.video_play,
                title: 'Video',
                subtitle: 'Share a video from gallery or record a new one',
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                onGalleryTap: () => _pickVideo(ImageSource.gallery),
                onCameraTap: () => _pickVideo(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMediaCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onGalleryTap,
    required VoidCallback onCameraTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    onTap: onGalleryTap,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    onTap: onCameraTap,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary
          ? Colors.white.withOpacity(0.15)
          : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPreviewWithControls(BuildContext context) {
    return Stack(
      children: [
        // المعاينة بملء الشاشة
        Positioned.fill(
          child: _buildMediaPreview(),
        ),
        // طبقة تعتيم خفيفة
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        // أدوات التحكم السفلية
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // معلومات الملف
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isVideo ? Iconsax.video_play : Iconsax.gallery,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isVideo ? 'Video ready to share' : 'Photo ready to share',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // زر تغيير
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _mediaFile = null;
                        _videoController?.controller.dispose();
                        _videoController?.dispose();
                        _videoController = null;
                        _isVideo = false;
                      });
                    },
                    icon: const Icon(Iconsax.refresh, size: 20),
                    label: const Text('Choose Another'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
