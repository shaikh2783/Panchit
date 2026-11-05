import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../data/models/blocked_users_models.dart';
import '../controllers/blocked_users_controller.dart';

class BlockedUsersPage extends GetView<BlockedUsersController> {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Scaffold(
      backgroundColor: palette.groupedCanvas,
      appBar: MessengerAppBar(title: AppTranslations.blockedUsersTitle.tr),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = controller.errorMessage.value.trim();
          if (error.isNotEmpty && controller.items.isEmpty) {
            return MessengerEmptyState(
              icon: Icons.cloud_off_outlined,
              title: AppTranslations.blockedUsersTitle.tr,
              message: _cleanError(error),
              actionLabel: AppTranslations.retry.tr,
              onAction: controller.load,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 120) {
                  controller.loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (controller.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessengerEmptyState(
                        icon: Icons.block_outlined,
                        title: AppTranslations.blockedUsersTitle.tr,
                        message: AppTranslations.blockedUsersEmpty.tr,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: MessengerSection(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < controller.items.length;
                                index++
                              )
                                _BlockedUserRow(
                                  user: controller.items[index],
                                  isUpdating:
                                      controller.isUpdating[controller
                                          .items[index]
                                          .id] ??
                                      false,
                                  showDivider:
                                      index < controller.items.length - 1,
                                  onUnblock: () => _confirmUnblock(
                                    context,
                                    controller.items[index],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (controller.isLoadingMore.value)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 20 + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    BlockedUserModel user,
  ) async {
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppTranslations.blockedUsersUnblockTitle.tr),
            content: Text(AppTranslations.blockedUsersUnblockMessage.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppTranslations.settingsLogoutCancel.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppTranslations.blockedUsersUnblock.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved) {
      return;
    }

    try {
      final message = await controller.unblockUser(user);
      Get.snackbar(
        AppTranslations.blockedUsersUserUnblocked.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      Get.snackbar(
        AppTranslations.blockedUsersTitle.tr,
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({
    required this.user,
    required this.isUpdating,
    required this.showDivider,
    required this.onUnblock,
  });

  final BlockedUserModel user;
  final bool isUpdating;
  final bool showDivider;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.trim().isEmpty
        ? user.userName
        : user.displayName;
    final username = user.userName.trim();
    return MessengerRow(
      title: displayName,
      subtitle: username.isEmpty ? null : '@$username',
      leading: MessengerAvatar(
        name: displayName,
        imageUrl: user.pictureUrl,
        radius: 22,
      ),
      enabled: !isUpdating,
      showDivider: showDivider,
      onTap: isUpdating ? null : onUnblock,
      trailing: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: onUnblock,
              child: Text(AppTranslations.blockedUsersUnblock.tr),
            ),
    );
  }
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}
