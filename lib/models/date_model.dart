class DateNight {
  final String id;
  final String title;
  final DateTime date;
  final String? location;
  final String? description;
  final int? rating;

  DateNight({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.description,
    this.rating,
  });

  factory DateNight.fromJson(Map<String, dynamic> json) {
    return DateNight(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      location: json['location'],
      description: json['description'],
      rating: json['rating'],
    );
  }
}

class DateIdea {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? couple;
  final bool isCustom;

  DateIdea({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.couple,
    this.isCustom = false,
  });

  factory DateIdea.fromJson(Map<String, dynamic> json) {
    return DateIdea(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      couple: json['couple']?.toString(),
      isCustom: json['is_custom'] ?? false,
    );
  }
}
