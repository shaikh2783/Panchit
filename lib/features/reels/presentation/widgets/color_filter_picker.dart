import 'dart:io';

import 'package:flutter/material.dart';

const List<double> kDefaultFilter = [
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

const List<ReelFilter> kReelFilters = [
  ReelFilter(kDefaultFilter, 'Normal'),
  ReelFilter(
    [
      1.0, 0.2, 0, 0, 0,
      0.2, 1.0, 0.2, 0, 0,
      0, 0.2, 1.0, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Vintage',
  ),
  ReelFilter(
    [
      1.2, 0.1, 0, 0, 0,
      0.1, 1.1, 0.1, 0, 0,
      0, 0.1, 1.0, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Warm',
  ),
  ReelFilter(
    [
      0.8, 0, 0, 0, 0,
      0, 0.8, 0.1, 0, 0,
      0.1, 0.1, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Cool',
  ),
  ReelFilter(
    [
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'B&W',
  ),
  ReelFilter(
    [
      1.0, 0.2, 0.2, 0, -30,
      0.2, 1.0, 0.2, 0, -30,
      0.2, 0.2, 1.0, 0, -30,
      0, 0, 0, 1, 0,
    ],
    'Faded',
  ),
  ReelFilter(
    [
      0.1, 0.4, 0, 0, 0,
      0.3, 1.0, 0.3, 0, 0,
      0, 0.4, 0.1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Night',
  ),
  ReelFilter(
    [
      1.0, 0.1, 0, 0, 0,
      0.1, 1.5, 0.1, 0, 0,
      0, 0.1, 1.0, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Vivid',
  ),
];

class ReelFilter {
  final List<double> matrix;
  final String name;

  const ReelFilter(this.matrix, this.name);
}

class ColorFilterPicker extends StatefulWidget {
  final void Function(ReelFilter filter) onFilterChanged;
  final String? thumbnailPath;

  const ColorFilterPicker({
    super.key,
    required this.onFilterChanged,
    this.thumbnailPath,
  });

  @override
  State<ColorFilterPicker> createState() => _ColorFilterPickerState();
}

class _ColorFilterPickerState extends State<ColorFilterPicker> {
  static const Color _accentColor = Color(0xFFE1306C);
  static const double _itemWidth = 74;
  static const double _itemSpacing = 12;

  final ScrollController _scrollController = ScrollController();

  int _selected = 0;

  ReelFilter get _selectedFilter => kReelFilters[_selected];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectFilter(int index) {
    if (index < 0 || index >= kReelFilters.length) return;

    setState(() {
      _selected = index;
    });

    widget.onFilterChanged(kReelFilters[index]);
    _scrollToSelected(index);
  }

  void _scrollToSelected(int index) {
    if (!_scrollController.hasClients) return;

    final targetOffset = index * (_itemWidth + _itemSpacing);
    final maxOffset = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111113).withOpacity(0.96)
            : Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFECECEC),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.34 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kReelFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
              itemBuilder: (context, index) {
                final filter = kReelFilters[index];
                final isSelected = _selected == index;

                return _FilterItem(
                  width: _itemWidth,
                  filter: filter,
                  thumbnailPath: widget.thumbnailPath,
                  isSelected: isSelected,
                  isDark: isDark,
                  accentColor: _accentColor,
                  onTap: () => _selectFilter(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Text(
          'Filters',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _accentColor.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 13,
                color: _accentColor,
              ),
              const SizedBox(width: 5),
              Text(
                _selectedFilter.name,
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Tap to apply',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FilterItem extends StatelessWidget {
  final double width;
  final ReelFilter filter;
  final String? thumbnailPath;
  final bool isSelected;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterItem({
    required this.width,
    required this.filter,
    required this.thumbnailPath,
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 62 : 56,
                height: isSelected ? 62 : 56,
                padding: EdgeInsets.all(isSelected ? 3 : 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFE1306C),
                      Color(0xFFFF8A00),
                    ],
                  )
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isDark
                        ? Colors.white24
                        : Colors.black12,
                    width: 1.4,
                  ),
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.matrix(filter.matrix),
                        child: _FilterThumbnail(
                          thumbnailPath: thumbnailPath,
                          isDark: isDark,
                        ),
                      ),
                      if (isSelected)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                color: isSelected
                    ? isDark
                    ? Colors.white
                    : Colors.black
                    : isDark
                    ? Colors.white54
                    : Colors.black54,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                filter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterThumbnail extends StatelessWidget {
  final String? thumbnailPath;
  final bool isDark;

  const _FilterThumbnail({
    required this.thumbnailPath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final path = thumbnailPath;

    if (path == null || path.trim().isEmpty) {
      return _placeholder();
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
            Color(0xFF2A2A2E),
            Color(0xFF111113),
          ]
              : const [
            Color(0xFFEDEDED),
            Color(0xFFD8D8D8),
          ],
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white38 : Colors.black38,
        size: 22,
      ),
    );
  }
}