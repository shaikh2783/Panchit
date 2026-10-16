import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/controllers/app_controller.dart';
import '../../../../core/controllers/locale_controller.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../../data/services/call_notification_service.dart';
import '../../../home/presentation/controllers/profile_controller.dart';
import '../../data/services/blocked_users_service.dart';
import '../controllers/blocked_users_controller.dart';
import 'blocked_users_page.dart';
import 'connected_accounts_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Scaffold(
      backgroundColor: palette.groupedCanvas,
      appBar: MessengerAppBar(title: AppTranslations.settingsTitle.tr),
      body: const SettingsContent(showPageTitle: false),
    );
  }
}

/// The settings body can be embedded directly in a root navigation tab.
/// Standalone routes hide this title and use [SettingsPage]'s app bar instead.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, this.showPageTitle = true});

  final bool showPageTitle;

  Future<void> _showLanguageSheet(
    BuildContext context,
    ChatLocaleController controller,
  ) async {
    final palette = MessengerDesign.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.78;
        return SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              MessengerSheetHeader(
                title: AppTranslations.settingsLanguage.tr,
                subtitle: AppTranslations.settingsLanguageSheetDescription.tr,
                action: IconButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Divider(height: 1, color: palette.divider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: ChatLocaleController.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = ChatLocaleController.supportedLanguages[index];
                    final selected = _sameLocale(
                      controller.currentLocale,
                      language.locale,
                    );
                    return MessengerRow(
                      title: _localizedLanguageLabel(language),
                      icon: Icons.language_rounded,
                      showDivider:
                          index <
                          ChatLocaleController.supportedLanguages.length - 1,
                      trailing: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? MessengerDesign.primary
                            : palette.subtle,
                      ),
                      onTap: () async {
                        await controller.changeLocale(language.locale);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
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

  Future<void> _showThemeSheet(
    BuildContext context,
    AppController controller,
  ) async {
    final palette = MessengerDesign.of(context);
    final options = <({ThemeMode mode, String label, IconData icon})>[
      (
        mode: ThemeMode.system,
        label: AppTranslations.settingsSystemMode.tr,
        icon: Icons.brightness_auto_rounded,
      ),
      (
        mode: ThemeMode.light,
        label: AppTranslations.settingsLightMode.tr,
        icon: Icons.light_mode_rounded,
      ),
      (
        mode: ThemeMode.dark,
        label: AppTranslations.settingsDarkMode.tr,
        icon: Icons.dark_mode_rounded,
      ),
    ];
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessengerSheetHeader(
              title: AppTranslations.settingsTheme.tr,
              subtitle: AppTranslations.settingsThemeDescription.tr,
              action: IconButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Divider(height: 1, color: palette.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: Column(
                children: [
                  for (var index = 0; index < options.length; index++)
                    MessengerRow(
                      title: options[index].label,
                      icon: options[index].icon,
                      showDivider: index < options.length - 1,
                      trailing: Icon(
                        controller.themeMode.value == options[index].mode
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: controller.themeMode.value == options[index].mode
                            ? MessengerDesign.primary
                            : palette.subtle,
                      ),
                      onTap: () async {
                        await controller.setThemeMode(options[index].mode);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    final appController = Get.find<AppController>();
    final profileController = Get.find<ProfileController>();
    final palette = MessengerDesign.of(context);
    if (!profileController.hasLoadedOnce.value &&
        !profileController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!profileController.hasLoadedOnce.value &&
            !profileController.isLoading.value) {
          unawaited(profileController.load());
        }
      });
    }

    return ColoredBox(
      color: palette.groupedCanvas,
      child: ListView(
        padding: EdgeInsets.only(
          top: showPageTitle ? 0 : 18,
          bottom: 32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (showPageTitle)
            MessengerPageTitle(
              title: AppTranslations.settingsTitle.tr,
              subtitle: AppTranslations.settingsHeroDescription.tr,
            ),
          Obx(
            () => _IdentityCard(
              name: sessionController.currentUserName.value,
              email: sessionController.currentUserEmail.value,
              pictureUrl: sessionController.currentUserPicture.value,
            ),
          ),
          const SizedBox(height: 22),
          MessengerSection(
            title: AppTranslations.settingsAccountControlsTitle.tr,
            child: Column(
              children: [
                Obx(
                  () => MessengerRow(
                    title: AppTranslations.profileConnectedAccounts.tr,
                    subtitle: _connectedAccountsSubtitle(profileController),
                    icon: Icons.switch_account_rounded,
                    showDivider: true,
                    onTap: () => Get.to(() => const ConnectedAccountsPage()),
                  ),
                ),
                MessengerRow(
                  title: AppTranslations.settingsBlockedUsers.tr,
                  subtitle: AppTranslations.settingsBlockedUsersSubtitle.tr,
                  icon: Icons.block_rounded,
                  onTap: () {
                    Get.to(
                      () => const BlockedUsersPage(),
                      binding: BindingsBuilder(() {
                        Get.put(
                          BlockedUsersController(
                            Get.find<BlockedUsersService>(),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          MessengerSection(
            title: AppTranslations.settingsPreferencesTitle.tr,
            child: Column(
              children: [
                GetBuilder<ChatLocaleController>(
                  builder: (controller) => MessengerRow(
                    title: AppTranslations.settingsLanguage.tr,
                    subtitle: _localizedLanguageLabel(
                      controller.currentLanguage,
                    ),
                    icon: Icons.language_rounded,
                    showDivider: true,
                    onTap: () => _showLanguageSheet(context, controller),
                  ),
                ),
                Obx(() {
                  final mode = appController.themeMode.value;
                  return MessengerRow(
                    title: AppTranslations.settingsTheme.tr,
                    subtitle: _themeModeLabel(mode),
                    icon: mode == ThemeMode.system
                        ? Icons.brightness_auto_rounded
                        : mode == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    onTap: () => _showThemeSheet(context, appController),
                  );
                }),
              ],
            ),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 22),
            const _CallAccessSettingsSection(),
          ],
        ],
      ),
    );
  }

  String _connectedAccountsSubtitle(ProfileController controller) {
    if (controller.isLoading.value) {
      return AppTranslations.loading.tr;
    }
    if (controller.errorMessage.value.trim().isNotEmpty) {
      return controller.errorMessage.value.trim();
    }
    if (!controller.switchAccountsEnabled.value) {
      return AppTranslations.profileLinkedAccountsDisabled.tr;
    }
    if (controller.accounts.isEmpty) {
      return AppTranslations.profileNoConnectedAccounts.tr;
    }
    return '${controller.accounts.length} · '
        '${AppTranslations.profileReadyToSwitch.tr}';
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => AppTranslations.settingsDarkMode.tr,
      ThemeMode.light => AppTranslations.settingsLightMode.tr,
      ThemeMode.system => AppTranslations.settingsSystemMode.tr,
    };
  }

  bool _sameLocale(Locale a, Locale b) {
    return a.languageCode == b.languageCode &&
        (a.countryCode ?? '') == (b.countryCode ?? '');
  }

  String _localizedLanguageLabel(AppLanguage language) {
    final code = language.code.toLowerCase();
    final countryCode = language.countryCode?.toLowerCase() ?? '';
    if (code == 'ar') return AppTranslations.settingsArabic.tr;
    if (code == 'fr') return AppTranslations.settingsFrench.tr;
    if (code == 'es') return AppTranslations.settingsSpanish.tr;
    if (code == 'pt' && countryCode == 'br') {
      return AppTranslations.settingsPortugueseBrazil.tr;
    }
    if (code == 'pt') return AppTranslations.settingsPortuguese.tr;
    if (code == 'de') return AppTranslations.settingsGerman.tr;
    if (code == 'tr') return AppTranslations.settingsTurkish.tr;
    if (code == 'nl') return AppTranslations.settingsDutch.tr;
    if (code == 'it') return AppTranslations.settingsItalian.tr;
    if (code == 'ru') return AppTranslations.settingsRussian.tr;
    if (code == 'ro') return AppTranslations.settingsRomanian.tr;
    if (code == 'el') return AppTranslations.settingsGreek.tr;
    if (code == 'uk') return AppTranslations.settingsUkrainian.tr;
    return AppTranslations.settingsEnglish.tr;
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.pictureUrl,
  });

  final String name;
  final String email;
  final String pictureUrl;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final resolvedName = name.trim().isEmpty
        ? AppTranslations.profileCurrentAccount.tr
        : name.trim();
    final resolvedEmail = email.trim().isEmpty
        ? AppTranslations.profileNoEmailAttached.tr
        : email.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MessengerDesign.pagePadding,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(
                MessengerDesign.sectionRadius,
              ),
              border: Border.all(color: palette.divider, width: 0.7),
            ),
            child: Row(
              children: [
                MessengerAvatar(
                  name: resolvedName,
                  imageUrl: pictureUrl,
                  radius: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.profileCurrentAccount.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        resolvedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resolvedEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallAccessSettingsSection extends StatefulWidget {
  const _CallAccessSettingsSection();

  @override
  State<_CallAccessSettingsSection> createState() =>
      _CallAccessSettingsSectionState();
}

class _CallAccessSettingsSectionState extends State<_CallAccessSettingsSection>
    with WidgetsBindingObserver {
  static const MethodChannel _permissionsChannel = MethodChannel(
    'messenger/call_permissions',
  );

  bool _loading = true;
  bool _notificationsEnabled = false;
  bool _fullScreenEnabled = false;
  bool _batteryUnrestricted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadStatuses());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadStatuses());
    }
  }

  Future<void> _loadStatuses() async {
    if (!Platform.isAndroid) {
      return;
    }
    if (mounted) {
      setState(() => _loading = true);
    }

    var notificationsEnabled = false;
    try {
      notificationsEnabled = (await Permission.notification.status).isGranted;
    } catch (_) {
      notificationsEnabled = false;
    }

    final results = await Future.wait<bool>([
      _readNativeStatus('canUseFullScreenIntent'),
      _readNativeStatus('isIgnoringBatteryOptimizations'),
    ]);

    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _notificationsEnabled = notificationsEnabled;
      _fullScreenEnabled = results[0];
      _batteryUnrestricted = results[1];
    });
  }

  Future<bool> _readNativeStatus(String method) async {
    try {
      return await _permissionsChannel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestNotificationAccess() async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted &&
          (status.isPermanentlyDenied || status.isRestricted)) {
        await openAppSettings();
      }
    } catch (_) {
      await openAppSettings();
    }
    await _refreshAfterSettingsChange();
  }

  Future<void> _openFullScreenSettings() async {
    final opened =
        await CallNotificationService.openFullScreenIncomingCallSettings();
    if (!opened) {
      await openAppSettings();
    }
    await _refreshAfterSettingsChange();
  }

  Future<void> _openBatterySettings() async {
    final opened =
        await CallNotificationService.openBatteryOptimizationSettingsPage();
    if (!opened) {
      await openAppSettings();
    }
    await _refreshAfterSettingsChange();
  }

  Future<void> _refreshAfterSettingsChange() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _loadStatuses();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return MessengerSection(
      title: AppTranslations.settingsCallAccessTitle.tr,
      caption: AppTranslations.settingsCallAccessDescription.tr,
      child: Column(
        children: [
          _CallStatusRow(
            title: AppTranslations.settingsCallAccessNotifications.tr,
            subtitle:
                AppTranslations.settingsCallAccessNotificationsSubtitle.tr,
            icon: Icons.notifications_outlined,
            enabled: _notificationsEnabled,
            loading: _loading,
            showDivider: true,
            onTap: _requestNotificationAccess,
          ),
          _CallStatusRow(
            title: AppTranslations.settingsCallAccessFullScreen.tr,
            subtitle: AppTranslations.settingsCallAccessFullScreenSubtitle.tr,
            icon: Icons.fullscreen_rounded,
            enabled: _fullScreenEnabled,
            loading: _loading,
            showDivider: true,
            onTap: _openFullScreenSettings,
          ),
          _CallStatusRow(
            title: AppTranslations.settingsCallAccessBattery.tr,
            subtitle: AppTranslations.settingsCallAccessBatterySubtitle.tr,
            icon: Icons.battery_saver_outlined,
            enabled: _batteryUnrestricted,
            loading: _loading,
            onTap: _openBatterySettings,
          ),
        ],
      ),
    );
  }
}

class _CallStatusRow extends StatelessWidget {
  const _CallStatusRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.loading,
    required this.onTap,
    this.showDivider = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return MessengerRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      showDivider: showDivider,
      onTap: onTap,
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _StatusPill(enabled: enabled),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? MessengerDesign.online : MessengerDesign.warning;
    final label = enabled
        ? AppTranslations.settingsCallAccessEnabled.tr
        : AppTranslations.settingsCallAccessNeedsSetup.tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
