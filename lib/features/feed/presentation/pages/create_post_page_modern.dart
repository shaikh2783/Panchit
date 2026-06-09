import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/theme/app_text_styles.dart';
import 'package:snginepro/core/theme/theme_controller.dart';
import 'package:snginepro/core/config/dynamic_app_config_provider.dart';
import 'package:snginepro/core/config/colored_pattern_model.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/create_post_request.dart';
import 'package:snginepro/features/feed/data/models/post_type_config.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_bloc.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_overview_event.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Professional create post page - supports dark mode
class CreatePostPageModern extends StatefulWidget {
  const CreatePostPageModern({
    super.key,
    this.handle,
    this.handleId,
    this.handleName,
    this.handleAvatar,
    this.initialPostType,
    this.showPrivacySelector = true,
    this.initialPrivacy,
    this.competition,
  });

  final String? handle; // 'me', 'page', 'group', 'event'
  final int? handleId; // ID for page/group/event
  final String? handleName; // Display name for page/group/event
  final String? handleAvatar; // Avatar for page/group/event
  final PostTypeOption? initialPostType; // Initial post type (e.g., Reel)
  final bool showPrivacySelector; // Toggle privacy picker visibility
  final String? initialPrivacy; // Optional starting privacy value
  final CompetitionModel? competition;

  @override
  State<CreatePostPageModern> createState() => _CreatePostPageModernState();
}

