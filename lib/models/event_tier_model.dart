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
    return EventTier(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      maxQuantity: json['max_quantity'] ?? 0,
      remaining: json['remaining'] ?? 0,
      benefits: List<String>.from(json['benefits'] ?? []),
      availableFrom: json['available_from'] != null ? DateTime.tryParse(json['available_from']) : null,
      availableUntil: json['available_until'] != null ? DateTime.tryParse(json['available_until']) : null,
      isAvailableNow: json['is_available_now'] ?? true,
    );
  }
}
