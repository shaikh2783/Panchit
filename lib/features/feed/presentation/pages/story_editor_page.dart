import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Crop aspect presets offered by the story editor.
enum StoryCropAspect { original, square, portrait }

extension _StoryCropAspectLabel on StoryCropAspect {
  String get label {
    switch (this) {
      case StoryCropAspect.original:
        return 'crop_aspect_original'.tr;
      case StoryCropAspect.square:
        return 'crop_aspect_square'.tr;
      case StoryCropAspect.portrait:
        return 'crop_aspect_portrait'.tr;
    }
  }
}

enum _OverlayItemType { text, sticker }

class _OverlayItem {
  _OverlayItem({
    required this.id,
    required this.type,
    required this.content,
    required this.offset,
    this.color = Colors.white,
    this.fontSize = 30,
    this.scale = 1,
    this.rotation = 0,
  });

  final int id;
  final _OverlayItemType type;
  String content;
  Color color;
  double fontSize;
  Offset offset;
  double scale;
  double rotation;
}

/// Full screen editor that lets the user crop a story's photo/video and add
/// text or emoji "symbol" overlays before sharing.
///
/// Returns the edited file's path via [Navigator.pop], or null if the user
/// closed the editor without finishing.
class StoryEditorPage extends StatefulWidget {
  const StoryEditorPage({
    super.key,
    required this.mediaFile,
    required this.isVideo,
  });

  final XFile mediaFile;
  final bool isVideo;

  @override
  State<StoryEditorPage> createState() => _StoryEditorPageState();
}

class _StoryEditorPageState extends State<StoryEditorPage> {
  static const List<Color> _textColorPalette = [
    Colors.white,
    Colors.black,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _itemsOnlyKey = GlobalKey();
  final TransformationController _mediaTransform = TransformationController();

  bool _ready = false;
  bool _isProcessing = false;
  bool _cropMode = false;

  Size? _imageSize;
  CachedVideoPlayerPlus? _videoController;
  Size? _frameSize;

  StoryCropAspect _aspect = StoryCropAspect.original;

  final List<_OverlayItem> _items = [];
  int _nextItemId = 0;
  int? _selectedItemId;

  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;

  _OverlayItem? get _selectedItem {
    for (final item in _items) {
      if (item.id == _selectedItemId) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.isVideo) {
      final controller = CachedVideoPlayerPlus.file(File(widget.mediaFile.path));
      await controller.initialize();
      controller.controller.setLooping(true);
      controller.controller.play();
      _videoController = controller;
    } else {
      final bytes = await File(widget.mediaFile.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _videoController?.controller.dispose();
    _videoController?.dispose();
    _mediaTransform.dispose();
    super.dispose();
  }

  Size get _naturalSize =>
      widget.isVideo ? _videoController!.controller.value.size : _imageSize!;

  double get _targetAspect {
    switch (_aspect) {
      case StoryCropAspect.original:
        final s = _naturalSize;
        return s.width / s.height;
      case StoryCropAspect.square:
        return 1;
      case StoryCropAspect.portrait:
        return 4 / 5;
    }
  }

  void _setAspect(StoryCropAspect aspect) {
    setState(() {
      _aspect = aspect;
      _mediaTransform.value = Matrix4.identity();
    });
  }

  void _toggleCropMode() {
    setState(() {
      _cropMode = !_cropMode;
      _selectedItemId = null;
    });
  }

  void _exitCropModeIfNeeded() {
    if (_cropMode) {
      setState(() => _cropMode = false);
    }
  }

  Future<void> _openAddTextSheet({_OverlayItem? editing}) async {
    _exitCropModeIfNeeded();
    final controller = TextEditingController(text: editing?.content ?? '');
    Color selectedColor = editing?.color ?? Colors.white;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'add_text_overlay_title'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 3,
                    style: TextStyle(
                      color: selectedColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      // Keeps the preview legible even when the chosen
                      // color (e.g. black) is close to the sheet's own
                      // background.
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 1)),
                        Shadow(blurRadius: 6, color: Colors.white38, offset: Offset(0, 0)),
                      ],
                    ),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'type_something'.tr,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _textColorPalette.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final color = _textColorPalette[i];
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        Navigator.pop(ctx, {'text': text, 'color': selectedColor});
                      },
                      child: Text(editing == null ? 'add_button'.tr : 'save_button'.tr),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    final text = result['text'] as String;
    final color = result['color'] as Color;

