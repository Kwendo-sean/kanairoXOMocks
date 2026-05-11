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
  final String firstName;
  final String lastName;
  final String fullName;
  final String? mainProfilePhotoUrl;
  final String neighborhoodDisplay;
  final String lifeStage;
  final String primarySocialCircle;
  final String headline;
  final String bio;
  final List<String> interests;
  final List<MomentPreview> moments;
  final bool isVerified;
  final bool momentsAreLimited;
  final bool isConnected;
  final bool hasPendingRequest;
  final String? receivedRequestId;

  ProfilePreviewModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.mainProfilePhotoUrl,
    required this.neighborhoodDisplay,
    required this.lifeStage,
    required this.primarySocialCircle,
    required this.headline,
    required this.bio,
    required this.interests,
    required this.moments,
    required this.isVerified,
    required this.momentsAreLimited,
    required this.isConnected,
    required this.hasPendingRequest,
    this.receivedRequestId,
  });

  factory ProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    final statusObj = json['connection_status'];
    bool connected = false;
    bool pending = false;
    String? reqId;

    if (statusObj is Map) {
      connected = statusObj['is_connected'] ?? false;
      pending = statusObj['has_pending_request'] ?? false;
      reqId = statusObj['received_request_id']?.toString();
    } else if (statusObj is String) {
      // Handle various backend string formats
      connected = statusObj == 'connected' || 
                 statusObj == 'mutual' || 
                 statusObj == 'already_connected';
      pending = statusObj == 'pending';
    }

    // Secondary check: if the main response has is_connected at root
    if (json['is_connected'] == true) connected = true;

    return ProfilePreviewModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      mainProfilePhotoUrl: ApiConstants.fixMediaUrl(json['main_profile_photo_url']),
      neighborhoodDisplay: json['neighborhood_display'] ?? json['neighborhood'] ?? '',
      lifeStage: json['life_stage'] ?? '',
      primarySocialCircle: json['primary_social_circle'] ?? '',
      headline: json['headline'] ?? '',
      bio: json['bio'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      moments: (json['moments'] as List? ?? [])
          .map((m) => MomentPreview.fromMap(m))
          .toList(),
      isVerified: json['is_verified'] ?? false,
      momentsAreLimited: json['moments_are_limited'] ?? false,
      isConnected: connected,
      hasPendingRequest: pending,
      receivedRequestId: reqId,
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
