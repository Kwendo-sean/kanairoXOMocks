// lib/models/discovery_models.dart
import 'dart:convert';

// Discovery Session Model
class DiscoverySession {
  final String id;
  final String sessionId;
  final String userId;
  final String userDisplayName;
  final DateTime startedAt;
  final DateTime lastActivity;
  final bool isActive;
  final String context;
  final int batchSize;
  final Map<String, dynamic> filters;
  final int profilesShown;
  final int profilesSwiped;
  final int connectionsMade;
  final int savesMade;
  final String? timeElapsed;

  DiscoverySession({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userDisplayName,
    required this.startedAt,
    required this.lastActivity,
    required this.isActive,
    required this.context,
    required this.batchSize,
    required this.filters,
    required this.profilesShown,
    required this.profilesSwiped,
    required this.connectionsMade,
    required this.savesMade,
    this.timeElapsed,
  });

  factory DiscoverySession.fromJson(Map<String, dynamic> json) {
    try {
      return DiscoverySession(
        id: json['id']?.toString() ?? '0',
        sessionId: json['session_id']?.toString() ?? '',
        userId: json['user']?.toString() ?? '0',
        userDisplayName: json['user_display_name']?.toString() ?? 'User',
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'].toString())
            : DateTime.now(),
        lastActivity: json['last_activity'] != null
            ? DateTime.parse(json['last_activity'].toString())
            : DateTime.now(),
        isActive: json['is_active'] ?? true,
        context: json['context']?.toString() ?? 'general',
        batchSize: (json['batch_size'] as num?)?.toInt() ?? 10,
        filters: json['filters'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['filters'])
            : <String, dynamic>{},
        profilesShown: (json['profiles_shown'] as num?)?.toInt() ?? 0,
        profilesSwiped: (json['profiles_swiped'] as num?)?.toInt() ?? 0,
        connectionsMade: (json['connections_made'] as num?)?.toInt() ?? 0,
        savesMade: (json['saves_made'] as num?)?.toInt() ?? 0,
        timeElapsed: json['time_elapsed']?.toString(),
      );
    } catch (e) {
      print('Error parsing DiscoverySession: $e');
      // Return a default session
      return DiscoverySession(
        id: '0',
        sessionId: '',
        userId: '0',
        userDisplayName: 'User',
        startedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        isActive: false,
        context: 'general',
        batchSize: 10,
        filters: {},
        profilesShown: 0,
        profilesSwiped: 0,
        connectionsMade: 0,
        savesMade: 0,
      );
    }
  }
}

// Discovery Item Model
class DiscoveryItem {
  final String id;
  final String sessionId;
  final String sessionContext;
  final String itemType;
  final String itemId;
  final int position;
  final DateTime shownAt;
  final String? userAction;
  final DateTime? actionTakenAt;
  final double overallScore;
  final Map<String, dynamic> componentScores;
  final String explanation;
  final Map<String, dynamic> itemDetails;
  final Map<String, dynamic> profileDetails;

  DiscoveryItem({
    required this.id,
    required this.sessionId,
    required this.sessionContext,
    required this.itemType,
    required this.itemId,
    required this.position,
    required this.shownAt,
    this.userAction,
    this.actionTakenAt,
    required this.overallScore,
    required this.componentScores,
    required this.explanation,
    required this.itemDetails,
    this.profileDetails = const {},
  });

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    try {
      return DiscoveryItem(
        id: json['id']?.toString() ?? '0',
        sessionId: json['session']?.toString() ?? '0',
        sessionContext: json['session_context']?.toString() ?? 'general',
        itemType: json['item_type']?.toString() ?? 'profile',
        itemId: json['item_id']?.toString() ?? '0',
        position: (json['position'] as num?)?.toInt() ?? 0,
        shownAt: json['shown_at'] != null
            ? DateTime.parse(json['shown_at'].toString())
            : DateTime.now(),
        userAction: json['user_action']?.toString(),
        actionTakenAt: json['action_taken_at'] != null
            ? DateTime.parse(json['action_taken_at'].toString())
            : null,
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
        componentScores: json['component_scores'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['component_scores'])
            : <String, dynamic>{},
        explanation: json['explanation']?.toString() ?? 'Recommended for you',
        itemDetails: json['item_details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['item_details'])
            : <String, dynamic>{},
        profileDetails: json['profile_details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['profile_details'])
            : <String, dynamic>{},
      );
    } catch (e) {
      print('Error parsing DiscoveryItem: $e');
      return DiscoveryItem(
        id: '0',
        sessionId: '0',
        sessionContext: 'general',
        itemType: 'profile',
        itemId: '0',
        position: 0,
        shownAt: DateTime.now(),
        overallScore: 0.0,
        componentScores: {},
        explanation: 'Recommended for you',
        itemDetails: {},
        profileDetails: {},
      );
    }
  }

  bool get isProfile => itemType == 'profile';

  String get compatibilityText {
    if (overallScore >= 80) {
      return 'Excellent Match';
    } else if (overallScore >= 60) {
      return 'Great Match';
    } else if (overallScore >= 40) {
      return 'Good Match';
    } else {
      return 'Potential Match';
    }
  }
}

// Discovery Batch Response Model
class DiscoveryBatch {
  final DiscoverySession session;
  final List<DiscoveryItem> discoveries;
  final BatchInfo batchInfo;

