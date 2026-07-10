import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/presentation/controllers/music_sheet_controller.dart';
import 'package:snginepro/features/reels/presentation/pages/selected_music_sheet.dart';

Future<SelectedMusic?> showMusicSheet(
  BuildContext context, {
  required MusicSheetController controller,
}) async {
  return await showModalBottomSheet<SelectedMusic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MusicSheetBody(controller: controller),
  );
}

class _MusicSheetBody extends StatelessWidget {
  final MusicSheetController controller;
  const _MusicSheetBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Obx(() {
              if (controller.isSearching.value) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: const Color(0xFFE1306C),
                        decoration: InputDecoration(
                          hintText: 'Search sounds...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white38, size: 20),
                        ),
                        onChanged: controller.onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: controller.onCancelSearch,
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFFE1306C))),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text('Sounds',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: controller.onSearchTap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            }),
          ),
          // Tab bar
          Obx(() {
            if (controller.isSearching.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(controller.tabs.length, (i) {
                  final selected = controller.selectedTab.value == i;
                  return GestureDetector(
                    onTap: () => controller.onTabChanged(i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE1306C)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.tabs[i],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.exploreList.isEmpty &&
                  controller.searchList.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE1306C)));
              }

              // Search mode
              if (controller.isSearching.value) {
                if (controller.searchList.isEmpty &&
                    controller.searchCtrl.text.isNotEmpty &&
                    !controller.isLoading.value) {
                  return const Center(
                    child: Text('No results',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return _MusicList(
                  items: controller.searchList,
                  controller: controller,
                );
              }

              // Tab pages
              return PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MusicList(
                      items: controller.exploreList, controller: controller),
                  _CategoriesGrid(controller: controller),
                  _MusicList(
                      items: controller.savedList, controller: controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MusicList extends StatelessWidget {
  final List<Music> items;
  final MusicSheetController controller;

  const _MusicList({required this.items, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No sounds yet', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final music = items[i];
        return _MusicTile(music: music, controller: controller);
      },
    );
  }
}

class _MusicTile extends StatelessWidget {
  final Music music;
  final MusicSheetController controller;

  const _MusicTile({required this.music, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: music.image != null && music.image!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: music.image!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => _imagePlaceholder(),
                errorWidget: (_, __, ___) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
      title: Text(
        music.title ?? 'Unknown',
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        music.artist ?? '',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Obx(() {
        if (controller.isDownloading.value) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFE1306C)),
          );
        }
        return const Icon(Icons.chevron_right, color: Colors.white38);
      }),
      onTap: () async {
        final selected = await controller.downloadAndSelect(music);
        if (selected == null) return;

        if (!context.mounted) return;

        // Show trim sheet
        final trimmed = await showModalBottomSheet<SelectedMusic>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SelectedMusicSheet(
            selectedMusic: selected,
            videoDurationSec: controller.videoDurationSec,
          ),
        );

        if (trimmed != null && context.mounted) {
          Navigator.of(context).pop(trimmed);
        }
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.white10,
      child: const Icon(Icons.music_note, color: Colors.white38, size: 22),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final MusicSheetController controller;

  const _CategoriesGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categoryList.isEmpty) {
        return const Center(
          child: Text('No categories', style: TextStyle(color: Colors.white54)),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: controller.categoryList.length,
        itemBuilder: (context, i) {
          final cat = controller.categoryList[i];
          return GestureDetector(
            onTap: () {
              controller.onTabChanged(0);
              if (cat.id != null) controller.fetchByCategory(cat.id!);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cat.image != null && cat.image!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: cat.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.white10),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.white10),
                    )
                  else
                    Container(color: Colors.white10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        cat.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