class _CreatePostPageModernState extends State<CreatePostPageModern> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _feelingValueController = TextEditingController();
  final List<File> _images = [];
  File? _video; // Single video file
  File? _audio; // Single audio file
  UploadedFileData? _uploadedVideo; // Video upload result with thumbnail
  final List<TextEditingController> _pollOptions = [
    TextEditingController(),
    TextEditingController(),
  ];

  PostTypeOption _selectedType = PostTypeOption.text;
  late String _privacy;
  bool _isAnonymous = false;
  bool _isScheduled = false;
  bool _isAdultContent = false;
  bool _isPaid = false;
  String? _scheduledDateTime; // تاريخ الجدولة بصيغة YYYY-MM-DD HH:mm:ss
  String? _postPrice; // سعر المنشور المدفوع
  bool _forSubscriptions = false; // للمشتركين فقط
  bool _isCreating = false;
  double _videoUploadProgress = 0.0; // 0.0 - 1.0
  
  // متغيرات الأنماط الملونة
  ColoredPattern? _selectedColoredPattern;
  bool _showColoredPatterns = false;
  bool _feelingsEnabled = false;
  bool _feelingsSynced = false;
  List<Map<String, dynamic>> _feelings = [];
  List<Map<String, dynamic>> _activities = [];
  String? _selectedFeelingAction;
  String? _selectedFeelingActivity;

  final ThemeController _themeController = Get.find();

  bool get _isCompetitionEntryMode => widget.competition != null;

  List<PostTypeOption> get _competitionAllowedPostTypes {
    final competition = widget.competition;
    if (competition == null) return const <PostTypeOption>[];
    switch (competition.allowedMediaType) {
      case CompetitionAllowedMediaType.imageOnly:
        return const <PostTypeOption>[PostTypeOption.photos];
      case CompetitionAllowedMediaType.videoOnly:
        return const <PostTypeOption>[PostTypeOption.video];
      case CompetitionAllowedMediaType.textOnly:
        return const <PostTypeOption>[PostTypeOption.text];
      case CompetitionAllowedMediaType.all:
        return const <PostTypeOption>[
          PostTypeOption.text,
          PostTypeOption.photos,
          PostTypeOption.video,
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _privacy = widget.initialPrivacy ?? 'public';
    // Set initial post type if provided
    if (widget.initialPostType != null) {
      _selectedType = widget.initialPostType!;
    }
    if (_isCompetitionEntryMode) {
      final allowedTypes = _competitionAllowedPostTypes;
      if (allowedTypes.isNotEmpty && !allowedTypes.contains(_selectedType)) {
        _selectedType = allowedTypes.first;
      }
    }
    // إضافة listeners للتحديث عند تغيير النص أو التركيز
    _textController.addListener(() => setState(() {}));
    _textFocusNode.addListener(() => setState(() {}));
    
    // تحديث الإعدادات من السيرفر عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final configProvider = Provider.of<DynamicAppConfigProvider>(context, listen: false);
      // تحديث الإعدادات إذا كانت قديمة (أكثر من 5 دقائق)
      if (configProvider.lastUpdate == null || 
          DateTime.now().difference(configProvider.lastUpdate!).inMinutes > 5) {
        configProvider.loadConfig(forceRefresh: true);
      }
      
      // تحميل بيانات الـ Feelings
      _loadFeelingsFromProvider();
    });
  }

  /// تحميل بيانات الـ Feelings من الـ Provider الموجود
  Future<void> _loadFeelingsFromProvider() async {
    try {
      final configProvider = Provider.of<DynamicAppConfigProvider>(context, listen: false);
      
      // التأكد من تحميل الإعدادات أولاً
      if (configProvider.appConfig == null) {
        await configProvider.loadConfig(forceRefresh: false);
      }
      
      // جلب البيانات من الـ Provider مباشرة باستخدام الـ getters الجديدة
      final feelingsData = configProvider.feelings ?? [];
      final activitiesData = configProvider.activities ?? [];
      
      // إذا لم تكن البيانات متوفرة، استخدم البيانات الافتراضية
      if (feelingsData.isEmpty && activitiesData.isEmpty) {
        _setDefaultFeelingsData();
        return;
      }
      
      setState(() {
        _feelingsEnabled = true; // نمكن الـ feelings دائماً إذا كانت البيانات متوفرة
        _feelings = feelingsData.map((f) => Map<String, dynamic>.from(f)).toList();
        _activities = activitiesData.map((a) => Map<String, dynamic>.from(a)).toList();
        _feelingsSynced = true;
      });

      final allActions = <String>{};
      for (var feeling in _feelings) {
        final action = feeling['action']?.toString();
        if (action != null && action.isNotEmpty) {
          allActions.add(action);
        }
      }
    } catch (e) {
      // في حالة الخطأ، نستخدم البيانات الافتراضية
      _setDefaultFeelingsData();
    }
  }

  /// تعيين بيانات افتراضية للـ Feelings والـ Activities
  void _setDefaultFeelingsData() {
    setState(() {
      _feelingsEnabled = true;
      _feelings = [
        {'action': 'happy', 'text': 'سعيد', 'value': 'happy'},
        {'action': 'sad', 'text': 'حزين', 'value': 'sad'},
        {'action': 'excited', 'text': 'متحمس', 'value': 'excited'},
        {'action': 'frustrated', 'text': 'محبط', 'value': 'frustrated'},
        {'action': 'grateful', 'text': 'ممتن', 'value': 'grateful'},
        {'action': 'tired', 'text': 'متعب', 'value': 'tired'},
      ];
      _activities = [
        {'action': 'listening', 'text': 'يستمع إلى', 'value': 'music'},
        {'action': 'watching', 'text': 'يشاهد', 'value': 'movie'},
        {'action': 'reading', 'text': 'يقرأ', 'value': 'book'},
        {'action': 'playing', 'text': 'يلعب', 'value': 'game'},
        {'action': 'eating', 'text': 'يتناول', 'value': 'food'},
        {'action': 'traveling', 'text': 'يسافر إلى', 'value': 'place'},
      ];
      _feelingsSynced = true;
    });
    
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _feelingValueController.dispose();
    for (var controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isCompetitionEntryMode &&
        !(widget.competition?.allowedMediaType.allowsImages ?? false)) {
      Get.snackbar(
        'error'.tr,
        'This competition only allows text or video entries.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images.map((e) => File(e.path)));
        _selectedType = PostTypeOption.photos; // Auto-switch to photos type
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_isCompetitionEntryMode &&
        !(widget.competition?.allowedMediaType.allowsVideo ?? false)) {
      Get.snackbar(
        'error'.tr,
        'This competition only allows text or image entries.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? videoFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (videoFile != null) {
      setState(() {
        _video = File(videoFile.path);
        // Only auto-switch to video if not already reel type
        if (_selectedType != PostTypeOption.reel) {
          _selectedType = PostTypeOption.video;
        }
        _images.clear(); // Clear images when video selected
      });
    }
  }

  Future<void> _pickAudio() async {
    // For now, using video picker as audio picker - can be enhanced with file_picker package
    final picker = ImagePicker();
    final XFile? audioFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (audioFile != null && audioFile.path.endsWith('.mp3') ||
        audioFile!.path.endsWith('.m4a')) {
      setState(() {
        _audio = File(audioFile.path);
        _selectedType = PostTypeOption.audio;
        _images.clear();
        _video = null;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _video = file; // Store file as video temporarily
          _selectedType = PostTypeOption.file;
          _images.clear();
          _audio = null;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_file'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // دوال الأنماط الملونة
  void _toggleColoredPatterns() {
    setState(() {
      _showColoredPatterns = !_showColoredPatterns;
      if (_showColoredPatterns) {
        // إزالة الصور والفيديو عند تفعيل الأنماط الملونة
        _images.clear();
        _video = null;
        _audio = null;
        _selectedType = PostTypeOption.colored;
      } else {
        _selectedColoredPattern = null;
        _selectedType = PostTypeOption.text;
      }
    });
  }

  void _selectColoredPattern(ColoredPattern? pattern) {
    setState(() {
      _selectedColoredPattern = pattern;
    });
  }

  Color _getPatternBackground() {
    if (_selectedColoredPattern == null) return Colors.transparent;
    
    if (_selectedColoredPattern!.backgroundColors != null) {
      final colorStr = _selectedColoredPattern!.backgroundColors!.primary.replaceAll('#', '');
      return Color(int.parse('0xFF$colorStr'));
    }
    
    return const Color(0xFF6C5CE7);
  }

  FeelingData? _buildFeelingData() {
    final action = _selectedFeelingAction;
    if (action == null || action.isEmpty) return null;
    final value = _selectedFeelingActivity ?? _feelingValueController.text.trim();
    if (value.isEmpty) return null;
    return FeelingData(action: action, value: value);
  }

  bool _shouldHideTextField() {
    // إخفاء TextField عندما:
    // 1. يتم اختيار خلفية ملونة
    // 2. النص فارغ أو بيض فقط
    // 3. النص غير مُركز (TextField غير مُفعل)
    return _selectedColoredPattern != null && 
           (_textController.text.isEmpty || _textController.text.trim().isEmpty) &&
           !_textFocusNode.hasFocus;
  }

  /// تحويل اسم الأيقونة إلى emoji
  String _convertIconNameToEmoji(String? iconName) {
    if (iconName == null || iconName.isEmpty) return '😊';
    
    switch (iconName.toLowerCase()) {
      // Feelings/Actions Icons
      case 'grinning-face-with-smiling-eyes':
      case 'grinning-face':
        return '😊';
      case 'headphone':
        return '🎧';
      case 'glasses':
        return '👓';
      case 'video-game':
        return '🎮';
      case 'shortcake':
        return '🍰';
      case 'tropical-drink':
        return '🍹';
      case 'airplane':
        return '✈️';
      case 'books':
        return '�';
      case 'calendar':
        return '📅';
      case 'birthday-cake':
        return '🎂';
      case 'magnifying-glass-tilted-left':
        return '�';
      
      // Emotions Icons
      case 'smiling-face-with-heart-eyes':
        return '😍';
      case 'relieved-face':
        return '�';
      case 'flexed-biceps':
        return '💪';
      case 'disappointed-face':
        return '😞';
      case 'winking-face-with-tongue':
        return '😜';
      case 'downcast-face-with-sweat':
        return '😓';
      case 'sleeping-face':
        return '�';
      case 'confused-face':
        return '😕';
      case 'worried-face':
        return '😟';
      case 'angry-face':
        return '😠';
      case 'pouting-face':
        return '😡';
      case 'face-with-open-mouth':
        return '😲';
      case 'pensive-face':
        return '😔';
      case 'confounded-face':
        return '😖';
      
      // Legacy support
      case 'happy':
        return '😊';
      case 'sad':
      case 'crying':
        return '�';
      case 'angry':
        return '😠';
      case 'heart-eyes':
      case 'love':
        return '�';
      case 'laughing':
      case 'laugh':
        return '�';
      case 'surprised':
      case 'shock':
        return '�';
      case 'tired':
      case 'exhausted':
        return '😴';
      case 'thinking':
        return '🤔';
      case 'cool':
        return '😎';
      case 'wink':
        return '�';
      case 'kiss':
        return '😘';
      case 'excited':
        return '🤩';
      case 'nervous':
        return '�';
      
      default:
        return '😊';
    }
  }

  /// الحصول على ترجمة الـ Action بناءً على اسم العمل
  String _getTranslatedAction(String action) {
    switch (action.toLowerCase()) {
      case 'feeling':
        return 'feeling_action'.tr;
      case 'listening to':
        return 'listening_to_action'.tr;
      case 'watching':
        return 'watching_action'.tr;
      case 'playing':
        return 'playing_action'.tr;
      case 'eating':
        return 'eating_action'.tr;
      case 'drinking':
        return 'drinking_action'.tr;
      case 'traveling to':
        return 'traveling_to_action'.tr;
      case 'reading':
        return 'reading_action'.tr;
      case 'attending':
        return 'attending_action'.tr;
      case 'celebrating':
        return 'celebrating_action'.tr;
      case 'looking for':
        return 'looking_for_action'.tr;
      default:
        return action; // إرجاع النص الأصلي إذا لم تجد ترجمة
    }
  }

  /// الحصول على ترجمة العاطفة بناءً على اسم العاطفة
  String _getTranslatedEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'emotion_happy'.tr;
      case 'loved':
        return 'emotion_loved'.tr;
      case 'satisfied':
        return 'emotion_satisfied'.tr;
      case 'strong':
        return 'emotion_strong'.tr;
      case 'sad':
        return 'emotion_sad'.tr;
      case 'crazy':
        return 'emotion_crazy'.tr;
      case 'tired':
        return 'emotion_tired'.tr;
      case 'sleepy':
        return 'emotion_sleepy'.tr;
      case 'confused':
        return 'emotion_confused'.tr;
      case 'worried':
        return 'emotion_worried'.tr;
      case 'angry':
        return 'emotion_angry'.tr;
      case 'annoyed':
        return 'emotion_annoyed'.tr;
      case 'shocked':
        return 'emotion_shocked'.tr;
      case 'down':
        return 'emotion_down'.tr;
      case 'confounded':
        return 'emotion_confounded'.tr;
      default:
        return emotion; // إرجاع النص الأصلي إذا لم تجد ترجمة
    }
  }

  /// الحصول على الـ placeholder المترجم بناءً على الـ Action
  String _getTranslatedPlaceholder(String action) {
    switch (action.toLowerCase()) {
      case 'feeling':
        return 'feeling_placeholder'.tr;
      case 'listening to':
        return 'listening_to_placeholder'.tr;
      case 'watching':
        return 'watching_placeholder'.tr;
      case 'playing':
        return 'playing_placeholder'.tr;
      case 'eating':
        return 'eating_placeholder'.tr;
      case 'drinking':
        return 'drinking_placeholder'.tr;
      case 'traveling to':
        return 'traveling_to_placeholder'.tr;
      case 'reading':
        return 'reading_placeholder'.tr;
      case 'attending':
        return 'attending_placeholder'.tr;
      case 'celebrating':
        return 'celebrating_placeholder'.tr;
      case 'looking for':
        return 'looking_for_placeholder'.tr;
      default:
        return 'What are you ${action.toLowerCase()}?'; // fallback
    }
  }

  /// الحصول على ترجمة نوع المنشور
  String _getPostTypeLabel(PostTypeOption type) {
    switch (type) {
      case PostTypeOption.text:
        return 'post_type_text'.tr;
      case PostTypeOption.photos:
        return 'post_type_photos'.tr;
      case PostTypeOption.album:
        return 'post_type_album'.tr;
      case PostTypeOption.video:
        return 'post_type_video'.tr;
      case PostTypeOption.reel:
        return 'post_type_reel'.tr;
      case PostTypeOption.audio:
        return 'post_type_audio'.tr;
      case PostTypeOption.file:
        return 'post_type_file'.tr;
      case PostTypeOption.poll:
        return 'post_type_poll'.tr;
      case PostTypeOption.feeling:
        return 'post_type_feeling'.tr;
      case PostTypeOption.colored:
        return 'post_type_colored'.tr;
      case PostTypeOption.offer:
        return 'post_type_offer'.tr;
      case PostTypeOption.job:
        return 'post_type_job'.tr;
    }
  }

  void _addPollOption() {
    if (_pollOptions.length < 10) {
      setState(() {
        _pollOptions.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptions.length > 2) {
      setState(() {
        _pollOptions[index].dispose();
        _pollOptions.removeAt(index);
      });
    }
  }

  bool _validateCompetitionEntryFlow() {
    final competition = widget.competition;
    if (competition == null) return true;

    if (!competition.isRegistrationOpen) {
      Get.snackbar(
        'error'.tr,
        'entry_registration_closed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }

    if (_audio != null ||
        _selectedType == PostTypeOption.audio ||
        _selectedType == PostTypeOption.album ||
        _selectedType == PostTypeOption.file ||
        _selectedType == PostTypeOption.poll ||
        _selectedType == PostTypeOption.offer ||
        _selectedType == PostTypeOption.job ||
        _selectedType == PostTypeOption.feeling ||
        _selectedType == PostTypeOption.colored ||
        _selectedType == PostTypeOption.reel) {
      Get.snackbar(
        'error'.tr,
        'Competition entries currently support only text, photos, or video.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }

    switch (competition.allowedMediaType) {
      case CompetitionAllowedMediaType.imageOnly:
        if (_images.isEmpty || _video != null) {
          Get.snackbar(
            'error'.tr,
            'entry_image_required'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.videoOnly:
        if (_video == null || _images.isNotEmpty) {
          Get.snackbar(
            'error'.tr,
            'entry_video_required'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.textOnly:
        if (_textController.text.trim().isEmpty ||
            _images.isNotEmpty ||
            _video != null) {
          Get.snackbar(
            'error'.tr,
            'entry_text_required'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return false;
        }
        return true;
      case CompetitionAllowedMediaType.all:
        if (_images.isEmpty &&
            _video == null &&
            _textController.text.trim().isEmpty) {
          Get.snackbar(
            'error'.tr,
            'entry_no_content'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return false;
        }
        return true;
    }
  }

  String _competitionMediaTypeLabel() {
    if (_video != null) return 'video';
    if (_images.isNotEmpty) return 'image';
    return 'text';
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty &&
        _images.isEmpty &&
        _video == null &&
        _audio == null) {
      Get.snackbar(
        'error'.tr,
        'please_write_text_or_add_content'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (!_validateCompetitionEntryFlow()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      final apiService = context.read<PostsApiService>();
      final competitionApi = _isCompetitionEntryMode
          ? context.read<CompetitionApiService>()
          : null;

      // Upload images if present
      List<UploadedFileData>? uploadedPhotos;
      if (_images.isNotEmpty) {
        uploadedPhotos = [];
        for (final image in _images) {
          final result = await apiService.uploadFile(
            image,
            type: FileUploadType.photo,
          );
          if (result != null) {
            uploadedPhotos.add(result);
          } else {
          }
        }
      }

      // Upload video if present
      if (_video != null) {
        _videoUploadProgress = 0.0;
        setState(() {});

        try {
          _uploadedVideo = await apiService.uploadFile(
            _video!,
            type: FileUploadType.video,
            onProgress: (sent, total) {
              if (total > 0) {
                final p = sent / total;
                // Reduce updates to avoid excessive rebuilds
                if ((p - _videoUploadProgress).abs() >= 0.01) {
                  setState(() => _videoUploadProgress = p.clamp(0.0, 1.0));
                }
              }
            },
          );

          if (_uploadedVideo != null) {
            if (_uploadedVideo!.thumb != null) {
            }
          } else {
            Get.snackbar(
              'Warning',
              'Video upload failed - Post will be created without video',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.warning,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        } catch (videoError) {
          Get.snackbar(
            'Video upload error',
            videoError.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          // Continue without video
          _uploadedVideo = null;
        }
      }

      // Upload audio if present
      UploadedFileData? uploadedAudio;
      if (_audio != null) {
        uploadedAudio = await apiService.uploadFile(
          _audio!,
          type: FileUploadType.audio,
        );
        if (uploadedAudio != null) {
        }
      }

      // Build the request
      final request = _buildPostRequest(
        photos: uploadedPhotos,
        video: _uploadedVideo,
        audio: uploadedAudio,
      );

      // Create the post
      final postResponse = await apiService.createPostAdvanced(request);
      if (!postResponse.isSuccess) {
        throw Exception(postResponse.message ?? 'Failed to create post');
      }

      if (_isCompetitionEntryMode) {
        final createdPostId = postResponse.postId ??
            (() {
              final rawPostId = postResponse.postData?['post_id'];
              if (rawPostId is int) return rawPostId;
              return int.tryParse(rawPostId?.toString() ?? '');
            })();
        if (createdPostId == null) {
          throw Exception('Created post ID not found for competition entry.');
        }
        await competitionApi!.submitCompetitionEntry(
          competitionId: widget.competition!.id,
          request: CompetitionSubmitRequest(
            postId: createdPostId,
            mediaType: _competitionMediaTypeLabel(),
            message: _textController.text.trim(),
          ),
        );
        if (mounted) {
          try {
            context.read<WalletOverviewBloc>().add(const RefreshWalletOverview());
          } catch (_) {}
        }
      }

      // Update list and go back to main page
      if (mounted) {
        // Add new post immediately instead of full reload
        if (postResponse.isSuccess && postResponse.postData != null) {
          try {
            final newPost = Post.fromJson(postResponse.postData!);
            context.read<PostsBloc>().add(AddPostEvent(newPost));
          } catch (e) {
            // In case of parsing failure, fall back to reload
            context.read<PostsBloc>().add(RefreshPostsEvent());
          }
        } else {
          // If we didn't get post data, refresh the list
          context.read<PostsBloc>().add(RefreshPostsEvent());
        }

        // Close page first and return success
        Get.back(result: true);

        // Show success message
        Get.snackbar(
          'success'.tr,
          _isCompetitionEntryMode
              ? 'competition_entry_submitted'.tr
              : _uploadedVideo != null
                  ? 'post_published_video_processing'.tr
                  : 'post_successfully_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        _isCompetitionEntryMode
            ? e.toString().replaceFirst('Exception: ', '')
            : 'failed_to_create_post'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
        _videoUploadProgress = 0.0;
      }
    }
  }

  CreatePostRequest _buildPostRequest({
    List<UploadedFileData>? photos,
    UploadedFileData? video,
    UploadedFileData? audio,
  }) {
    // Use the original handle from widget, let toJson() handle the override
    final handle = widget.handle ?? 'me';
    final handleId = widget.handleId;
    final feeling = _buildFeelingData();

    var effectiveType = _selectedType;
    if (_isCompetitionEntryMode) {
      if (video != null) {
        effectiveType = PostTypeOption.video;
      } else if (photos != null && photos.isNotEmpty) {
        effectiveType = PostTypeOption.photos;
      } else {
        effectiveType = PostTypeOption.text;
      }
    }

    switch (effectiveType) {
      case PostTypeOption.photos:
        // Convert UploadedFileData to PhotoData with size and extension
        final photoData = photos?.map((file) {
          // Extract extension from source (e.g., "photos/2025/11/xxx.jpg" -> "jpg")
          final ext = file.source.split('.').last;
          return PhotoData(
            source: file.source,
            size: file.size,
            extension: ext,
            blur: file.blur,
          );
        }).toList();
        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          photos: photoData,
          // Don't include coloredPattern for photo posts
          feeling: feeling,
          scheduleDate: _isScheduled ? _scheduledDateTime : null,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
          isPaid: _isPaid, // 💰 منشور مدفوع
          postPrice: _postPrice,
          forSubscriptions: _forSubscriptions,
        );
      case PostTypeOption.video:
        // Pass full video data object from upload response with all metadata
        final videoData = video != null
            ? {
                'source': video.source,
                'type': video.type,
                'url': video.url,
                'category_id': '1', // Default category as string
                if (video.thumb != null) 'thumb': video.thumb,
                if (video.size != null) 'size': video.size,
                if (video.duration != null) 'duration': video.duration,
                if (video.width != null) 'width': video.width,
                if (video.height != null) 'height': video.height,
                if (video.extension != null) 'extension': video.extension,
                if (video.meta != null) 'meta': video.meta,
              }
            : null;


        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          video: videoData,
          // Don't include coloredPattern for video posts
          feeling: feeling,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
        );
      case PostTypeOption.reel:
        // Reel is similar to video but with reel property
        // Extract relative path from thumb URL
        String? thumbPath;
        if (video?.thumb != null) {
          final thumbUrl = video!.thumb!;
          if (thumbUrl.contains('/content/uploads/')) {
            thumbPath = thumbUrl.split('/content/uploads/').last;
          } else {
            thumbPath = thumbUrl;
          }
        }
        
        final reelData = video != null
            ? {
                'source': video.source,
                if (thumbPath != null) 'thumb': thumbPath,
              }
            : null;


        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          reel: reelData,
          reelThumbnail: thumbPath,
          // Don't include coloredPattern for reel posts
          feeling: feeling,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
        );
      case PostTypeOption.audio:
        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          audio: audio != null ? AudioData(source: audio.source) : null,
          // Don't include coloredPattern for audio posts
          feeling: feeling,
          scheduleDate: _isScheduled ? _scheduledDateTime : null,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
          isPaid: _isPaid, // 💰 منشور مدفوع
          postPrice: _postPrice,
          forSubscriptions: _forSubscriptions,
        );
      case PostTypeOption.poll:
        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          pollOptions: _pollOptions
              .map((c) => c.text)
              .where((t) => t.isNotEmpty)
              .toList(),
          // Don't include coloredPattern for poll posts
          feeling: feeling,
          scheduleDate: _isScheduled ? _scheduledDateTime : null,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
          isPaid: _isPaid, // 💰 منشور مدفوع
          postPrice: _postPrice,
          forSubscriptions: _forSubscriptions,
        );
      case PostTypeOption.colored:
        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          coloredPattern: _selectedColoredPattern?.id,
          feeling: feeling,
          scheduleDate: _isScheduled ? _scheduledDateTime : null,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
          isPaid: _isPaid, // 💰 منشور مدفوع
          postPrice: _postPrice,
          forSubscriptions: _forSubscriptions,
        );
      default:
        return CreatePostRequest(
          handle: handle,
          pageId: handle == 'page' && handleId != null ? handleId.toString() : null,
          groupId: handle == 'group' && handleId != null ? handleId.toString() : null,
          eventId: handle == 'event' && handleId != null ? handleId.toString() : null,
          privacy: _privacy,
          message: _textController.text,
          // Don't include coloredPattern for regular text posts
          feeling: feeling,
          scheduleDate: _isScheduled ? _scheduledDateTime : null,
          forAdult: _isAdultContent, // 🆕 محتوى للبالغين
          isAnonymous: _isAnonymous, // 🔒 منشور مجهول
          isPaid: _isPaid, // 💰 منشور مدفوع
          postPrice: _postPrice,
          forSubscriptions: _forSubscriptions,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final userName =
        auth.currentUser?['user_fullname'] ??
        auth.currentUser?['user_firstname'] ??
        auth.currentUser?['user_name'] ??
        'User';
    final userAvatar = (widget.handle == 'page' && widget.handleAvatar != null) 
        ? widget.handleAvatar 
        : auth.currentUser?['user_picture'];
    
    // Use handleName if posting to page/group/event, otherwise use userName
    final displayName = widget.handleName ?? userName;

    return Consumer<DynamicAppConfigProvider>(
      builder: (context, configProvider, child) {
        // إذا تغيرت البيانات ولم يتم تحديث الـ feelings، قم بالتحديث
        if (configProvider.appConfig != null && !_feelingsSynced) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadFeelingsFromProvider();
          });
        }
        
        return Obx(() {
          final isDark = _themeController.isDarkMode;

      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFF8F9FA),
        appBar: _buildAppBar(isDark),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
            ),
          ),
          child: _isCreating
              ? _buildLoadingState(isDark)
              : _buildBody(displayName, userAvatar, isDark),
        ),
      );
        });
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    String title = 'create_post_title'.tr;
    if (_isCompetitionEntryMode) {
      title = widget.competition!.title;
    } else if (widget.handle == 'me') {
      title = 'post_as_user'.trParams({'name': widget.handleName ?? 'User'});
    } else if (widget.handle == 'page') {
      title = 'post_to_page'.trParams({'name': widget.handleName ?? ''});
    } else if (widget.handle == 'group') {
      title = 'post_to_page'.trParams({'name': widget.handleName ?? ''});
    }
    
    return AppBar(
      backgroundColor: isDark 
        ? const Color(0xFF1A1A1A).withOpacity(0.95)
        : Colors.white.withOpacity(0.95),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [
                  const Color(0xFF1A1A1A).withOpacity(0.98),
                  const Color(0xFF0A0A0A).withOpacity(0.95),
                ]
              : [
                  Colors.white.withOpacity(0.98),
                  const Color(0xFFF8F9FA).withOpacity(0.95),
                ],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [Colors.white, const Color(0xFFF5F5F5)],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.grey[700],
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.grey[800],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isCreating 
                ? [Colors.grey[500]!, Colors.grey[600]!]
                : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isCreating 
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'create_post_button'.tr, 
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isDark 
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black54 
                : Colors.grey.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_video != null && _videoUploadProgress > 0)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 280,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _videoUploadProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading video: ${(100 * _videoUploadProgress).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creating post...',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Creating your post...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we process your content',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String userName, String? userAvatar, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User header
          _buildUserHeader(userName, userAvatar, isDark),

          const SizedBox(height: 12),

          // Post types
          _buildPostTypeSelector(isDark),

          if (_isCompetitionEntryMode) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Allowed entry type: ${widget.competition!.allowedMediaType.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Text field
          _buildTextInput(isDark),

          const SizedBox(height: 16),

          // Additional content by type
          _buildTypeSpecificContent(isDark),

          const SizedBox(height: 16),

          // Additional tools
          Consumer<DynamicAppConfigProvider>(
            builder: (context, provider, child) {
              _syncFeelingsFromConfig(context, provider);
              return const SizedBox.shrink();
            },
          ),

          _buildAdditionalTools(isDark),

          const SizedBox(height: 16),

          // Privacy settings
          _buildPrivacySettings(isDark),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String userName, String? userAvatar, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.transparent,
                backgroundImage: userAvatar != null
                    ? CachedNetworkImageProvider(userAvatar)
                    : null,
                child: userAvatar == null
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  if (widget.showPrivacySelector) ...[
                    const SizedBox(height: 8),
                    _buildPrivacyDropdown(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
            : [const Color(0xFFF0F0F0), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _privacy,
        isDense: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.grey[700],
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        items: [
          DropdownMenuItem(
            value: 'public',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.public, size: 16, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text('public_privacy'.tr),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'friends',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people, size: 16, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text('friends_privacy'.tr),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'me',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text('private_privacy'.tr),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _privacy = value);
          }
        },
      ),
    );
  }

  Widget _buildPostTypeSelector(bool isDark) {
    final types = _isCompetitionEntryMode
        ? _competitionAllowedPostTypes
        : PostTypeOption.values.take(8).toList();
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView(
          scrollDirection: Axis.horizontal,
            children: types.map((type) {
            final config = PostTypeConfig.getConfig(type);
            final isSelected = _selectedType == type;

            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedType = type);

                  if (type == PostTypeOption.photos) {
                    _pickImages();
                  } else if (type == PostTypeOption.video) {
                    _pickVideo();
                  } else if (type == PostTypeOption.reel) {
                    _pickVideo(); // Reel uses same video picker
                  } else if (type == PostTypeOption.audio) {
                    _pickAudio();
                  } else if (type == PostTypeOption.file) {
                    _pickFile();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              config.color.withOpacity(0.2),
                              config.color.withOpacity(0.1),
                            ],
                          )
                        : LinearGradient(
                            colors: isDark 
                              ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
                              : [const Color(0xFFF5F5F5), Colors.white],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                        ? config.color 
                        : (isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: config.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: isDark 
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? config.color.withOpacity(0.2)
                              : (isDark 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          config.icon,
                          color: isSelected
                              ? config.color
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          _getPostTypeLabel(type),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected 
                              ? config.color 
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextInput(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _selectedColoredPattern != null 
              ? (_selectedColoredPattern!.isImagePattern ? null : _getPatternBackground())
              : (isDark ? Colors.grey[900] : Colors.white),
          gradient: _selectedColoredPattern?.backgroundColors != null && 
                    _selectedColoredPattern!.backgroundColors!.secondary != null &&
                    !_selectedColoredPattern!.isImagePattern
              ? LinearGradient(
                  colors: [
                    _getPatternBackground(),
                    Color(int.parse('0xFF${_selectedColoredPattern!.backgroundColors!.secondary!.replaceAll('#', '')}'))
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          // إضافة دعم للصور كخلفيات
          image: _selectedColoredPattern?.isImagePattern == true && _selectedColoredPattern!.backgroundImage != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(_selectedColoredPattern!.backgroundImage!.full),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _shouldHideTextField() 
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    // عندما ينقر المستخدم، نظهر TextField مؤقتاً
                  });
                  // Focus على TextField
                  FocusScope.of(context).requestFocus(_textFocusNode);
                },
                child: Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'tap_to_write'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          maxLines: null,
          minLines: 4,
          style: TextStyle(
            fontSize: _selectedColoredPattern != null ? 20 : 16,
            height: 1.5,
            color: _selectedColoredPattern != null 
                ? Colors.white
                : (isDark ? Colors.white : Colors.grey[800]),
            fontWeight: _selectedColoredPattern != null ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: _selectedColoredPattern != null ? TextAlign.center : TextAlign.start,
          decoration: InputDecoration(
            hintText: 'what_do_you_want_to_share'.tr,
            hintStyle: TextStyle(
              fontSize: _selectedColoredPattern != null ? 20 : 16,
              color: _selectedColoredPattern != null 
                  ? Colors.white70
                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificContent(bool isDark) {
    if (_selectedType == PostTypeOption.photos && _images.isNotEmpty) {
      return _buildImageGrid(isDark);
    }

    if (_selectedType == PostTypeOption.video && _video != null) {
      return _buildVideoPreview(isDark);
    }

    if (_selectedType == PostTypeOption.reel && _video != null) {
      return _buildVideoPreview(isDark); // Reel uses same preview as video
    }

    if (_selectedType == PostTypeOption.audio && _audio != null) {
      return _buildAudioPreview(isDark);
    }

    if (_selectedType == PostTypeOption.poll) {
      return _buildPollInput(isDark);
    }

    if (_selectedType == PostTypeOption.colored && _showColoredPatterns) {
      return _buildColoredPatternsGrid(isDark);
    }

    return const SizedBox.shrink();
  }

  Widget _buildColoredPatternsGrid(bool isDark) {
    return Consumer<DynamicAppConfigProvider>(
      builder: (context, configProvider, child) {
        // التحقق من تفعيل الخلفيات الملونة في الخادم
        final featuresConfig = configProvider.features;
        final coloredPostsEnabled = featuresConfig?.posts.coloredPosts ?? false;
        final patterns = configProvider.coloredPatterns ?? [];
        
        // إذا لم تكن الخلفيات الملونة مفعلة في الخادم
        if (!coloredPostsEnabled) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'colored_posts_not_enabled'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'colored_posts_not_enabled_description'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }
        
        // إذا لم تكن هناك أنماط متاحة
        if (patterns.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'no_patterns_available'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'no_patterns_description'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
                : [Colors.white, const Color(0xFFF8F9FA)],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.color_lens_rounded, 
                      color: isDark ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'choose_background'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر Refresh للأنماط الملونة
                    Consumer<DynamicAppConfigProvider>(
                      builder: (context, configProvider, child) {
                        return configProvider.isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? Colors.white60 : Colors.grey[600]!,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: () async {
                                  try {
                                    await configProvider.loadConfig(forceRefresh: true);
                                    if (mounted) {
                                      final patternsCount = configProvider.coloredPatterns?.length ?? 0;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Updated! Found $patternsCount patterns'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update patterns'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                                tooltip: 'Refresh patterns',
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                              );
                      },
                    ),
                    const Spacer(),
                    if (_selectedColoredPattern != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectColoredPattern(null),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
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
                const SizedBox(height: 16),
                if (patterns.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.color_lens_outlined, 
                          size: 48, 
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No colored patterns available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: patterns.length,
                    itemBuilder: (context, index) {
                      final pattern = patterns[index];
                      final isSelected = _selectedColoredPattern?.id == pattern.id;
                      
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                              ? Border.all(
                                  color: const Color(0xFFFF6B6B), 
                                  width: 3,
                                )
                              : Border.all(
                                  color: isDark 
                                    ? Colors.white.withOpacity(0.2) 
                                    : Colors.grey[300]!,
                                ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectColoredPattern(pattern),
                            borderRadius: BorderRadius.circular(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildPatternPreview(pattern),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(ColoredPattern pattern) {
    if (pattern.backgroundImage != null && pattern.backgroundImage!.full.isNotEmpty) {
      return Image.network(
        pattern.backgroundImage!.full,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildColorPreview(pattern);
        },
      );
    } else {
      return _buildColorPreview(pattern);
    }
  }

  Widget _buildColorPreview(ColoredPattern pattern) {
    if (pattern.backgroundColors != null) {
      final primary = Color(int.parse('0xFF${pattern.backgroundColors!.primary.replaceAll('#', '')}'));
      
      if (pattern.backgroundColors!.secondary != null) {
        final secondary = Color(int.parse('0xFF${pattern.backgroundColors!.secondary!.replaceAll('#', '')}'));
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      } else {
        return Container(color: primary);
      }
    }
    
    return Container(
      color: const Color(0xFF6C5CE7),
      child: const Icon(Icons.color_lens, color: Colors.white),
    );
  }

  Widget _buildVideoPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.videocam_rounded, 
                size: 40, 
                color: Colors.white
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _video!.path.split('/').last,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Video', 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF667eea),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _video = null;
                    _uploadedVideo = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf093fb).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.audiotrack_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _audio!.path.split('/').last,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf093fb).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Audio', 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFf093fb),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _audio = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'photos_count'.trParams({'count': _images.length.toString()}),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickImages(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'add_more_photos'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _images.asMap().entries.map((entry) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          entry.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _removeImage(entry.key),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollInput(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4facfe).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.poll_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'poll_options'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._pollOptions.asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF3A3A3A) 
                            : const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: entry.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Option ${entry.key + 1}',
                            hintStyle: TextStyle(
                              color: isDark 
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_pollOptions.length > 2) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _removePollOption(entry.key),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (_pollOptions.length < 10)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4facfe).withOpacity(0.1),
                      const Color(0xFF00f2fe).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4facfe).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addPollOption,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: const Color(0xFF4facfe),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'add_option'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4facfe),
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

  Widget _buildAdditionalTools(bool isDark) {
    final showPhotosTool = !_isCompetitionEntryMode ||
        (widget.competition?.allowedMediaType.allowsImages ?? false);
    final showVideoTool = !_isCompetitionEntryMode ||
        (widget.competition?.allowedMediaType.allowsVideo ?? false);
    if (_isCompetitionEntryMode &&
        !showPhotosTool &&
        !showVideoTool &&
        _selectedFeelingAction == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
            : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_to_your_post'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (showPhotosTool) ...[
                    _buildToolButton(
                      Icons.photo_library_rounded,
                      'photos_button'.tr,
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                      () => _pickImages(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (showVideoTool) ...[
                    _buildToolButton(
                      Icons.videocam_rounded,
                      'post_type_video'.tr,
                      const Color(0xFF4facfe),
                      const Color(0xFF00f2fe),
                      () => _pickVideo(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (!_isCompetitionEntryMode) ...[
                    _buildToolButton(
                      Icons.color_lens_rounded,
                      'colored_button'.tr,
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFFE66D),
                      () => _toggleColoredPatterns(),
                    ),
                    const SizedBox(width: 12),
                    _buildToolButton(
                      Icons.emoji_emotions_rounded,
                      'feeling_button'.tr,
                      const Color(0xFFf093fb),
                      const Color(0xFFf5576c),
                      _openFeelingPicker,
                    ),
                    const SizedBox(width: 12),
                    _buildToolButton(
                      Icons.location_on_rounded,
                      'location_button'.tr,
                      const Color(0xFFff9a9e),
                      const Color(0xFFfecfef),
                      () {},
                    ),
                  ],
      
            
                ],
              ),
            ),
            if (_selectedFeelingAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildFeelingSummary(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    Color startColor,
    Color endColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon, 
                  color: Colors.white, 
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeelingSummary() {
    final action = _selectedFeelingAction;
    if (action == null || action.isEmpty) {
      return const SizedBox.shrink();
    }

    final value = _selectedFeelingActivity ?? _feelingValueController.text.trim();
    final label = value.isNotEmpty ? '$action · $value' : action;
    
    // تحديد الأيقونة المناسبة بناءً على نوع الـ Action
    IconData icon;
    Color iconColor;
    switch (action.toLowerCase()) {
      case 'feeling':
        icon = Icons.emoji_emotions;
        iconColor = Colors.orange;
        break;
      case 'listening to':
        icon = Icons.headphones;
        iconColor = Colors.green;
        break;
      case 'watching':
        icon = Icons.visibility;
        iconColor = Colors.blue;
        break;
      case 'playing':
        icon = Icons.games;
        iconColor = Colors.purple;
        break;
      case 'reading':
        icon = Icons.book;
        iconColor = Colors.brown;
        break;
      case 'eating':
        icon = Icons.restaurant;
        iconColor = Colors.red;
        break;
      case 'drinking':
        icon = Icons.local_cafe;
        iconColor = Colors.amber;
        break;
      case 'traveling to':
        icon = Icons.flight;
        iconColor = Colors.indigo;
        break;
      case 'celebrating':
        icon = Icons.celebration;
        iconColor = Colors.pink;
        break;
      case 'attending':
        icon = Icons.event;
        iconColor = Colors.teal;
        break;
      case 'looking for':
        icon = Icons.search;
        iconColor = Colors.cyan;
        break;
      default:
        icon = Icons.emoji_emotions_outlined;
        iconColor = Colors.orange;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: _clearFeelingSelection,
          child: Text('clear_button'.tr),
        ),
      ],
    );
  }

  void _openFeelingPicker() {
    final provider = Provider.of<DynamicAppConfigProvider>(context, listen: false);
    _syncFeelingsFromConfig(context, provider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final bottomInset = media.viewInsets.bottom; // keyboard
        final safeBottom = media.padding.bottom; // safe area (e.g., iPhone home indicator)
        final bottomPadding = bottomInset > 0 ? bottomInset : safeBottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: _buildFeelingSheet(sheetContext),
          ),
        );
      },
    );
  }

  Widget _buildFeelingSheet(BuildContext sheetContext) {
    if (!_feelingsEnabled && _feelings.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('feelings_not_enabled'.tr),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text('close_dialog'.tr),
          ),
        ],
      );
    }

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'feelings_activity_title'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: _clearFeelingSelection,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
            
              value: _selectedFeelingAction,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.emoji_emotions),
              ),
              hint: Text('choose_feeling_or_activity'.tr),
              items: () {
                final uniqueFeelingsActions = <String>{};
                final items = <DropdownMenuItem<String>>[];
                
                
                for (var feeling in _feelings) {
                  final action = feeling['action']?.toString();
                  if (action != null && action.isNotEmpty && !uniqueFeelingsActions.contains(action)) {
                    uniqueFeelingsActions.add(action);
                    final translatedLabel = _getTranslatedAction(action);
                    
                    
                    items.add(DropdownMenuItem<String>(
                      value: action,
                      child: Text(translatedLabel),
                    ));
                  }
                }
                
                return items;
              }(),
              onChanged: (value) {
                setSheetState(() {
                  _selectedFeelingAction = value;
                  _selectedFeelingActivity = null;
                  _feelingValueController.clear();
                });
              },
            ),
        const SizedBox(height: 12),
        // التحقق من نوع الـ Action المختار
        if (_selectedFeelingAction != null) ...[
          if (_selectedFeelingAction == 'Feeling')
            // للـ Feelings، نعرض dropdown بقائمة الـ activities المتاحة (المشاعر)
            DropdownButtonFormField<String>(
              value: _selectedFeelingActivity,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.emoji_emotions),
              ),
              hint: Text('select_a_feeling'.tr),
              items: () {
                final items = <DropdownMenuItem<String>>[];
                
                
                // جمع جميع الـ activities المتاحة (هذه هي المشاعر الفعلية)
                final uniqueFeelings = <String>{};
                for (var activity in _activities) {
                  final feelingValue = activity['text']?.toString();
                  final feelingAction = activity['action']?.toString();
                  if (feelingValue != null && feelingValue.isNotEmpty && !uniqueFeelings.contains(feelingValue)) {
                    uniqueFeelings.add(feelingValue);
                    final translatedEmotion = _getTranslatedEmotion(feelingValue);
                    items.add(DropdownMenuItem<String>(
                      value: feelingValue,
                      child: Row(
                        children: [
                          Text(
                            _convertIconNameToEmoji(activity['icon']?.toString()),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(translatedEmotion),
                        ],
                      ),
                    ));
                  }
                }
                
                return items;
              }(),
              onChanged: (value) {
                setState(() {
                  _selectedFeelingActivity = value;
                  _feelingValueController.clear();
                });
              },
            )
          else
            // لباقي الأنشطة (Listening To, Watching, Playing, إلخ)، نعرض text field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTranslatedPlaceholder(_selectedFeelingAction ?? ''),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feelingValueController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: () {
                      // إضافة أيقونة مناسبة للنشاط
                      IconData icon;
                      final actionLower = _selectedFeelingAction?.toLowerCase() ?? '';
                      
                      if (actionLower.contains('listen')) {
                        icon = Icons.headphones;
                      } else if (actionLower.contains('watch')) {
                        icon = Icons.visibility;
                      } else if (actionLower.contains('play')) {
                        icon = Icons.games;
                      } else if (actionLower.contains('read')) {
                        icon = Icons.book;
                      } else if (actionLower.contains('eat')) {
                        icon = Icons.restaurant;
                      } else if (actionLower.contains('drink')) {
                        icon = Icons.local_cafe;
                      } else if (actionLower.contains('travel')) {
                        icon = Icons.flight;
                      } else if (actionLower.contains('celebrat')) {
                        icon = Icons.celebration;
                      } else if (actionLower.contains('attend')) {
                        icon = Icons.event;
                      } else if (actionLower.contains('look')) {
                        icon = Icons.search;
                      } else {
                        icon = Icons.text_fields;
                      }
                      return Icon(icon, color: Colors.grey[600]);
                    }(),
                    hintText: _getTranslatedPlaceholder(_selectedFeelingAction ?? ''),
                    counterText: '', // إخفاء عداد الأحرف
                  ),
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true, // التركيز التلقائي على الحقل
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: Text('apply_button'.tr),
          ),
        ],
      );
      },
    );
  }

  void _clearFeelingSelection() {
    setState(() {
      _selectedFeelingAction = null;
      _selectedFeelingActivity = null;
      _feelingValueController.clear();
    });
  }

  void _syncFeelingsFromConfig(BuildContext context, DynamicAppConfigProvider provider) {
    final expandable = provider.appConfig?.expandable ?? {};
    final rawFeelings = _normalizeList(expandable['feelings']);
    final rawActivities = _normalizeList(expandable['activities']);
    final enabled = provider.features?.posts.feelings ?? false;

    final shouldUpdate = !_feelingsSynced ||
        _feelingsEnabled != enabled ||
        !const DeepCollectionEquality().equals(_feelings, rawFeelings) ||
        !const DeepCollectionEquality().equals(_activities, rawActivities);

    if (!shouldUpdate) return;

    if (rawFeelings.isEmpty && rawActivities.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _feelings = rawFeelings;
        _activities = rawActivities;
        _feelingsEnabled = enabled;
        _feelingsSynced = true;
      });
    });
  }

List<Map<String, dynamic>> _normalizeList(dynamic data) {
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        }
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return {'text': item.toString()};
      }).toList();
    }
    return [];
  }

  Widget _buildPrivacySettings(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.subtitleLarge(isDark: isDark)),
          const SizedBox(height: 12),
          _buildSettingSwitch(
            'Post anonymously',
            _isAnonymous,
            (value) => setState(() => _isAnonymous = value),
            isDark,
          ),
          _buildSettingSwitch(
            'Schedule post',
            _isScheduled,
            (value) => setState(() {
              _isScheduled = value;
              if (value) {
                _showScheduleDatePicker();
              } else {
                _scheduledDateTime = null;
              }
            }),
            isDark,
          ),
          if (_isScheduled && _scheduledDateTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Scheduled: $_scheduledDateTime',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          _buildSettingSwitch(
            'Paid post',
            _isPaid,
            (value) => setState(() {
              _isPaid = value;
              if (!value) {
                _postPrice = null;
                _forSubscriptions = false;
              }
            }),
            isDark,
          ),
          if (_isPaid) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter post price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => setState(() => _postPrice = value),
              ),
            ),
            _buildSettingSwitch(
              'For subscriptions only',
              _forSubscriptions,
              (value) => setState(() => _forSubscriptions = value),
              isDark,
            ),
          ],
          _buildSettingSwitch(
            'Adult content',
            _isAdultContent,
            (value) => setState(() => _isAdultContent = value),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium(isDark: isDark)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleDatePicker() async {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: future,
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        final scheduledDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        // Format: YYYY-MM-DD HH:mm:ss
        final formatted =
            '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')} ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}:00';
        setState(() => _scheduledDateTime = formatted);
      }
    }
  }
}
