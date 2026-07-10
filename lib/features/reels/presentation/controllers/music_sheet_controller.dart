import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/reels/data/models/music_model.dart';
import 'package:snginepro/features/reels/data/services/music_api_service.dart';

class MusicSheetController extends GetxController {
  MusicSheetController({required this.musicService, required this.videoDurationSec});

  final MusicApiService musicService;
  final int videoDurationSec;

  final RxInt selectedTab = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;
  final RxBool isSearching = false.obs;

  final RxList<Music> exploreList = <Music>[].obs;
  final RxList<MusicCategory> categoryList = <MusicCategory>[].obs;
  final RxList<Music> savedList = <Music>[].obs;
  final RxList<Music> searchList = <Music>[].obs;

  final TextEditingController searchCtrl = TextEditingController();
  final PageController pageController = PageController();

  // Localization keys — translated at the display site with .tr
  final List<String> tabs = ['explore', 'categories', 'saved'];

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchCtrl.dispose();
    pageController.dispose();
    super.onClose();
  }

  void _loadAll() {
    fetchExplore();
    fetchCategories();
    fetchSaved();
  }

  Future<void> fetchExplore({bool refresh = false}) async {
    isLoading.value = true;
    try {
      final items = await musicService.fetchMusicExplore(
        lastItemId: refresh || exploreList.isEmpty ? null : exploreList.last.id,
      );
      if (refresh) exploreList.clear();
      exploreList.addAll(items);
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> fetchCategories() async {
    try {
      final items = await musicService.fetchMusicCategories();
      categoryList.value = items;
    } catch (_) {}
  }

  Future<void> fetchSaved({bool refresh = false}) async {
    try {
      final items = await musicService.fetchSavedMusics();
      if (refresh) savedList.clear();
      savedList.value = items;
    } catch (_) {}
  }

  Future<void> fetchByCategory(int categoryId) async {
    isLoading.value = true;
    try {
      final items = await musicService.fetchMusicByCategory(categoryId: categoryId);
      // Show results inline on explore tab
      exploreList.value = items;
    } catch (_) {}
    isLoading.value = false;
  }

  void onTabChanged(int index) {
    selectedTab.value = index;
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
    isSearching.value = false;
    searchCtrl.clear();
    searchList.clear();
    if (index == 0) fetchExplore(refresh: true);
    if (index == 2) fetchSaved(refresh: true);
  }

  void onSearchChanged(String q) {
    if (q.trim().isEmpty) {
      searchList.clear();
      _debounceTimer?.cancel();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      isLoading.value = true;
      try {
        final items = await musicService.searchMusic(keyword: q.trim());
        searchList.value = items;
      } catch (_) {}
      isLoading.value = false;
    });
  }

  Timer? _debounceTimer;

  void onSearchTap() {
    isSearching.value = true;
    searchList.clear();
  }

  void onCancelSearch() {
    isSearching.value = false;
    searchCtrl.clear();
    searchList.clear();
  }

  /// Downloads music and returns a SelectedMusic ready for use.
  Future<SelectedMusic?> downloadAndSelect(Music music) async {
    if (isDownloading.value) return null;
    isDownloading.value = true;
    try {
      final file = await DefaultCacheManager()
          .getSingleFile(music.sound ?? '');
      isDownloading.value = false;
      return SelectedMusic(
        music: music,
        audioStartMS: 0,
        downloadedURL: file.path,
      );
    } catch (e) {
      isDownloading.value = false;
      return null;
    }
  }
}
