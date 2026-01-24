import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final int age;
  final String location;
  final String bio;
  final String mood;
  final String moodIcon;
  final String imageUrl;
  final List<String> interests;
  final List<String> lookingFor;

  const UserProfile({
    required this.name,
    required this.age,
    required this.location,
    required this.bio,
    required this.mood,
    required this.moodIcon,
    required this.imageUrl,
    this.interests = const [],
    this.lookingFor = const [],
  });
}

class Mood {
  final String name;
  final String icon;
  final bool isSelected;

  const Mood({
    required this.name,
    required this.icon,
    this.isSelected = false,
  });
}

class Experience {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final String? coverImage;
  final String venueName;
  final String venueAddress;
  final String neighborhood;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String timezone;
  final int maxCapacity;
  final int currentAttendees;
  final bool isFull;
  final String pricingTier;
  final double basePrice;
  final String currency;
  final String primaryMood;
  final List<String> secondaryMoods;
  final List<String> targetIntents;
  final double discoveryScore;
  final bool isFeatured;
  final bool isVerified;
  final String status;
  final String eventType;
  final ExperienceCategory? category;
  final List<ExperienceTag> tags;
  final ExperienceOrganizer organizer;
  final List<ExperienceCollaborator> collaborators;
  final List<ExperienceSchedule> schedule;
  final List<ExperiencePricingTier> pricingTiers;
  final Map<String, dynamic>? analytics;
  final int savesCount;
  final int sharesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Experience({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    this.coverImage,
    required this.venueName,
    required this.venueAddress,
    required this.neighborhood,
    required this.startDateTime,
    required this.endDateTime,
    required this.timezone,
    required this.maxCapacity,
    required this.currentAttendees,
    required this.isFull,
    required this.pricingTier,
    required this.basePrice,
    required this.currency,
    required this.primaryMood,
    required this.secondaryMoods,
    required this.targetIntents,
    required this.discoveryScore,
    required this.isFeatured,
    required this.isVerified,
    required this.status,
    required this.eventType,
    this.category,
    required this.tags,
    required this.organizer,
    required this.collaborators,
    required this.schedule,
    required this.pricingTiers,
    this.analytics,
    required this.savesCount,
    required this.sharesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      coverImage: json['cover_image'],
      venueName: json['venue_name'] ?? '',
      venueAddress: json['venue_address'] ?? '',
      neighborhood: json['neighborhood'] ?? 'other',
      startDateTime: DateTime.parse(json['start_datetime']),
      endDateTime: DateTime.parse(json['end_datetime']),
      timezone: json['timezone'] ?? 'Africa/Nairobi',
      maxCapacity: json['max_capacity'] ?? 0,
      currentAttendees: json['current_attendees'] ?? 0,
      isFull: json['is_full'] ?? false,
      pricingTier: json['pricing_tier'] ?? 'free',
      basePrice: double.tryParse(json['base_price'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'KES',
      primaryMood: json['primary_mood'] ?? 'social',
      secondaryMoods: List<String>.from(json['secondary_moods'] ?? []),
      targetIntents: List<String>.from(json['target_intents'] ?? []),
      discoveryScore: double.tryParse(json['discovery_score'].toString()) ?? 0.0,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      status: json['status'] ?? 'draft',
      eventType: json['event_type'] ?? 'community',
      category: json['category'] != null
          ? ExperienceCategory.fromJson(json['category'])
          : null,
      tags: json['tags'] != null
          ? List<ExperienceTag>.from(
              json['tags'].map((x) => ExperienceTag.fromJson(x)))
          : [],
      organizer: ExperienceOrganizer.fromJson(json['organizer'] ?? {}),
      collaborators: json['collaborators'] != null
          ? List<ExperienceCollaborator>.from(
              json['collaborators']
                  .map((x) => ExperienceCollaborator.fromJson(x)))
          : [],
      schedule: json['schedules'] != null
          ? List<ExperienceSchedule>.from(
              json['schedules'].map((x) => ExperienceSchedule.fromJson(x)))
          : [],
      pricingTiers: json['pricing_tiers'] != null
          ? List<ExperiencePricingTier>.from(
              json['pricing_tiers']
                  .map((x) => ExperiencePricingTier.fromJson(x)))
          : [],
      analytics: json['analytics'],
      savesCount: json['saves_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'short_description': shortDescription,
        'cover_image': coverImage,
        'venue_name': venueName,
        'venue_address': venueAddress,
        'neighborhood': neighborhood,
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
        'timezone': timezone,
        'max_capacity': maxCapacity,
        'current_attendees': currentAttendees,
        'is_full': isFull,
        'pricing_tier': pricingTier,
        'base_price': basePrice,
        'currency': currency,
        'primary_mood': primaryMood,
        'secondary_moods': secondaryMoods,
        'target_intents': targetIntents,
        'discovery_score': discoveryScore,
        'is_featured': isFeatured,
        'is_verified': isVerified,
        'status': status,
        'event_type': eventType,
        'category': category?.toJson(),
        'tags': tags.map((x) => x.toJson()).toList(),
        'organizer': organizer.toJson(),
        'collaborators': collaborators.map((x) => x.toJson()).toList(),
        'schedules': schedule.map((x) => x.toJson()).toList(),
        'pricing_tiers': pricingTiers.map((x) => x.toJson()).toList(),
        'saves_count': savesCount,
        'shares_count': sharesCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Experience copyWith({
    int? currentAttendees,
    bool? isFull,
  }) {
    return Experience(
      id: id,
      title: title,
      description: description,
      shortDescription: shortDescription,
      coverImage: coverImage,
      venueName: venueName,
      venueAddress: venueAddress,
      neighborhood: neighborhood,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      timezone: timezone,
      maxCapacity: maxCapacity,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      isFull: isFull ?? this.isFull,
      pricingTier: pricingTier,
      basePrice: basePrice,
      currency: currency,
      primaryMood: primaryMood,
      secondaryMoods: secondaryMoods,
      targetIntents: targetIntents,
      discoveryScore: discoveryScore,
      isFeatured: isFeatured,
      isVerified: isVerified,
      status: status,
      eventType: eventType,
      category: category,
      tags: tags,
      organizer: organizer,
      collaborators: collaborators,
      schedule: schedule,
      pricingTiers: pricingTiers,
      analytics: analytics,
      savesCount: savesCount,
      sharesCount: sharesCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get priceDisplay {
    switch (pricingTier) {
      case 'free':
        return 'Free';
      case 'donation':
        return 'Donation';
      default:
        return '$currency ${basePrice.toStringAsFixed(0)}';
    }
  }

  String get formattedDate {
    return '${startDateTime.day}/${startDateTime.month}/${startDateTime.year}';
  }

  String get formattedTime {
    return '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isUpcoming => startDateTime.isAfter(DateTime.now());

  bool get isOngoing =>
      startDateTime.isBefore(DateTime.now()) && endDateTime.isAfter(DateTime.now());

  int get ticketsAvailable => maxCapacity - currentAttendees;

  double get capacityPercentage =>
      maxCapacity > 0 ? (currentAttendees / maxCapacity) * 100 : 0;
}

class ExperienceCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  ExperienceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory ExperienceCategory.fromJson(Map<String, dynamic> json) {
    return ExperienceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'calendar',
      color: json['color'] ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
      };
}

class ExperienceTag {
  final String id;
  final String name;
  final String description;

  ExperienceTag({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ExperienceTag.fromJson(Map<String, dynamic> json) {
    return ExperienceTag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

class ExperienceOrganizer {
  final String id;
  final String firstName;
  final String? lastName;
  final String? profilePicture;
  final int trustScore;
  final String? bio;

  ExperienceOrganizer({
    required this.id,
    required this.firstName,
    this.lastName,
    this.profilePicture,
    required this.trustScore,
    this.bio,
  });

  factory ExperienceOrganizer.fromJson(Map<String, dynamic> json) {
    return ExperienceOrganizer(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePicture: json['profile_picture'],
      trustScore: json['trust_score'] ?? 0,
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'profile_picture': profilePicture,
        'trust_score': trustScore,
        'bio': bio,
      };
}

class ExperienceCollaborator {
  final String id;
  final String name;
  final String? title;
  final String? bio;
  final String? photo;
  final String collaboratorType;

  ExperienceCollaborator({
    required this.id,
    required this.name,
    this.title,
    this.bio,
    this.photo,
    required this.collaboratorType,
  });

  factory ExperienceCollaborator.fromJson(Map<String, dynamic> json) {
    return ExperienceCollaborator(
      id: json['id'] ?? '',
      name: json['display_name'] ?? json['external_name'] ?? '',
      title: json['external_title'],
      bio: json['external_bio'],
      photo: json['external_photo'],
      collaboratorType: json['collaborator_type'] ?? 'speaker',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': name,
        'external_title': title,
        'external_bio': bio,
        'external_photo': photo,
        'collaborator_type': collaboratorType,
      };
}

class ExperienceSchedule {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool isBreak;

  ExperienceSchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.isBreak,
  });

  factory ExperienceSchedule.fromJson(Map<String, dynamic> json) {
    return ExperienceSchedule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
      isBreak: json['is_break'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
        'is_break': isBreak,
      };
}

class ExperiencePricingTier {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int? maxQuantity;
  final int currentQuantity;
  final List<String> benefits;
  final bool isActive;
  final bool isAvailable;

  ExperiencePricingTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    this.maxQuantity,
    required this.currentQuantity,
    required this.benefits,
    required this.isActive,
    required this.isAvailable,
  });

  factory ExperiencePricingTier.fromJson(Map<String, dynamic> json) {
    return ExperiencePricingTier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'KES',
      maxQuantity: json['max_quantity'],
      currentQuantity: json['current_quantity'] ?? 0,
      benefits: List<String>.from(json['benefits'] ?? []),
      isActive: json['is_active'] ?? true,
      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'max_quantity': maxQuantity,
        'current_quantity': currentQuantity,
        'benefits': benefits,
        'is_active': isActive,
        'is_available': isAvailable,
      };

  int? get quantityRemaining =>
      maxQuantity != null ? maxQuantity! - currentQuantity : null;
}

class ExperienceAttendee {
  final String id;
  final String eventId;
  final String userId;
  final String status;
  final String paymentStatus;
  final double paidAmount;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int numberOfGuests;
  final int? rating;
  final String? review;
  final DateTime registrationDate;

  ExperienceAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.paidAmount,
    this.checkInTime,
    this.checkOutTime,
    required this.numberOfGuests,
    this.rating,
    this.review,
    required this.registrationDate,
  });

  factory ExperienceAttendee.fromJson(Map<String, dynamic> json) {
    return ExperienceAttendee(
      id: json['id'] ?? '',
      eventId: json['event'] ?? '',
      userId: json['user'] ?? '',
      status: json['status'] ?? 'registered',
      paymentStatus: json['payment_status'] ?? 'pending',
      paidAmount: double.tryParse(json['paid_amount'].toString()) ?? 0.0,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      numberOfGuests: json['number_of_guests'] ?? 0,
      rating: json['rating'],
      review: json['review'],
      registrationDate: DateTime.parse(json['registration_date']),
    );
  }
}

class ExperienceWaitlist {
  final String id;
  final String eventId;
  final String userId;
  final int position;
  final DateTime joinedAt;
  final DateTime? notifiedAt;
  final DateTime? expiresAt;

  ExperienceWaitlist({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.position,
    required this.joinedAt,
    this.notifiedAt,
    this.expiresAt,
  });

  factory ExperienceWaitlist.fromJson(Map<String, dynamic> json) {
    return ExperienceWaitlist(
      id: json['id'] ?? '',
      eventId: json['event'] ?? '',
      userId: json['user'] ?? '',
      position: json['position'] ?? 0,
      joinedAt: DateTime.parse(json['joined_at']),
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
}

// Sample data for the prototype
final sampleProfiles = [
  const UserProfile(
    name: 'Sofia',
    age: 28,
    location: 'Brooklyn, NY',
    bio:
        'Looking for people who appreciate quiet mornings, good design, and conversations that matter.',
    mood: 'Calm',
    moodIcon: 'coffee',
    imageUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=500&fit=crop',
  ),
  const UserProfile(
    name: 'Marcus',
    age: 31,
    location: 'Manhattan, NY',
    bio:
        'Architect by day, jazz enthusiast by night. I believe the best conversations happen over good food and even better questions.',
    mood: 'Reflective',
    moodIcon: 'building',
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h-500&fit=crop',
    interests: [
      'Architecture',
      'Jazz',
      'Photography',
      'Cooking',
      'Philosophy'
    ],
    lookingFor: ['Friends', 'Community'],
  ),
];

final sampleMoods = [
  const Mood(name: 'Energetic', icon: 'bolt'),
  const Mood(name: 'Reflective', icon: 'brain'),
  const Mood(name: 'Adventurous', icon: 'compass'),
  const Mood(name: 'Calm', icon: 'waves'),
  const Mood(name: 'Curious', icon: 'eye'),
  const Mood(name: 'Creative', icon: 'paint-brush'),
];
