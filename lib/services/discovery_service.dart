// lib/services/discovery_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryService {
  static const String _baseUrl = 'http://192.168.100.83:8000/api/v1/discovery';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Start a new discovery session
  Future<DiscoverySession> startDiscoverySession({
    String context = 'general',
    Map<String, dynamic> filters = const {},
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    print('Starting discovery session with context: $context');

    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/start/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'context': context,
        'filters': filters,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return DiscoverySession.fromJson(data);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Bad request');
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to start discovery session: ${response.statusCode} ${response.body}');
    }
  }

  // Get a batch of discoveries
  Future<DiscoveryBatch> getDiscoveryBatch(String sessionId, {int batchSize = 10}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    print('Getting discovery batch for session: $sessionId');

    final response = await http.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/batch/?batch_size=$batchSize'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Batch response status: ${response.statusCode}');
    print('Batch response body: ${response.body}'); // Add this line

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Batch data structure:');
      print('- Session: ${data['session'] != null}');
      print('- Discoveries count: ${data['discoveries'] is List ? data['discoveries'].length : 'N/A'}');
      print('- Batch info: ${data['batch_info']}');

      if (data['discoveries'] is List) {
        for (var i = 0; i < min(3, data['discoveries'].length); i++) {
          print('  Discovery $i: ${data['discoveries'][i]}');
        }
      }

      return DiscoveryBatch.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Session not found or expired');
    } else {
      throw Exception('Failed to get discovery batch: ${response.body}');
    }
  }
  // Record user action on a discovery item
  Future<DiscoveryItem> recordUserAction(
      String itemId,
      String action, {
        double? rating,
        Map<String, dynamic>? context,
        String? explanation,
      }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    print('Recording action: $action for item: $itemId');

    final request = UserActionRequest(
      action: action,
      rating: rating,
      context: context,
      explanation: explanation,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/items/$itemId/action/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    print('Action response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DiscoveryItem.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Item not found');
    } else {
      throw Exception('Failed to record action: ${response.body}');
    }
  }

  // Get user's discovery sessions
  Future<List<DiscoverySession>> getMySessions() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/sessions/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] ?? data; // Handle both list and paginated responses
      if (results is List) {
        return results.map((item) => DiscoverySession.fromJson(item)).toList();
      } 
      return [];
    } else {
      throw Exception('Failed to get sessions: ${response.body}');
    }
  }

  // Get user's discovery preferences
  Future<Map<String, dynamic>> getPreferences() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/preferences/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get preferences: ${response.body}');
    }
  }

  // Update user's discovery preferences
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> preferences) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('$_baseUrl/preferences/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(preferences),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update preferences: ${response.body}');
    }
  }

  // Get discovery statistics
  Future<Map<String, dynamic>> getStats({int days = 7}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/stats/?days=$days'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats: ${response.body}');
    }
  }

  // Get discovery insights
  Future<Map<String, dynamic>> getInsights() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/insights/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get insights: ${response.body}');
    }
  }
}
