import 'dart:convert';
import 'dart:math';
import 'package:kanairoxo/models/discovery_models.dart';
import 'api_client.dart';

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
