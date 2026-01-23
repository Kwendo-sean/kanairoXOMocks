import 'package:flutter/foundation.dart';
import '../services/api_client.dart'; // Import ApiClient to access baseUrl

class User {
  final String? publicId;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? fullName;
  final bool isVerified;

  // Base profile fields
  final String? neighborhood;
  final String? occupation;
  final String? company;
  final String? bio;

  // Extended profile fields
  final String? headline;
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

  // Computed field for UI
  String get neighborhoodDisplay {
    final neighborhoodValue = primaryNeighborhood ?? neighborhood;
    if (neighborhoodValue != null && neighborhoodValue.isNotEmpty) {
      final mapping = {
        'westlands': 'Westlands',
        'kilimani': 'Kilimani/Kileleshwa',
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
        'other_nairobi': 'Other Nairobi Area',
        'outside_nairobi': 'Outside Nairobi',
      };
      return mapping[neighborhoodValue] ?? 'Nairobi';
    }
    return 'Nairobi';
  }

  User({
    this.publicId,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.displayName,
    this.fullName,
    this.isVerified = false,
    this.neighborhood,
    this.occupation,
    this.company,
    this.bio,
    this.headline,
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
  });

  factory User.fromJson(Map<String, dynamic> json) {

    // Helper to construct full URL from a relative path
    String? _constructFullUrl(String? path) {
      if (path == null || path.isEmpty || path.startsWith('http')) {
        return path;
      }
      final uri = Uri.parse(ApiClient.baseUrl);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      return '$baseUrl$path';
    }

    // Parse all photos and construct their full URLs
    List<Map<String, dynamic>> photos = (json['profile_photos'] ?? json['all_profile_photos'] ?? [])
        .whereType<Map>() // Allow Map<dynamic, dynamic>
        .map<Map<String, dynamic>>((photoMap) {
          final typedPhoto = Map<String, dynamic>.from(photoMap);
          return {
            ...typedPhoto,
            'url': _constructFullUrl(typedPhoto['url'] as String?),
          };
        }).toList();

    // Get the main photo URL from the root of the JSON
    String? mainPhotoUrl = _constructFullUrl(json['main_profile_photo'] as String?);

    // If the root main photo URL is null, find it from the list of all photos
    if (mainPhotoUrl == null || mainPhotoUrl.isEmpty) {
      try {
        final mainPhotoFromList = photos.firstWhere((p) => p['is_main'] == true);
        mainPhotoUrl = mainPhotoFromList['url'];
      } catch (e) {
        // No main photo found in the list, can leave it as null
      }
    }

    return User(
      publicId: json['public_id']?.toString() ?? 'KX000000',
      phoneNumber: json['phone_number']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      isVerified: json['is_verified'] == true,

      neighborhood: json['neighborhood']?.toString(),
      occupation: json['occupation']?.toString(),
      company: json['company']?.toString(),
      bio: json['bio']?.toString(),

      headline: json['headline']?.toString(),
      primaryNeighborhood: json['primary_neighborhood']?.toString(),
      lifeStage: json['life_stage']?.toString(),
      primarySocialCircle: json['primary_social_circle']?.toString(),
      interests: _parseList<String>(json['interests']),
      connectionFrequency: json['connection_frequency']?.toString() ?? 'regular',
      profileVisibility: json['profile_visibility']?.toString() ?? 'public',
      
      mainProfilePhoto: mainPhotoUrl, // Use the processed URL
      profilePhotos: photos, // Use the processed list

      profileCompletionPercentage: _parseInt(json['profile_completion_percentage']),
      profileViewsCount: _parseInt(json['profile_views_count']),
      profileSavesCount: _parseInt(json['profile_saves_count']),
      voiceIntro: json['voice_intro']?.toString(),
      voiceIntroStatus: json['voice_intro_status']?.toString(),
    );
  }

  static List<T> _parseList<T>(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return List<T>.from(value);
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  @override
  String toString() {
    return 'User{name: $fullName, publicId: $publicId, completion: $profileCompletionPercentage%}';
  }
}

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