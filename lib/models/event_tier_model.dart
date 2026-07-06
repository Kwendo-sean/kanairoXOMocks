class EventTier {
  final String id;
  final String name;
  final String description;
  final double price;
  final int maxQuantity;
  final int remaining;
  final List<String> benefits;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool isAvailableNow;

  EventTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.maxQuantity,
    required this.remaining,
    required this.benefits,
    this.availableFrom,
    this.availableUntil,
    required this.isAvailableNow,
  });

  factory EventTier.fromJson(Map<String, dynamic> json) {
    // Backend serializes price as a STRING ("2500.00") — parse both
    // string and numeric forms so tier prices don't collapse to 0.
    double parsePrice(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return EventTier(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      maxQuantity: parseInt(json['max_quantity']),
      remaining: parseInt(json['remaining']),
      benefits: List<String>.from(json['benefits'] ?? []),
      availableFrom: json['available_from'] != null ? DateTime.tryParse(json['available_from']) : null,
      availableUntil: json['available_until'] != null ? DateTime.tryParse(json['available_until']) : null,
      isAvailableNow: json['is_available_now'] ?? true,
    );
  }
}
