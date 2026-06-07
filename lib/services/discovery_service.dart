import 'package:flutter/foundation.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/models/connection_context_model.dart';
import 'api_client.dart';

class UserActionRequest {
  final String action;
  final double? rating;
  final Map<String, dynamic>? context;
  final String? explanation;

  UserActionRequest({
    required this.action,
    this.rating,
    this.context,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (rating != null) 'rating': rating,
      if (context != null) 'context': context,
      if (explanation != null) 'explanation': explanation,
    };
  }
}

class DiscoveryService {
  final ApiClient _apiClient = ApiClient();

  // Start a new discovery session
  Future<DiscoverySession> startDiscoverySession({
    String context = 'general',
    Map<String, dynamic> filters = const {},
  }) async {
    final response = await _apiClient.post('api/v1/discovery/sessions/start/', {
      'context': context,
      'filters': filters,
    });
    return DiscoverySession.fromJson(response);
  }

  // Get a batch of discoveries
  Future<DiscoveryBatch> getDiscoveryBatch(String sessionId, {int batchSize = 10}) async {
    final response = await _apiClient.get('api/v1/discovery/sessions/$sessionId/batch/', queryParameters: {
      'batch_size': batchSize.toString(),
    });
    
    // Debug output for items
    final discoveries = response['discoveries'] as List?;
    if (discoveries != null) {
      for (var item in discoveries) {
        if (item['item_type'] == 'profile' && item['profile_details'] != null) {
          debugPrint('=== DISCOVER PROFILE ===');
          debugPrint('name: ${item['profile_details']['full_name']}');
          debugPrint('photo: ${item['profile_details']['profile_photo_url']}');
        }
      }
    }
    
    return DiscoveryBatch.fromJson(response);
  }

  // Record user action on a discovery item
  Future<DiscoveryItem> recordUserAction(
    String itemId,
    String action, {
    double? rating,
    Map<String, dynamic>? context,
    String? explanation,
  }) async {
    final request = UserActionRequest(
      action: action,
      rating: rating,
      context: context,
      explanation: explanation,
    );
    final response = await _apiClient.post('api/v1/discovery/items/$itemId/action/', request.toJson());
    return DiscoveryItem.fromJson(response);
  }

  Future<ConnectionContextModel?> getConnectionContext(String targetUserId) async {
    try {
      final response = await _apiClient.get('api/v1/discovery/context/$targetUserId/');
      return ConnectionContextModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Context fetch error: $e');
      return null;
    }
  }

  // Get user's discovery sessions
  Future<List<DiscoverySession>> getMySessions() async {
    final response = await _apiClient.get('api/v1/discovery/sessions/');
    final results = response['results'] ?? response;
    if (results is List) {
      return results.map((item) => DiscoverySession.fromJson(item)).toList();
    }
    return [];
  }

  // Get user's discovery preferences
  Future<Map<String, dynamic>> getPreferences() async {
    return await _apiClient.get('api/v1/discovery/preferences/');
  }

  // Update user's discovery preferences
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> preferences) async {
    return await _apiClient.patch('api/v1/discovery/preferences/', preferences);
  }

  // Get discovery statistics
  Future<Map<String, dynamic>> getStats({int days = 7}) async {
    return await _apiClient.get('api/v1/discovery/stats/', queryParameters: {'days': days.toString()});
  }

  // Get discovery insights
  Future<Map<String, dynamic>> getInsights() async {
    return await _apiClient.get('api/v1/discovery/insights/');
  }
}
