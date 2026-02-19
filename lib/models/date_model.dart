class DateNight {
  final String id;
  final String title;
  final DateTime date;
  final String? location;
  final String? description;

  DateNight({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.description,
  });

  factory DateNight.fromJson(Map<String, dynamic> json) {
    return DateNight(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      description: json['description'],
    );
  }
}

class DateIdea {
  final String id;
  final String title;
  final String? description;
  final String category;

  DateIdea({
    required this.id,
    required this.title,
    this.description,
    required this.category,
  });

  factory DateIdea.fromJson(Map<String, dynamic> json) {
    return DateIdea(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
    );
  }
}
