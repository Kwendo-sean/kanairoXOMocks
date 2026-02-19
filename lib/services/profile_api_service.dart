import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient = ApiClient();

  Future<User> getMyProfile() async {
    try {
      final response = await _apiClient.get('api/v1/profiles/me/');
      return User.fromJson(response);
    } catch (e) {
      if (e.toString().contains('Error 500')) {
        throw Exception('Server error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<User> getUserProfile(String id) async {
    final response = await _apiClient.get('api/v1/profiles/public/$id/');
    return User.fromJson(response);
  }

  Future<User> updateProfile(UserProfileUpdate update) async {
    final response = await _apiClient.patch('api/v1/profiles/me/', update.toJson());
    return User.fromJson(response);
  }

  Future<bool> saveProfile(String id) async {
    await _apiClient.post('api/v1/profiles/$id/save/', {});
    return true;
  }

  Future<bool> unsaveProfile(String id) async {
    await _apiClient.delete('api/v1/profiles/$id/save/');
    return true;
  }

  Future<List<User>> getSavedProfiles() async {
    final response = await _apiClient.get('api/v1/profiles/saved/');
    if (response is List) {
      return response.map((data) => User.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> recordProfileView(String id) async {
    await _apiClient.post('api/v1/profiles/$id/view/', {});
  }

  Future<List<User>> searchProfiles({
    String? query,
    String? neighborhood,
    String? lifeStage,
    int limit = 20,
  }) async {
    final queryParams = {
      if (query != null && query.isNotEmpty) 'search': query,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (lifeStage != null) 'life_stage': lifeStage,
      'limit': limit.toString(),
    };

    final response = await _apiClient.get('api/v1/profiles/search/', queryParameters: queryParams);
    final results = response['results'] ?? response;

    if (results is List) {
      return results.map((data) => User.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> uploadProfilePhotos(List<XFile> images) async {
    await _apiClient.uploadMultipleFiles(
      'api/v1/profiles/upload-multiple-photos/',
      files: images,
      fileFieldName: 'photos',
    );
  }

  Future<void> reorderProfilePhotos(List<Map<String, dynamic>> photos) async {
    await _apiClient.post(
      'api/v1/profiles/reorder-photos/',
      {'photos': photos},
    );
  }

  Future<void> deleteProfilePhoto(String photoUrl) async {
    await _apiClient.delete(
      'api/v1/profiles/delete-photo/',
      body: {'photo_url': photoUrl},
    );
  }

  Future<void> setMainProfilePhoto(String photoUrl) async {
    await _apiClient.post(
      'api/v1/profiles/set-main-photo/',
      {'photo_url': photoUrl},
    );
  }

  Future<void> uploadVoiceIntro(XFile audioFile) async {
    await _apiClient.uploadMultipleFiles(
      'api/v1/profiles/upload-voice-intro/',
      files: [audioFile],
      fileFieldName: 'voice_intro',
    );
  }

  Future<void> deleteVoiceIntro() async {
    await _apiClient.delete('api/v1/profiles/delete-voice-intro/');
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
    ];
  }

  List<Map<String, String>> getSocialCircles() {
    return [
      {'value': 'arts_culture', 'label': 'Arts & Culture'},
      {'value': 'tech_innovation', 'label': 'Tech & Innovation'},
      {'value': 'business_finance', 'label': 'Business & Finance'},
    ];
  }

  List<Map<String, String>> getConnectionFrequencies() {
    return [
      {'value': 'occasional', 'label': 'Occasional - 1-2 times/month'},
      {'value': 'regular', 'label': 'Regular - 1-2 times/week'},
      {'value': 'selective', 'label': 'Selective - a few times a year'},
    ];
  }

  List<Map<String, String>> getVisibilityOptions() {
    return [
      {'value': 'public', 'label': 'Public'},
      {'value': 'connections', 'label': 'Connections Only'},
    ];
  }

  List<String> getCommonInterests() {
    return ['Coffee', 'Art', 'Music', 'Travel', 'Photography'];
  }
}
