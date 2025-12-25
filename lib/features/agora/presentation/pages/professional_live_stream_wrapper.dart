import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../bloc/live_stream_creation_bloc.dart';
import '../../bloc/live_comments_bloc.dart';
import '../../data/api_service/live_stream_api_service.dart';
import 'professional_live_stream_page.dart';

/// Wrapper لصفحة البث المباشر مع Providers محلية
/// يحل مشكلة Provider scope errors
class ProfessionalLiveStreamWrapper extends StatelessWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? node; // page أو group
  final int? nodeId; // معرف الصفحة أو المجموعة

  const ProfessionalLiveStreamWrapper({
    Key? key,
    this.initialTitle,
    this.initialDescription,
    this.node,
    this.nodeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LiveStreamCreationBloc(
            LiveStreamApiService(context.read<ApiClient>()),
          ),
        ),
        BlocProvider(
          create: (context) => LiveCommentsBloc(
            apiService: LiveStreamApiService(context.read<ApiClient>()),
          ),
        ),
      ],
      child: ProfessionalLiveStreamPage(
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        node: node,
        nodeId: nodeId,
      ),
    );
  }
}