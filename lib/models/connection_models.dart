import 'package:kanairoxo/utils/constants.dart';

class ConnectionRequestModel {
  final String requestId;
  final String initiatorId;
  final String initiatorName;
  final String? initiatorPhotoUrl;
  final String initiatorNeighborhood;
  final String initiatorHeadline;
  final String initiatorLifeStage;
  final String timeAgo;

  ConnectionRequestModel({
    required this.requestId,
    required this.initiatorId,
    required this.initiatorName,
    this.initiatorPhotoUrl,
    required this.initiatorNeighborhood,
    required this.initiatorHeadline,
    required this.initiatorLifeStage,
    required this.timeAgo,
  });

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestModel(
      requestId: json['request_id']?.toString() ?? '',
      initiatorId: json['initiator_id']?.toString() ?? '',
      initiatorName: json['initiator_name'] ?? '',
      initiatorPhotoUrl: ApiConstants.fixMediaUrl(json['initiator_photo_url']),
      initiatorNeighborhood: json['initiator_neighborhood'] ?? '',
      initiatorHeadline: json['initiator_headline'] ?? '',
      initiatorLifeStage: json['initiator_life_stage'] ?? '',
      timeAgo: json['time_ago'] ?? '',
    );
  }
}

class ProfilePreviewModel {
  final String id;
  final String name;
  final String? photoUrl;
  final int? age;
  final String? gender;
  final String bio;
  final String headline;
  final String neighborhood;
  final String lifeStage;
  final String socialCircle;
  final List<GalleryItem> gallery;
  final List<String> interests;
  final List<String> intents;
  final List<String> sharedInterests;
  final int mutualConnectionsCount;
  final String connectionStatus; // none, request_sent, request_received, connected, blocked
  final String? connectionId;
  final CompatibilityModel? compatibility;
  final List<String> badges;
  final bool canMessage;

  ProfilePreviewModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.age,
    this.gender,
    required this.bio,
    required this.headline,
    required this.neighborhood,
    required this.lifeStage,
    required this.socialCircle,
    required this.gallery,
    required this.interests,
    required this.intents,
    required this.sharedInterests,
    required this.mutualConnectionsCount,
    required this.connectionStatus,
    this.connectionId,
    this.compatibility,
    required this.badges,
    required this.canMessage,
  });

  factory ProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    return ProfilePreviewModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      photoUrl: ApiConstants.fixMediaUrl(json['photo_url']),
      age: json['age'],
      gender: json['gender'],
      bio: json['bio'] ?? '',
      headline: json['headline'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      lifeStage: json['life_stage'] ?? '',
      socialCircle: json['social_circle'] ?? '',
      gallery: (json['gallery'] as List? ?? [])
          .map((item) => GalleryItem.fromJson(item))
          .toList(),
      interests: List<String>.from(json['interests'] ?? []),
      intents: List<String>.from(json['intents'] ?? []),
      sharedInterests: List<String>.from(json['shared_interests'] ?? []),
      mutualConnectionsCount: json['mutual_connections_count'] ?? 0,
      connectionStatus: json['connection_status'] ?? 'none',
      connectionId: json['connection_id']?.toString(),
      compatibility: json['compatibility'] != null 
          ? CompatibilityModel.fromJson(json['compatibility']) 
          : null,
      badges: List<String>.from(json['badges'] ?? []),
      canMessage: json['can_message'] ?? false,
    );
  }
}

class GalleryItem {
  final String imageUrl;
  final String? caption;

  GalleryItem({required this.imageUrl, this.caption});

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      imageUrl: ApiConstants.fixMediaUrl(json['image_url']),
      caption: json['caption'],
    );
  }
}

class CompatibilityModel {
  final int score;
  final CompatibilityBreakdown breakdown;

  CompatibilityModel({required this.score, required this.breakdown});

  factory CompatibilityModel.fromJson(Map<String, dynamic> json) {
    return CompatibilityModel(
      score: json['score'] ?? 0,
      breakdown: CompatibilityBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }
}

class CompatibilityBreakdown {
  final int interests;
  final int intent;
  final int neighborhood;
  final int lifeStage;
  final int socialCircle;
  final int ageRange;

  CompatibilityBreakdown({
    required this.interests,
    required this.intent,
    required this.neighborhood,
    required this.lifeStage,
    required this.socialCircle,
    required this.ageRange,
  });

  factory CompatibilityBreakdown.fromJson(Map<String, dynamic> json) {
    return CompatibilityBreakdown(
      interests: json['interests'] ?? 0,
      intent: json['intent'] ?? 0,
      neighborhood: json['neighborhood'] ?? 0,
      lifeStage: json['life_stage'] ?? 0,
      socialCircle: json['social_circle'] ?? 0,
      ageRange: json['age_range'] ?? 0,
    );
  }
}

class MomentPreview {
  final String id;
  final String imageUrl;

  MomentPreview({required this.id, required this.imageUrl});

  factory MomentPreview.fromMap(Map<String, dynamic> map) {
    return MomentPreview(
      id: map['id']?.toString() ?? '',
      imageUrl: ApiConstants.fixMediaUrl(map['image_url']),
    );
  }
}
