import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/settings/presentation/pages/cache_settings_page.dart';
import '../../../settings/presentation/pages/privacy_settings_page.dart';
import '../../../settings/presentation/pages/change_password_page.dart';
import '../../../settings/presentation/pages/manage_sessions_page.dart';
import '../../../settings/presentation/pages/two_factor_auth_page.dart';
import '../../../settings/presentation/pages/user_information_page.dart';
import '../../../settings/presentation/pages/addresses_page.dart';
import '../../../blocking/presentation/pages/blocked_users_page.dart';
import '../../../verification/presentation/pages/account_verification_page.dart';
import '../../../monetization/presentation/pages/monetization_settings_page.dart';
import '../../../monetization/presentation/pages/monetization_payments_page.dart';
import '../../../monetization/presentation/pages/monetization_earnings_page.dart';
import '../../../affiliates/presentation/pages/my_affiliates_page.dart';
import '../../../affiliates/presentation/pages/affiliates_payments_page.dart';
import '../../../points/presentation/pages/my_points_page.dart';
import '../../../points/presentation/pages/points_payments_page.dart';
import '../../../market/presentation/pages/market_settings_page.dart';
import '../../../market/presentation/pages/market_withdrawals_page.dart';
import '../../../bank/presentation/pages/bank_settings_page.dart';
import '../../../funding/presentation/pages/funding_settings_page.dart';
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
          'settings'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        actions: [
          // Quick theme toggle button
          GetBuilder<ThemeController>(
            builder: (controller) => IconButton(
              tooltip: controller.isDarkMode
                  ? 'switch_to_light_mode'.tr
                  : 'switch_to_dark_mode'.tr,
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.isDarkMode
                          ? 'dark_mode_enabled'.tr
                          : 'light_mode_enabled'.tr,
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
          _GlassHeader(
            title: 'customize_experience'.tr,
            subtitle: 'customize_experience_subtitle'.tr,
          ),
          const SizedBox(height: 20),

          // Privacy & Security
          _SectionTitle('privacy_security'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'privacy_settings'.tr,
            subtitle: 'privacy_settings_subtitle'.tr,
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
            title: 'blocked_users'.tr,
            subtitle: 'blocked_users_subtitle'.tr,
            icon: Icons.block_rounded,
            gradient: const [Color(0xFFEF5350), Color(0xFFE53935)],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
              );
            },
          ),

          const SizedBox(height: 22),

          // Security Settings
          _SectionTitle('privacy_security'.tr),
          const SizedBox(height: 10),
          _ExpandableSettingsSection(
            title: 'privacy_security'.tr,
            subtitle: 'manage_sessions_subtitle'.tr,
            icon: Icons.security_rounded,
            gradient: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
            children: [
              _SettingsTile(
                title: 'change_password'.tr,
                subtitle: 'change_password_subtitle'.tr,
                icon: Icons.key_rounded,
                gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'manage_sessions'.tr,
                subtitle: 'manage_sessions_subtitle'.tr,
                icon: Icons.devices_rounded,
                gradient: const [Color(0xFF66BB6A), Color(0xFF388E3C)],
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageSessionsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Account
          _SectionTitle('account'.tr),
          const SizedBox(height: 10),
          // _SettingsTile(
          //   title: 'my_information'.tr,
          //   subtitle: 'my_information_subtitle'.tr,
          //   icon: Icons.person_rounded,
          //   gradient: const [Color(0xFF81C784), Color(0xFF43A047)],
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const UserInformationPage(),
          //       ),
          //     );
          //   },
          // ),
         
         
          _SettingsTile(
            title: 'my_addresses'.tr,
            subtitle: 'my_addresses_subtitle'.tr,
            icon: Icons.location_on_rounded,
            gradient: const [Color(0xFFEF5350), Color(0xFFE53935)],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddressesPage()),
              );
            },
          ),

          _SettingsTile(
            title: 'verification'.tr,
            subtitle: 'verification_subtitle'.tr,
            icon: Icons.verified_user_rounded,
            gradient: const [Color(0xFF64B5F6), Color(0xFF1976D2)],
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountVerificationPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // Notifications
          _SectionTitle('notifications'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'notification_settings'.tr,
            subtitle: 'notification_settings_subtitle'.tr,
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

          // Membership & Monetization
          _SectionTitle('membership_monetization'.tr),
          const SizedBox(height: 10),
          // _SettingsTile(
          //   title: 'membership'.tr,
          //   subtitle: 'membership_subtitle'.tr,
          //   icon: Icons.card_membership_rounded,
          //   gradient: const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     ScaffoldMessenger.of(
          //       context,
          //     ).showSnackBar(SnackBar(content: Text('coming_soon'.tr)));
          //   },
          // ),
        
        
          _ExpandableSettingsSection(
            title: 'monetization'.tr,
            subtitle: 'monetization_subtitle'.tr,
            icon: Icons.monetization_on_rounded,
            gradient: const [Color(0xFF66BB6A), Color(0xFF388E3C)],
            children: [
              _SettingsTile(
                title: 'settings'.tr,
                subtitle: 'monetization_options'.tr,
                icon: Icons.settings_rounded,
                gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonetizationSettingsPage(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'payments'.tr,
                subtitle: 'payments_subtitle'.tr,
                icon: Icons.payment_rounded,
                gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonetizationPaymentsPage(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'earnings'.tr,
                subtitle: 'earnings_subtitle'.tr,
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonetizationEarningsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Affiliates
          _SectionTitle('affiliates'.tr),
          const SizedBox(height: 10),
          _ExpandableSettingsSection(
            title: 'affiliates'.tr,
            subtitle: 'affiliates_subtitle'.tr,
            icon: Icons.people_rounded,
            gradient: const [Color(0xFF29B6F6), Color(0xFF0277BD)],
            children: [
              _SettingsTile(
                title: 'my_affiliates'.tr,
                subtitle: 'my_affiliates_subtitle'.tr,
                icon: Icons.group_rounded,
                gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyAffiliatesPage(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'payments'.tr,
                subtitle: 'affiliate_payments_subtitle'.tr,
                icon: Icons.payments_rounded,
                gradient: const [Color(0xFF26C6DA), Color(0xFF0097A7)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AffiliatesPaymentsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Points
          _SectionTitle('points_section'.tr),
          const SizedBox(height: 10),
          _ExpandableSettingsSection(
            title: 'points_section'.tr,
            subtitle: 'points_subtitle'.tr,
            icon: Icons.stars_rounded,
            gradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
            children: [
              _SettingsTile(
                title: 'my_points'.tr,
                subtitle: 'my_points_subtitle'.tr,
                icon: Icons.star_rounded,
                gradient: const [Color(0xFFFFD54F), Color(0xFFFFA000)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPointsPage(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'payments'.tr,
                subtitle: 'points_payments_subtitle'.tr,
                icon: Icons.redeem_rounded,
                gradient: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PointsPaymentsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Financial
          _SectionTitle('financial'.tr),
          const SizedBox(height: 10),
          // _SettingsTile(
          //   title: 'Payments', // 'المدفوعات'
          //   subtitle: 'Payment methods and history', // 'طرق الدفع والسجل'
          //   icon: Icons.payment_rounded,
          //   gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Coming Soon')), // 'قريباً'
          //     );
          //   },
          // ),
          _SettingsTile(
            title: 'bank_transfers'.tr,
            subtitle: 'bank_transfers_subtitle'.tr,
            icon: Icons.account_balance_rounded,
            gradient: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BankSettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // Marketplace & Funding
          _SectionTitle('marketplace_funding'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'marketplace'.tr,
            subtitle: 'marketplace_subtitle'.tr,
            icon: Icons.shopping_bag_rounded,
            gradient: const [Color(0xFFEC407A), Color(0xFFD81B60)],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketSettingsPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'funding'.tr,
            subtitle: 'funding_subtitle'.tr,
            icon: Icons.campaign_rounded,
            gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundingSettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // Storage & Cache
          _SectionTitle('storage_cache'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'cache_management'.tr,
            subtitle: 'cache_management_subtitle'.tr,
            icon: Icons.storage_rounded,
            gradient: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
            onTap: () {
              HapticFeedback.selectionClick();
              Get.to(() => const CacheSettingsPage());
            },
          ),

          const SizedBox(height: 22),

          // Application
          _SectionTitle('application'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'theme'.tr,
            subtitle: 'theme_subtitle'.tr,
            icon: Icons.brightness_6_rounded,
            gradient: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            onTap: () => _showThemeSheet(context),
          ),
          _SettingsTile(
            title: 'language'.tr,
            subtitle: 'language_subtitle'.tr,
            icon: Icons.language_rounded,
            gradient: const [Color(0xFF4DB6AC), Color(0xFF00897B)],
            onTap: () => _showLanguageSheet(context),
          ),

          const SizedBox(height: 22),

          // Support
          _SectionTitle('support'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'report_issue'.tr,
            subtitle: 'report_issue_subtitle'.tr,
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
          // _SettingsTile(
          //   title: 'help_center'.tr,
          //   subtitle: 'help_center_subtitle'.tr,
          //   icon: Icons.help_center_rounded,
          //   gradient: const [Color(0xFF7986CB), Color(0xFF3F51B5)],
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     ScaffoldMessenger.of(
          //       context,
          //     ).showSnackBar(SnackBar(content: Text('coming_soon'.tr)));
          //   },
          // ),
          // _SettingsTile(
          //   title: 'terms_policies'.tr,
          //   subtitle: 'terms_policies_subtitle'.tr,
          //   icon: Icons.description_rounded,
          //   gradient: const [Color(0xFFA1887F), Color(0xFF6D4C41)],
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     ScaffoldMessenger.of(
          //       context,
          //     ).showSnackBar(SnackBar(content: Text('coming_soon'.tr)));
          //   },
          // ),

          const SizedBox(height: 22),

          // Danger Zone
          _SectionTitle('danger_zone'.tr),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'delete_account'.tr,
            subtitle: 'delete_account_subtitle'.tr,
            icon: Icons.delete_forever_rounded,
            gradient: const [Color(0xFFEF5350), Color(0xFFD32F2F)],
            onTap: () {
              HapticFeedback.heavyImpact();
              _showDeleteAccountDialog(context);
            },
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // ---------- Helpers ----------
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_account_title'.tr,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delete_account_confirm'.tr,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              'delete_account_warning'.tr,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.red,
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('coming_soon'.tr),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('delete'.tr),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GetBuilder<LocalizationController>(
        builder: (controller) {
          final options = controller.languageOptions;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'choose_language'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final option = options[index];
                      final isSelected =
                          option.locale == controller.currentLocale;
                      return _LanguageTile(
                        title: option.nameKey.tr,
                        subtitle: option.subtitle,
                        flag: option.flag,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          localizationController.changeLocale(option.code);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('language_switch_success'.tr),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
                  Icons.chevron_right_rounded, // LTR arrow
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
    required this.flag,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String subtitle;
  final String flag;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
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
      leading: Icon(icon, color: isSelected ? theme.primaryColor : null),
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

// Expandable Settings Section Widget
class _ExpandableSettingsSection extends StatefulWidget {
  const _ExpandableSettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<Widget> children;

  @override
  State<_ExpandableSettingsSection> createState() =>
      _ExpandableSettingsSectionState();
}

class _ExpandableSettingsSectionState
    extends State<_ExpandableSettingsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _GradientIconBadge(
                    icon: widget.icon,
                    gradient: widget.gradient,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(children: widget.children),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
