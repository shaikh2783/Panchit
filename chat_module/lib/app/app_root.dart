import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../settings.dart';
import 'core/controllers/session_controller.dart';
import 'core/localization/app_translations.dart';
import 'core/theme/messenger_design.dart';
import 'core/widgets/messenger_ui.dart';
import 'features/auth/presentation/pages/auth_flow_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

class AppRoot extends GetView<SessionController> {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sessionState = controller.state.value;

      if (!messengerLicenseActive) {
        return const _LicenseDisabledView();
      }

      switch (sessionState) {
        case SessionViewState.loading:
          return const _AppLoadingView();
        case SessionViewState.login:
          return const LoginPage();
        case SessionViewState.home:
          return const HomePage();
        case SessionViewState.authFlow:
          return const AuthFlowPage();
        case SessionViewState.banned:
          return _AccountBannedView(message: controller.bannedMessage.value);
      }
    });
  }
}

class _AccountBannedView extends GetView<SessionController> {
  const _AccountBannedView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final resolvedMessage = message.trim().isEmpty
        ? AppTranslations.accountBannedBody.tr
        : message.trim();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: MessengerEmptyState(
          icon: Icons.block_rounded,
          title: AppTranslations.accountBannedTitle.tr,
          message:
              '$resolvedMessage\n\n${AppTranslations.accountBannedSupport.tr}',
          actionLabel: AppTranslations.settingsLogout.tr,
          onAction: controller.signOut,
        ),
      ),
    );
  }
}

class _LicenseDisabledView extends StatelessWidget {
  const _LicenseDisabledView();

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final message = messengerLicenseMessage.trim().isEmpty
        ? 'Messenger package license is disabled.'
        : messengerLicenseMessage.trim();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: MessengerEmptyState(
          icon: Icons.gpp_bad_outlined,
          title: 'Messenger license disabled',
          message: message,
        ),
      ),
    );
  }
}

class _AppLoadingView extends StatelessWidget {
  const _AppLoadingView();

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: MessengerDesign.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.loading.tr,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
