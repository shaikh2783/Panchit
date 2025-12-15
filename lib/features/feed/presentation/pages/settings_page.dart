import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/settings/presentation/pages/cache_settings_page.dart';
import '../../../settings/presentation/pages/privacy_settings_page.dart';
import '../../../../core/localization/localization_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import 'developer_info_page.dart';
import 'report_bug_page.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
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
          'Settings', // 'الإعدادات'
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        actions: [
          // Quick theme toggle button
          GetBuilder<ThemeController>(
            builder: (controller) => IconButton(
              tooltip: controller.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.isDarkMode ? 'dark_mode_enabled'.tr : 'light_mode_enabled'.tr
                    ),
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  controller.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(controller.isDarkMode),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Header (glassy)
          const _GlassHeader(
            title: 'Customize Your Experience', // 'تخصيص تجربتك'
            subtitle: 'Manage privacy, notifications, and your account', // 'إدارة الخصوصية والإشعارات وحسابك'
          ),
          const SizedBox(height: 20),
          // Privacy & Security
          const _SectionTitle('Privacy & Security'), // 'الخصوصية والأمان'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Privacy Settings', // 'إعدادات الخصوصية'
            subtitle: 'Control who can see your information', // 'تحكم في من يمكنه رؤية معلوماتك'
            icon: Icons.lock_rounded,
            gradient: const [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySettingsPage()),
              );
            },
          ),
          _SettingsTile(
            title: 'Blocked Users', // 'المحظورون'
            subtitle: 'Manage blocked users', // 'إدارة المستخدمين المحظورين'
            icon: Icons.block_rounded,
            gradient: const [Color(0xFFEF5350), Color(0xFFE53935)],
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon')), // 'قريباً'
              );
            },
          ),
          const SizedBox(height: 22),
          // Account
          const _SectionTitle('Account'), // 'الحساب'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Account Information', // 'معلومات الحساب'
            subtitle: 'View and edit your account', // 'عرض وتعديل حسابك'
            icon: Icons.person_rounded,
            gradient: const [Color(0xFF81C784), Color(0xFF43A047)],
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon')), // 'قريباً'
              );
            },
          ),
          _SettingsTile(
            title: 'Password', // 'كلمة المرور'
            subtitle: 'Change your password', // 'تغيير كلمة المرور'
            icon: Icons.key_rounded,
            gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon')), // 'قريباً'
              );
            },
          ),
          const SizedBox(height: 22),
          // Notifications
          const _SectionTitle('Notifications'), // 'الإشعارات'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Notification Settings', // 'إعدادات الإشعارات'
            subtitle: 'Manage alerts and notifications', // 'إدارة التنبيهات والإشعارات'
            icon: Icons.notifications_rounded,
            gradient: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacySettingsPage(initialTab: 1),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          // Storage & Cache
          const _SectionTitle('Storage & Cache'), // 'التخزين والكاش'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Cache Settings', // 'إعدادات الكاش'
            subtitle: 'Manage video cache and storage', // 'إدارة كاش الفيديو والتخزين'
            icon: Icons.storage_rounded,
            gradient: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
            onTap: () {
              HapticFeedback.selectionClick();
              Get.to(() => const CacheSettingsPage());
            },
          ),
          const SizedBox(height: 22),
          // Application
          const _SectionTitle('Application'), // 'التطبيق'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Theme', // 'المظهر'
            subtitle: 'Light / Dark mode', // 'الوضع الفاتح / الداكن'
            icon: Icons.brightness_6_rounded,
            gradient: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            onTap: () => _showThemeSheet(context),
          ),
          _SettingsTile(
            title: 'Language', // 'اللغة'
            subtitle: 'English / Arabic', // 'English / العربية'
            icon: Icons.language_rounded,
            gradient: const [Color(0xFF4DB6AC), Color(0xFF00897B)],
            onTap: () => _showLanguageSheet(context),
          ),
          _SettingsTile(
            title: 'Developer Info', // 'معلومات المطور'
            subtitle: 'Contact & Support', // 'التواصل والدعم'
            icon: Icons.code_rounded,
            gradient: [
              if (isDark) const Color(0xFFB0BEC5) else const Color(0xFF90A4AE),
              if (isDark) const Color(0xFF78909C) else const Color(0xFF607D8B),
            ],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeveloperInfoPage()),
              );
            },
          ),
          const SizedBox(height: 22),
          // Support
          const _SectionTitle('Support'), // 'الدعم'
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Report an Issue', // 'الإبلاغ عن مشكلة'
            subtitle: 'Send video of the problem', // 'إرسال فيديو للمشكلة'
            icon: Icons.bug_report_rounded,
            gradient: const [Color(0xFFFF7043), Color(0xFFE64A19)],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportBugPage()),
              );
            },
          ),
          _SettingsTile(
            title: 'Help Center', // 'مركز المساعدة'
            subtitle: 'FAQs and support', // 'الأسئلة الشائعة والدعم'
            icon: Icons.help_center_rounded,
            gradient: const [Color(0xFF7986CB), Color(0xFF3F51B5)],
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon')), // 'قريباً'
              );
            },
          ),
          _SettingsTile(
            title: 'Terms & Policies', // 'الشروط والسياسات'
            subtitle: 'Terms of Service and Privacy Policy', // 'شروط الخدمة وسياسة الخصوصية'
            icon: Icons.description_rounded,
            gradient: const [Color(0xFFA1887F), Color(0xFF6D4C41)],
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming Soon')), // 'قريباً'
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
  // ---------- Helpers ----------
  void _showLanguageSheet(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GetBuilder<LocalizationController>(
              builder: (controller) => _LanguageTile(
                title: 'English',
                subtitle: 'Full English interface (LTR)', // 'واجهة إنجليزية كاملة (LTR)'
                isSelected: controller.isEnglish,
                onTap: () {
                  HapticFeedback.selectionClick();
                  localizationController.changeLocale('en');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('language_switch_success'.tr)),
                  );
                },
              ),
            ),
            GetBuilder<LocalizationController>(
              builder: (controller) => _LanguageTile(
                title: 'العربية', // 'Arabic'
                subtitle: 'واجهة عربية كاملة (RTL)', // 'Full Arabic interface (RTL)'
                isSelected: controller.isArabic,
                onTap: () {
                  HapticFeedback.selectionClick();
                  localizationController.changeLocale('ar');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('language_switch_success'.tr)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showThemeSheet(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GetBuilder<ThemeController>(
              builder: (controller) => _ThemeTile(
                title: 'light_mode'.tr, // 'الوضع الفاتح'
                subtitle: 'clean_bright_interface'.tr, // 'واجهة نظيفة ومشرقة'
                icon: Icons.light_mode,
                isSelected: !controller.isDarkMode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  themeController.setDarkMode(false);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('light_mode_enabled'.tr)),
                  );
                },
              ),
            ),
            GetBuilder<ThemeController>(
              builder: (controller) => _ThemeTile(
                title: 'dark_mode'.tr, // 'الوضع الداكن'
                subtitle: 'easy_eyes_interface'.tr, // 'واجهة مريحة للعيون'
                icon: Icons.dark_mode,
                isSelected: controller.isDarkMode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  themeController.setDarkMode(true);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('dark_mode_enabled'.tr)),
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
// =============== UI Pieces ===============
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
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
                colors: [Color(0xFF7B4397), Color(0xFF1D976C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // LTR
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
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: theme.colorScheme.primary.withOpacity(0.06),
          highlightColor: theme.colorScheme.primary.withOpacity(0.03),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                _GradientIconBadge(icon: icon, gradient: gradient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // LTR
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, // LTR arrow
                    size: 24, color: theme.iconTheme.color?.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _GradientIconBadge extends StatelessWidget {
  const _GradientIconBadge({required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Icon(icon, color: Colors.white),
    );
  }
}
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.language_rounded,
        color: isSelected ? theme.primaryColor : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected 
              ? theme.primaryColor.withValues(alpha: 0.75)
              : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.chevron_right_rounded,
        color: isSelected ? theme.primaryColor : null,
      ),
      onTap: onTap,
    );
  }
}
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.primaryColor : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected 
              ? theme.primaryColor.withValues(alpha: 0.75)
              : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.chevron_right_rounded,
        color: isSelected ? theme.primaryColor : null,
      ),
      onTap: onTap,
    );
  }
}