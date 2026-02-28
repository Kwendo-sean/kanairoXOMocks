import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kanairoxo/services/api_client.dart';

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
      'api/memories/memories/',
      queryParameters: queryParameters,
    );

    return (response as List).map((json) => Memory.fromJson(json)).toList();
  }

  /// Get memory timeline (grouped by month)
  Future<Map<String, TimelineMonth>> getTimeline() async {
    final response = await _api.get('api/memories/memories/timeline/');

    final timeline = <String, TimelineMonth>{};
    (response as Map<String, dynamic>).forEach((key, value) {
      timeline[key] = TimelineMonth.fromJson(value);
    });

    return timeline;
  }

  /// Get memory statistics
  Future<MemoryStats> getStats() async {
    final response = await _api.get('api/memories/memories/stats/');
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
      Uri.parse('${ApiClient.baseUrl}/api/memories/memories/'),
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
      throw Exception('Failed to create memory. Please try again.');
    }
  }

  /// React to memory
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await _api.post(
      'api/memories/memories/$memoryId/react/',
      {'reaction_type': reactionType},
    );
  }

  /// Remove reaction
  Future<void> unreact(String memoryId) async {
    await _api.delete('api/memories/memories/$memoryId/unreact/');
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(String memoryId) async {
    final response = await _api.post(
      'api/memories/memories/$memoryId/toggle_favorite/',
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
      'api/memories/comments/',
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
    await _api.delete('api/memories/memories/$memoryId/');
  }
}

// ── Models ──────────────────────────────────────────────────────────────────

class Memory {
  final String id;
  final String title;
  final String? description;
  final String memoryType;
  final DateTime memoryDate;
  final String? photo;
  final String? voiceNote;
  final int? voiceDuration;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? mood;
  final List<String> emotionTags;
  final bool isPrivate;
  final bool isFavorite;
  final List<String> tags;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final String? createdById;
  final String? createdByName;
  final DateTime createdAt;
  final List<MemoryReaction> reactions;
  final List<MemoryComment> comments;
  final String? userReaction;

  Memory({
    required this.id,
    required this.title,
    this.description,
    required this.memoryType,
    required this.memoryDate,
    this.photo,
    this.voiceNote,
    this.voiceDuration,
    this.locationName,
    this.latitude,
    this.longitude,
    this.mood,
    this.emotionTags = const [],
    this.isPrivate = false,
    this.isFavorite = false,
    this.tags = const [],
    this.viewCount = 0,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.createdById,
    this.createdByName,
    required this.createdAt,
    this.reactions = const [],
    this.comments = const [],
    this.userReaction,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      memoryType: json['memory_type'],
      memoryDate: DateTime.parse(json['memory_date']),
      photo: json['photo'],
      voiceNote: json['voice_note'],
      voiceDuration: json['voice_duration'],
      locationName: json['location_name'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      mood: json['mood'],
      emotionTags: List<String>.from(json['emotion_tags'] ?? []),
      isPrivate: json['is_private'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['view_count'] ?? 0,
      reactionCount: json['reaction_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      createdById: json['created_by']?['id']?.toString(),
      createdByName: json['created_by']?['first_name'],
      createdAt: DateTime.parse(json['created_at']),
      reactions: (json['reactions'] as List?)
          ?.map((r) => MemoryReaction.fromJson(r))
          .toList() ??
          [],
      comments: (json['comments'] as List?)
          ?.map((c) => MemoryComment.fromJson(c))
          .toList() ??
          [],
      userReaction: json['user_reaction'],
    );
  }
}

class MemoryReaction {
  final String id;
  final String userId;
  final String userName;
  final String reactionType;
  final DateTime createdAt;

  MemoryReaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reactionType,
    required this.createdAt,
  });

  factory MemoryReaction.fromJson(Map<String, dynamic> json) {
    return MemoryReaction(
      id: json['id'].toString(),
      userId: json['user']['id'].toString(),
      userName: json['user']['first_name'],
      reactionType: json['reaction_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class MemoryComment {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final String? parentCommentId;
  final List<MemoryComment> replies;
  final DateTime createdAt;

  MemoryComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    this.parentCommentId,
    this.replies = const [],
    required this.createdAt,
  });

  factory MemoryComment.fromJson(Map<String, dynamic> json) {
    return MemoryComment(
      id: json['id'].toString(),
      userId: json['user']['id'].toString(),
      userName: json['user']['first_name'],
      comment: json['comment'],
      parentCommentId: json['parent_comment']?.toString(),
      replies: (json['replies'] as List?)
          ?.map((r) => MemoryComment.fromJson(r))
          .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TimelineMonth {
  final String label;
  final List<Memory> memories;

  TimelineMonth({
    required this.label,
    required this.memories,
  });

  factory TimelineMonth.fromJson(Map<String, dynamic> json) {
    return TimelineMonth(
      label: json['label'],
      memories: (json['memories'] as List)
          .map((m) => Memory.fromJson(m))
          .toList(),
    );
  }
}

class MemoryStats {
  final int total;
  final int favorites;
  final List<MemoryTypeCount> byType;
  final int recent30Days;
  final List<LocationCount> topLocations;

  MemoryStats({
    required this.total,
    required this.favorites,
    required this.byType,
    required this.recent30Days,
    required this.topLocations,
  });

  factory MemoryStats.fromJson(Map<String, dynamic> json) {
    return MemoryStats(
      total: json['total'],
      favorites: json['favorites'],
      byType: (json['by_type'] as List)
          .map((t) => MemoryTypeCount.fromJson(t))
          .toList(),
      recent30Days: json['recent_30_days'],
      topLocations: (json['top_locations'] as List)
          .map((l) => LocationCount.fromJson(l))
          .toList(),
    );
  }
}

class MemoryTypeCount {
  final String type;
  final int count;

  MemoryTypeCount({required this.type, required this.count});

  factory MemoryTypeCount.fromJson(Map<String, dynamic> json) {
    return MemoryTypeCount(
      type: json['memory_type'],
      count: json['count'],
    );
  }
}

class LocationCount {
  final String location;
  final int count;

  LocationCount({required this.location, required this.count});

  factory LocationCount.fromJson(Map<String, dynamic> json) {
    return LocationCount(
      location: json['location_name'],
      count: json['count'],
    );
  }
}
