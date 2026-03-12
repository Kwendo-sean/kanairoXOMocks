import 'package:flutter/material.dart';

enum MomentType { event, meetup, vibe, date }

class Moment {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final String eventName;
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
    required this.userAvatarUrl,
    required this.eventName,
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
}
