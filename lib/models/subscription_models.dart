class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final String interval; // monthly, quarterly, annual
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.interval,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '',
      interval: json['interval'] ?? '',
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

class UserSubscription {
  final bool isPremium;
  final Map<String, dynamic>? subscription;

  UserSubscription({required this.isPremium, this.subscription});

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      isPremium: json['is_premium'] ?? false,
      subscription: json['subscription'],
    );
  }
}
