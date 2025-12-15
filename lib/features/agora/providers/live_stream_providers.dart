import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../data/api_service/live_stream_api_service.dart';
import '../bloc/live_comments_bloc.dart';
/// Provider للـ Blocs الخاصة بالبث المباشر
class LiveStreamBlocProvider extends StatelessWidget {
  final Widget child;
  final String liveId;
  const LiveStreamBlocProvider({
    Key? key,
    required this.child,
    required this.liveId,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // استخدام ApiClient المصادق من dependency injection
    final apiService = LiveStreamApiService(context.read<ApiClient>());
    return MultiBlocProvider(
      providers: [
        // Live Comments Bloc
        BlocProvider(
          create: (context) => LiveCommentsBloc(
            apiService: apiService,
          ),
        ),
        // Live Stats Bloc
        BlocProvider(
          create: (context) => LiveStatsBloc(
            apiService: apiService,
          ),
        ),
      ],
      child: child,
    );
  }
}
/// Widget مساعد لإنشاء Provider للبث المباشر
class LiveStreamPage extends StatelessWidget {
  final String liveId;
  final Widget Function(BuildContext context) builder;
  const LiveStreamPage({
    Key? key,
    required this.liveId,
    required this.builder,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LiveStreamBlocProvider(
      liveId: liveId,
      child: Builder(
        builder: builder,
      ),
    );
  }
}
/// Mixin لتسهيل الوصول إلى Live Blocs
mixin LiveStreamBlocsMixin {
  LiveCommentsBloc getLiveCommentsBloc(BuildContext context) {
    return context.read<LiveCommentsBloc>();
  }
  LiveStatsBloc getLiveStatsBloc(BuildContext context) {
    return context.read<LiveStatsBloc>();
  }
  void startLiveComments(BuildContext context, String liveId) {
    getLiveCommentsBloc(context).add(
      LoadLiveComments(postId: liveId),
    );
    getLiveCommentsBloc(context).add(
      StartLiveCommentsPolling(postId: liveId),
    );
  }
  void stopLiveComments(BuildContext context) {
    getLiveCommentsBloc(context).add(StopLiveCommentsPolling());
  }
  void startLiveStats(BuildContext context, String liveId) {
    getLiveStatsBloc(context).add(
      LoadLiveStats(liveId: liveId),
    );
    getLiveStatsBloc(context).add(
      StartLiveStatsPolling(liveId: liveId),
    );
  }
  void stopLiveStats(BuildContext context) {
    getLiveStatsBloc(context).add(StopLiveStatsPolling());
  }
  void addLiveComment(BuildContext context, String liveId, String text) {
    getLiveCommentsBloc(context).add(
      AddLiveComment(
        postId: liveId,
        text: text,
      ),
    );
  }
  void reactToComment(BuildContext context, String commentId, String reactionType) {
    getLiveCommentsBloc(context).add(
      ReactToLiveComment(
        commentId: commentId,
        reactionType: reactionType,
      ),
    );
  }
}