// lib/models/user_model.dart
import 'dart:convert';

class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String firstName;
  final String lastName;
  final String? displayName;
  final int? age;
  final List<String> profilePhotos;
  final String? bio;
  final String? headline;
  final List<String> interests;
  final String? primaryNeighborhood;
  final List<String> secondaryNeighborhoods;
  final String? lifeStage;
  final String? primarySocialCircle;
  final List<String> secondarySocialCircles;
  final String connectionFrequency;
  final String profileVisibility;
  final List<String> verificationBadges;
  final int profileCompletionPercentage;
  final int profileViewsCount;
  final int profileSavesCount;
  final String? voiceIntro;
  final double? voiceIntroDuration;
  final String voiceIntroStatus;
  final String moderationStatus;
  final String publicId;
  final DateTime lastProfileUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.age,
    this.profilePhotos = const [],
    this.bio,
    this.headline,
    this.interests = const [],
    this.primaryNeighborhood,
    this.secondaryNeighborhoods = const [],
    this.lifeStage,
    this.primarySocialCircle,
    this.secondarySocialCircles = const [],
    this.connectionFrequency = 'regular',
    this.profileVisibility = 'public',
    this.verificationBadges = const [],
    this.profileCompletionPercentage = 0,
    this.profileViewsCount = 0,
    this.profileSavesCount = 0,
    this.voiceIntro,
    this.voiceIntroDuration,
    this.voiceIntroStatus = 'pending',
    this.moderationStatus = 'pending',
    required this.publicId,
    required this.lastProfileUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      displayName: json['display_name'],
      age: json['age'],
      profilePhotos: List<String>.from(json['profile_photos'] ?? []),
      bio: json['bio'],
      headline: json['headline'],
      interests: List<String>.from(json['interests'] ?? []),
      primaryNeighborhood: json['primary_neighborhood'],
      secondaryNeighborhoods: List<String>.from(json['secondary_neighborhoods'] ?? []),
      lifeStage: json['life_stage'],
      primarySocialCircle: json['primary_social_circle'],
      secondarySocialCircles: List<String>.from(json['secondary_social_circles'] ?? []),
      connectionFrequency: json['connection_frequency'] ?? 'regular',
      profileVisibility: json['profile_visibility'] ?? 'public',
      verificationBadges: List<String>.from(json['verification_badges'] ?? []),
      profileCompletionPercentage: json['profile_completion_percentage'] ?? 0,
      profileViewsCount: json['profile_views_count'] ?? 0,
      profileSavesCount: json['profile_saves_count'] ?? 0,
      voiceIntro: json['voice_intro'],
      voiceIntroDuration: json['voice_intro_duration']?.toDouble(),
      voiceIntroStatus: json['voice_intro_status'] ?? 'pending',
      moderationStatus: json['moderation_status'] ?? 'pending',
      publicId: json['public_id'] ?? '',
      lastProfileUpdate: DateTime.parse(json['last_profile_update']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'phone_number': phoneNumber,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'display_name': displayName,
    'age': age,
    'profile_photos': profilePhotos,
    'bio': bio,
    'headline': headline,
    'interests': interests,
    'primary_neighborhood': primaryNeighborhood,
    'secondary_neighborhoods': secondaryNeighborhoods,
    'life_stage': lifeStage,
    'primary_social_circle': primarySocialCircle,
    'secondary_social_circles': secondarySocialCircles,
    'connection_frequency': connectionFrequency,
    'profile_visibility': profileVisibility,
    'verification_badges': verificationBadges,
    'profile_completion_percentage': profileCompletionPercentage,
    'profile_views_count': profileViewsCount,
    'profile_saves_count': profileSavesCount,
    'voice_intro': voiceIntro,
    'voice_intro_duration': voiceIntroDuration,
    'voice_intro_status': voiceIntroStatus,
    'moderation_status': moderationStatus,
    'public_id': publicId,
    'last_profile_update': lastProfileUpdate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get fullName => '$firstName $lastName';

  String get displayNameOrFull => displayName ?? fullName;

  String? get mainProfilePhoto => profilePhotos.isNotEmpty ? profilePhotos[0] : null;

  bool get hasCompleteProfile => profileCompletionPercentage >= 70;

  bool get hasVoiceIntro => voiceIntro != null && voiceIntro!.isNotEmpty;

  bool get isVerified => verificationBadges.isNotEmpty;

  String get neighborhoodDisplay {
    const neighborhoodNames = {
      'westlands': 'Westlands',
      'kilimani': 'Kilimani',
      'lavington': 'Lavington',
      'karen': 'Karen',
      'langata': 'Langata',
      'nairobi_cbd': 'Nairobi CBD',
      'parklands': 'Parklands',
      'runda': 'Runda',
      'muthaiga': 'Muthaiga',
      'kasarani': 'Kasarani',
      'ruiru': 'Ruiru',
      'kayole': 'Kayole',
      'embakasi': 'Embakasi',
      'dandora': 'Dandora',
      'buruburu': 'Buruburu',
      'south_b': 'South B/C',
      'upperhill': 'Upper Hill',
      'other_nairobi': 'Nairobi',
      'outside_nairobi': 'Outside Nairobi',
    };
    return neighborhoodNames[primaryNeighborhood] ?? 'Nairobi';
  }

  String get lifeStageDisplay {
    const lifeStageNames = {
      'student': 'Student',
      'early_career': 'Early Career',
      'mid_career': 'Mid Career',
      'established': 'Established Professional',
      'entrepreneur': 'Entrepreneur',
      'creative': 'Creative/Freelancer',
      'in_transition': 'In Transition',
      'retired': 'Retired',
    };
    return lifeStageNames[lifeStage] ?? 'Not specified';
  }

  String get socialCircleDisplay {
    const socialCircleNames = {
      'arts_culture': 'Arts & Culture',
      'tech_innovation': 'Tech & Innovation',
      'business_finance': 'Business & Finance',
      'academia_research': 'Academia & Research',
      'health_wellness': 'Health & Wellness',
      'sports_fitness': 'Sports & Fitness',
      'ngo_social': 'NGO & Social Impact',
      'food_hospitality': 'Food & Hospitality',
      'fashion_lifestyle': 'Fashion & Lifestyle',
      'music_entertainment': 'Music & Entertainment',
    };
    return socialCircleNames[primarySocialCircle] ?? 'Not specified';
  }
}

