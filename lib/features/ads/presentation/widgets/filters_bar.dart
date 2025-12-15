import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
class FiltersBar extends StatelessWidget {
  const FiltersBar({
    super.key,
    required this.sortBy,
    required this.sortDir,
    required this.placement,
    required this.isApproved,
    required this.searchQuery,
    required this.onSortChanged,
    required this.onSortDirChanged,
    required this.onPlacementChanged,
    required this.onApprovalChanged,
    required this.onSearchChanged,
  });
  final String sortBy;
  final String sortDir;
  final String? placement;
  final bool? isApproved;
  final String searchQuery;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onSortDirChanged;
  final ValueChanged<String?> onPlacementChanged;
  final ValueChanged<bool?> onApprovalChanged;
  final ValueChanged<String> onSearchChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.cardColor,
                  theme.cardColor.withOpacity(0.95),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First Row: Sort + Search
          Row(
            children: [
              _ChipButton(
                icon: Iconsax.sort,
                label: _getSortLabel(),
                onTap: () => _showSortMenu(context),
              ),
              const SizedBox(width: 8),
              _ChipToggle(
                active: sortDir == 'desc',
                iconOn: Iconsax.arrow_down_1,
                iconOff: Iconsax.arrow_up_1,
                onChanged: onSortDirChanged,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SearchField(
                  hint: 'search'.tr,
                  initialValue: searchQuery,
                  onChanged: onSearchChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second Row: Filters
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: placement,
                  label: 'placement'.tr,
                  icon: Iconsax.location,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'newsfeed', child: Text('Newsfeed')),
                    DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
                    DropdownMenuItem(value: 'pages', child: Text('Pages')),
                    DropdownMenuItem(value: 'groups', child: Text('Groups')),
                  ],
                  onChanged: onPlacementChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  value: isApproved == null
                      ? null
                      : (isApproved! ? 'approved' : 'pending'),
                  label: 'status'.tr,
                  icon: Iconsax.shield_tick,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (v) {
                    if (v == 'approved') {
                      onApprovalChanged(true);
                    } else if (v == 'pending') {
                      onApprovalChanged(false);
                    } else {
                      onApprovalChanged(null);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _getSortLabel() {
    switch (sortBy) {
      case 'campaign_spend':
        return 'ads_sort_top_spend'.tr;
      case 'campaign_end_date':
        return 'ads_sort_ending_soon'.tr;
      default:
        return 'ads_sort_newest'.tr;
    }
  }
  void _showSortMenu(BuildContext context) async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(30, 80, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'campaign_created_date',
          child: Row(
            children: [
              const Icon(Iconsax.clock, size: 18),
              const SizedBox(width: 12),
              Text('ads_sort_newest'.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'campaign_spend',
          child: Row(
            children: [
              const Icon(Iconsax.chart_21, size: 18),
              const SizedBox(width: 12),
              Text('ads_sort_top_spend'.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'campaign_end_date',
          child: Row(
            children: [
              const Icon(Iconsax.calendar, size: 18),
              const SizedBox(width: 12),
              Text('ads_sort_ending_soon'.tr),
            ],
          ),
        ),
      ],
    );
    if (selected != null) {
      onSortChanged(selected);
    }
  }
}
class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.15),
                theme.colorScheme.primary.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ChipToggle extends StatelessWidget {
  const _ChipToggle({
    required this.active,
    required this.iconOn,
    required this.iconOff,
    required this.onChanged,
  });
  final bool active;
  final IconData iconOn;
  final IconData iconOff;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!active),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.primary.withOpacity(0.15),
                    ],
                  )
                : null,
            color: active ? null : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withOpacity(0.4)
                  : theme.dividerColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            active ? iconOn : iconOff,
            size: 16,
            color: active ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    required this.icon,
  });
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: Icon(Iconsax.arrow_down_1, size: 16),
          hint: Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hint,
    required this.onChanged,
    required this.initialValue,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal,
            size: 18,
            color: theme.iconTheme.color?.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
              onChanged: onChanged,
              controller: TextEditingController(text: initialValue),
            ),
          ),
        ],
      ),
    );
  }
}
