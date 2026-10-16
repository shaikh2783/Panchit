import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../bootstrap/app_bootstrap.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../accounts/data/models/connected_accounts_models.dart';
import '../../../accounts/data/services/accounts_service.dart';

class ProfileController extends GetxController {
  ProfileController(
    this._accountsService,
    this._sessionController,
    this._preferences,
  );

  final AccountsService _accountsService;
  final SessionController _sessionController;
  final ChatAppPreferences _preferences;

  final isLoading = true.obs;
  final hasLoadedOnce = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final switchAccountsEnabled = false.obs;
  final canAddAccount = false.obs;
  final isMasterAccount = false.obs;
  final currentUserId = 0.obs;
  final accounts = <ConnectedAccountModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      return;
    }
    load();
  }

  Future<void> load() async {
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      errorMessage.value = '';
      accounts.clear();
      hasLoadedOnce.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _accountsService.fetchConnectedAccounts();
      _applyResponse(response);
    } catch (error) {
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
    } finally {
      isLoading.value = false;
      hasLoadedOnce.value = true;
    }
  }

  Future<void> addAccount({
    required String usernameEmail,
    required String password,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final response = await _accountsService.addConnectedAccount(
        usernameEmail: usernameEmail,
        password: password,
      );
      _applyResponse(response);
    } catch (error) {
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> switchAccount(ConnectedAccountModel account) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final result = await _accountsService.switchConnectedAccount(
        userId: account.userId,
      );
      if (!result.switched ||
          result.sessionToken.isEmpty ||
          result.accountId == 0) {
        throw Exception('Unable to switch account');
      }
      await _sessionController.switchConnectedAccount(
        token: result.sessionToken,
        userId: result.accountId,
        userName: result.user?.name,
        email: result.user?.email,
        picture: result.user?.picture,
      );
      await AppBootstrap.restartApp();
    } catch (error) {
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> removeAccount(ConnectedAccountModel account) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final response = await _accountsService.removeConnectedAccount(
        userId: account.userId,
      );
      _applyResponse(response);
    } catch (error) {
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> revokeCurrentConnection() async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final response = await _accountsService.revokeConnectedAccount();
      _applyResponse(response);
    } catch (error) {
      errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
        error.toString(),
      );
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _applyResponse(ConnectedAccountsResponse response) {
    switchAccountsEnabled.value = response.switchAccountsEnabled;
    canAddAccount.value = response.canAddAccount;
    isMasterAccount.value = response.isMasterAccount;
    currentUserId.value = response.currentUserId;
    accounts.assignAll(response.accounts);
  }
}
