import 'package:snginepro/core/network/api_client.dart';
import '../models/call_model.dart';
import 'package:flutter/foundation.dart';

class CallsApiService {
  final ApiClient _apiClient;
  final String baseUrl = 'https://www.panchit.com/apis/php';

  CallsApiService(this._apiClient);

  /// Get incoming calls
  Future<List<CallModel>> getIncomingCalls() async {
    try {
      final response = await _apiClient.get('/chat/calls');

      if (response['status'] == 'success') {
        // data is directly an array, not an object with 'calls' key
        final List<dynamic> callsJson = response['data'] ?? [];
        return callsJson.map((json) => CallModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get incoming calls');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get call status by call ID
  Future<CallModel?> getCallStatus({required int callId}) async {
    try {
      // Try the new endpoint first (if implemented)
      try {
        final response = await _apiClient.get('/chat/calls/$callId');
        
        if (response['status'] == 'success') {
          final callData = response['data'];
          if (callData != null) {
            return CallModel.fromJson(callData);
          }
        }
      } catch (e) {
        // If 404, fallback to old method (searching in list)
        if (e.toString().contains('404')) {
        } else {
          rethrow;
        }
      }
      
      // Fallback: Use the old method (search in calls list)
      final response = await _apiClient.get('/chat/calls');

      if (response['status'] == 'success') {
        // data is directly an array, not an object with 'calls' key
        final List<dynamic> callsJson = response['data'] ?? [];
        final calls = callsJson.map((json) => CallModel.fromJson(json)).toList();
        
        // Find the call by ID
        try {
          final call = calls.firstWhere((call) => call.callId == callId);
          return call;
        } catch (e) {
          // Call not found in list
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Start a new call
  Future<Map<String, dynamic>> startCall({
    required int toUserId,
    required String callType, // 'audio' or 'video'
  }) async {
    try {
      final body = {
        'to_user_id': toUserId,
        'call_type': callType,
      };

      
      final response = await _apiClient.post('/chat/calls/start', body: body);

      
      if (response['status'] == 'success') {
        final data = response['data'];
        return data;
      } else {
        throw Exception(response['message'] ?? 'Failed to start call');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Answer an incoming call
  Future<Map<String, dynamic>> answerCall({required int callId}) async {
    try {
      final body = {'call_id': callId};

      final response = await _apiClient.post('/chat/calls/answer', body: body);

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to answer call');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall({required int callId}) async {
    try {
      final body = {'call_id': callId};

      final response = await _apiClient.post('/chat/calls/decline', body: body);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to decline call');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// End an active call
  Future<Map<String, dynamic>> endCall({required int callId}) async {
    try {
      final body = {'call_id': callId};

      final response = await _apiClient.post('/chat/calls/end', body: body);

      if (response['status'] == 'success') {
        return response['data'] ?? {};
      } else {
        throw Exception(response['message'] ?? 'Failed to end call');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a pending call (caller only)
  Future<void> cancelCall({required int callId}) async {
    try {
      final body = {'call_id': callId};

      final response = await _apiClient.post('/chat/calls/cancel', body: body);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to cancel call');
      }
    } catch (e) {
      rethrow;
    }
  }
}