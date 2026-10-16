import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../chat/data/models/chat_contacts_response.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../data/models/chat_call_models.dart';
import '../../data/services/agora_call_service.dart';
import '../controllers/webrtc_call_controller.dart';

class WebRtcCallPage extends StatefulWidget {
  const WebRtcCallPage({
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
  State<WebRtcCallPage> createState() => _WebRtcCallPageState();
}

class _WebRtcCallPageState extends State<WebRtcCallPage> {
  late final String _tag;
  late final WebRtcCallController _controller;

  @override
  void initState() {
    super.initState();
    final tagSeed = widget.initialCall?.callId ?? widget.conversationId;
    _tag = 'webrtc-call-$tagSeed-${widget.callType.name}';
    _controller = Get.put(
      WebRtcCallController(
        chatService: Get.find<ChatService>(),
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
    Get.delete<WebRtcCallController>(tag: _tag, force: true);
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
              child: _IncomingWebRtcPrompt(
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
              _WebRtcVideoBody(
                controller: _controller,
                cardColor: Colors.black,
                textColor: textColor,
                mutedColor: mutedColor,
                avatarUrl: widget.avatarUrl,
                title: widget.conversationTitle,
              )
            else
              _WebRtcAudioBody(
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
                      IconButton(
                        onPressed: _controller.isInvitingMember.value
                            ? null
                            : () =>
                                  _showWebRtcInviteSheet(context, _controller),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
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
                child: _WebRtcCallActions(
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

class _WebRtcVideoBody extends StatelessWidget {
  const _WebRtcVideoBody({
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.statusText.value;
      final tiles = controller.orderedVideoTiles();
      final focusedTile = _findVideoTile(
        tiles,
        controller.enlargedVideoTileId.value,
      );

      return ColoredBox(
        color: cardColor,
        child: _InteractiveVideoStage(
          controller: controller,
          tiles: tiles,
          focusedTile: focusedTile,
          status: status,
          textColor: textColor,
          mutedColor: mutedColor,
          avatarUrl: avatarUrl,
          title: title,
        ),
      );
    });
  }
}

class _WebRtcAudioBody extends StatelessWidget {
  const _WebRtcAudioBody({
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cardColor, const Color(0xFF090A0D)],
        ),
      ),
      child: Obx(
        () => _CallWaitingState(
          avatarUrl: avatarUrl,
          title: title,
          status: controller.isConnected.value
              ? controller.callDurationText.value
              : controller.statusText.value,
          textColor: textColor,
          mutedColor: mutedColor,
        ),
      ),
    );
  }
}

class _InteractiveVideoStage extends StatelessWidget {
  const _InteractiveVideoStage({
    required this.controller,
    required this.tiles,
    required this.focusedTile,
    required this.status,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final List<WebRtcVideoTile> tiles;
  final WebRtcVideoTile? focusedTile;
  final String status;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return _CallWaitingState(
        avatarUrl: avatarUrl,
        title: title,
        status: status,
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (tiles.length <= 2) {
      WebRtcVideoTile? localTile;
      WebRtcVideoTile? remoteTile;
      for (final tile in tiles) {
        if (tile.isLocal) {
          localTile = tile;
        } else {
          remoteTile ??= tile;
        }
      }
      return _ReferenceVideoStage(
        controller: controller,
        mainTile: remoteTile ?? localTile!,
        localTile: remoteTile == null ? null : localTile,
        status: status,
        avatarUrl: avatarUrl,
        title: title,
      );
    }

    if (focusedTile != null && tiles.length > 1) {
      final secondaryTiles = tiles
          .where((tile) => tile.id != focusedTile!.id)
          .toList(growable: false);
      return LayoutBuilder(
        builder: (context, constraints) {
          final thumbnailHeight = constraints.maxHeight < 430 ? 92.0 : 118.0;
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: _ReorderableVideoTile(
                    controller: controller,
                    tile: focusedTile!,
                    status: status,
                    avatarUrl: avatarUrl,
                    title: title,
                    isFocused: true,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: thumbnailHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: secondaryTiles.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final tile = secondaryTiles[index];
                      return SizedBox(
                        width: thumbnailHeight * 0.82,
                        child: _ReorderableVideoTile(
                          controller: controller,
                          tile: tile,
                          status: status,
                          avatarUrl: avatarUrl,
                          title: title,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return _VideoTileGrid(
      controller: controller,
      tiles: tiles,
      status: status,
      avatarUrl: avatarUrl,
      title: title,
    );
  }
}

class _ReferenceVideoStage extends StatelessWidget {
  const _ReferenceVideoStage({
    required this.controller,
    required this.mainTile,
    required this.localTile,
    required this.status,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final WebRtcVideoTile mainTile;
  final WebRtcVideoTile? localTile;
  final String status;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _VideoTileContent(
          controller: controller,
          tile: mainTile,
          status: status,
          avatarUrl: avatarUrl,
          title: title,
        ),
        IgnorePointer(
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
        if (localTile != null)
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
                      child: _VideoTileContent(
                        controller: controller,
                        tile: localTile!,
                        status: status,
                        avatarUrl: avatarUrl,
                        title: title,
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
    );
  }
}

class _VideoTileGrid extends StatelessWidget {
  const _VideoTileGrid({
    required this.controller,
    required this.tiles,
    required this.status,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final List<WebRtcVideoTile> tiles;
  final String status;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (tiles.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _ReorderableVideoTile(
          controller: controller,
          tile: tiles.first,
          status: status,
          avatarUrl: avatarUrl,
          title: title,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      physics: tiles.length > 4
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tiles.length <= 2 ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: tiles.length <= 2 ? 1.22 : 0.78,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        return _ReorderableVideoTile(
          controller: controller,
          tile: tiles[index],
          status: status,
          avatarUrl: avatarUrl,
          title: title,
        );
      },
    );
  }
}

class _ReorderableVideoTile extends StatelessWidget {
  const _ReorderableVideoTile({
    required this.controller,
    required this.tile,
    required this.status,
    required this.avatarUrl,
    required this.title,
    this.isFocused = false,
  });

  final WebRtcCallController controller;
  final WebRtcVideoTile tile;
  final String status;
  final String avatarUrl;
  final String title;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != tile.id,
      onAcceptWithDetails: (details) {
        controller.moveVideoTileBefore(
          draggedId: details.data,
          targetId: tile.id,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        Widget buildTile({required double opacity}) {
          return Opacity(
            opacity: opacity,
            child: _VideoTileCard(
              controller: controller,
              tile: tile,
              status: status,
              avatarUrl: avatarUrl,
              title: title,
              isFocused: isFocused,
              isDropHighlighted: isHighlighted,
            ),
          );
        }

        return LongPressDraggable<String>(
          data: tile.id,
          feedback: _VideoDragFeedback(label: _tileLabel(tile, title)),
          childWhenDragging: buildTile(opacity: 0.42),
          child: buildTile(opacity: 1),
        );
      },
    );
  }
}

class _VideoTileCard extends StatelessWidget {
  const _VideoTileCard({
    required this.controller,
    required this.tile,
    required this.status,
    required this.avatarUrl,
    required this.title,
    required this.isFocused,
    required this.isDropHighlighted,
  });

  final WebRtcCallController controller;
  final WebRtcVideoTile tile;
  final String status;
  final String avatarUrl;
  final String title;
  final bool isFocused;
  final bool isDropHighlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDropHighlighted
        ? AppColors.primary
        : isFocused
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.16);
    return GestureDetector(
      onTap: isFocused
          ? controller.clearVideoTileFocus
          : () => controller.toggleVideoTileFocus(tile.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(isFocused ? 22 : 18),
          border: Border.all(
            color: borderColor,
            width: isDropHighlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _VideoTileContent(
              controller: controller,
              tile: tile,
              status: status,
              avatarUrl: avatarUrl,
              title: title,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _TileIconButton(
                icon: isFocused
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                onTap: isFocused
                    ? controller.clearVideoTileFocus
                    : () => controller.toggleVideoTileFocus(tile.id),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _TileNameBadge(label: _tileLabel(tile, title)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTileContent extends StatelessWidget {
  const _VideoTileContent({
    required this.controller,
    required this.tile,
    required this.status,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final WebRtcVideoTile tile;
  final String status;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    switch (tile.kind) {
      case WebRtcVideoTileKind.local:
        return Obx(
          () => controller.isLocalPreviewReady.value
              ? RTCVideoView(
                  controller.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : _VideoTilePlaceholder(
                  avatarUrl: avatarUrl,
                  title: 'You',
                  status: status,
                  icon: Icons.videocam_off_rounded,
                ),
        );
      case WebRtcVideoTileKind.legacyRemote:
        return Obx(
          () => controller.hasRemoteStream.value
              ? RTCVideoView(
                  controller.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : _VideoTilePlaceholder(
                  avatarUrl: avatarUrl,
                  title: title,
                  status: AppTranslations.callWaitingForRemoteMedia.tr,
                  icon: Icons.person_rounded,
                ),
        );
      case WebRtcVideoTileKind.remote:
        final participant = tile.participant!;
        return Obx(
          () => participant.hasStream.value
              ? RTCVideoView(
                  participant.renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : _VideoTilePlaceholder(
                  avatarUrl: participant.avatarUrl,
                  title: participant.displayName,
                  status: AppTranslations.callWaitingForRemoteMedia.tr,
                  icon: Icons.person_rounded,
                ),
        );
    }
  }
}

class _VideoTilePlaceholder extends StatelessWidget {
  const _VideoTilePlaceholder({
    required this.avatarUrl,
    required this.title,
    required this.status,
    required this.icon,
  });

  final String avatarUrl;
  final String title;
  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: const Color(0xFF111326),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatarUrl.trim().isNotEmpty
                  ? _AvatarCircle(avatarUrl: avatarUrl, size: 64)
                  : Icon(icon, color: Colors.white, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileNameBadge extends StatelessWidget {
  const _TileNameBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TileIconButton extends StatelessWidget {
  const _TileIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _VideoDragFeedback extends StatelessWidget {
  const _VideoDragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 136,
        height: 86,
        decoration: BoxDecoration(
          color: const Color(0xEE111326),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_rounded, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

WebRtcVideoTile? _findVideoTile(List<WebRtcVideoTile> tiles, String id) {
  if (id.trim().isEmpty) {
    return null;
  }
  for (final tile in tiles) {
    if (tile.id == id) {
      return tile;
    }
  }
  return null;
}

String _tileLabel(WebRtcVideoTile tile, String fallbackTitle) {
  switch (tile.kind) {
    case WebRtcVideoTileKind.local:
      return 'You';
    case WebRtcVideoTileKind.legacyRemote:
      return fallbackTitle;
    case WebRtcVideoTileKind.remote:
      return tile.participant?.displayName.trim().isNotEmpty == true
          ? tile.participant!.displayName
          : fallbackTitle;
  }
}

class _IncomingWebRtcPrompt extends StatelessWidget {
  const _IncomingWebRtcPrompt({
    required this.controller,
    required this.textColor,
    required this.mutedColor,
    required this.avatarUrl,
    required this.title,
  });

  final WebRtcCallController controller;
  final Color textColor;
  final Color mutedColor;
  final String avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final call = controller.initialCall;
    final invite = call?.invite;
    final activeParticipants = (call?.participants ?? const [])
        .where((participant) => participant.isActive)
        .toList(growable: false);
    final isInvite = call?.isGroupCallInvite == true || invite != null;
    final invitedByName = invite?.invitedByName.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        children: [
          const Spacer(),
          _AvatarCircle(avatarUrl: avatarUrl, size: 132),
          const SizedBox(height: 28),
          Text(
            isInvite && invitedByName.isNotEmpty ? invitedByName : title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isInvite
                ? (controller.isVideoCall
                      ? 'Invited you to a group video call'
                      : 'Invited you to a group voice call')
                : controller.isVideoCall
                ? AppTranslations.callIncomingVideo.tr
                : AppTranslations.callIncomingVoice.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isInvite && activeParticipants.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              activeParticipants
                  .map((participant) => participant.displayName)
                  .where((name) => name.isNotEmpty)
                  .take(4)
                  .join(', '),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundActionButton(
                icon: Icons.call_end_rounded,
                color: const Color(0xFFFF4D5E),
                onPressed: controller.declineIncomingCall,
              ),
              _RoundActionButton(
                icon: Icons.call_rounded,
                color: const Color(0xFF30D158),
                onPressed: controller.acceptIncomingCall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebRtcCallActions extends StatelessWidget {
  const _WebRtcCallActions({required this.controller, required this.textColor});

  final WebRtcCallController controller;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
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
                _CallControlButton(
                  icon: controller.isMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_none_rounded,
                  label: AppTranslations.callMute.tr,
                  background: Colors.white.withValues(alpha: 0.16),
                  foreground: textColor,
                  onPressed: controller.toggleMute,
                ),
                if (controller.isVideoCall)
                  _CallControlButton(
                    icon: controller.isLocalPreviewReady.value
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: AppTranslations.callCamera.tr,
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: textColor,
                    onPressed: controller.toggleCamera,
                  ),
                _CallControlButton(
                  icon: controller.isSpeakerOn.value
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  label: AppTranslations.callSpeaker.tr,
                  background: controller.isSpeakerOn.value
                      ? const Color(0xFF517C88).withValues(alpha: 0.78)
                      : Colors.white.withValues(alpha: 0.16),
                  foreground: controller.isSpeakerOn.value
                      ? const Color(0xFF79E4F4)
                      : textColor,
                  onPressed: controller.toggleSpeaker,
                ),
                if (controller.isVideoCall)
                  _CallControlButton(
                    icon: Icons.cameraswitch_rounded,
                    label: AppTranslations.callFlip.tr,
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: textColor,
                    onPressed: controller.switchCamera,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _CallControlButton(
              icon: Icons.call_end_rounded,
              label: AppTranslations.callEnd.tr,
              background: MessengerDesign.destructive,
              foreground: Colors.white,
              onPressed: controller.endCall,
              showLabel: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
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

Future<void> _showWebRtcInviteSheet(
  BuildContext context,
  WebRtcCallController controller,
) async {
  final chatService = Get.find<ChatService>();
  final excludedIds = controller.callParticipants
      .where((participant) {
        final status = participant.status.trim().toLowerCase();
        return participant.isActive ||
            status == 'invited' ||
            status == 'pending';
      })
      .map((participant) => participant.userId)
      .toSet();
  excludedIds.add(controller.recipientUserId);
  final currentUserId = Get.find<ChatAppPreferences>().getUserId() ?? 0;
  if (currentUserId > 0) {
    excludedIds.add(currentUserId);
  }

  final resultMessage = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return _InviteMemberSheet(
        contactsLoader: chatService.fetchContacts,
        excludedIds: excludedIds,
        onInvite: (contact) async {
          final message = await controller.inviteMember(contact.id);
          final normalizedMessage = message.trim().toLowerCase();
          final participantWasAdded = controller.callParticipants.any((item) {
            if (item.userId != contact.id) {
              return false;
            }
            final status = item.status.trim().toLowerCase();
            return item.isActive || status == 'invited' || status == 'pending';
          });
          final messageReportsSuccess =
              normalizedMessage == 'invite sent' ||
              (normalizedMessage.contains('invite sent') &&
                  !normalizedMessage.contains('already'));
          return _InviteMemberResult(
            message: message,
            succeeded: participantWasAdded || messageReportsSuccess,
          );
        },
      );
    },
  );
  if (context.mounted && resultMessage?.trim().isNotEmpty == true) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultMessage!)));
  }
}

class _InviteMemberResult {
  const _InviteMemberResult({required this.message, required this.succeeded});

  final String message;
  final bool succeeded;
}

class _InviteMemberSheet extends StatefulWidget {
  const _InviteMemberSheet({
    required this.contactsLoader,
    required this.excludedIds,
    required this.onInvite,
  });

  final Future<ChatContactsResponse> Function() contactsLoader;
  final Set<int> excludedIds;
  final Future<_InviteMemberResult> Function(ChatContactModel contact) onInvite;

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  late Future<ChatContactsResponse> _contactsFuture;
  String _query = '';
  int? _invitingContactId;
  String _inviteError = '';

  @override
  void initState() {
    super.initState();
    _contactsFuture = widget.contactsLoader();
  }

  void _retryContacts() {
    setState(() {
      _contactsFuture = widget.contactsLoader();
    });
  }

  Future<void> _invite(ChatContactModel contact) async {
    if (_invitingContactId != null) {
      return;
    }
    setState(() {
      _invitingContactId = contact.id;
      _inviteError = '';
    });
    _InviteMemberResult result;
    try {
      result = await widget.onInvite(contact);
    } catch (error) {
      result = _InviteMemberResult(
        message: error.toString().trim().isEmpty
            ? AppTranslations.composeContactsUnavailable.tr
            : error.toString(),
        succeeded: false,
      );
    }
    if (!mounted) {
      return;
    }
    if (result.succeeded) {
      Navigator.of(context).pop(result.message);
      return;
    }
    setState(() {
      _invitingContactId = null;
      _inviteError = result.message.trim().isEmpty
          ? AppTranslations.composeContactsUnavailable.tr
          : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _invitingContactId == null,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.groupDetailsAddMembers.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _invitingContactId == null
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: AppTranslations.composeSearchHint.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
              if (_inviteError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _inviteError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<ChatContactsResponse>(
                  future: _contactsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppTranslations.composeContactsUnavailable.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _retryContacts,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(AppTranslations.retry.tr),
                            ),
                          ],
                        ),
                      );
                    }
                    final response = snapshot.data;
                    if (response == null || !response.isReady) {
                      return Center(
                        child: Text(
                          response?.message.trim().isNotEmpty == true
                              ? response!.message
                              : AppTranslations.composeContactsUnavailable.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    final contacts = response.contacts
                        .where(
                          (contact) =>
                              contact.id > 0 &&
                              contact.canMessage &&
                              !widget.excludedIds.contains(contact.id),
                        )
                        .where((contact) {
                          final query = _query.trim().toLowerCase();
                          if (query.isEmpty) return true;
                          return contact.title.toLowerCase().contains(query) ||
                              contact.userName.toLowerCase().contains(query);
                        })
                        .toList();
                    if (contacts.isEmpty) {
                      return Center(
                        child: Text(
                          AppTranslations.composeNoContacts.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _AvatarCircle(
                            avatarUrl: contact.avatarUrl,
                            size: 44,
                          ),
                          title: Text(
                            contact.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: contact.isOnline
                              ? Text(AppTranslations.chatOnlineNow.tr)
                              : contact.lastSeen.trim().isNotEmpty
                              ? Text(contact.lastSeen)
                              : null,
                          trailing: _invitingContactId == contact.id
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_call),
                          enabled: _invitingContactId == null,
                          onTap: () => _invite(contact),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarCircle(avatarUrl: avatarUrl, size: 128),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF4D5E),
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFF4D5E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.avatarUrl, required this.size});

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF3063F7), Color(0xFF1D2A62)],
        ),
        image: avatarUrl.trim().isNotEmpty
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl.trim().isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: size * 0.42)
          : null,
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
