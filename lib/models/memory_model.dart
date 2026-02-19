class Memory {
  final String id;
  final String title;
  final String date;
  final String? description;
  final List<String> images;

  Memory({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    required this.images,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      description: json['description'],
      images: List<String>.from(json['images']),
    );
  }
}
