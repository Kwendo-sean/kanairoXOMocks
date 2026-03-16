import 'package:flutter/material.dart';
import '../core/utils/url_helper.dart';

enum MomentType { event, meetup, vibe, date }

extension MomentTypeExtension on MomentType {
  String get value => toString().split('.').last;

  static MomentType fromString(String value) {
    return MomentType.values.firstWhere(
      (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => MomentType.vibe,
    );
  }
}

class Moment {
  final String id;
  final String userName;
  final String? userAvatarUrl;
  final String? eventName;
  final DateTime date;
  final MomentType type;
  final String photoUrl;
  final String caption;
  final String? location;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;

  Moment({
    required this.id,
    required this.userName,
    this.userAvatarUrl,
    this.eventName,
    required this.date,
    required this.type,
    required this.photoUrl,
    required this.caption,
    this.location,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  factory Moment.fromJson(Map<String, dynamic> json) {
    // Handle nested user object or potential root fields
    final userJson = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    
    // Image URL — handle variations
    final rawImageUrl = json['image_url'] ?? json['image'] ?? json['photo'] ?? json['photo_url'] ?? '';
    
    // User photo — handle variations
    final rawUserPhoto = userJson?['profile_photo_url'] ?? userJson?['photo'] ?? userJson?['avatar'] ?? userJson?['profile_photo'] ?? '';
    
    // Username — handle variations
    final userName = userJson?['full_name'] ?? userJson?['display_name'] ?? userJson?['username'] ?? json['author_name'] ?? 'User';

    return Moment(
      id: json['id']?.toString() ?? '',
      caption: json['caption'] ?? json['description'] ?? '',
      type: MomentTypeExtension.fromString(json['tag'] ?? json['category'] ?? json['type'] ?? 'vibe'),
      photoUrl: UrlHelper.fixMediaUrl(rawImageUrl.toString()),
      date: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      userName: userName.toString(),
      userAvatarUrl: UrlHelper.fixMediaUrl(rawUserPhoto.toString()),
      likeCount: json['likes_count'] ?? json['like_count'] ?? json['likes'] ?? 0,
      commentCount: json['comments_count'] ?? json['comment_count'] ?? json['comments'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      location: json['location_name'] ?? json['location'],
    );
  }
}
