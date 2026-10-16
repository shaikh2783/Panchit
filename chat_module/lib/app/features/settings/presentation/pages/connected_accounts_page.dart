import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../accounts/data/models/connected_accounts_models.dart';
import '../../../home/presentation/controllers/profile_controller.dart';

class ConnectedAccountsPage extends StatefulWidget {
  const ConnectedAccountsPage({super.key});

  @override
  State<ConnectedAccountsPage> createState() => _ConnectedAccountsPageState();
}

class _ConnectedAccountsPageState extends State<ConnectedAccountsPage> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProfileController>();
    if (!_controller.isLoading.value) {
      unawaited(_controller.load());
    }
  }

  Future<void> _showAddAccountDialog() async {
    final credentials = await showDialog<_AccountCredentials>(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
    if (credentials == null) {
      return;
    }

    try {
      await _controller.addAccount(
        usernameEmail: credentials.identifier,
        password: credentials.password,
      );
      Get.snackbar(
        AppTranslations.profileAccountAdded.tr,
        AppTranslations.profileAddAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showControllerError(error);
    }
  }

  Future<void> _switchAccount(ConnectedAccountModel account) async {
    try {
      await _controller.switchAccount(account);
    } catch (error) {
      _showControllerError(error);
    }
  }

  Future<void> _confirmRemoveAccount(ConnectedAccountModel account) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppTranslations.profileRemoveAccountTitle.tr),
            content: Text(AppTranslations.profileRemoveAccountMessage.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppTranslations.settingsLogoutCancel.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppTranslations.profileRemoveAccount.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await _controller.removeAccount(account);
      Get.snackbar(
        AppTranslations.profileConnectedAccounts.tr,
        AppTranslations.profileRemoveAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showControllerError(error);
    }
  }

  Future<void> _confirmRevokeAccount() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppTranslations.profileRevokeAccountTitle.tr),
            content: Text(AppTranslations.profileRevokeAccountMessage.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppTranslations.settingsLogoutCancel.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: MessengerDesign.destructive,
                ),
                child: Text(AppTranslations.profileRevokeAccount.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await _controller.revokeCurrentConnection();
      Get.snackbar(
        AppTranslations.profileConnectedAccounts.tr,
        AppTranslations.profileRevokeAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showControllerError(error);
    }
  }

  void _showControllerError(Object error) {
    final controllerMessage = _controller.errorMessage.value.trim();
    final message = controllerMessage.isNotEmpty
        ? controllerMessage
        : _cleanError(error);
    Get.snackbar(
      AppTranslations.loginFailed.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Scaffold(
      backgroundColor: palette.groupedCanvas,
      appBar: MessengerAppBar(
        title: AppTranslations.profileConnectedAccounts.tr,
        actions: [
          Obx(
            () => _controller.canAddAccount.value
                ? IconButton(
                    tooltip: AppTranslations.profileAddAccount.tr,
                    onPressed: _controller.isSubmitting.value
                        ? null
                        : _showAddAccountDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.accounts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = _controller.errorMessage.value.trim();
        if (error.isNotEmpty && _controller.accounts.isEmpty) {
          return MessengerEmptyState(
            icon: Icons.cloud_off_outlined,
            title: AppTranslations.profileConnectedAccounts.tr,
            message: error,
            actionLabel: AppTranslations.retry.tr,
            onAction: _controller.load,
          );
        }

        if (_controller.accounts.isEmpty) {
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
                MessengerEmptyState(
                  icon: Icons.switch_account_outlined,
                  title: AppTranslations.profileNoConnectedAccounts.tr,
                  message: _controller.switchAccountsEnabled.value
                      ? AppTranslations.profileAttachAnotherAccount.tr
                      : AppTranslations.profileLinkedAccountsDisabled.tr,
                  actionLabel: _controller.canAddAccount.value
                      ? AppTranslations.profileAddAccount.tr
                      : null,
                  onAction: _controller.canAddAccount.value
                      ? _showAddAccountDialog
                      : null,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              0,
              18,
              0,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (_controller.isSubmitting.value)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (!_controller.switchAccountsEnabled.value) ...[
                MessengerSection(
                  child: MessengerRow(
                    title: AppTranslations.profileLinkedAccountsDisabled.tr,
                    icon: Icons.info_outline_rounded,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              MessengerSection(
                title: AppTranslations.profileConnectedAccounts.tr,
                caption: _controller.canAddAccount.value
                    ? AppTranslations.profileAttachAnotherAccount.tr
                    : null,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < _controller.accounts.length;
                      index++
                    )
                      _ConnectedAccountRow(
                        account: _controller.accounts[index],
                        enabled: !_controller.isSubmitting.value,
                        showDivider: index < _controller.accounts.length - 1,
                        onSwitch: _controller.accounts[index].switchable
                            ? () => _switchAccount(_controller.accounts[index])
                            : null,
                        onRemove: _controller.accounts[index].removable
                            ? () => _confirmRemoveAccount(
                                _controller.accounts[index],
                              )
                            : null,
                        onRevoke: _controller.accounts[index].revokeAvailable
                            ? _confirmRevokeAccount
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

enum _AccountAction { switchAccount, remove, revoke }

class _ConnectedAccountRow extends StatelessWidget {
  const _ConnectedAccountRow({
    required this.account,
    required this.enabled,
    required this.showDivider,
    this.onSwitch,
    this.onRemove,
    this.onRevoke,
  });

  final ConnectedAccountModel account;
  final bool enabled;
  final bool showDivider;
  final VoidCallback? onSwitch;
  final VoidCallback? onRemove;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final actions = <_AccountAction>[
      if (onSwitch != null) _AccountAction.switchAccount,
      if (onRemove != null) _AccountAction.remove,
      if (onRevoke != null) _AccountAction.revoke,
    ];
    return MessengerRow(
      title: account.resolvedName,
      subtitle: _subtitle,
      leading: MessengerAvatar(
        name: account.resolvedName,
        imageUrl: account.userPicture,
        radius: 21,
      ),
      enabled: enabled,
      showDivider: showDivider,
      onTap: onSwitch,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (account.isCurrent || account.isMaster)
            _AccountBadge(
              label: account.isCurrent
                  ? AppTranslations.profileAccountCurrent.tr
                  : AppTranslations.profileAccountMaster.tr,
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 2),
            PopupMenuButton<_AccountAction>(
              enabled: enabled,
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              onSelected: (action) {
                switch (action) {
                  case _AccountAction.switchAccount:
                    onSwitch?.call();
                    break;
                  case _AccountAction.remove:
                    onRemove?.call();
                    break;
                  case _AccountAction.revoke:
                    onRevoke?.call();
                    break;
                }
              },
              itemBuilder: (_) => [
                if (onSwitch != null)
                  PopupMenuItem(
                    value: _AccountAction.switchAccount,
                    child: _PopupActionLabel(
                      icon: Icons.swap_horiz_rounded,
                      label: AppTranslations.profileSwitchAccount.tr,
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: _AccountAction.remove,
                    child: _PopupActionLabel(
                      icon: Icons.link_off_rounded,
                      label: AppTranslations.profileRemoveAccount.tr,
                    ),
                  ),
                if (onRevoke != null)
                  PopupMenuItem(
                    value: _AccountAction.revoke,
                    child: _PopupActionLabel(
                      icon: Icons.delete_outline_rounded,
                      label: AppTranslations.profileRevokeAccount.tr,
                      destructive: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _subtitle {
    if (account.userName.isNotEmpty &&
        account.userName != account.resolvedName) {
      return account.userName;
    }
    if (account.switchable) {
      return AppTranslations.profileReadyToSwitch.tr;
    }
    return account.isMaster
        ? AppTranslations.profileAccountMaster.tr
        : AppTranslations.profileAccountCurrent.tr;
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MessengerDesign.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: MessengerDesign.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PopupActionLabel extends StatelessWidget {
  const _PopupActionLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? MessengerDesign.destructive : null;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _AccountCredentials(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppTranslations.profileAddAccountTitle.tr),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _identifierController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppTranslations.profileAddAccountIdentifier.tr,
                hintText: AppTranslations.profileAddAccountIdentifierHint.tr,
              ),
              validator: (value) => value?.trim().isEmpty ?? true
                  ? AppTranslations.profileAccountEmptyField.tr
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: AppTranslations.profileAddAccountPassword.tr,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? AppTranslations.profileAccountEmptyField.tr
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppTranslations.settingsLogoutCancel.tr),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppTranslations.profileAddAccountConfirm.tr),
        ),
      ],
    );
  }
}

class _AccountCredentials {
  const _AccountCredentials({required this.identifier, required this.password});

  final String identifier;
  final String password;
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}
