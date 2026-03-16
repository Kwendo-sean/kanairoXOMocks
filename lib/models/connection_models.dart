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
  final String fullName;
  final String? profilePhotoUrl;
  final String neighborhood;
  final String lifeStage;
  final String headline;
  final String bio;
  final List<String> interests;
  final List<MomentPreview> moments;
  final bool momentsAreLimited;
  final bool isConnected;
  final bool hasPendingRequest;
  final String? receivedRequestId;

  ProfilePreviewModel({
    required this.id,
    required this.fullName,
    this.profilePhotoUrl,
    required this.neighborhood,
    required this.lifeStage,
    required this.headline,
    required this.bio,
    required this.interests,
    required this.moments,
    required this.momentsAreLimited,
    required this.isConnected,
    required this.hasPendingRequest,
    this.receivedRequestId,
  });

  factory ProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    final status = json['connection_status'] as Map? ?? {};
    return ProfilePreviewModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      profilePhotoUrl: ApiConstants.fixMediaUrl(json['profile_photo_url']),
      neighborhood: json['neighborhood'] ?? '',
      lifeStage: json['life_stage'] ?? '',
      headline: json['headline'] ?? '',
      bio: json['bio'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      moments: (json['moments'] as List? ?? [])
          .map((m) => MomentPreview.fromMap(m))
          .toList(),
      momentsAreLimited: json['moments_are_limited'] ?? false,
      isConnected: status['is_connected'] ?? false,
      hasPendingRequest: status['has_pending_request'] ?? false,
      receivedRequestId: status['received_request_id']?.toString(),
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
