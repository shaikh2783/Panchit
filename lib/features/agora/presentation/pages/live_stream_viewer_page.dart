import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/theme/widgets/elevated_card.dart';
import '../../../../core/network/api_client.dart';
import '../../application/agora_service.dart';
import '../widgets/remote_video_widget.dart';
import '../widgets/live_chat_widget.dart';
import '../widgets/live_reactions_widget.dart';
import '../../data/api_service/live_stream_api_service.dart';
import '../../providers/live_stream_providers.dart';
import '../widgets/live_chat_api_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
class LiveStreamViewerPage extends StatefulWidget {
  const LiveStreamViewerPage({
    super.key,
    required this.channelName,
    required this.token,
    required this.broadcasterName,
    this.uid = 0,
    this.thumbnailUrl,
    this.broadcasterAvatar,
    this.isVerified = false,
    this.viewersCount = 0,
    this.postId, // معرف البوست للـ API
    this.liveId, // معرف البث المباشر
  });
  final String channelName;
  final String token;
  final String broadcasterName;
  final int uid;
  final String? thumbnailUrl;
  final String? broadcasterAvatar;
  final bool isVerified;
  final int viewersCount;
  final String? postId; // جديد للـ API
  final String? liveId; // جديد للـ API
  @override
  State<LiveStreamViewerPage> createState() => _LiveStreamViewerPageState();
}
class _LiveStreamViewerPageState extends State<LiveStreamViewerPage> 
    with TickerProviderStateMixin, LiveStreamBlocsMixin {
  late AgoraService _agoraService;
  late LiveStreamApiService _liveApiService;
  late AnimationController _controlsAnimationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _interfaceAnimationController;
  Timer? _hideControlsTimer;
  Timer? _statsUpdateTimer;
  bool _isLoading = true;
  bool _showControls = true;
  bool _showChat = false;
  bool _isStreamEnded = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentViewers = 0;
  bool _hasJoinedLive = false;
  bool _isLoadingStats = false;
  Map<String, dynamic>? _liveStats;
  String? _lastCommentId; // لتتبع آخر تعليق للتحديثات الفعلية
  @override
  void initState() {
    super.initState();
    _currentViewers = widget.viewersCount;
    _liveApiService = LiveStreamApiService(context.read<ApiClient>());
    // طباعة القيم المُمررة للتطوير
    _initializeAnimations();
    _initializeAgora();
    _hideSystemUI();
    _joinLiveStream();
    // لا نبدأ stats updates هنا - سنبدأها بعد نجاح join
  }
  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _interfaceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controlsAnimationController.forward();
    _interfaceAnimationController.forward();
    _loadingAnimationController.repeat();
  }
  // الانضمام للبث المباشر عبر API
  Future<void> _joinLiveStream() async {
    final postId = widget.postId ?? widget.liveId;
    if (postId == null) {
      return;
    }
    try {
      final result = await _liveApiService.joinLiveStream(postId: postId);
      if (result['status'] == 'success') {
        setState(() {
          _hasJoinedLive = true;
        });
        // بدء مراقبة الإحصائيات فقط بعد نجاح الانضمام
        _startStatsUpdates();
        // تحديث عدد المشاهدين فور الانضمام - معالجة محسنة
        final data = result['data'];
        if (data != null) {
          // جرب live_count أولاً (من stats API)
          int? viewerCount = data['live_count'];
          // إذا لم نجد live_count، جرب من post object
          if (viewerCount == null && data['post'] != null) {
            final statistics = data['post']['statistics'];
            if (statistics != null) {
              viewerCount = statistics['live_viewers'] ?? statistics['reactions'] ?? 0;
            }
          }
          // إذا لم نجد أي عدد، استخدم 1 (المستخدم الحالي)
          viewerCount ??= 1;
          setState(() {
            _currentViewers = viewerCount!;
          });
          // طباعة تفاصيل إضافية للتطوير
          if (data['post'] != null) {
            final post = data['post'];
          }
        }
        // عرض رسالة نجاح
        _showSuccessMessage('انضممت للبث المباشر بنجاح!');
      } else {
        setState(() {
          _isStreamEnded = true;
        });
        if (result['error_type'] == 'stream_ended') {
          _showStreamEndedMessage();
        } else {
          _showJoinFailedMessage(result['message'] ?? 'فشل في الانضمام للبث');
        }
      }
    } catch (e) {
      _showJoinFailedMessage('خطأ في الاتصال: ${e.toString()}');
    }
  }
  // عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // عرض رسالة انتهاء البث
  void _showStreamEndedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('انتهى البث المباشر'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  // عرض رسالة فشل الانضمام
  void _showJoinFailedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فشل في الانضمام للبث: $message'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          onPressed: _joinLiveStream,
        ),
      ),
    );
  }
  // بدء تحديثات إحصائيات البث
  void _startStatsUpdates() {
    final postId = widget.postId ?? widget.liveId;
    if (postId == null) {
      return;
    }
    // تحديث الإحصائيات كل 3 ثوانٍ (أسرع للتفاعل)
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _hasJoinedLive && !_isStreamEnded) {
        _fetchLiveStats();
      } else {
        timer.cancel();
      }
    });
    // جلب الإحصائيات فوراً
    _fetchLiveStats();
  }
  // جلب إحصائيات البث المباشر
  Future<void> _fetchLiveStats() async {
    final postId = widget.postId ?? widget.liveId;
    if (_isLoadingStats || postId == null || !_hasJoinedLive) return;
    try {
      setState(() {
        _isLoadingStats = true;
      });
      final result = await _liveApiService.getLiveStats(postId: postId);
      if (!mounted) return; // تحقق من mounted قبل setState
      if (result['status'] == 'success') {
        final data = result['data'];
        final newViewerCount = data['live_count'];
        // معلومات إضافية للتطوير
        if (data['comments'] != null) {
          final comments = data['comments'] as List;
          // تحديث آخر comment ID لللاستعلامات المستقبلية
          if (comments.isNotEmpty) {
            _lastCommentId = comments.last['comment_id']?.toString();
          }
        }
        // تحديث إذا حصلنا على قيمة جديدة مختلفة
        if (newViewerCount != null && newViewerCount != _currentViewers) {
          setState(() {
            _liveStats = data;
            _currentViewers = newViewerCount;
          });
        }
        // التحقق من حالة البث
        if (data['is_live'] == false || data['status'] == 'ended') {
          setState(() {
            _isStreamEnded = true;
          });
          _statsUpdateTimer?.cancel();
          _showStreamEndedMessage();
        }
      } else {
        // إذا فشل جلب الإحصائيات، قد يكون البث انتهى
        if (result['error_type'] == 'stream_ended') {
          setState(() {
            _isStreamEnded = true;
          });
          _statsUpdateTimer?.cancel();
          _showStreamEndedMessage();
        }
      }
    } catch (e) {
      // لا نوقف التحديثات عند خطأ واحد، قد يكون مؤقت
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }
  // مغادرة البث المباشر
  Future<void> _leaveLiveStream() async {
    final postId = widget.postId ?? widget.liveId;
    if (postId == null || !_hasJoinedLive) return;
    try {
      await _liveApiService.leaveLiveStream(postId: postId);
      // إيقاف التحديثات
      _statsUpdateTimer?.cancel();
      // تحديث الحالة فقط إذا كان mounted
      if (mounted) {
        setState(() {
          _hasJoinedLive = false;
        });
      }
    } catch (e) {
      // حتى لو فشلت مغادرة API، نوقف التحديثات محلياً
      _statsUpdateTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasJoinedLive = false;
        });
      }
    }
  }
  // بناء واجهة إحصائيات البث
  Widget _buildLiveStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حالة البث المباشر
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isStreamEnded ? Colors.grey : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isStreamEnded ? 'منتهي' : 'مباشر',
                style: TextStyle(
                  color: _isStreamEnded ? Colors.grey : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // عدد المشاهدين الحقيقي 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _formatViewersCount(_currentViewers),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'مشاهد',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              // مؤشر التحديث
              if (_isLoadingStats) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_liveStats != null) ...[
            const SizedBox(height: 8),
            // عدد التعليقات
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_liveStats!['comments_count'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // عدد الإعجابات
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_liveStats!['total_reactions'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          // مؤشر التحديث
          if (_isLoadingStats) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
  // تنسيق عدد المشاهدين
  String _formatViewersCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}م';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}ك';
    }
    return count.toString();
  }
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  Future<void> _initializeAgora() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
      // إنشاء AgoraService محلياً
      _agoraService = AgoraService();
      // تهيئة Agora
      final initialized = await _agoraService.initialize();
      if (!initialized) {
        // التحقق من نوع الخطأ
        await _handlePermissionsError();
        return;
      }
      // الانضمام للقناة
      final joined = await _agoraService.joinChannel(
        channelName: widget.channelName,
        token: widget.token,
        uid: widget.uid,
      );
      if (!joined) {
        throw Exception('فشل في الانضمام للقناة - تحقق من معرف القناة والتوكن');
      }
      setState(() {
        _isLoading = false;
      });
      _loadingAnimationController.stop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _loadingAnimationController.stop();
    }
  }
  // إظهار/إخفاء واجهة التحكم
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _controlsAnimationController.forward();
      _interfaceAnimationController.forward();
      _hideControlsTimer?.cancel();
      _hideControlsTimer = Timer(const Duration(seconds: 5), () {
        _hideControlsTimer = null;
        if (mounted) {
          _controlsAnimationController.reverse();
          _interfaceAnimationController.reverse();
          setState(() {
            _showControls = false;
          });
        }
      });
    } else {
      _controlsAnimationController.reverse();
      _interfaceAnimationController.reverse();
      _hideControlsTimer?.cancel();
      _hideControlsTimer = null;
    }
  }
  // تبديل عرض الدردشة
  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
  }
  // معالجة أخطاء الصلاحيات
  Future<void> _handlePermissionsError() async {
    // إظهار رسالة خطأ للمستخدم
    setState(() {
      _hasError = true;
      _errorMessage = 'يجب السماح بالوصول للكاميرا والمايكروفون لمشاهدة البث المباشر';
    });
    // إظهار حوار تعليمات
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      _showPermissionsDialog();
    }
  }
  // عرض حوار تعليمات الصلاحيات
  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('صلاحيات مطلوبة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لمشاهدة البث المباشر، نحتاج للوصول إلى:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.videocam, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('الكاميرا - لعرض الفيديو'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.mic, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('المايكروفون - للصوت'),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '⚠️ يبدو أن الصلاحيات مرفوضة نهائياً. '
                'يجب تفعيلها يدوياً من إعدادات التطبيق.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // العودة للصفحة السابقة
            },
            child: Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // فتح إعدادات التطبيق
              await _openAppSettings();
            },
            icon: Icon(Icons.settings),
            label: Text('فتح الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  // فتح إعدادات التطبيق
  Future<void> _openAppSettings() async {
    try {
      // استخدام package:permission_handler
      final opened = await openAppSettings();
      if (opened) {
        // إظهار رسالة تعليمية
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'فعّل الكاميرا والمايكروفون ثم ارجع للتطبيق',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'حاول مجدداً',
              textColor: Colors.white,
              onPressed: () {
                // إعادة تهيئة Agora
                _initializeAgora();
              },
            ),
          ),
        );
      }
    } catch (e) {
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingWidget()
            : _hasError
                ? _buildErrorWidget()
                : _buildStreamWidget(_agoraService),
      ),
    );
  }
  Widget _buildErrorWidget() {
    return Center(
      child: ElevatedCard(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'فشل في الاتصال بالبث',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'حدث خطأ غير متوقع',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showSystemUI();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Iconsax.arrow_left_2),
                      label: const Text('رجوع'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _hasError = false;
                          _errorMessage = null;
                        });
                        _loadingAnimationController.repeat();
                        _initializeAgora();
                      },
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('إعادة محاولة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLoadingWidget() {
    return Stack(
      children: [
        // خلفية الصورة المصغرة إذا كانت متوفرة
        if (widget.thumbnailUrl != null)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(widget.thumbnailUrl!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        // مؤشر التحميل
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _loadingAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _loadingAnimationController.value * 2 * 3.14159,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.video_play,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الاتصال بالبث المباشر...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.broadcasterName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // زر الإلغاء
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                _showSystemUI();
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Iconsax.close_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStreamWidget(AgoraService agoraService) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // عرض الفيديو
          _buildVideoWidget(agoraService),
          // شارة LIVE وإحصائيات
          AnimatedBuilder(
            animation: _interfaceAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _interfaceAnimationController.value) * -100),
                child: Opacity(
                  opacity: _interfaceAnimationController.value,
                  child: _buildTopInterface(),
                ),
              );
            },
          ),
          // معلومات البث والإحصائيات
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _interfaceAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset((1 - _interfaceAnimationController.value) * 100, 0),
                  child: Opacity(
                    opacity: _interfaceAnimationController.value,
                    child: _buildLiveStats(),
                  ),
                );
              },
            ),
          ),
          // تفاعلات مباشرة
          LiveReactionsWidget(
            onReactionSent: (reaction) {
              // TODO: إرسال التفاعل عبر Agora أو API
            },
          ),
          // دردشة مباشرة
          if (_showChat)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                width: 320,
                child: (widget.postId ?? widget.liveId) != null 
                  ? LiveStreamBlocProvider(
                      liveId: widget.postId ?? widget.liveId!,
                      child: LiveChatApiWidget(liveId: widget.postId ?? widget.liveId!),
                    )
                  : LiveChatWidget(
                      channelName: widget.channelName,
                      isVisible: _showChat,
                      onToggleVisibility: _toggleChat,
                    ),
              ),
            ),
          // أدوات التحكم المحسنة
          AnimatedBuilder(
            animation: _controlsAnimationController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: _showChat ? 280 : 0, // ترك مساحة للدردشة
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (1 - _controlsAnimationController.value) * 100,
                  ),
                  child: Opacity(
                    opacity: _controlsAnimationController.value,
                    child: _buildEnhancedControls(agoraService),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildVideoWidget(AgoraService agoraService) {
    if (!agoraService.hasRemoteUsers) {
      // عرض رسالة انتظار أو صورة مصغرة
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.video,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'انتظار بدء البث...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.broadcasterName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    // عرض فيديو البث المباشر
    final remoteUid = agoraService.remoteUsers.keys.first;
    return RemoteVideoWidget(
      uid: remoteUid,
      channelName: widget.channelName,
      agoraService: agoraService, // تمرير AgoraService
    );
  }
  // بناء الواجهة العلوية
  Widget _buildTopInterface() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // شارة LIVE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // عدد المشاهدين
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentViewers}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // بناء أدوات التحكم المحسنة
  Widget _buildEnhancedControls(AgoraService agoraService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // معلومات البث المباشر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.broadcasterAvatar != null && widget.broadcasterAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.broadcasterAvatar!)
                      : null,
                  backgroundColor: Colors.grey,
                  child: widget.broadcasterAvatar == null || widget.broadcasterAvatar!.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.broadcasterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FOLLOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الخروج
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // أزرار وسطية
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر كتم الصوت
                    GestureDetector(
                      onTap: () => _agoraService.toggleMute(),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _agoraService.isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر المشاركة
                    GestureDetector(
                      onTap: () {
                        // TODO: تطبيق مشاركة البث
                      },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
              // زر الدردشة
              GestureDetector(
                onTap: _toggleChat,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _showChat 
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      if (!_showChat)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    // إيقاف جميع المؤقتات
    _hideControlsTimer?.cancel();
    _statsUpdateTimer?.cancel();
    // مغادرة البث المباشر عند الخروج (بدون انتظار)
    if (_hasJoinedLive && (widget.postId != null || widget.liveId != null)) {
      _leaveLiveStream().catchError((e) {});
    }
    // تنظيف الموارد
    _controlsAnimationController.dispose();
    _loadingAnimationController.dispose();
    _interfaceAnimationController.dispose();
    // تنظيف Agora والنظام
    _agoraService.leaveChannel().catchError((e) {});
    _showSystemUI();
    super.dispose();
  }
}