    setState(() {
      if (editing != null) {
        editing.content = text;
        editing.color = color;
      } else {
        final frame = _frameSize ?? const Size(300, 500);
        _items.add(
          _OverlayItem(
            id: _nextItemId++,
            type: _OverlayItemType.text,
            content: text,
            color: color,
            offset: Offset(frame.width / 2 - 60, frame.height / 2 - 20),
          ),
        );
      }
    });
  }

  Future<void> _openStickerSheet() async {
    _exitCropModeIfNeeded();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(ctx);
              _addSticker(emoji.emoji);
            },
            config: Config(
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: const Color(0xFF1C1C1E),
                columns: 8,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            ),
          ),
        );
      },
    );
  }

  void _addSticker(String emoji) {
    final frame = _frameSize ?? const Size(300, 500);
    setState(() {
      _items.add(
        _OverlayItem(
          id: _nextItemId++,
          type: _OverlayItemType.sticker,
          content: emoji,
          offset: Offset(frame.width / 2 - 24, frame.height / 2 - 24),
          fontSize: 48,
        ),
      );
    });
  }

  Widget _buildMediaLayer(BoxConstraints constraints) {
    final frameW = constraints.maxWidth;
    final frameH = constraints.maxHeight;
    final naturalSize = _naturalSize;
    final coverScale = math.max(frameW / naturalSize.width, frameH / naturalSize.height);
    final coverW = naturalSize.width * coverScale;
    final coverH = naturalSize.height * coverScale;

    final mediaChild = SizedBox(
      width: coverW,
      height: coverH,
      child: widget.isVideo
          ? VideoPlayer(_videoController!.controller)
          : Image.file(File(widget.mediaFile.path), fit: BoxFit.fill),
    );

    return IgnorePointer(
      ignoring: !_cropMode,
      child: InteractiveViewer(
        transformationController: _mediaTransform,
        minScale: 1,
        maxScale: 4,
        boundaryMargin: EdgeInsets.zero,
        constrained: false,
        child: mediaChild,
      ),
    );
  }

  Widget _itemContent(_OverlayItem item) {
    if (item.type == _OverlayItemType.sticker) {
      return Text(item.content, style: TextStyle(fontSize: item.fontSize));
    }
    return Text(
      item.content,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: item.color,
        fontSize: item.fontSize,
        fontWeight: FontWeight.w700,
        // A dark + a light shadow keep the text readable whether it lands
        // on a bright or a dark part of the photo/video underneath.
        shadows: const [
          Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 1)),
          Shadow(blurRadius: 6, color: Colors.white38, offset: Offset(0, 0)),
        ],
      ),
    );
  }

  Widget _buildOverlayItemWidget(_OverlayItem item) {
    final isSelected = _selectedItemId == item.id;
    return Positioned(
      left: item.offset.dx,
      top: item.offset.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selectedItemId = item.id),
        onDoubleTap: item.type == _OverlayItemType.text
            ? () => _openAddTextSheet(editing: item)
            : null,
        onScaleStart: (details) {
          setState(() => _selectedItemId = item.id);
          _gestureStartScale = item.scale;
          _gestureStartRotation = item.rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            item.scale = (_gestureStartScale * details.scale).clamp(0.3, 6.0);
            item.rotation = _gestureStartRotation + details.rotation;
            item.offset += details.focalPointDelta;
          });
        },
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(item.rotation)
            ..scaleByDouble(item.scale, item.scale, item.scale, 1),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: _itemContent(item),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsLayer() {
    return IgnorePointer(
      ignoring: _cropMode,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _selectedItemId = null),
            ),
          ),
          ..._items.map(_buildOverlayItemWidget),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return AspectRatio(
      aspectRatio: _targetAspect,
      child: ClipRect(
        child: RepaintBoundary(
          key: _canvasKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              LayoutBuilder(
                builder: (context, constraints) {
                  _frameSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaLayer(constraints),
                      RepaintBoundary(
                        key: _itemsOnlyKey,
                        child: _buildItemsLayer(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 26),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconButton(
            icon: Iconsax.close_circle,
            onTap: () => Navigator.of(context).pop(),
          ),
          Row(
            children: [
              if (_items.isNotEmpty) ...[
                _circleIconButton(
                  icon: Iconsax.undo,
                  onTap: () => setState(() {
                    _items.removeLast();
                    _selectedItemId = null;
                  }),
                ),
                const SizedBox(width: 12),
              ],
              _isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _circleIconButton(
                      icon: Iconsax.tick_circle,
                      color: AppColors.primary,
                      onTap: _handleDone,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemBar() {
    final item = _selectedItem;
    if (item == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.type == _OverlayItemType.text
                ? 'text_overlay_label'.tr
                : 'sticker_overlay_label'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Row(
            children: [
              if (item.type == _OverlayItemType.text)
                IconButton(
                  icon: const Icon(Iconsax.edit_2, color: Colors.white, size: 20),
                  onPressed: () => _openAddTextSheet(editing: item),
                ),
              IconButton(
                icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                onPressed: () => setState(() {
                  _items.removeWhere((i) => i.id == item.id);
                  _selectedItemId = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? AppColors.primary : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: StoryCropAspect.values.map((a) {
          final selected = _aspect == a;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(a.label),
              selected: selected,
              onSelected: (_) => _setAspect(a),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cropMode) ...[
            _buildAspectChips(),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(
                icon: Iconsax.crop,
                label: 'crop_tool_label'.tr,
                active: _cropMode,
                onTap: _toggleCropMode,
              ),
              _toolButton(
                icon: Iconsax.text,
                label: 'text_tool_label'.tr,
                active: false,
                onTap: () => _openAddTextSheet(),
              ),
              _toolButton(
                icon: Iconsax.sticker,
                label: 'sticker_tool_label'.tr,
                active: false,
                onTap: _openStickerSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _exportPhoto() async {
    if (_selectedItemId != null) {
      setState(() => _selectedItemId = null);
      await WidgetsBinding.instance.endOfFrame;
    }
    final boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/story_edited_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> _exportVideo() async {
    if (_selectedItemId != null) {
      setState(() => _selectedItemId = null);
      await WidgetsBinding.instance.endOfFrame;
    }

    final hasItems = _items.isNotEmpty;
    final hasCrop = _aspect != StoryCropAspect.original ||
        _mediaTransform.value != Matrix4.identity();

    if (!hasItems && !hasCrop) {
      return widget.mediaFile.path;
    }

    final controller = _videoController!.controller;
    final videoSize = controller.value.size;
    final frameSize = _frameSize ?? videoSize;
    final dir = await getTemporaryDirectory();

    String? overlayPath;
    if (hasItems) {
      final boundary =
          _itemsOnlyKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final overlayFile = File(
        '${dir.path}/story_overlay_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await overlayFile.writeAsBytes(byteData!.buffer.asUint8List(), flush: true);
      overlayPath = overlayFile.path;
    }

    var cropRect = Rect.fromLTWH(0, 0, videoSize.width, videoSize.height);
    if (hasCrop) {
      final coverScale = math.max(
        frameSize.width / videoSize.width,
        frameSize.height / videoSize.height,
      );
      final coverW = videoSize.width * coverScale;
      final coverH = videoSize.height * coverScale;
      final inv = Matrix4.inverted(_mediaTransform.value);
      final corners = [
        MatrixUtils.transformPoint(inv, Offset.zero),
        MatrixUtils.transformPoint(inv, Offset(frameSize.width, 0)),
        MatrixUtils.transformPoint(inv, Offset(0, frameSize.height)),
        MatrixUtils.transformPoint(inv, Offset(frameSize.width, frameSize.height)),
      ];
      final xs = corners.map((p) => p.dx).toList();
      final ys = corners.map((p) => p.dy).toList();
      final minX = xs.reduce(math.min).clamp(0.0, coverW);
      final maxX = xs.reduce(math.max).clamp(0.0, coverW);
      final minY = ys.reduce(math.min).clamp(0.0, coverH);
      final maxY = ys.reduce(math.max).clamp(0.0, coverH);

      var cropX = minX / coverScale;
      var cropY = minY / coverScale;
      var cropW = (maxX - minX) / coverScale;
      var cropH = (maxY - minY) / coverScale;

      // ffmpeg's h264 encoder needs even width/height.
      cropW = ((cropW.floor() ~/ 2) * 2).toDouble().clamp(2.0, videoSize.width);
      cropH = ((cropH.floor() ~/ 2) * 2).toDouble().clamp(2.0, videoSize.height);
      cropX = cropX.clamp(0.0, videoSize.width - cropW);
      cropY = cropY.clamp(0.0, videoSize.height - cropH);

      cropRect = Rect.fromLTWH(cropX, cropY, cropW, cropH);
    }

    final cropW = cropRect.width.round();
    final cropH = cropRect.height.round();
    final cropX = cropRect.left.round();
    final cropY = cropRect.top.round();

    final outputPath =
        '${dir.path}/story_edited_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final String command;
    if (overlayPath != null) {
      final overlayW = (frameSize.width * 2).round();
      final overlayH = (frameSize.height * 2).round();
      command =
          '-y -i "${widget.mediaFile.path}" -i "$overlayPath" '
          '-filter_complex "[0:v]crop=$cropW:$cropH:$cropX:$cropY,scale=$overlayW:$overlayH[bg];[bg][1:v]overlay=0:0:format=auto[outv]" '
          '-map "[outv]" -map 0:a? -c:v libx264 -preset veryfast -c:a aac '
          '-movflags +faststart "$outputPath"';
    } else {
      command =
          '-y -i "${widget.mediaFile.path}" '
          '-filter_complex "[0:v]crop=$cropW:$cropH:$cropX:$cropY[outv]" '
          '-map "[outv]" -map 0:a? -c:v libx264 -preset veryfast -c:a aac '
          '-movflags +faststart "$outputPath"';
    }

    final session = await FFmpegKit.execute(command);
    final success = ReturnCode.isSuccess(await session.getReturnCode());

    if (overlayPath != null) {
      unawaited(File(overlayPath).delete());
    }

    final output = File(outputPath);
    if (!success || !await output.exists() || await output.length() == 0) {
      throw Exception('could_not_prepare_clip'.tr);
    }

    return outputPath;
  }

  Future<void> _handleDone() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final path = widget.isVideo ? await _exportVideo() : await _exportPhoto();
      if (mounted) Navigator.pop(context, path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'create_story_error_prefix'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: !_ready
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildCanvas(),
                        ),
                      ),
                    ),
                    _buildSelectedItemBar(),
                    _buildBottomToolbar(),
                  ],
                ),
              ),
      ),
    );
  }
}