class UserProfileUpdate {
  final String? bio;
  final String? headline;
  final String? primaryNeighborhood;
  final List<String>? secondaryNeighborhoods;
  final String? lifeStage;
  final String? primarySocialCircle;
  final List<String>? secondarySocialCircles;
  final List<String>? interests;
  final String? connectionFrequency;
  final String? profileVisibility;

  UserProfileUpdate({
    this.bio,
    this.headline,
    this.primaryNeighborhood,
    this.secondaryNeighborhoods,
    this.lifeStage,
    this.primarySocialCircle,
    this.secondarySocialCircles,
    this.interests,
    this.connectionFrequency,
    this.profileVisibility,
  });

  Map<String, dynamic> toJson() => {
    if (bio != null) 'bio': bio,
    if (headline != null) 'headline': headline,
    if (primaryNeighborhood != null) 'primary_neighborhood': primaryNeighborhood,
    if (secondaryNeighborhoods != null) 'secondary_neighborhoods': secondaryNeighborhoods,
    if (lifeStage != null) 'life_stage': lifeStage,
    if (primarySocialCircle != null) 'primary_social_circle': primarySocialCircle,
    if (secondarySocialCircles != null) 'secondary_social_circles': secondarySocialCircles,
    if (interests != null) 'interests': interests,
    if (connectionFrequency != null) 'connection_frequency': connectionFrequency,
    if (profileVisibility != null) 'profile_visibility': profileVisibility,
  };
}