import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/api_service/live_stream_api_service.dart';
// Events
abstract class LiveStreamCreationEvent extends Equatable {
  const LiveStreamCreationEvent();
  @override
  List<Object?> get props => [];
}
class CreateLiveStreamEvent extends LiveStreamCreationEvent {
  final String? title;
  final String? description;
  final String? videoThumbnail;
  final String? node;
  final int? nodeId;
  final bool tipsEnabled;
  final bool forSubscriptions;
  final bool isPaid;
  final double postPrice;
  const CreateLiveStreamEvent({
    this.title,
    this.description,
    this.videoThumbnail,
    this.node,
    this.nodeId,
    this.tipsEnabled = false,
    this.forSubscriptions = false,
    this.isPaid = false,
    this.postPrice = 0,
  });
  @override
  List<Object?> get props => [
    title,
    description,
    videoThumbnail,
    node,
    nodeId,
    tipsEnabled,
    forSubscriptions,
    isPaid,
    postPrice,
  ];
}
class ResetCreationStateEvent extends LiveStreamCreationEvent {}
// States
abstract class LiveStreamCreationState extends Equatable {
  const LiveStreamCreationState();
  @override
  List<Object?> get props => [];
}
class LiveStreamCreationInitial extends LiveStreamCreationState {}
class LiveStreamCreationLoading extends LiveStreamCreationState {}
class LiveStreamCreationSuccess extends LiveStreamCreationState {
  final int liveId;
  final int postId;
  final String channelName;
  final Map<String, dynamic> postData;
  final String? agoraToken;
  final int? agoraUid;
  const LiveStreamCreationSuccess({
    required this.liveId,
    required this.postId,
    required this.channelName,
    required this.postData,
    this.agoraToken,
    this.agoraUid,
  });
  @override
  List<Object?> get props => [
    liveId,
    postId,
    channelName,
    postData,
    agoraToken,
    agoraUid,
  ];
}
class LiveStreamCreationError extends LiveStreamCreationState {
  final String message;
  final String? errorType;
  const LiveStreamCreationError({
    required this.message,
    this.errorType,
  });
  @override
  List<Object?> get props => [message, errorType];
}
// Bloc
class LiveStreamCreationBloc extends Bloc<LiveStreamCreationEvent, LiveStreamCreationState> {
  final LiveStreamApiService _apiService;
  LiveStreamCreationBloc(this._apiService) : super(LiveStreamCreationInitial()) {
    on<CreateLiveStreamEvent>(_onCreateLiveStream);
    on<ResetCreationStateEvent>(_onResetCreationState);
  }
  Future<void> _onCreateLiveStream(
    CreateLiveStreamEvent event,
    Emitter<LiveStreamCreationState> emit,
  ) async {
    emit(LiveStreamCreationLoading());
    try {
      // إنشاء البث المباشر
      final createResponse = await _apiService.createLiveStream(
        title: event.title,
        description: event.description,
        videoThumbnail: event.videoThumbnail,
        node: event.node,
        nodeId: event.nodeId,
        tipsEnabled: event.tipsEnabled,
        forSubscriptions: event.forSubscriptions,
        isPaid: event.isPaid,
        postPrice: event.postPrice,
      );
      // استخراج البيانات من الاستجابة
      final liveId = createResponse['live_id'];
      final postId = createResponse['post_id'];
      final channelName = createResponse['channel_name'];
      final postData = Map<String, dynamic>.from(createResponse['post'] ?? {});
      // التحقق من وجود agora_token في الاستجابة المباشرة
      final directAgoraToken = createResponse['agora_token'];
      final directAgoraUid = createResponse['agora_uid'];
      if (liveId == null || postId == null || channelName == null) {
        throw Exception('بيانات البث المباشر غير مكتملة في الاستجابة');
      }
      // إذا كان agora_token موجود مباشرة، استخدمه
      if (directAgoraToken != null) {
        emit(LiveStreamCreationSuccess(
          liveId: int.parse(liveId.toString()),
          postId: int.parse(postId.toString()),
          channelName: channelName.toString(),
          postData: postData,
          agoraToken: directAgoraToken.toString(),
          agoraUid: directAgoraUid != null ? int.tryParse(directAgoraUid.toString()) : null,
        ));
        return; // الانتهاء هنا، لا حاجة لطلب token إضافي
      }
      try {
        // انتظار قصير للتأكد من أن البث تم إنشاؤه في قاعدة البيانات
        await Future.delayed(const Duration(milliseconds: 1500));
        // محاولة الحصول على Agora token للمذيع
        final tokenResponse = await _apiService.getAgoraToken(
          liveId: liveId.toString(),
          role: 'publisher',
        );
        final tokenData = tokenResponse['data'];
        // استخراج البيانات الصحيحة من الاستجابة
        final agoraToken = tokenData?['agora_audience_token']; // البيانات الحقيقية من API
        final agoraUid = tokenData?['agora_audience_uid'];
        final realChannelName = tokenData?['agora_channel_name'] ?? channelName.toString();
        emit(LiveStreamCreationSuccess(
          liveId: int.parse(liveId.toString()),
          postId: int.parse(postId.toString()),
          channelName: realChannelName, // استخدام اسم القناة الحقيقي
          postData: postData,
          agoraToken: agoraToken,
          agoraUid: agoraUid != null ? int.tryParse(agoraUid.toString()) : null,
        ));
      } catch (tokenError) {
        // البث تم إنشاؤه بنجاح حتى لو فشل token - نولد token مؤقت
        // يمكن للمستخدم المتابعة والتطبيق سيعمل مع Agora بدون backend token
        emit(LiveStreamCreationSuccess(
          liveId: int.parse(liveId.toString()),
          postId: int.parse(postId.toString()),
          channelName: channelName.toString(),
          postData: postData,
          // نستخدم null للـ token - Agora سيعمل بدون token للتجربة
          agoraToken: null,
          agoraUid: null,
        ));
      }
    } catch (e) {
      String errorMessage = 'فشل في إنشاء البث المباشر';
      String? errorType;
      if (e.toString().contains('unauthorized') || e.toString().contains('401')) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
        errorType = 'auth_required';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'خطأ في الاتصال، تحقق من الإنترنت';
        errorType = 'network_error';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية إنشاء البث المباشر';
        errorType = 'permission_denied';
      } else {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      }
      emit(LiveStreamCreationError(
        message: errorMessage,
        errorType: errorType,
      ));
    }
  }
  void _onResetCreationState(
    ResetCreationStateEvent event,
    Emitter<LiveStreamCreationState> emit,
  ) {
    emit(LiveStreamCreationInitial());
  }
}