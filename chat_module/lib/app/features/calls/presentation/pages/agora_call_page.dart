import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../data/models/chat_call_models.dart';
import '../../data/services/agora_call_service.dart';
import '../controllers/agora_call_controller.dart';

class AgoraCallPage extends StatefulWidget {
  const AgoraCallPage({
    super.key,
    required this.conversationId,
    required this.recipientUserId,
    required this.conversationTitle,
    required this.avatarUrl,
    required this.callType,
    this.isIncoming = false,
    this.initialCall,
    this.autoAccept = false,
  });

  final int conversationId;
  final int recipientUserId;
  final String conversationTitle;
  final String avatarUrl;
  final AgoraCallType callType;
  final bool isIncoming;
  final ChatCallModel? initialCall;
  final bool autoAccept;

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  late final String _tag;
  late final AgoraCallController _controller;

  @override
  void initState() {
    super.initState();
    final tagSeed = widget.initialCall?.callId ?? widget.conversationId;
    _tag = 'agora-call-$tagSeed-${widget.callType.name}';
    _controller = Get.put(
      AgoraCallController(
        callService: Get.find<AgoraCallService>(),
        chatService: Get.find(),
        conversationId: widget.conversationId,
        recipientUserId: widget.recipientUserId,
        conversationTitle: widget.conversationTitle,
        avatarUrl: widget.avatarUrl,
        callType: widget.callType,
        isIncoming: widget.isIncoming,
        initialCall: widget.initialCall,
        autoAccept: widget.autoAccept,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<AgoraCallController>(tag: _tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        const textColor = Colors.white;
        final mutedColor = Colors.white.withValues(alpha: 0.78);
        final error = _controller.errorMessage.value;
        final isIncomingPrompt = _controller.isAwaitingIncomingDecision.value;

        if (isIncomingPrompt && error.isEmpty) {
          return ColoredBox(
            color: const Color(0xFF11131A),
            child: SafeArea(
              child: _IncomingCallPrompt(
                controller: _controller,
                textColor: textColor,
                mutedColor: mutedColor,
                avatarUrl: widget.avatarUrl,
                title: widget.conversationTitle,
              ),
            ),
          );
        }

        final status = _controller.isConnected.value
            ? _controller.callDurationText.value
            : _controller.statusText.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (error.isNotEmpty)
              _CallErrorState(message: error)
            else if (_controller.isVideoCall)
              _VideoCallBody(
                controller: _controller,
                cardColor: Colors.black,
                textColor: textColor,
                mutedColor: mutedColor,
                avatarUrl: widget.avatarUrl,
                title: widget.conversationTitle,
              )
            else
              _AudioCallBody(
                controller: _controller,
                cardColor: const Color(0xFF171920),
                textColor: textColor,
                mutedColor: mutedColor,
                avatarUrl: widget.avatarUrl,
                title: widget.conversationTitle,
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _controller.endCall,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.conversationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              status.isEmpty
                                  ? AppTranslations.callConnecting.tr
                                  : status,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48, height: 48),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _CallActions(
                  controller: _controller,
                  textColor: textColor,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _VideoCallBody extends StatelessWidget {
  const _VideoCallBody({
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final AgoraCallController controller;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final engine = controller.engine;
      final remoteUid = controller.remoteUid.value;
      final localPreviewReady = controller.isLocalPreviewReady.value;
      final isCameraOff = controller.isCameraOff.value;
      final status = controller.statusText.value;

      return ColoredBox(
        color: cardColor,
        child: Stack(
          children: [
            Positioned.fill(
              child: engine != null && remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: engine,
                        canvas: VideoCanvas(uid: remoteUid),
                        connection: RtcConnection(
                          channelId: controller.channelName,
                        ),
                      ),
                    )
                  : _CallWaitingState(
                      avatarUrl: avatarUrl,
                      title: title,
                      status: status,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.48),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.66),
                      ],
                      stops: const [0, 0.24, 0.62, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 104,
              right: 16,
              child: SizedBox(
                width: 92,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF292A2F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            engine != null && localPreviewReady && !isCameraOff
                            ? AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: engine,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  isCameraOff
                                      ? Icons.videocam_off_rounded
                                      : Icons.person_rounded,
                                  color: Colors.white70,
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.58),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: controller.switchCamera,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 31,
                            height: 31,
                            child: Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AudioCallBody extends StatelessWidget {
  const _AudioCallBody({
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final AgoraCallController controller;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.isConnected.value
          ? controller.callDurationText.value
          : controller.statusText.value;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cardColor, const Color(0xFF090A0D)],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: _CallWaitingState(
          avatarUrl: avatarUrl,
          title: title,
          status: status,
          textColor: textColor,
          mutedColor: mutedColor,
        ),
      );
    });
  }
}

class _CallWaitingState extends StatelessWidget {
  const _CallWaitingState({
    required this.avatarUrl,
    required this.title,
    required this.status,
    required this.textColor,
    required this.mutedColor,
  });

  final String avatarUrl;
  final String title;
  final String status;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: avatarUrl.trim().isEmpty
                  ? null
                  : NetworkImage(avatarUrl),
              child: avatarUrl.trim().isEmpty
                  ? Text(
                      title.isEmpty ? 'M' : title.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status.isEmpty ? AppTranslations.callConnecting.tr : status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingCallPrompt extends StatelessWidget {
  const _IncomingCallPrompt({
    required this.controller,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final AgoraCallController controller;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 10,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              backgroundImage: avatarUrl.trim().isEmpty
                  ? null
                  : NetworkImage(avatarUrl),
              child: avatarUrl.trim().isEmpty
                  ? Text(
                      title.isEmpty ? 'M' : title.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.callIncoming.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.isVideoCall
                ? AppTranslations.callVideo.tr
                : AppTranslations.callVoice.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _CallActions(controller: controller, textColor: textColor),
        ],
      ),
    );
  }
}

class _CallActions extends StatelessWidget {
  const _CallActions({required this.controller, required this.textColor});

  final AgoraCallController controller;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAwaitingIncomingDecision.value) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallActionButton(
              icon: Icons.call_end_rounded,
              label: AppTranslations.callDeclineAction.tr,
              onTap: controller.declineIncomingCall,
              background: const Color(0xFFE34D4D),
              foreground: AppColors.white,
            ),
            _CallActionButton(
              icon: Icons.call_rounded,
              label: AppTranslations.callAccept.tr,
              onTap: controller.acceptIncomingCall,
              background: const Color(0xFF28B463),
              foreground: AppColors.white,
            ),
          ],
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallActionButton(
                  icon: controller.isMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_none_rounded,
                  label: AppTranslations.callMute.tr,
                  onTap: controller.toggleMute,
                  background: Colors.white.withValues(alpha: 0.16),
                  foreground: textColor,
                ),
                if (controller.isVideoCall)
                  _CallActionButton(
                    icon: controller.isCameraOff.value
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: AppTranslations.callCamera.tr,
                    onTap: controller.toggleCamera,
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: textColor,
                  ),
                _CallActionButton(
                  icon: controller.isSpeakerOn.value
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  label: AppTranslations.callSpeaker.tr,
                  onTap: controller.toggleSpeaker,
                  background: controller.isSpeakerOn.value
                      ? const Color(0xFF517C88).withValues(alpha: 0.78)
                      : Colors.white.withValues(alpha: 0.16),
                  foreground: controller.isSpeakerOn.value
                      ? const Color(0xFF79E4F4)
                      : textColor,
                ),
                if (controller.isVideoCall)
                  _CallActionButton(
                    icon: Icons.cameraswitch_rounded,
                    label: AppTranslations.callFlip.tr,
                    onTap: controller.switchCamera,
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: textColor,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _CallActionButton(
              icon: Icons.call_end_rounded,
              label: AppTranslations.callEnd.tr,
              onTap: controller.endCall,
              background: MessengerDesign.destructive,
              foreground: Colors.white,
              showLabel: false,
            ),
          ],
        ),
      );
    });
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: foreground),
            ),
            if (showLabel) ...[
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CallErrorState extends StatelessWidget {
  const _CallErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
