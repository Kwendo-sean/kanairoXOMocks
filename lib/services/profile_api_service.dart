import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import 'api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient = ApiClient();

  // --- NEW REPOSITORY METHODS ---

  static const _profileCacheKey = 'cached_profile_json';

  Future<ProfileModel> getProfile() async {
    try {
      final response = await _apiClient.get('api/v1/profiles/edit/');

      final data = response;
      final profileData = data is Map<String, dynamic>
        ? (data.containsKey('profile') ? data['profile'] as Map<String, dynamic> : data)
        : data as Map<String, dynamic>;

      // Cache the raw body rather than a serialised model — nothing to keep
      // in sync as the model changes.
      unawaited(_cacheProfile(profileData));
      return ProfileModel.fromJson(profileData);
    } catch (e) {
      // Offline, or the server is unreachable: show the last profile we saw
      // rather than an error screen with nothing on it.
      final cached = await _readCachedProfile();
      if (cached != null) return ProfileModel.fromJson(cached);
      rethrow;
    }
  }

  Future<void> _cacheProfile(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(json));
    } catch (_) {
      // A cache write failing must never break the fetch that succeeded.
    }
  }

  Future<Map<String, dynamic>?> _readCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<GalleryPhotoModel>> getGallery({String? userId}) async {
    final endpoint = userId != null 
        ? 'api/v1/profiles/$userId/gallery/' 
        : 'api/v1/profiles/gallery/';
    final response = await _apiClient.get(endpoint);
    final list = response is List
      ? response
      : (response['results'] as List? ?? []);
    return list.map((p) => GalleryPhotoModel.fromJson(p)).toList();
  }
  
  Future<void> uploadGalleryPhoto(File photo) async {
    final fileName = photo.path.split('/').last;
    
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        photo.path,
        filename: fileName),
      'is_primary': false,
    });
    
    await ApiClient.instance.dio.post(
      'api/v1/profiles/gallery/upload/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  /// Uploads a single profile photo to the primary endpoint.
  /// Returns the new photo URL from the response.
  Future<String> uploadSingleProfilePhoto(File photo) async {
    final fileName = photo.path.split('/').last;
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
    });

    final response = await ApiClient.instance.dio.post(
      'api/v1/profiles/upload-photo/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    // Expecting response format: {"success": true, "photo_url": "..."}
    return response.data['photo_url'] ?? '';
  }
  
  Future<void> deleteGalleryPhoto(int id) async {
    await _apiClient.delete('api/v1/profiles/gallery/$id/delete/');
  }

  // --- EXISTING METHODS ---

  Future<User> getMyProfile() async {
    final response = await _apiClient.get('api/v1/auth/profile/');
    return User.fromJson(response);
  }

  Future<User> getUserProfile(String id) async {
    final response = await _apiClient.get('api/v1/profiles/public/$id/');
    return User.fromJson(response);
  }

  Future<User> updateProfile(UserProfileUpdate update) async {
    final json = update.toJson();

    // Interests have a dedicated bulk endpoint — send separately
    final interests = json.remove('interests');
    if (interests != null && interests is List && interests.isNotEmpty) {
      await _apiClient.post('api/v1/profiles/interests/bulk/', {'interests': interests});
    }

    final response = await _apiClient.patch('api/v1/profiles/edit/', json);
    return User.fromJson(response);
  }

  Future<bool> saveProfile(String id) async {
    await _apiClient.post('api/v1/profiles/$id/save/', {});
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

  Future<void> uploadProfilePhotos(List<XFile> images) async {
    await _apiClient.uploadMultipleFiles(
      'api/v1/profiles/upload-multiple-photos/',
      files: images,
      fileFieldName: 'photos',
    );
  }

  Future<void> reorderProfilePhotos(List<Map<String, dynamic>> photos) async {
    await _apiClient.post('api/v1/profiles/reorder-photos/', {'photos': photos});
  }

  Future<void> deleteProfilePhoto(String photoUrl) async {
    await _apiClient.delete('api/v1/profiles/delete-photo/', body: {'photo_url': photoUrl});
  }

  Future<void> setMainProfilePhoto(String photoUrl) async {
    await _apiClient.post('api/v1/profiles/set-main-photo/', {'photo_url': photoUrl});
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

  List<Map<String, String>> getNeighborhoods() {
    return [
      {'value': 'westlands', 'label': 'Westlands'},
      {'value': 'kilimani', 'label': 'Kilimani/Kileleshwa'},
      {'value': 'lavington', 'label': 'Lavington'},
      {'value': 'karen', 'label': 'Karen'},
      {'value': 'langata', 'label': 'Langata'},
      {'value': 'nairobi_cbd', 'label': 'Nairobi CBD'},
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
    ];
  }

  List<Map<String, String>> getConnectionFrequencies() {
    return [
      {'value': 'occasional', 'label': 'Occasional'},
      {'value': 'regular', 'label': 'Regular'},
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
