import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/messenger/data/models/call_model.dart';
import 'package:snginepro/features/messenger/data/services/calls_api_service.dart';
import 'package:snginepro/features/messenger/presentation/managers/call_manager.dart';
import 'package:snginepro/features/messenger/presentation/pages/incoming_call_screen.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:provider/provider.dart';

/// Global service for handling incoming calls from anywhere in the app
class GlobalCallService extends GetxService {
  late CallManager _callManager;
  late CallsApiService _callsApiService;
  Timer? _pollTimer;
  final Set<int> _shownCallIds = {}; // Track shown calls to avoid duplicates
  
  CallManager get callManager => _callManager;

  /// Initialize the global call service
  Future<GlobalCallService> init(ApiClient apiClient) async {
    
    _callsApiService = CallsApiService(apiClient);
    _callManager = CallManager(_callsApiService);
    
    // Initialize Agora with app ID.
    // Timeout guards against the native engine init hanging and never
    // completing (seen as an app frozen at launch on some devices).
    try {
      await _callManager
          .initializeAgora('06e8cc01e5ce4a1ba6d1254c2a5aa7da')
          .timeout(const Duration(seconds: 15));
    } catch (e) {
    }
    
    // Start polling for incoming calls
    startPolling();
    
    return this;
  }

  /// Start polling for incoming calls
  void startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) {
      return;
    }

    
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
       await _checkForIncomingCalls();
    });
  }

  /// Stop polling for incoming calls
  void stopPolling() {
    if (_pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = null;
    }
  }

  /// Check for incoming calls
  Future<void> _checkForIncomingCalls() async {
    try {
      final calls = await _callsApiService.getIncomingCalls();
      
      // Get current user ID to filter out outgoing calls
      int? currentUserId;
      try {
        final context = Get.context;
        if (context != null) {
          final authNotifier = context.read<AuthNotifier>();
          final userIdValue = authNotifier.currentUser?['user_id'];
          currentUserId = int.tryParse(userIdValue?.toString() ?? '');
        }
      } catch (e) {
      }
      
      // Filter out:
      // 1. Calls we've already shown
      // 2. Calls that are already answered or declined
      // 3. Outgoing calls (where fromUserId == currentUserId)
      // 4. Calls not in pending status
      final newCalls = calls.where((call) {
        final isIncoming = currentUserId == null || call.fromUserId != currentUserId;
        final notAnswered = !call.answered;
        final notDeclined = !call.declined;
        final isPending = call.callStatus == 'pending';
        final notShown = !_shownCallIds.contains(call.callId);
        
        final shouldShow = notShown && isPending && notAnswered && notDeclined && isIncoming;
        
        if (!shouldShow && !_shownCallIds.contains(call.callId)) {
          // Mark as shown even if filtered out, to avoid re-checking old calls
          _shownCallIds.add(call.callId);
        }
        
        return shouldShow;
      }).toList();

      for (final call in newCalls) {
        _shownCallIds.add(call.callId);
        _showIncomingCallScreen(call);
      }

      // Clean up old shown call IDs (keep last 50)
      if (_shownCallIds.length > 50) {
        final toRemove = _shownCallIds.length - 50;
        _shownCallIds.removeAll(_shownCallIds.take(toRemove));
      }
    } catch (e) {
    }
  }

  /// Show incoming call screen
  void _showIncomingCallScreen(CallModel call) {
    // Only show if not already on the incoming call screen
    if (Get.currentRoute == '/IncomingCallScreen') {
      return;
    }

    
    Get.to(
      () => IncomingCallScreen(
        callData: call,
        callManager: _callManager,
      ),
      preventDuplicates: true,
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    stopPolling();
    _callManager.dispose();
    super.onClose();
  }
}
