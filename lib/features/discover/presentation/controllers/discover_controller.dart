import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../data/services/homepage_widgets_api_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/application/auth_notifier.dart';
class DiscoverController extends GetxController {
  final HomepageWidgetsApiService _apiService = 
      HomepageWidgetsApiService(Get.find<ApiClient>());
  // Loading state
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  // Widgets data
  final _widgets = Rxn<HomepageWidgets>();
  HomepageWidgets? get widgets => _widgets.value;
  // Error message
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  // AuthNotifier used for authentication status
  AuthNotifier? _authNotifier;
  // Keep a reference to the listener callback
  VoidCallback? _authListener;
  @override
  void onInit() {
    super.onInit();
    // Try to retrieve AuthNotifier from context
    try {
      final context = Get.context;
      if (context != null) {
        _authNotifier = context.read<AuthNotifier>();
        // Build the listener callback
        _authListener = () {
          if (_authNotifier!.isInitialized) {
            loadWidgets();
          }
        };
        // Subscribe to AuthNotifier changes
        _authNotifier!.addListener(_authListener!);
      }
    } catch (e) {
    }
    // If AuthNotifier is already ready, load widgets right away
    if (_authNotifier?.isInitialized ?? false) {
      loadWidgets();
    } else {
    }
  }
  /// Load all widgets
  Future<void> loadWidgets() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      // Ensure AuthNotifier is initialized
      if (_authNotifier != null && !_authNotifier!.isInitialized) {
        _isLoading.value = false;
        return;
      }
      // Check authentication status
      if (_authNotifier != null && !_authNotifier!.isAuthenticated) {
        _errorMessage.value = 'Please log in to see personalized content';
        return;
      }
      // Retrieve auth token from AuthNotifier
      final authToken = _authNotifier?.authToken;
      
      final response = await _apiService.getHomepageWidgets(authToken: authToken);
      if (response.success && response.widgets != null) {
        _widgets.value = response.widgets;
      } else {
        _errorMessage.value = response.message ?? 'Failed to load data';
      }
    } catch (e) {
      // Handle authentication-related errors specifically
      String errorString = e.toString().toLowerCase();
      if (errorString.contains('401') || 
          errorString.contains('not logged in') ||
          errorString.contains('unauthorized') ||
          errorString.contains('authentication')) {
        _errorMessage.value = 'Please log in to access this content';
      } else {
        _errorMessage.value = 'Network error occurred. Please try again.';
      }
    } finally {
      _isLoading.value = false;
    }
  }
  /// Refresh data
  @override
  Future<void> refresh() async {
    await loadWidgets();
  }
  /// Authentication status
  bool get isAuthenticated => _authNotifier?.isAuthenticated ?? false;
  @override
  void onClose() {
    // Remove listener from AuthNotifier
    if (_authNotifier != null && _authListener != null) {
      _authNotifier!.removeListener(_authListener!);
    }
    super.onClose();
  }
}
