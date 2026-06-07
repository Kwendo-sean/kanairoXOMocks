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

class MomentMedia {
  final String imageUrl;
  final String mediaType; // photo, video
  final int? durationMs;

  MomentMedia({required this.imageUrl, required this.mediaType, this.durationMs});

  factory MomentMedia.fromJson(Map<String, dynamic> json) {
    return MomentMedia(
      imageUrl: ApiConstants.fixMediaUrl(json['image_url'] ?? json['file']),
      mediaType: json['media_type'] ?? 'photo',
      durationMs: json['duration_ms'],
    );
  }
}

class Moment {
  final String id;
  final String userName;
  final String userId;
  final String? userAvatarUrl;
  final String? eventName;
  final DateTime date;
  final MomentType type;
  final String photoUrl; // URL to image or video file
  final String mediaType; // 'image' | 'video'
  final List<MomentMedia> gallery;
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
    required this.userId,
    this.userAvatarUrl,
    this.eventName,
    required this.date,
    required this.type,
    required this.photoUrl,
    this.mediaType = 'image',
    this.gallery = const [],
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

  Moment copyWith({
    String? id,
    String? userName,
    String? userId,
    String? userAvatarUrl,
    String? eventName,
    DateTime? date,
    MomentType? type,
    String? photoUrl,
    String? mediaType,
    List<MomentMedia>? gallery,
    String? caption,
    String? location,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    bool? isSavedByMe,
    String? trackName,
    String? trackArtist,
    String? trackImageUrl,
    String? trackPreviewUrl,
    LinkedEvent? linkedEvent,
  }) {
    return Moment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      eventName: eventName ?? this.eventName,
      date: date ?? this.date,
      type: type ?? this.type,
      photoUrl: photoUrl ?? this.photoUrl,
      mediaType: mediaType ?? this.mediaType,
      gallery: gallery ?? this.gallery,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      trackName: trackName ?? this.trackName,
      trackArtist: trackArtist ?? this.trackArtist,
      trackImageUrl: trackImageUrl ?? this.trackImageUrl,
      trackPreviewUrl: trackPreviewUrl ?? this.trackPreviewUrl,
      linkedEvent: linkedEvent ?? this.linkedEvent,
    );
  }

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
    final userId = userJson?['id']?.toString() ?? userJson?['public_id']?.toString() ?? json['author_id']?.toString() ?? '';

    LinkedEvent? linked;
    if (json['linked_event'] != null) {
      linked = LinkedEvent.fromJson(json['linked_event']);
    }

    final List<MomentMedia> gallery = (json['gallery'] as List? ?? [])
        .map((m) => MomentMedia.fromJson(m as Map<String, dynamic>))
        .toList();

    return Moment(
      id: json['id']?.toString() ?? '',
      userId: userId,
      caption: json['caption'] ?? json['description'] ?? '',
      type: MomentTypeExtension.fromString(json['tag'] ?? json['category'] ?? json['type'] ?? 'vibe'),
      photoUrl: ApiConstants.fixMediaUrl(rawImageUrl?.toString()),
      mediaType: (json['media_type'] ?? 'image').toString(),
      gallery: gallery,
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
