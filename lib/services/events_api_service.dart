import 'package:flutter/foundation.dart';

import '../models/data_models.dart';
import 'api_client.dart';

class EventsApiService {
  final ApiClient _apiClient = ApiClient();

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

    final response = await _apiClient.get('events/', queryParameters: queryParams);
    final results = response['results'] ?? response;

    if (results is List) {
      return results.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Experience>> fetchFeaturedExperiences() async {
    final response = await _apiClient.get('events/public/');
    final featuredEvents = response['featured_events'] ?? [];

    if (featuredEvents is List) {
      return featuredEvents.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ExperienceCategory>> fetchCategories() async {
    try {
      final response = await _apiClient.get('events/categories/');
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          return results.map((e) => ExperienceCategory.fromJson(e)).toList();
        }
      } else if (response is List) {
        return response.map((e) => ExperienceCategory.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
      return [];
    }
  }

  Future<Experience> fetchExperienceDetail(String id) async {
    final response = await _apiClient.get('events/$id/');
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

    return await _apiClient.post('events/$experienceId/register/', body);
  }

  Future<Map<String, dynamic>> checkInToExperience({
    required String experienceId,
    required String qrCodeData,
  }) async {
    final body = {
      'qr_code_data': qrCodeData,
    };

    return await _apiClient.post('events/$experienceId/check-in/', body);
  }

  Future<Map<String, dynamic>> saveExperience(String experienceId) async {
    return await _apiClient.post('events/$experienceId/save/', {});
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    return await _apiClient.post('events/$experienceId/join-waitlist/', {});
  }

  Future<List<Experience>> fetchUserExperiences() async {
    final response = await _apiClient.get('events/my-events/');
    final attending = response['attending'] ?? [];

    if (attending is List) {
      return attending.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Experience>> discoverExperiences() async {
    final response = await _apiClient.get('events/discover/');
    final results = response['results'] ?? response;

    if (results is List) {
      return results.map((e) => Experience.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> hostEvent(Map<String, dynamic> eventData) async {
    return await _apiClient.post('events/host/', eventData);
  }

  Future<Map<String, dynamic>> checkHostingEligibility() async {
    return await _apiClient.get('events/hosting/eligibility/');
  }

  Future<List<Map<String, dynamic>>> getTicketTemplates() async {
    final response = await _apiClient.get('tickets/templates/');
    return List<Map<String, dynamic>>.from(response);
  }
}
