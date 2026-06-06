import '../core/utils/url_helper.dart';

class ProfileModel {
  final int id;
  final String fullName;
  final String location;
  final String headline;
  final String bio;
  final String? profilePhotoUrl;
  final String primaryNeighborhood;
  final String lifeStage;
  final String primarySocialCircle;
  final String profileVisibility;
  final List<InterestModel> interests;
  final int completionPercentage;
  final List<NextStepModel> nextSteps;
  final int viewsCount;
  final int savesCount;
  final int galleryCount;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.location,
    required this.headline,
    required this.bio,
    this.profilePhotoUrl,
    required this.primaryNeighborhood,
    required this.lifeStage,
    required this.primarySocialCircle,
    required this.profileVisibility,
    required this.interests,
    required this.completionPercentage,
    required this.nextSteps,
    required this.viewsCount,
    required this.savesCount,
    required this.galleryCount,
  });

  ProfileModel copyWith({
    int? id,
    String? fullName,
    String? location,
    String? headline,
    String? bio,
    String? profilePhotoUrl,
    String? primaryNeighborhood,
    String? lifeStage,
    String? primarySocialCircle,
    String? profileVisibility,
    List<InterestModel>? interests,
    int? completionPercentage,
    List<NextStepModel>? nextSteps,
    int? viewsCount,
    int? savesCount,
    int? galleryCount,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      location: location ?? this.location,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      primaryNeighborhood: primaryNeighborhood ?? this.primaryNeighborhood,
      lifeStage: lifeStage ?? this.lifeStage,
      primarySocialCircle: primarySocialCircle ?? this.primarySocialCircle,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      interests: interests ?? this.interests,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      nextSteps: nextSteps ?? this.nextSteps,
      viewsCount: viewsCount ?? this.viewsCount,
      savesCount: savesCount ?? this.savesCount,
      galleryCount: galleryCount ?? this.galleryCount,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      location: json['location'] ?? json['primary_neighborhood'] ?? '',
      headline: json['headline'] ?? '',
      bio: json['bio'] ?? '',
      profilePhotoUrl: UrlHelper.fixMediaUrl(json['profile_photo_url']),
      primaryNeighborhood: json['primary_neighborhood'] ?? '',
      lifeStage: json['life_stage'] ?? '',
      primarySocialCircle: json['primary_social_circle'] ?? '',
      profileVisibility: json['profile_visibility'] ?? 'public',
      interests: (json['interests'] as List? ?? [])
          .map((i) => InterestModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      completionPercentage: json['completion_percentage'] ?? 0,
      nextSteps: (json['next_steps'] as List? ?? [])
          .map((s) => NextStepModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      viewsCount: json['views_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      galleryCount: json['gallery_count'] ?? 0,
    );
  }
}

class InterestModel {
  final int id;
  final String name;

  InterestModel({required this.id, required this.name});

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class NextStepModel {
  final String key;
  final String label;

  NextStepModel({required this.key, required this.label});

  factory NextStepModel.fromJson(Map<String, dynamic> json) {
    return NextStepModel(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class GalleryPhotoModel {
  final int id;
  final String imageUrl;
  final String caption;
  final DateTime uploadedAt;

  GalleryPhotoModel({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.uploadedAt,
  });

  factory GalleryPhotoModel.fromJson(Map<String, dynamic> json) {
    return GalleryPhotoModel(
      id: json['id'] ?? 0,
      // ITEM 1: Ensure we use 'image_url' and don't prefix if it's already absolute
      imageUrl: json['image_url'] ?? '', 
      caption: json['caption'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
    );
  }
}
