import '../utils/constants.dart';

class DateRequestModel {
  final String id;
  final UserSummary sender;
  final UserSummary receiver;
  final VenueSummary venue;
  final PackageSummary package;
  final String vibe;
  final int budget;
  final String status;
  final DateTime createdAt;
  final DateTime? preferredDate;
  final String? message;
  final String? paymentReference;

  DateRequestModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.venue,
    required this.package,
    required this.vibe,
    required this.budget,
    required this.status,
    required this.createdAt,
    this.preferredDate,
    this.message,
    this.paymentReference,
  });

  factory DateRequestModel.fromJson(Map<String, dynamic> json) {
    return DateRequestModel(
      id: json['id']?.toString() ?? '',
      sender: UserSummary.fromJson(json['sender'] is Map ? json['sender'] as Map<String, dynamic> : {}),
      receiver: UserSummary.fromJson(json['receiver'] is Map ? json['receiver'] as Map<String, dynamic> : {}),
      venue: VenueSummary.fromJson(json['venue'] is Map ? json['venue'] as Map<String, dynamic> : {}),
      package: PackageSummary.fromJson(json['package'] is Map ? json['package'] as Map<String, dynamic> : {}),
      vibe: json['vibe']?.toString() ?? 'cozy',
      budget: double.tryParse(json['budget']?.toString() ?? '0')?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      preferredDate: DateTime.tryParse(json['preferred_date']?.toString() ?? ''),
      message: json['message']?.toString(),
      paymentReference: json['payment_reference']?.toString(),
    );
  }

  DateRequestModel copyWith({String? status, String? paymentReference}) {
    return DateRequestModel(
      id: id,
      sender: sender,
      receiver: receiver,
      venue: venue,
      package: package,
      vibe: vibe,
      budget: budget,
      status: status ?? this.status,
      createdAt: createdAt,
      preferredDate: preferredDate,
      message: message,
      paymentReference: paymentReference ?? this.paymentReference,
    );
  }
}

class UserSummary {
  final String id;
  final String name;
  final String? photo;

  UserSummary({
    required this.id,
    required this.name,
    this.photo,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      photo: ApiConstants.fixMediaUrl(json['photo']?.toString() ?? json['photo_url']?.toString()),
    );
  }
}

class VenueSummary {
  final String id;
  final String name;
  final String neighborhood;
  final String? coverImage;

  VenueSummary({
    required this.id,
    required this.name,
    required this.neighborhood,
    this.coverImage,
  });

  factory VenueSummary.fromJson(Map<String, dynamic> json) {
    return VenueSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Venue',
      neighborhood: json['neighborhood']?.toString() ?? json['location']?.toString() ?? 'Nairobi',
      coverImage: ApiConstants.fixMediaUrl(json['cover_image']?.toString() ?? json['image_url']?.toString()),
    );
  }
}

class PackageSummary {
  final String id;
  final String name;
  final int price;

  PackageSummary({
    required this.id,
    required this.name,
    required this.price,
  });

  factory PackageSummary.fromJson(Map<String, dynamic> json) {
    return PackageSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Package',
      price: double.tryParse(json['price']?.toString() ?? '0')?.toInt() ?? 0,
    );
  }
}
