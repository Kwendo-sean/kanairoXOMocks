import '../core/utils/url_helper.dart';

class Memory {
  final String id;
  final String title;
  final DateTime memoryDate;
  final String? description;
  final String? photo;
  final String? locationName;
  final String memoryType;
  final bool isFavorite;
  final int reactionCount;
  final int commentCount;
  final String? userReaction;

  Memory({
    required this.id,
    required this.title,
    required this.memoryDate,
    this.description,
    this.photo,
    this.locationName,
    required this.memoryType,
    this.isFavorite = false,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.userReaction,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      memoryDate: DateTime.tryParse(json['memory_date'] ?? '') ?? DateTime.now(),
      description: json['description'],
      photo: UrlHelper.fixMediaUrl(json['photo'] ?? json['image_url'] ?? json['image']),
      locationName: json['location_name'],
      memoryType: json['memory_type'] ?? 'vibe',
      isFavorite: json['is_favorite'] ?? false,
      reactionCount: json['reaction_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      userReaction: json['user_reaction'],
    );
  }

  String get day => memoryDate.day.toString();
  String get month {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[memoryDate.month - 1];
  }
}
