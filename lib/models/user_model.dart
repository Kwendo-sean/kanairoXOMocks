import 'package:flutter/foundation.dart';
import 'package:kanairoxo/utils/constants.dart';

// ---------------------------------------------------------------------------
// Main User Model
// ---------------------------------------------------------------------------

enum AccountType { single, couple, searching, host }

class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String role;
  final String accountType; // 'single' | 'couple' | 'searching' | 'host'
  final bool isVerified;
  final DateTime dateJoined;
  final DateTime? lastActive;
  final UserProfile? profile;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    required this.role,
    this.accountType = 'single',
    required this.isVerified,
    required this.dateJoined,
    this.lastActive,
    this.profile,
  });

  bool get isCoupleAccount => accountType == 'couple';
  bool get isSingleAccount => accountType == 'single';
  bool get isSearchingAccount => accountType == 'searching';
  bool get isHostAccount => accountType == 'host';

  String get fullName {
    final fName = firstName ?? '';
    final lName = lastName ?? '';
    if (fName.isNotEmpty && lName.isNotEmpty) return '$fName $lName';
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return phoneNumber;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("User.fromJson received account_type: ${json['account_type']}");
    }
    
    // Safely determine account type, defaulting to 'single'
    final accountType = json['account_type']?.toString() ?? 'single';

    return User(
      id: json['public_id']?.toString() ?? json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      displayName: json['display_name']?.toString(),
      role: json['role']?.toString() ?? 'standard',
      accountType: accountType,
      isVerified: json['is_verified'] == true,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : DateTime.now(),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile'], accountType: accountType) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'role': role,
      'account_type': accountType,
      'is_verified': isVerified,
      'date_joined': dateJoined.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }
}

// ---------------------------------------------------------------------------
// User Profile Model (Nested inside User)
// ---------------------------------------------------------------------------

class UserProfile {
  final String? bio;
  final String? headline;
  final String? occupation;
  final String? company;
  final String? neighborhood;
  final String? primaryNeighborhood;
  final String? lifeStage;
  final String? primarySocialCircle;
  final List<String> interests;
  final String? connectionFrequency;
  final String? profileVisibility;
  final String? mainProfilePhoto;
  final List<Map<String, dynamic>> profilePhotos;
  final int profileCompletionPercentage;
  final int profileViewsCount;
  final int profileSavesCount;
  final String? voiceIntro;
  final String? voiceIntroStatus;
  final String? journalEntry; // Couple only
  final String? specialMessage; // Couple only

  String get neighborhoodDisplay {
    final value = primaryNeighborhood ?? neighborhood;
    if (value == null || value.isEmpty) return 'Nairobi';
    final mapping = {
      'westlands': 'Westlands',
      'kilimani': 'Kilimani/Kileleshwa',
      'lavington': 'Lavington',
      'karen': 'Karen',
      'langata': 'Langata',
      'nairobi_cbd': 'Nairobi CBD',
    };
    return mapping[value] ?? value;
  }

  UserProfile({
    this.bio,
    this.headline,
    this.occupation,
    this.company,
    this.neighborhood,
    this.primaryNeighborhood,
    this.lifeStage,
    this.primarySocialCircle,
    this.interests = const [],
    this.connectionFrequency,
    this.profileVisibility,
    this.mainProfilePhoto,
    this.profilePhotos = const [],
    this.profileCompletionPercentage = 0,
    this.profileViewsCount = 0,
    this.profileSavesCount = 0,
    this.voiceIntro,
    this.voiceIntroStatus,
    this.journalEntry,
    this.specialMessage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String accountType = 'single'}) {
    final profileData = json['profile'] ?? json;
    if (profileData is! Map<String, dynamic>) return UserProfile();

    String? _processUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      if (path.startsWith('http')) return path;
      final baseUrl = Uri.parse(ApiConstants.baseUrl);
      return baseUrl.resolve(path).toString();
    }

    List<Map<String, dynamic>> photos = (profileData['profile_photos'] ?? [])
        .whereType<Map>()
        .map<Map<String, dynamic>>((photoMap) {
          final typedPhoto = Map<String, dynamic>.from(photoMap);
          return {
            ...typedPhoto,
            'url': _processUrl(typedPhoto['url'] as String?),
          };
        }).toList();

