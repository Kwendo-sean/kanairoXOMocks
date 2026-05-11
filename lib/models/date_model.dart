class DateNight {
  final String id;
  final String title;
  final DateTime date;
  final String? location;
  final String? description;
  final int? rating;
  final String? formattedDate;

  DateNight({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.description,
    this.rating,
    this.formattedDate,
  });

  factory DateNight.fromJson(Map<String, dynamic> json) {
    return DateNight(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      location: json['location'],
      description: json['description'],
      rating: json['rating'],
      formattedDate: json['formatted_date'],
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

class BucketListItem {
  final String id;
  final String title;
  final String category;
  final bool userACompleted;
  final bool userBCompleted;
  final String? completionPhoto;
  final bool completed;

  BucketListItem({
    required this.id,
    required this.title,
    required this.category,
    required this.userACompleted,
    required this.userBCompleted,
    this.completionPhoto,
    required this.completed,
  });

  factory BucketListItem.fromJson(Map<String, dynamic> json) {
    return BucketListItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      userACompleted: json['user_a_completed'] ?? false,
      userBCompleted: json['user_b_completed'] ?? false,
      completionPhoto: json['completion_photo'],
      completed: json['completed'] ?? false,
    );
  }
}

class SharedGoal {
  final String id;
  final String title;
  final String type;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final double progressPercent;

  SharedGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.progressPercent,
  });

  factory SharedGoal.fromJson(Map<String, dynamic> json) {
    return SharedGoal(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'personal',
      targetAmount: double.tryParse(json['target_amount']?.toString() ?? '0') ?? 0,
      currentAmount: double.tryParse(json['current_amount']?.toString() ?? '0') ?? 0,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      progressPercent: double.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
    );
  }
}
