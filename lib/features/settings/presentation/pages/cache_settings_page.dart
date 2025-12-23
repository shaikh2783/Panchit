import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snginepro/App_Settings.dart';
import 'package:snginepro/core/services/video_precache_service.dart';

/// صفحة إعدادات الكاش
/// تسمح للمستخدم بإدارة إعدادات كاش الفيديوهات
class CacheSettingsPage extends StatefulWidget {
  const CacheSettingsPage({super.key});

  @override
  State<CacheSettingsPage> createState() => _CacheSettingsPageState();
}

class _CacheSettingsPageState extends State<CacheSettingsPage> {
  late int videoCacheDays;
  late bool enablePreCache;
  late int preCacheVideos;
  late bool wifiOnlyPreCache;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    videoCacheDays = AppSettings.videoCacheDuration;
    enablePreCache = AppSettings.enableVideoPreCaching;
    preCacheVideos = AppSettings.preCacheCount;
    wifiOnlyPreCache = AppSettings.preCacheOnlyOnWifi;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'cache_settings_title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Header (glassy)
          _GlassHeader(
            title: 'cache_manage_title'.tr,
            subtitle: 'cache_manage_subtitle'.tr,
            icon: Icons.storage_rounded,
          ),
          const SizedBox(height: 20),

          // معلومات الكاش
          _SectionTitle('cache_information_section'.tr),
          const SizedBox(height: 10),
          _CacheInfoTile(
            icon: Icons.video_library,
            label: 'cached_videos_label'.tr,
            value: '${VideoPrecacheService().cachedCount}',
            gradient: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
          ),
          _CacheInfoTile(
            icon: Icons.storage,
            label: 'cache_duration_label'.tr,
            value: 'cache_duration_value'.trParams({
              'days': AppSettings.videoCacheDuration.toString(),
            }),
            gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
          ),
          _CacheInfoTile(
            icon: Icons.sd_storage,
            label: 'max_cache_size_label'.tr,
            value: 'cache_size_value'.trParams({
              'size': AppSettings.maxCacheSize.toString(),
            }),
            gradient: const [Color(0xFF81C784), Color(0xFF43A047)],
          ),

          const SizedBox(height: 22),

          // إعدادات Pre-Cache
          _SectionTitle('pre_cache_settings_section'.tr),
          const SizedBox(height: 10),
          _CacheSettingToggleTile(
            title: 'enable_auto_pre_cache'.tr,
            subtitle: 'enable_auto_pre_cache_subtitle'.tr,
            icon: Icons.bolt_rounded,
            value: enablePreCache,
            gradient: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
            onChanged: (value) {
              setState(() => enablePreCache = value);
              _showSnackBar(
                value
                    ? 'pre_cache_enabled_message'.tr
                    : 'pre_cache_disabled_message'.tr,
              );
            },
          ),
          if (enablePreCache) ...[
            const SizedBox(height: 12),
            _CacheSettingOptionTile(
              title: 'pre_cache_count_title'.tr,
              subtitle: 'pre_cache_count_subtitle'.tr,
              icon: Icons.filter_list_rounded,
              value: preCacheVideos,
              options: const [1, 2, 3, 5],
              gradient: const [Color(0xFF64B5F6), Color(0xFF1E88E5)],
              onChanged: (value) {
                setState(() => preCacheVideos = value);
                _showSnackBar(
                  'pre_cache_set_message'.trParams({'count': value.toString()}),
                );
              },
            ),
            const SizedBox(height: 12),
            _CacheSettingToggleTile(
              title: 'wifi_only_pre_cache_title'.tr,
              subtitle: 'wifi_only_pre_cache_subtitle'.tr,
              icon: Icons.wifi_rounded,
              value: wifiOnlyPreCache,
              gradient: const [Color(0xFF4DB6AC), Color(0xFF00897B)],
              onChanged: (value) {
                setState(() => wifiOnlyPreCache = value);
                _showSnackBar(
                  value
                      ? 'wifi_only_pre_cache_snackbar'.tr
                      : 'wifi_all_networks_snackbar'.tr,
                );
              },
            ),
          ],

          const SizedBox(height: 22),

          // إدارة الكاش
          _SectionTitle('cache_management_section'.tr),
          const SizedBox(height: 10),
          _DeleteCacheTile(onDelete: () => _showDeleteConfirmation(context)),

          const SizedBox(height: 22),

          // نصائح
          _TipsCard(isDark: isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_cache_title'.tr),
        content: Text('clear_cache_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              await VideoPrecacheService().clearAllCache();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('cache_cleared_success_message'.tr);
                setState(() {});
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// =============== UI Pieces ===============

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0x1FFFFFFF), const Color(0x11000000)]
              : [const Color(0x11FFFFFF), const Color(0x08000000)],
        ),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _CacheInfoTile extends StatelessWidget {
  const _CacheInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CacheSettingToggleTile extends StatelessWidget {
  const _CacheSettingToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.gradient,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final List<Color> gradient;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.selectionClick();
                onChanged(newValue);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CacheSettingOptionTile extends StatefulWidget {
  const _CacheSettingOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.options,
    required this.gradient,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int value;
  final List<int> options;
  final List<Color> gradient;
  final ValueChanged<int> onChanged;

  @override
  State<_CacheSettingOptionTile> createState() =>
      _CacheSettingOptionTileState();
}

class _CacheSettingOptionTileState extends State<_CacheSettingOptionTile> {
  late int selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: widget.gradient),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = selectedValue == option;
                  final optionLabelKey = option == 1
                      ? 'pre_cache_option_single'
                      : 'pre_cache_option_multiple';
                  final optionLabel = optionLabelKey.trParams({
                    'count': option.toString(),
                  });

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedValue = option);
                      widget.onChanged(option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: isSelected
                            ? LinearGradient(colors: widget.gradient)
                            : null,
                        color: isSelected
                            ? null
                            : theme.colorScheme.surface.withOpacity(0.6),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : theme.dividerColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteCacheTile extends StatelessWidget {
  const _DeleteCacheTile({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.red.withOpacity(0.06),
          highlightColor: Colors.red.withOpacity(0.03),
          onTap: () {
            HapticFeedback.lightImpact();
            onDelete();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'clear_all_cache'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'delete_all_cached_videos'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'cache_pro_tips_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'cache_pro_tips_body'.trParams({
              'days': AppSettings.videoCacheDuration.toString(),
            }),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