    String? mainPhotoUrl = _processUrl(profileData['main_profile_photo'] as String?);
    if (mainPhotoUrl == null || mainPhotoUrl.isEmpty) {
      try {
        mainPhotoUrl = photos.firstWhere((p) => p['is_main'] == true)['url'];
      } catch (e) {
        // No main photo found
      }
    }
    
    return UserProfile(
      bio: profileData['bio']?.toString(),
      headline: profileData['headline']?.toString(),
      occupation: profileData['occupation']?.toString(),
      company: profileData['company']?.toString(),
      neighborhood: profileData['neighborhood']?.toString(),
      primaryNeighborhood: profileData['primary_neighborhood']?.toString(),
      lifeStage: profileData['life_stage']?.toString(),
      primarySocialCircle: profileData['primary_social_circle']?.toString(),
      interests: List<String>.from(profileData['interests'] ?? []),
      connectionFrequency: profileData['connection_frequency']?.toString(),
      profileVisibility: profileData['profile_visibility']?.toString(),
      mainProfilePhoto: mainPhotoUrl,
      profilePhotos: photos,
      profileCompletionPercentage: int.tryParse(profileData['profile_completion_percentage']?.toString() ?? '0') ?? 0,
      profileViewsCount: int.tryParse(profileData['profile_views_count']?.toString() ?? '0') ?? 0,
      profileSavesCount: int.tryParse(profileData['profile_saves_count']?.toString() ?? '0') ?? 0,
      voiceIntro: _processUrl(profileData['voice_intro'] as String?),
      voiceIntroStatus: profileData['voice_intro_status']?.toString(),
      // Conditionally parse couple-specific fields
      journalEntry: accountType == 'couple' ? profileData['journal_entry']?.toString() : null,
      specialMessage: accountType == 'couple' ? profileData['special_message']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'bio': bio,
      'headline': headline,
      'occupation': occupation,
      'company': company,
      'neighborhood': neighborhood,
      'primary_neighborhood': primaryNeighborhood,
      'life_stage': lifeStage,
      'primary_social_circle': primarySocialCircle,
      'interests': interests,
      'connection_frequency': connectionFrequency,
      'profile_visibility': profileVisibility,
      'main_profile_photo': mainProfilePhoto,
      'profile_photos': profilePhotos,
      'profile_completion_percentage': profileCompletionPercentage,
      'profile_views_count': profileViewsCount,
      'profile_saves_count': profileSavesCount,
      'voice_intro': voiceIntro,
      'voice_intro_status': voiceIntroStatus,
    };

    if (journalEntry != null) {
      json['journal_entry'] = journalEntry;
    }
    if (specialMessage != null) {
      json['special_message'] = specialMessage;
    }

    return json;
  }
}

// ---------------------------------------------------------------------------
// Data Transfer Object for Profile Updates
// ---------------------------------------------------------------------------

class UserProfileUpdate {
  final String? bio;
  final String? headline;
  final String? primaryNeighborhood;
  final String? lifeStage;
  final String? primarySocialCircle;
  final List<String>? interests;
  final String? connectionFrequency;
  final String? profileVisibility;

  UserProfileUpdate({
    this.bio,
    this.headline,
    this.primaryNeighborhood,
    this.lifeStage,
    this.primarySocialCircle,
    this.interests,
    this.connectionFrequency,
    this.profileVisibility,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (bio != null) map['bio'] = bio;
    if (headline != null) map['headline'] = headline;
    if (primaryNeighborhood != null) map['primary_neighborhood'] = primaryNeighborhood;
    if (lifeStage != null) map['life_stage'] = lifeStage;
    if (primarySocialCircle != null) map['primary_social_circle'] = primarySocialCircle;
    if (interests != null) map['interests'] = interests;
    if (connectionFrequency != null) map['connection_frequency'] = connectionFrequency;
    if (profileVisibility != null) map['profile_visibility'] = profileVisibility;
    return map;
  }
}
