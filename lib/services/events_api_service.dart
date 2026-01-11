// lib/services/events_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../utils/constants.dart';

class EventsApiService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Experience>> fetchExperiences({
    String? category,
    String? neighborhood,
    String? mood,
    String? intent,
    String? status = 'live',
    int? limit,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        if (category != null) 'category': category,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (mood != null) 'mood': mood,
        if (intent != null) 'intent': intent,
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/events/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => Experience.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load experiences: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching experiences: $e');
      rethrow;
    }
  }

  Future<List<Experience>> fetchFeaturedExperiences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/public/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final featuredEvents = data['featured_events'] ?? [];

        if (featuredEvents is List) {
          return featuredEvents.map((e) => Experience.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load featured experiences: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching featured experiences: $e');
      rethrow;
    }
  }

  Future<List<ExperienceCategory>> fetchCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/categories/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data.map((e) => ExperienceCategory.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<Experience> fetchExperienceDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$id/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Experience.fromJson(data);
      } else {
        throw Exception('Failed to load experience detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching experience detail: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerForExperience({
    required String experienceId,
    int? pricingTierId,
    int numberOfGuests = 0,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        if (pricingTierId != null) 'pricing_tier': pricingTierId,
        'number_of_guests': numberOfGuests,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$experienceId/register/'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to register: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering for experience: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkInToExperience({
    required String experienceId,
    required String qrCodeData,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'qr_code_data': qrCodeData,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$experienceId/check-in/'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check in: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveExperience(String experienceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$experienceId/save/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save experience: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving experience: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$experienceId/join-waitlist/'),
        headers: headers,
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to join waitlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error joining waitlist: $e');
      rethrow;
    }
  }

  Future<List<Experience>> fetchUserExperiences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/my-events/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attending = data['attending'] ?? [];

        if (attending is List) {
          return attending.map((e) => Experience.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load user experiences: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user experiences: $e');
      rethrow;
    }
  }

  Future<List<Experience>> discoverExperiences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/discover/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => Experience.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to discover experiences: ${response.statusCode}');
      }
    } catch (e) {
      print('Error discovering experiences: $e');
      rethrow;
    }
  }
}