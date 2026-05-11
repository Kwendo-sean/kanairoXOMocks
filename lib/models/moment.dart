import 'package:kanairoxo/utils/constants.dart';

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

class LinkedEvent {
  final int id;
  final String title;
  final String? coverImageUrl;

  LinkedEvent({
    required this.id,
    required this.title,
    this.coverImageUrl,
  });

  factory LinkedEvent.fromJson(Map<String, dynamic> json) {
    return LinkedEvent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? json['name'] ?? '',
      coverImageUrl: json['cover_image'] ?? json['image_url'],
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
  
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final bool isSavedByMe;
  
  // Backwards compatibility getters
  int get likeCount => likesCount;
  int get commentCount => commentsCount;
  bool get isLiked => isLikedByMe;
  bool get isSaved => isSavedByMe;
  
  // Music fields
  final String? trackName;
  final String? trackArtist;
  final String? trackImageUrl;
  final String? trackPreviewUrl;
  
  // Linked Event
  final LinkedEvent? linkedEvent;

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
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    required this.isSavedByMe,
    this.trackName,
    this.trackArtist,
    this.trackImageUrl,
    this.trackPreviewUrl,
    this.linkedEvent,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  factory Moment.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    
    final rawImageUrl = 
        json['image_url'] 
        ?? json['image']
        ?? json['photo']
        ?? json['photo_url']
        ?? json['media_url']
        ?? json['file'];
    
    final rawUserPhoto = 
        userJson?['profile_photo_url'] 
        ?? userJson?['photo'] 
        ?? userJson?['avatar'] 
        ?? userJson?['profile_photo'];
    
    final userName = userJson?['full_name'] ?? userJson?['display_name'] ?? userJson?['username'] ?? json['author_name'] ?? 'User';

    LinkedEvent? linked;
    if (json['linked_event'] != null) {
      linked = LinkedEvent.fromJson(json['linked_event']);
    }

    return Moment(
      id: json['id']?.toString() ?? '',
      caption: json['caption'] ?? json['description'] ?? '',
      type: MomentTypeExtension.fromString(json['tag'] ?? json['category'] ?? json['type'] ?? 'vibe'),
      photoUrl: ApiConstants.fixMediaUrl(rawImageUrl?.toString()),
      date: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      userName: userName.toString(),
      userAvatarUrl: rawUserPhoto != null ? ApiConstants.fixMediaUrl(rawUserPhoto.toString()) : null,
      likesCount: json['likes_count'] ?? json['like_count'] ?? 0,
      commentsCount: json['comments_count'] ?? json['comment_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] ?? json['is_liked'] ?? false,
      isSavedByMe: json['is_saved_by_me'] ?? json['is_saved'] ?? false,
      location: json['location_name'] ?? json['location'],
      trackName: json['track_name'],
      trackArtist: json['track_artist'],
      trackImageUrl: json['track_image_url'],
      trackPreviewUrl: json['track_preview_url'] ?? json['song_preview_url'],
      linkedEvent: linked,
      eventName: linked?.title ?? json['event_name'],
    );
  }
}
