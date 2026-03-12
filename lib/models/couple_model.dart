import 'package:kanairoxo/models/user_model.dart';

/// Represents a couple relationship between two users
class Couple {
  final String id;
  final User user1;
  final User user2;
  final String? coupleName;
  final DateTime? anniversaryDate;
  final String relationshipStage;
  final int dailyCheckinStreak;
  final int totalDates;
  final int totalMemories;
  final int totalAspirations;
  final int relationshipPulse;
  final DateTime? lastPulseUpdate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Couple({
    required this.id,
    required this.user1,
    required this.user2,
    this.coupleName,
    this.anniversaryDate,
    this.relationshipStage = 'dating',
    this.dailyCheckinStreak = 0,
    this.totalDates = 0,
    this.totalMemories = 0,
    this.totalAspirations = 0,
    this.relationshipPulse = 50,
    this.lastPulseUpdate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the partner for the current user
  User getPartner(String currentUserId) {
    return user1.id == currentUserId ? user2 : user1;
  }

  /// Check if a user is a member of this couple
  bool isMember(String userId) {
    return user1.id == userId || user2.id == userId;
  }

  factory Couple.fromJson(Map<String, dynamic> json) {
    // Manually add 'account_type' to ensure it's always set for couple users
    if (json['user1'] is Map<String, dynamic>) {
      json['user1']['account_type'] = 'couple';
    }
    if (json['user2'] is Map<String, dynamic>) {
      json['user2']['account_type'] = 'couple';
    }

    return Couple(
      id: json['id'].toString(),
      user1: User.fromJson(json['user1']),
      user2: User.fromJson(json['user2']),
      coupleName: json['couple_name'],
      anniversaryDate: json['anniversary_date'] != null
          ? DateTime.parse(json['anniversary_date'])
          : null,
      relationshipStage: json['relationship_stage'] ?? 'dating',
      dailyCheckinStreak: json['daily_checkin_streak'] ?? 0,
      totalDates: json['total_dates'] ?? 0,
      totalMemories: json['total_memories'] ?? 0,
      totalAspirations: json['total_aspirations'] ?? 0,
      relationshipPulse: json['relationship_pulse'] ?? 50,
      lastPulseUpdate: json['last_pulse_update'] != null
          ? DateTime.parse(json['last_pulse_update'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1': user1.toJson(),
      'user2': user2.toJson(),
      'couple_name': coupleName,
      'anniversary_date': anniversaryDate?.toIso8601String(),
      'relationship_stage': relationshipStage,
      'daily_checkin_streak': dailyCheckinStreak,
      'total_dates': totalDates,
      'total_memories': totalMemories,
      'total_aspirations': totalAspirations,
      'relationship_pulse': relationshipPulse,
      'last_pulse_update': lastPulseUpdate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Simplified couple status for auth state management
class CoupleStatus {
  final String coupleId;
  final User partner;
  final String? coupleName;
  final bool isActive;
  final String relationshipStage;

  CoupleStatus({
    required this.coupleId,
    required this.partner,
    this.coupleName,
    this.isActive = true,
    this.relationshipStage = 'dating',
  });

  factory CoupleStatus.fromJson(Map<String, dynamic> json) {
    // The API returns the full couple object with both users
    // We need to identify which one is the partner
    final currentUserId = json['current_user_id']?.toString();
    final user1Data = json['user1'];
    final user2Data = json['user2'];

    // Manually add 'account_type' before parsing
    if (user1Data is Map<String, dynamic>) {
      user1Data['account_type'] = 'couple';
    }
    if (user2Data is Map<String, dynamic>) {
      user2Data['account_type'] = 'couple';
    }

    User partner;
    if (currentUserId != null) {
      partner = user1Data['id'].toString() == currentUserId
          ? User.fromJson(user2Data)
          : User.fromJson(user1Data);
    } else {
      // Fallback: assume user2 is partner (shouldn't happen with proper API response)
      partner = User.fromJson(user2Data);
    }

    return CoupleStatus(
      coupleId: json['id'].toString(),
      partner: partner,
      coupleName: json['couple_name'],
      isActive: json['is_active'] ?? true,
      relationshipStage: json['relationship_stage'] ?? 'dating',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couple_id': coupleId,
      'partner': partner.toJson(),
      'couple_name': coupleName,
      'is_active': isActive,
      'relationship_stage': relationshipStage,
    };
  }
}

/// Connection request for partner linking
class ConnectionRequest {
  final String id;
  final User sender;
  final String receiverEmail;
  final String receiverName;
  final String invitationCode;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  ConnectionRequest({
    required this.id,
    required this.sender,
    required this.receiverEmail,
    required this.receiverName,
    required this.invitationCode,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      id: json['id'].toString(),
      sender: User.fromJson(json['sender']),
      receiverEmail: json['receiver_email'],
      receiverName: json['receiver_name'],
      invitationCode: json['invitation_code'],
      message: json['message'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'receiver_email': receiverEmail,
      'receiver_name': receiverName,
      'invitation_code': invitationCode,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }
}