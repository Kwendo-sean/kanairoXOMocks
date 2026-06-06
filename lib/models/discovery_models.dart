import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

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
  final int masonrySavesMade;
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
    required this.masonrySavesMade,
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
        masonrySavesMade: (json['saves_made'] as num?)?.toInt() ?? 0,
        timeElapsed: json['time_elapsed']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing DiscoverySession: $e');
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
        masonrySavesMade: 0,
      );
    }
  }
}

// Discovery Item Model (Handles Profiles and Ads)
class DiscoveryItem {
  final bool isAd;
  
  // Profile fields
  final String? id;
  final String? explanation;
  final double overallScore;
  final Map<String, dynamic> profileDetails;
  
  // Ad fields
  final String? adId;
  final String? title;
  final String? subtitle;
  final String? body;
  final String? imageUrl;
  final String? ctaText;
  final String? ctaType;
  final String? ctaUrl;
  final String? ctaEventId;
  final AdSponsor? sponsor;
  final String? sponsoredByLabel;

  DiscoveryItem({
    this.isAd = false,
    this.id,
    this.explanation,
    this.overallScore = 0.0,
    this.profileDetails = const {},
    this.adId,
    this.title,
    this.subtitle,
    this.body,
    this.imageUrl,
    this.ctaText,
    this.ctaType,
    this.ctaUrl,
    this.ctaEventId,
    this.sponsor,
    this.sponsoredByLabel,
  });

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    bool isAd = json['is_ad'] ?? false;
    if (isAd) {
      return DiscoveryItem(
        isAd: true,
        adId: json['id']?.toString(),
        title: json['title'],
        subtitle: json['subtitle'],
        body: json['body'],
        imageUrl: ApiConstants.fixMediaUrl(json['image_url']),
        ctaText: json['cta_text'],
        ctaType: json['cta_type'],
        ctaUrl: json['cta_url'],
        ctaEventId: json['cta_event_id']?.toString(),
        sponsor: json['sponsor'] != null ? AdSponsor.fromJson(json['sponsor']) : null,
        sponsoredByLabel: json['sponsored_by_label'],
      );
    } else {
      return DiscoveryItem(
        isAd: false,
        id: json['id']?.toString(),
        explanation: json['explanation'] ?? 'Recommended for you',
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
        profileDetails: json['profile_details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['profile_details'])
            : json, // Fallback if direct profile fields are at root
      );
    }
  }

  String get compatibilityText {
    if (overallScore >= 80) return 'Excellent Match';
    if (overallScore >= 60) return 'Great Match';
    if (overallScore >= 40) return 'Good Match';
    return 'Potential Match';
  }
}

class AdSponsor {
  final String id;
  final String name;
  final String? logoUrl;
  final bool isVerified;

  AdSponsor({required this.id, required this.name, this.logoUrl, this.isVerified = false});

  factory AdSponsor.fromJson(Map<String, dynamic> json) {
    return AdSponsor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: ApiConstants.fixMediaUrl(json['logo_url']),
      isVerified: json['is_verified'] ?? false,
    );
  }
}

// Discovery Batch Response Model
class DiscoveryBatch {
  final List<DiscoveryItem> discoveries;

  DiscoveryBatch({required this.discoveries});

  factory DiscoveryBatch.fromJson(Map<String, dynamic> json) {
    var list = json['recommendations'] as List? ?? json['discoveries'] as List? ?? [];
    return DiscoveryBatch(
      discoveries: list.map((item) => DiscoveryItem.fromJson(item)).toList(),
    );
  }
}

// Profile Model from Profile Details
class DiscoveryProfile {
  final String userId;
  final String fullName;
  final String? profilePhotoUrl;
  final String neighborhood;
  final String lifeStage;
  final String headline;
  final int matchScore;
  final String? firstName;
  final String? bio;
  final int? age;
  final List<String> interests;

  DiscoveryProfile({
    required this.userId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.neighborhood,
    required this.lifeStage,
    required this.headline,
    required this.matchScore,
    this.firstName,
    this.bio,
    this.age,
    required this.interests,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    try {
      String userId = json['id']?.toString() ?? json['user_id']?.toString() ?? '0';
      List<String> interests = List<String>.from(json['interests'] ?? []);
      
      return DiscoveryProfile(
        userId: userId,
        fullName: json['full_name'] ?? json['display_name'] ?? 'User',
        profilePhotoUrl: ApiConstants.fixMediaUrl(json['main_profile_photo_url'] ?? json['photo_url'] ?? json['profile_photo_url']),
        neighborhood: json['neighborhood'] ?? '',
        lifeStage: json['life_stage'] ?? '',
        headline: json['headline'] ?? '',
        matchScore: (json['match_score'] ?? json['overall_score'] ?? 0).toInt(),
        firstName: json['first_name'],
        bio: json['bio'],
        age: json['age'],
        interests: interests,
      );
    } catch (e) {
      return DiscoveryProfile(
        userId: '0', fullName: 'Error', neighborhood: '', lifeStage: '', headline: '', matchScore: 0, interests: []
      );
    }
  }
}
