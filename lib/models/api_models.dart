class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String role;
  final bool isVerified;
  final DateTime dateJoined;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    required this.role,
    required this.isVerified,
    required this.dateJoined,
    this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      phoneNumber: json['phone_number'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      displayName: json['display_name'],
      role: json['role'] ?? 'standard',
      isVerified: json['is_verified'] ?? false,
      dateJoined: DateTime.parse(json['date_joined']),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
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
      'is_verified': isVerified,
      'date_joined': dateJoined.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (displayName != null) {
      return displayName!;
    }
    return phoneNumber;
  }
}

class UserProfile {
  final String? neighborhood;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? occupation;
  final String? company;
  final String? bio;
  final String? instagramHandle;
  final String? twitterHandle;
  final String? linkedinUrl;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;

  UserProfile({
    this.neighborhood,
    this.dateOfBirth,
    this.gender,
    this.occupation,
    this.company,
    this.bio,
    this.instagramHandle,
    this.twitterHandle,
    this.linkedinUrl,
    this.notificationsEnabled = true,
    this.emailNotifications = false,
    this.pushNotifications = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      neighborhood: json['neighborhood'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      occupation: json['occupation'],
      company: json['company'],
      bio: json['bio'],
      instagramHandle: json['instagram_handle'],
      twitterHandle: json['twitter_handle'],
      linkedinUrl: json['linkedin_url'],
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? false,
      pushNotifications: json['push_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'neighborhood': neighborhood,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'occupation': occupation,
      'company': company,
      'bio': bio,
      'instagram_handle': instagramHandle,
      'twitter_handle': twitterHandle,
      'linkedin_url': linkedinUrl,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
    };
  }
}