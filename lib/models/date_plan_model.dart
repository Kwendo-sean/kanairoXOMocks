import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DatePlan {
  String? id;
  String? personId;
  String? personName;
  String? personPhoto;
  DateTime? preferredDate;
  String? message;
  String? vibe;
  Venue? selectedVenue;
  DatePackage? selectedPackage;
  double budget;
  
  DatePlan({
    this.id,
    this.personId,
    this.personName,
    this.personPhoto,
    this.preferredDate,
    this.message,
    this.vibe,
    this.selectedVenue,
    this.selectedPackage,
    this.budget = 5000,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': personId,
      'venue_id': selectedVenue?.id,
      'package_id': selectedPackage?.id,
      'vibe': vibe?.toLowerCase(),
      'budget': budget.toInt(),
      'preferred_date': preferredDate?.toIso8601String(),
      'message': message ?? '',
    };
  }
}

class Venue {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String location;
  final String priceRange;
  final String category;
  final String? neighborhood;

  Venue({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.location,
    required this.priceRange,
    required this.category,
    this.neighborhood,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Venue',
      imageUrl: ApiConstants.fixMediaUrl(json['image_url'] ?? json['photo_url']),
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      location: json['location'] ?? json['neighborhood'] ?? 'Nairobi',
      neighborhood: json['neighborhood'] ?? json['location'] ?? 'Nairobi',
      priceRange: json['price_range'] ?? r'$$',
      category: json['category'] ?? json['cuisine'] ?? 'Restaurant',
    );
  }
}

class DatePackage {
  final String id;
  final String name;
  final String description;
  final double price;

  DatePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory DatePackage.fromJson(Map<String, dynamic> json) {
    return DatePackage(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DateConfig {
  final double commissionRate;
  final double reservationFee;

  DateConfig({
    required this.commissionRate,
    required this.reservationFee,
  });

  factory DateConfig.fromJson(Map<String, dynamic> json) {
    return DateConfig(
      commissionRate: double.tryParse(json['commission_rate']?.toString() ?? '0.1') ?? 0.1,
      reservationFee: double.tryParse(json['reservation_fee']?.toString() ?? '500') ?? 500.0,
    );
  }
}

class DateConnection {
  final String id;
  final String name;
  final String? photoUrl;
  final String? neighborhood;
  final String? lastActive;

  DateConnection({
    required this.id, 
    required this.name, 
    this.photoUrl,
    this.neighborhood,
    this.lastActive,
  });

  factory DateConnection.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    String find(Map<String, dynamic> map, List<String> keys) {
      for (var key in keys) {
        if (map[key] != null && map[key].toString().trim().isNotEmpty) {
          return map[key].toString().trim();
        }
      }
      return '';
    }

    Map<String, dynamic> userData = json;
    
    if (json['other_user'] is Map<String, dynamic>) {
      userData = json['other_user'];
    } else if (currentUserId != null) {
      if (json['initiator_details'] is Map<String, dynamic> && 
          (json['initiator']?.toString() != currentUserId)) {
        userData = json['initiator_details'];
      } else if (json['receiver_details'] is Map<String, dynamic> && 
                 (json['receiver']?.toString() != currentUserId)) {
        userData = json['receiver_details'];
      }
    }
    
    if (userData == json) {
      const userKeys = [
        'other_user', 
        'initiator_details', 
        'receiver_details', 
        'user', 
        'profile', 
        'connection_user'
      ];
      for (var key in userKeys) {
        if (json[key] is Map<String, dynamic>) {
          userData = json[key];
          break;
        }
      }
    }

    Map<String, dynamic> profileData = userData['profile'] is Map<String, dynamic> ? userData['profile'] : {};
    
    String name = find(userData, ['full_name', 'name', 'display_name', 'initiator_name', 'username']);
    
    if (name.isEmpty) {
      String first = find(userData, ['first_name']);
      String last = find(userData, ['last_name']);
      if (first.isNotEmpty || last.isNotEmpty) {
        name = '$first $last'.trim();
      }
    }
    
    if (name.isEmpty && profileData.isNotEmpty) {
      name = find(profileData, ['full_name', 'name', 'display_name']);
    }

    String? photo = find(userData, [
      'main_profile_photo_url', 
      'photo_url', 
      'avatar_url', 
      'profile_photo', 
      'main_profile_photo',
      'photo',
      'image'
    ]);
    if ((photo == null || photo.isEmpty) && profileData.isNotEmpty) {
      photo = find(profileData, ['main_profile_photo', 'photo_url', 'url']);
    }

    String id = userData['public_id']?.toString() ?? 
                userData['id']?.toString() ?? 
                json['id']?.toString() ?? '';
    
    return DateConnection(
      id: id,
      name: name.isEmpty ? 'User' : name,
      photoUrl: ApiConstants.fixMediaUrl(photo),
      neighborhood: userData['neighborhood'] ?? profileData['neighborhood'] ?? 'Nairobi',
      lastActive: 'Active recently',
    );
  }
}

class DateReceipt {
  final String reference;
  final String status;
  final double amount;
  final DateTime createdAt;

  DateReceipt({required this.reference, required this.status, required this.amount, required this.createdAt});

  factory DateReceipt.fromJson(Map<String, dynamic> json) {
    return DateReceipt(
      reference: json['reference'] ?? json['receipt_no'] ?? json['id']?.toString() ?? 'REF-XXXX',
      status: json['status'] ?? 'completed',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
