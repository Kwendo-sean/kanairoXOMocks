import '../core/utils/url_helper.dart';

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
      title: json['title'] ?? '',
      description: json['description'],
      memoryType: json['memory_type'] ?? 'vibe',
      memoryDate: DateTime.tryParse(json['memory_date'] ?? '') ?? DateTime.now(),
      photo: UrlHelper.fixMediaUrl(json['photo'] ?? json['image_url'] ?? json['image']),
      voiceNote: json['voice_note'],
      voiceDuration: json['voice_duration'],
      locationName: json['location_name'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
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
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      reactions: (json['reactions'] as List?)?.map((r) => MemoryReaction.fromJson(r)).toList() ?? [],
      comments: (json['comments'] as List?)?.map((c) => MemoryComment.fromJson(c)).toList() ?? [],
      userReaction: json['user_reaction'],
    );
  }

  String get formattedDate => "${memoryDate.day}/${memoryDate.month}/${memoryDate.year}";
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
      userName: json['user']['first_name'] ?? '',
      reactionType: json['reaction_type'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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
      userName: json['user']['first_name'] ?? '',
      comment: json['comment'] ?? '',
      parentCommentId: json['parent_comment']?.toString(),
      replies: (json['replies'] as List?)?.map((r) => MemoryComment.fromJson(r)).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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
      label: json['label'] ?? '',
      memories: (json['memories'] as List).map((m) => Memory.fromJson(m)).toList(),
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
      total: json['total'] ?? 0,
      favorites: json['favorites'] ?? 0,
      byType: (json['by_type'] as List?)?.map((t) => MemoryTypeCount.fromJson(t)).toList() ?? [],
      recent30Days: json['recent_30_days'] ?? 0,
      topLocations: (json['top_locations'] as List?)?.map((l) => LocationCount.fromJson(l)).toList() ?? [],
    );
  }
}

class MemoryTypeCount {
  final String type;
  final int count;

  MemoryTypeCount({required this.type, required this.count});

  factory MemoryTypeCount.fromJson(Map<String, dynamic> json) {
    return MemoryTypeCount(
      type: json['memory_type'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class LocationCount {
  final String location;
  final int count;

  LocationCount({required this.location, required this.count});

  factory LocationCount.fromJson(Map<String, dynamic> json) {
    return LocationCount(
      location: json['location_name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
