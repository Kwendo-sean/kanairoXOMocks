import 'package:flutter/foundation.dart';
import '../models/data_models.dart';
import 'api_client.dart';

class EventsApiService {
  final ApiClient _apiClient = ApiClient();

  /// Flattens events_by_category map into a single list of events
  List<dynamic> _flattenCategoryMap(Map<String, dynamic> categoryMap) {
    final List<dynamic> allEvents = [];
    categoryMap.forEach((category, events) {
      if (events is List) {
        allEvents.addAll(events);
      }
    });
    return allEvents;
  }

  Future<List<Experience>> fetchExperiences({
    String? category,
    String? neighborhood,
    String? mood,
    String? intent,
    String? status = 'live',
    int? limit,
  }) async {
    final queryParams = {
      if (category != null) 'category': category,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (mood != null) 'mood': mood,
      if (intent != null) 'intent': intent,
      if (status != null) 'status': status,
      if (limit != null) 'limit': limit.toString(),
    };

    try {
      final response = await _apiClient.get('api/v1/events/', queryParameters: queryParams);
      
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        if (response.containsKey('results') && response['results'] is List) {
          list = response['results'];
        } else if (response.containsKey('events_by_category') && response['events_by_category'] is Map<String, dynamic>) {
          list = _flattenCategoryMap(response['events_by_category']);
        } else if (response.containsKey('events') && response['events'] is List) {
          list = response['events'];
        }
      }

      return list.map((e) => Experience.fromJson(e)).toList();
    } catch (e, stack) {
      debugPrint('Events load error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<List<Experience>> fetchFeaturedExperiences() async {
    try {
      final response = await _apiClient.get('api/v1/events/public/');
      
      List<dynamic> featuredList = [];
      
      if (response is Map) {
        // First priority: explicit featured_events list
        if (response.containsKey('featured_events') && response['featured_events'] is List) {
          featuredList = response['featured_events'];
        }
        
        // If featured is empty, but we have events_by_category, use some of those as fallback
        if (featuredList.isEmpty && response.containsKey('events_by_category') && response['events_by_category'] is Map<String, dynamic>) {
          featuredList = _flattenCategoryMap(response['events_by_category']);
        }
      } else if (response is List) {
        featuredList = response;
      }

      return featuredList.map((e) => Experience.fromJson(e)).toList();
    } catch (e, stack) {
      debugPrint('Featured events load error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<List<ExperienceCategory>> fetchCategories() async {
    try {
      final response = await _apiClient.get('api/v1/events/categories/');
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return results.map((e) => ExperienceCategory.fromJson(e)).toList();
        }
      } else if (response is List) {
        return response.map((e) => ExperienceCategory.fromJson(e)).toList();
      }
      return [];
    } catch (e, stack) {
      debugPrint('Categories load error: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

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

  Future<Map<String, dynamic>> checkInToExperience({
    required String experienceId,
    required String qrCodeData,
  }) async {
    final body = {
      'qr_code_data': qrCodeData,
    };

    return await _apiClient.post('api/v1/events/$experienceId/check-in/', body);
  }

  Future<Map<String, dynamic>> saveExperience(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/save/', {});
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/join-waitlist/', {});
  }

  Future<List<Experience>> fetchUserExperiences() async {
    final response = await _apiClient.get('api/v1/events/my-events/');
    final attending = response['attending'] ?? [];

    if (attending is List) {
      return attending.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Experience>> discoverExperiences() async {
    final response = await _apiClient.get('api/v1/events/discover/');
    final results = response['results'] ?? response;

    if (results is List) {
      return results.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> hostEvent(Map<String, dynamic> eventData) async {
    return await _apiClient.post('api/v1/events/host/', eventData);
  }

  Future<Map<String, dynamic>> checkHostingEligibility() async {
    return await _apiClient.get('api/v1/events/hosting/eligibility/');
  }

  Future<List<Map<String, dynamic>>> getTicketTemplates() async {
    final response = await _apiClient.get('api/tickets/templates/');
    return List<Map<String, dynamic>>.from(response);
  }
}
