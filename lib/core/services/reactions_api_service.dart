import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../../main.dart' show configCfgP;
import '../models/reaction_model.dart';

class ReactionsApiService {
  ReactionsApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetch all reactions from the server
  Future<List<ReactionModel>> fetchReactions() async {
    try {
      // Use authenticated endpoint
      final response = await _apiClient.get(configCfgP('reactions'));
      
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final reactionsJson = data['reactions'] as List<dynamic>?;
        
        if (reactionsJson != null) {
          final reactions = reactionsJson
              .map((json) => ReactionModel.fromJson(json as Map<String, dynamic>))
              .where((reaction) => reaction.enabled) // Only enabled reactions
              .toList();
          
          // Sort by order
          reactions.sort((a, b) => a.order.compareTo(b.order));
          
          return reactions;
        }
      }
      
      return [];
    } catch (e) {
      // Use debugPrint in development, silent in production
      if (kDebugMode) {
      }
      
      // If authentication fails, return default reactions as fallback
      if (e.toString().contains('not logged in') || e.toString().contains('401')) {
        return _getDefaultReactions();
      }
      
      return [];
    }
  }
  
  /// Fallback reactions when API call fails
  List<ReactionModel> _getDefaultReactions() {
    return [
      ReactionModel(
        reactionId: '1',
        reaction: 'like',
        title: 'Like',
        color: '#1e8bd2',
        image: 'reactions/like.png',
        order: 1,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '2',
        reaction: 'love',
        title: 'Love',
        color: '#f25268',
        image: 'reactions/love.png',
        order: 2,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '3',
        reaction: 'haha',
        title: 'Haha',
        color: '#f3b715',
        image: 'reactions/haha.png',
        order: 3,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '4',
        reaction: 'yay',
        title: 'Yay',
        color: '#F3B715',
        image: 'reactions/yay.png',
        order: 4,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '5',
        reaction: 'wow',
        title: 'Wow',
        color: '#f3b715',
        image: 'reactions/wow.png',
        order: 5,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '6',
        reaction: 'sad',
        title: 'Sad',
        color: '#f3b715',
        image: 'reactions/sad.png',
        order: 6,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '7',
        reaction: 'angry',
        title: 'Angry',
        color: '#f7806c',
        image: 'reactions/angry.png',
        order: 7,
        enabled: true,
      ),
    ];
  }
}
