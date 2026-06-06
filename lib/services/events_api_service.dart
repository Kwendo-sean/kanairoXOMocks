import 'package:flutter/foundation.dart';
import '../models/data_models.dart';
import 'api_client.dart';

class EventsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, List<Experience>>> fetchEventFeed() async {
    try {
      final response = await _apiClient.get('api/v1/events/feed/');
      
      final Map<String, List<Experience>> feed = {};
      
      if (response is Map) {
        response.forEach((key, value) {
          if (value is List) {
            feed[key] = value.map((e) => Experience.fromJson(e)).toList();
          }
        });
      }
      
      return feed;
    } catch (e) {
      debugPrint('Event feed load error: $e');
      rethrow;
    }
  }

  // ITEM 2: Use new endpoint /api/v1/events/search/
  Future<List<Experience>> searchEvents(String query) async {
    try {
      final response = await _apiClient.get('api/v1/events/search/', queryParameters: {'q': query});
      List<dynamic> list = [];
      if (response is Map && response['results'] != null) {
        list = response['results'] as List;
      } else if (response is List) {
        list = response;
      }
      return list.map((e) => Experience.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<List<Experience>> fetchSavedEvents() async {
    try {
      final response = await _apiClient.get('api/v1/events/saved/');
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        list = response['results'] ?? response['events'] ?? [];
      }
      return list.map((e) => Experience.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Saved events load error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleSave(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/save/', {});
  }

  // Legacy/Other methods kept for compatibility if needed
  Future<Experience> fetchExperienceDetail(String id) async {
    final response = await _apiClient.get('api/v1/events/$id/');
    return Experience.fromJson(response);
  }

  Future<Map<String, dynamic>> registerForExperience({
    required String experienceId,
    int? pricingTierId,
    int numberOfGuests = 0,
    String? notes,
  }) async {
    final body = {
      if (pricingTierId != null) 'pricing_tier': pricingTierId,
      'number_of_guests': numberOfGuests,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    return await _apiClient.post('api/v1/events/$experienceId/register/', body);
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/join-waitlist/', {});
  }
}