  DiscoveryBatch({
    required this.session,
    required this.discoveries,
    required this.batchInfo,
  });

  factory DiscoveryBatch.fromJson(Map<String, dynamic> json) {
    try {
      return DiscoveryBatch(
        session: DiscoverySession.fromJson(json['session'] ?? {}),
        discoveries: (json['discoveries'] as List?)
            ?.map((item) => DiscoveryItem.fromJson(item))
            .toList() ??
            [],
        batchInfo: BatchInfo.fromJson(json['batch_info'] ?? {'size': 0, 'remaining_today': 0}),
      );
    } catch (e) {
      print('Error parsing DiscoveryBatch: $e');
      return DiscoveryBatch(
        session: DiscoverySession.fromJson({}),
        discoveries: [],
        batchInfo: BatchInfo.fromJson({'size': 0, 'remaining_today': 0}),
      );
    }
  }
}

class BatchInfo {
  final int size;
  final int remainingToday;

  BatchInfo({
    required this.size,
    required this.remainingToday,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    try {
      return BatchInfo(
        size: (json['size'] as num?)?.toInt() ?? 0,
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return BatchInfo(size: 0, remainingToday: 0);
    }
  }
}

// Profile Model from Profile Details
class DiscoveryProfile {
  final String userId;
  final String displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final List<String> interests;
  final String? location;
  final String? imageUrl;
  final double? trustScore;
  final List<String>? currentMoods;
  final String? primaryIntent;
  final String? secondaryIntent;
  final bool isOnline;

  DiscoveryProfile({
    required this.userId,
    required this.displayName,
    this.bio,
    this.age,
    this.gender,
    required this.interests,
    this.location,
    this.imageUrl,
    this.trustScore,
    this.currentMoods,
    this.primaryIntent,
    this.secondaryIntent,
    this.isOnline = false,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different possible ID fields
      String userId = '';
      if (json['id'] != null) {
        userId = json['id'].toString();
      } else if (json['user_id'] != null) {
        userId = json['user_id'].toString();
      } else if (json['public_id'] != null) {
        userId = json['public_id'].toString();
      } else {
        userId = '0';
      }

      // Handle display name
      String displayName = '';
      if (json['display_name'] != null && json['display_name'].toString().isNotEmpty) {
        displayName = json['display_name'].toString();
      } else if (json['first_name'] != null || json['last_name'] != null) {
        displayName = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
        if (displayName.isEmpty) {
          displayName = 'User $userId';
        }
      } else {
        displayName = 'User $userId';
      }

      // Parse interests - handle different formats
      List<String> interests = [];
      if (json['interests'] is List) {
        interests = List<String>.from(json['interests'].map((i) => i.toString()));
      } else if (json['interests'] is String) {
        interests = json['interests'].split(',').map((i) => i.trim()).toList();
      }

      return DiscoveryProfile(
        userId: userId,
        displayName: displayName,
        bio: json['bio']?.toString(),
        age: (json['age'] as num?)?.toInt(),
        gender: json['gender']?.toString(),
        interests: interests,
        location: json['location']?.toString(),
        imageUrl: _getProfileImageUrl(json), // Helper method
        trustScore: (json['trust_score'] as num?)?.toDouble(),
        currentMoods: json['current_moods'] is List
            ? List<String>.from(json['current_moods'])
            : [],
        primaryIntent: json['primary_intent']?.toString(),
        secondaryIntent: json['secondary_intent']?.toString(),
        isOnline: json['is_online'] ?? false,
      );
    } catch (e) {
      print('Error parsing DiscoveryProfile: $e');
      print('JSON was: $json');
      // Return a minimal profile with the data we have
      return DiscoveryProfile(
        userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '0',
        displayName: json['display_name']?.toString() ?? 'User',
        interests: [],
      );
    }
  }

// Helper method to get profile image URL
  static String? _getProfileImageUrl(Map<String, dynamic> json) {
    // Try different possible image fields
    if (json['profile_image'] != null && json['profile_image']
        .toString()
        .isNotEmpty) {
      return json['profile_image'].toString();
    }

    if (json['profile_photos'] is List &&
        (json['profile_photos'] as List).isNotEmpty) {
      final photos = json['profile_photos'] as List;
      if (photos[0] is Map && photos[0]['url'] != null) {
        return photos[0]['url'].toString();
      } else if (photos[0] is String) {
        return photos[0];
      }
    }

    if (json['image_url'] != null) {
      return json['image_url'].toString();
    }

    return null;
  }
}

// User Action Request Model
class UserActionRequest {
  final String action;
  final double? rating;
  final Map<String, dynamic>? context;
  final String? explanation;

  UserActionRequest({
    required this.action,
    this.rating,
    this.context,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (rating != null) 'rating': rating,
      if (context != null) 'context': context,
      if (explanation != null) 'explanation': explanation,
    };
  }
}
