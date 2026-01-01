import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../bloc/live_stream_creation_bloc.dart';
import '../../bloc/live_comments_bloc.dart';
import '../../data/api_service/live_stream_api_service.dart';
import '../../data/models/live_stream_models.dart';
import '../widgets/live_stream_controls_widget.dart';

class ProfessionalLiveStreamPage extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? node; // page أو group
  final int? nodeId; // معرف الصفحة أو المجموعة

  const ProfessionalLiveStreamPage({
    Key? key,
    this.initialTitle,
    this.initialDescription,
    this.node,
    this.nodeId,
  }) : super(key: key);

  @override
  State<ProfessionalLiveStreamPage> createState() => _ProfessionalLiveStreamPageState();
}

class _ProfessionalLiveStreamPageState extends State<ProfessionalLiveStreamPage> {
  late RtcEngine _engine;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isEngineInitialized = false;
  bool _isLiveStreamActive = false;
  bool _isCameraEnabled = true;
  bool _isMicrophoneEnabled = true;
  bool _isFrontCamera = true;
  
  String? _currentStreamId;
  int _currentViewers = 0; // عدد المشاهدين الحالي
  Timer? _statsTimer; // مؤقت لتحديث الإحصائيات
  bool _isUpdatingStats = false; // لمنع التحديثات المتكررة

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _initializeAgoraEngine();
  }

  @override
  void dispose() {
    _isUpdatingStats = true; // منع أي تحديثات أثناء الـ dispose
    _titleController.dispose();
    _descriptionController.dispose();
    _stopStatsPolling(); // إيقاف تحديث الإحصائيات
    _disposeAgoraEngine();
    super.dispose();
  }

  Future<void> _initializeAgoraEngine() async {
    try {
      // طلب الأذونات
      await [Permission.camera, Permission.microphone].request();

      // إنشاء Agora engine
      _engine = createAgoraRtcEngine();
      
      await _engine.initialize(const RtcEngineContext(
        appId: "ba3efbf0e1cf4a9fb86c8a7734c79c0c", // App ID من البيئة
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine.enableVideo();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // إعداد معاينة الفيديو
      await _engine.startPreview();
      
      setState(() {
        _isEngineInitialized = true;
      });

    } catch (e) {

      _showErrorSnackBar('فشل في تهيئة محرك البث');
    }
  }

  Future<void> _disposeAgoraEngine() async {
    try {
      if (_isLiveStreamActive) {
        await _stopLiveStream();
      }
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {

    }
  }

  Future<void> _startLiveStream(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('يجب إدخال عنوان البث');
      return;
    }

    context.read<LiveStreamCreationBloc>().add(
      CreateLiveStreamEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        node: widget.node, // تمرير نوع الـ node (page/group)
        nodeId: widget.nodeId, // تمرير معرف الصفحة
        tipsEnabled: false,
        forSubscriptions: false,
        isPaid: false,
        postPrice: 0,
      ),
    );
  }

  Future<void> _joinAgoraChannel({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    try {

      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );

      setState(() {
        _isLiveStreamActive = true;
      });

      // بدء تحديث الإحصائيات

      _startStatsPolling();

    } catch (e) {

      _showErrorSnackBar('فشل في الانضمام لقناة البث');
    }
  }

  Future<void> _stopLiveStream() async {
    try {
      // إيقاف التحديث التلقائي للتعليقات والإحصائيات
      if (_currentStreamId != null) {

        context.read<LiveCommentsBloc>().add(StopLiveCommentsPolling());
        _stopStatsPolling();
      }
      
      if (_currentStreamId != null) {
        // إنهاء البث في الـ backend
        final apiService = LiveStreamApiService(context.read<ApiClient>());
        await apiService.endLiveStream(postId: _currentStreamId!);
      }

      // مغادرة قناة Agora
      await _engine.leaveChannel();
      
      setState(() {
        _isLiveStreamActive = false;
        _currentStreamId = null;
      });

      _showSuccessSnackBar('تم إنهاء البث بنجاح');
    } catch (e) {

      _showErrorSnackBar('فشل في إنهاء البث');
    }
  }

  /// بدء تحديث الإحصائيات كل 3 ثوان
  void _startStatsPolling() {
    _stopStatsPolling(); // إيقاف المؤقت السابق إن وجد

    _statsTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_isLiveStreamActive || _currentStreamId == null || _isUpdatingStats) {
        if (!mounted || !_isLiveStreamActive || _currentStreamId == null) {

          timer.cancel();
        }
        return;
      }

      _isUpdatingStats = true;
      
      try {
        final apiService = LiveStreamApiService(context.read<ApiClient>());
        final response = await apiService.getLiveStats(postId: _currentStreamId!);
        
        if (response['status'] == 'success' && response['data'] != null) {
          final liveCount = response['data']['live_count'] ?? 0;

          // التأكد من أن الـ widget ما زال مُثبت وأن القيمة تغيرت فعلاً
          if (mounted && liveCount != _currentViewers) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentViewers = liveCount;
                });

              }
            });
          }
        } else {

        }
      } catch (e) {

      } finally {
        if (mounted) {
          _isUpdatingStats = false;
        }
      }
    });
  }

  /// إيقاف تحديث الإحصائيات  
  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _toggleCamera() async {
    try {
      await _engine.enableLocalVideo(!_isCameraEnabled);
      setState(() {
        _isCameraEnabled = !_isCameraEnabled;
      });
    } catch (e) {

    }
  }

  Future<void> _toggleMicrophone() async {
    try {
      await _engine.enableLocalAudio(!_isMicrophoneEnabled);
      setState(() {
        _isMicrophoneEnabled = !_isMicrophoneEnabled;
      });
    } catch (e) {

    }
  }

  Future<void> _switchCamera() async {
    try {
      await _engine.switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    } catch (e) {

    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: BlocListener<LiveStreamCreationBloc, LiveStreamCreationState>(
        listener: (context, state) {
          if (state is LiveStreamCreationSuccess) {
            setState(() {
              _currentStreamId = state.postId.toString();
            });

            if (state.agoraToken != null && state.agoraUid != null) {

              _joinAgoraChannel(
                channelName: state.channelName,
                token: state.agoraToken!,
                uid: state.agoraUid!,
              );
            } else {

              // إنشاء البث بدون token (للتجربة)
              setState(() {
                _isLiveStreamActive = true;
              });
              
              _showSuccessSnackBar('تم إنشاء البث بنجاح! (بدون Agora token)');
            }

            _showSuccessSnackBar('تم إنشاء البث بنجاح!');
            
            // بدء تحديثات التعليقات والإحصائيات
            final commentsBloc = context.read<LiveCommentsBloc>();
            commentsBloc.add(LoadLiveComments(postId: _currentStreamId!));
            
            // تشغيل التحديث التلقائي للتعليقات كل 3 ثوان

            commentsBloc.add(StartLiveCommentsPolling(postId: _currentStreamId!));
            
            // تشغيل تحديث الإحصائيات حتى لو لم يكن هناك Agora token

            _startStatsPolling();
          } else if (state is LiveStreamCreationError) {
            _showErrorSnackBar(state.message);
          }
        },
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isLiveStreamActive ? 'البث المباشر - نشط' : 'البث المباشر الاحترافي',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_isLiveStreamActive)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text(
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
      ],
    );
  }

  Widget _buildBody() {
    if (!_isEngineInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'جاري تحضير البث...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video preview/stream
          Positioned.fill(
            child: _buildVideoView(),
          ),
          
          // Live stream setup (when not streaming)
          if (!_isLiveStreamActive)
            Positioned.fill(
              child: Builder(
                builder: (context) => _buildStreamSetupOverlay(context),
              ),
            ),
        
                // Live controls and overlay (when streaming)
        if (_isLiveStreamActive) ...[
          // Top overlay with live indicator and viewer count
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),

          // Controls overlay (positioned at bottom to not cover chat)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120, // Fixed height for controls only
            child: _buildControlsSection(),
          ),

          // Bottom chat area (above controls) - LAST for highest z-index
          Positioned(
            left: 16,
            right: 16,
            bottom: 130, // Above the 120px controls area
            height: 280, // Slightly smaller to fit better
            child: _buildChatArea(),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: _isEngineInitialized
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : Container(
                color: Colors.black54,
                child: const Center(
                  child: Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStreamSetupOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إعداد البث المباشر',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان البث *',
                  hintText: 'اكتب عنوان جذاب للبث',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 100,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Description input
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'وصف البث',
                  hintText: 'اكتب وصف مختصر للبث (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 24),
              
              // Start stream button
              BlocBuilder<LiveStreamCreationBloc, LiveStreamCreationState>(
                builder: (context, state) {
                  final isLoading = state is LiveStreamCreationLoading;
                  
                  return ElevatedButton.icon(
                    onPressed: isLoading ? null : () => _startLiveStream(context),
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      isLoading ? 'جاري الإنشاء...' : 'بدء البث المباشر',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return LiveStreamControlsWidget(
      key: ValueKey('controls_${_isLiveStreamActive}'),
      isStreaming: _isLiveStreamActive,
      isCameraEnabled: _isCameraEnabled,
      isMicrophoneEnabled: _isMicrophoneEnabled,
      isFrontCamera: _isFrontCamera,
      viewersCount: 0, // نخفي العداد هنا لأننا أضفناه في الأعلى
      onToggleCamera: _toggleCamera,
      onToggleMicrophone: _toggleMicrophone,
      onSwitchCamera: _switchCamera,
      onEndStream: _stopLiveStream,
    );
  }

  /// بناء الـ overlay العلوي مع مؤشر البث المباشر وعدد المشاهدين
  Widget _buildTopOverlay() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // مؤشر البث المباشر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text(
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
            
            const SizedBox(width: 12),
            
            // عدد المشاهدين
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatViewersCount(_currentViewers)} مشاهد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء منطقة الشات مع إمكانية الكتابة
  Widget _buildChatArea() {
    return BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
      builder: (context, state) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7), // أكثر وضوحاً
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // عنوان المحادثة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'محادثة مباشرة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        state is LiveCommentsLoaded ? '${state.comments.length}' : '0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // قائمة التعليقات
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildCommentsList(state),
                  ),
                ),
                
                // منطقة إدخال التعليق
                _buildCommentInput(),
              ],
            ),
          ),
        );
      },
    );
  }  /// بناء قائمة التعليقات
  Widget _buildCommentsList(LiveCommentsState state) {
    if (state is LiveCommentsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }
    
    if (state is LiveCommentsLoaded && state.comments.isNotEmpty) {
      // ترتيب التعليقات بحسب التوقيت - الأحدث أولاً
      final sortedComments = List<LiveCommentModel>.from(state.comments);
      sortedComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return ListView.builder(
        reverse: true, // الأحدث في الأسفل (كالدردشات العادية)
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedComments.length,
        itemBuilder: (context, index) {
          // مع reverse: true، index=0 يُظهر آخر تعليق
          final comment = sortedComments[index];
          return _buildCommentItem(comment);
        },
      );
    }
    
    return Center(
      child: Text(
        'ابدأ محادثة!',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  /// بناء عنصر تعليق واحد
  Widget _buildCommentItem(LiveCommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة المستخدم
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                comment.userName.isNotEmpty 
                    ? comment.userName.substring(0, 1).toUpperCase()
                    : 'م',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // محتوى التعليق
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.userName.isNotEmpty ? comment.userName : 'مجهول',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCommentTime(comment.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  /// منطقة إدخال التعليق
  Widget _buildCommentInput() {
    final TextEditingController commentController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9), // خلفية أكثر وضوحاً
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.5), // أكثر وضوحاً
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15), // أكثر وضوحاً
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendComment(commentController),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _sendComment(commentController),
            ),
          ),
        ],
      ),
    );
  }

  /// إرسال تعليق جديد
  void _sendComment(TextEditingController controller) {
    if (controller.text.trim().isEmpty || _currentStreamId == null) return;

    final commentsBloc = context.read<LiveCommentsBloc>();
    
    // إضافة التعليق عبر الـ BLoC
    commentsBloc.add(AddLiveComment(
      postId: _currentStreamId!,
      text: controller.text.trim(),
    ));

    controller.clear();
  }

  /// تنسيق عدد المشاهدين
  String _formatViewersCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  /// تنسيق وقت التعليق
  String _formatCommentTime(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inSeconds < 60) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}د';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}س';
      } else {
        return '${difference.inDays}ي';
      }
    } catch (e) {
      return 'الآن';
    }
  }
}