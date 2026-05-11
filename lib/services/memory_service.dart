import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/memory_model.dart';

class MemoryService {
  final ApiClient _api = ApiClient();

  /// Get all memories with optional filters
  Future<List<Memory>> getMemories({
    String? memoryType,
    bool? isFavorite,
    String? startDate,
    String? endDate,
    String? mood,
  }) async {
    final queryParameters = <String, String>{};
    if (memoryType != null) queryParameters['memory_type'] = memoryType;
    if (isFavorite != null) queryParameters['is_favorite'] = isFavorite.toString();
    if (startDate != null) queryParameters['start_date'] = startDate;
    if (endDate != null) queryParameters['end_date'] = endDate;
    if (mood != null) queryParameters['mood'] = mood;

    final response = await _api.get(
      'api/v1/memories/memories/',
      queryParameters: queryParameters,
    );

    return (response as List).map((json) => Memory.fromJson(json)).toList();
  }

  /// Get memory timeline (grouped by month)
  Future<Map<String, TimelineMonth>> getTimeline() async {
    final response = await _api.get('api/v1/memories/memories/timeline/');

    final timeline = <String, TimelineMonth>{};
    (response as Map<String, dynamic>).forEach((key, value) {
      timeline[key] = TimelineMonth.fromJson(value);
    });

    return timeline;
  }

  /// Get memory statistics
  Future<MemoryStats> getStats() async {
    final response = await _api.get('api/v1/memories/memories/stats/');
    return MemoryStats.fromJson(response);
  }

  /// Create memory with photo
  Future<Memory> createMemory({
    required String title,
    String? description,
    required String memoryType,
    DateTime? memoryDate,
    File? photo,
    String? locationName,
    double? latitude,
    double? longitude,
    String? mood,
    List<String>? emotionTags,
    List<String>? tags,
    bool isFavorite = false,
    bool isPrivate = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/v1/memories/memories/'),
    );

    // Add headers
    final token = await _api.getAccessToken();
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    request.fields['memory_type'] = memoryType;
    request.fields['memory_date'] =
        (memoryDate ?? DateTime.now()).toIso8601String();
    if (locationName != null) request.fields['location_name'] = locationName;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    if (mood != null) request.fields['mood'] = mood;
    request.fields['is_favorite'] = isFavorite.toString();
    request.fields['is_private'] = isPrivate.toString();

    // Add photo if provided
    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photo.path),
      );
    }

    // Add arrays
    if (emotionTags != null && emotionTags.isNotEmpty) {
      request.fields['emotion_tags'] = emotionTags.join(',');
    }
    if (tags != null && tags.isNotEmpty) {
      request.fields['tags'] = tags.join(',');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Memory.fromJson(json);
    } else {
      throw Exception('Failed to create memory: ${response.body}');
    }
  }

  /// React to memory
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await _api.post(
      'api/v1/memories/memories/$memoryId/react/',
      {'reaction_type': reactionType},
    );
  }

  /// Remove reaction
  Future<void> unreact(String memoryId) async {
    await _api.delete('api/v1/memories/memories/$memoryId/unreact/');
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(String memoryId) async {
    final response = await _api.post(
      'api/v1/memories/memories/$memoryId/toggle_favorite/',
      {},
    );
    return response['is_favorite'];
  }

  /// Add comment
  Future<MemoryComment> addComment(
      String memoryId,
      String comment, {
        String? parentCommentId,
      }) async {
    final response = await _api.post(
      'api/v1/memories/comments/',
      {
        'memory': memoryId,
        'comment': comment,
        if (parentCommentId != null) 'parent_comment': parentCommentId,
      },
    );
    return MemoryComment.fromJson(response);
  }

  /// Delete memory
  Future<void> deleteMemory(String memoryId) async {
    await _api.delete('api/v1/memories/memories/$memoryId/');
  }
}
