class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? location;
  final String? profileImageUrl;
  final String gender;
  final String? interestedIn;
  final bool isVerified;
  final DateTime createdAt;
  final List<String> interests;
  final String? currentMood;
  final bool isOnline;
  final DateTime? lastSeen;
  final Map<String, dynamic>? preferences;
  
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.dateOfBirth,
    this.bio,
    this.location,
    this.profileImageUrl,
    required this.gender,
    this.interestedIn,
    this.isVerified = false,
    required this.createdAt,
    this.interests = const [],
    this.currentMood,
    this.isOnline = false,
    this.lastSeen,
    this.preferences,
  });
  
  String get fullName => '$firstName $lastName';
  
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'interestedIn': interestedIn,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'interests': interests,
      'currentMood': currentMood,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'preferences': preferences,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      bio: json['bio'],
      location: json['location'],
      profileImageUrl: json['profileImageUrl'],
      gender: json['gender'],
      interestedIn: json['interestedIn'],
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      interests: List<String>.from(json['interests'] ?? []),
      currentMood: json['currentMood'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
      preferences: json['preferences'],
    );
  }
}

class UserPreferences {
  final bool showOnlineStatus;
  final bool allowNotifications;
  final String themeMode; // 'light', 'dark', 'system'
  final bool enableDisappearingMessages;
  final int disappearingMessageDuration; // in hours
  final bool enableStory;
  final int storyDuration; // in hours
  final List<String> blockedUsers;
  final bool showAge;
  final bool showDistance;
  
  const UserPreferences({
    this.showOnlineStatus = true,
    this.allowNotifications = true,
    this.themeMode = 'system',
    this.enableDisappearingMessages = true,
    this.disappearingMessageDuration = 48,
    this.enableStory = true,
    this.storyDuration = 12,
    this.blockedUsers = const [],
    this.showAge = true,
    this.showDistance = true,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'showOnlineStatus': showOnlineStatus,
      'allowNotifications': allowNotifications,
      'themeMode': themeMode,
      'enableDisappearingMessages': enableDisappearingMessages,
      'disappearingMessageDuration': disappearingMessageDuration,
      'enableStory': enableStory,
      'storyDuration': storyDuration,
      'blockedUsers': blockedUsers,
      'showAge': showAge,
      'showDistance': showDistance,
    };
  }
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      allowNotifications: json['allowNotifications'] ?? true,
      themeMode: json['themeMode'] ?? 'system',
      enableDisappearingMessages: json['enableDisappearingMessages'] ?? true,
      disappearingMessageDuration: json['disappearingMessageDuration'] ?? 48,
      enableStory: json['enableStory'] ?? true,
      storyDuration: json['storyDuration'] ?? 12,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      showAge: json['showAge'] ?? true,
      showDistance: json['showDistance'] ?? true,
    );
  }
}