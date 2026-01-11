// lib/services/profile_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ProfileApiService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<User> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/profiles/me/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<User> getUserProfile(String publicId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/profiles/public/$publicId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<User> updateProfile(UserProfileUpdate update) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/profiles/me/'),
        headers: headers,
        body: json.encode(update.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<bool> saveProfile(String publicId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/profiles/$publicId/save/'),
        headers: headers,
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save profile');
      }
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  Future<bool> unsaveProfile(String publicId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/profiles/$publicId/save/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to unsave profile');
      }
    } catch (e) {
      print('Error unsaving profile: $e');
      rethrow;
    }
  }

  Future<List<User>> getSavedProfiles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/profiles/saved/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data.map((e) => User.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to get saved profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting saved profiles: $e');
      rethrow;
    }
  }

  Future<void> recordProfileView(String publicId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/profiles/$publicId/view/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print('Failed to record profile view: ${response.statusCode}');
      }
    } catch (e) {
      print('Error recording profile view: $e');
    }
  }

  Future<List<User>> searchProfiles({
    String? query,
    String? neighborhood,
    String? lifeStage,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        if (query != null && query.isNotEmpty) 'search': query,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (lifeStage != null) 'life_stage': lifeStage,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/v1/profiles/search/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => User.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to search profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching profiles: $e');
      rethrow;
    }
  }

  // Helper methods for dropdown options
  List<Map<String, String>> getNeighborhoods() {
    return [
      {'value': 'westlands', 'label': 'Westlands'},
      {'value': 'kilimani', 'label': 'Kilimani/Kileleshwa'},
      {'value': 'lavington', 'label': 'Lavington'},
      {'value': 'karen', 'label': 'Karen'},
      {'value': 'langata', 'label': 'Langata'},
      {'value': 'nairobi_cbd', 'label': 'Nairobi CBD'},
      {'value': 'parklands', 'label': 'Parklands'},
      {'value': 'runda', 'label': 'Runda'},
      {'value': 'muthaiga', 'label': 'Muthaiga'},
      {'value': 'kasarani', 'label': 'Kasarani'},
      {'value': 'ruiru', 'label': 'Ruiru'},
      {'value': 'kayole', 'label': 'Kayole'},
      {'value': 'embakasi', 'label': 'Embakasi'},
      {'value': 'dandora', 'label': 'Dandora'},
      {'value': 'buruburu', 'label': 'Buruburu'},
      {'value': 'south_b', 'label': 'South B/C'},
      {'value': 'upperhill', 'label': 'Upper Hill'},
      {'value': 'other_nairobi', 'label': 'Other Nairobi Area'},
      {'value': 'outside_nairobi', 'label': 'Outside Nairobi'},
    ];
  }

  List<Map<String, String>> getLifeStages() {
    return [
      {'value': 'student', 'label': 'Student'},
      {'value': 'early_career', 'label': 'Early Career (0-5 years)'},
      {'value': 'mid_career', 'label': 'Mid Career (5-15 years)'},
      {'value': 'established', 'label': 'Established Professional'},
      {'value': 'entrepreneur', 'label': 'Entrepreneur/Business Owner'},
      {'value': 'creative', 'label': 'Creative/Freelancer'},
      {'value': 'in_transition', 'label': 'In Transition'},
      {'value': 'retired', 'label': 'Retired'},
    ];
  }

  List<Map<String, String>> getSocialCircles() {
    return [
      {'value': 'arts_culture', 'label': 'Arts & Culture'},
      {'value': 'tech_innovation', 'label': 'Tech & Innovation'},
      {'value': 'business_finance', 'label': 'Business & Finance'},
      {'value': 'academia_research', 'label': 'Academia & Research'},
      {'value': 'health_wellness', 'label': 'Health & Wellness'},
      {'value': 'sports_fitness', 'label': 'Sports & Fitness'},
      {'value': 'ngo_social', 'label': 'NGO & Social Impact'},
      {'value': 'food_hospitality', 'label': 'Food & Hospitality'},
      {'value': 'fashion_lifestyle', 'label': 'Fashion & Lifestyle'},
      {'value': 'music_entertainment', 'label': 'Music & Entertainment'},
    ];
  }

  List<Map<String, String>> getConnectionFrequencies() {
    return [
      {'value': 'occasional', 'label': 'Occasional - 1-2 times/month'},
      {'value': 'regular', 'label': 'Regular - 1-2 times/week'},
      {'value': 'active', 'label': 'Active - 3+ times/week'},
      {'value': 'selective', 'label': 'Very Selective'},
    ];
  }

  List<Map<String, String>> getVisibilityOptions() {
    return [
      {'value': 'public', 'label': 'Public - Visible to all KanairoXO users'},
      {'value': 'connections', 'label': 'Connections Only'},
      {'value': 'event_participants', 'label': 'Event Participants Only'},
      {'value': 'hidden', 'label': 'Hidden - Only visible to you'},
    ];
  }

  List<String> getCommonInterests() {
    return [
      'Coffee', 'Art', 'Music', 'Travel', 'Photography',
      'Food', 'Wine', 'Hiking', 'Reading', 'Yoga',
      'Meditation', 'Technology', 'Fashion', 'Sports',
      'Movies', 'Writing', 'Dancing', 'Cooking',
      'Entrepreneurship', 'Startups', 'Networking',
      'Wellness', 'Fitness', 'Cultural Events',
      'Social Impact', 'Volunteering', 'Education',
      'Nature', 'Animals', 'Gaming', 'Theater',
      'Poetry', 'Podcasts', 'Blogging', 'Design',
      'Architecture', 'History', 'Science',
      'Sustainability', 'Farming', 'Gardening',
    ];
  }
}