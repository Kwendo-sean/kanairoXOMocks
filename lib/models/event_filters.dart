import 'data_models.dart';

/// Quick-pill filters. These are the narrowings people reach for most, so
/// they get a one-tap row rather than living inside the filter sheet.
enum QuickFilter { tonight, thisWeekend, free, nearMe }

extension QuickFilterLabel on QuickFilter {
  String get label => switch (this) {
        QuickFilter.tonight => 'Tonight',
        QuickFilter.thisWeekend => 'This weekend',
        QuickFilter.free => 'Free',
        QuickFilter.nearMe => 'Near me',
      };
}

class EventFilters {
  final String? categoryId;
  final Set<QuickFilter> quick;
  final Set<String> neighborhoods;
  final double? maxPrice;
  final bool connectionsOnly;

  const EventFilters({
    this.categoryId,
    this.quick = const {},
    this.neighborhoods = const {},
    this.maxPrice,
    this.connectionsOnly = false,
  });

  /// Whether the screen should drop curated rails and show a flat result list.
  bool get isActive =>
      categoryId != null ||
      quick.isNotEmpty ||
      neighborhoods.isNotEmpty ||
      maxPrice != null ||
      connectionsOnly;

  /// Count of distinct narrowings, for the badge on the filter button.
  int get activeCount =>
      (categoryId != null ? 1 : 0) +
      quick.length +
      neighborhoods.length +
      (maxPrice != null ? 1 : 0) +
      (connectionsOnly ? 1 : 0);

  EventFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    Set<QuickFilter>? quick,
    Set<String>? neighborhoods,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? connectionsOnly,
  }) {
    return EventFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      quick: quick ?? this.quick,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      connectionsOnly: connectionsOnly ?? this.connectionsOnly,
    );
  }

  /// Human-readable summary shown above the results list.
  String summary(List<ExperienceCategory> categories) {
    final parts = <String>[];
    if (categoryId != null) {
      final match = categories.where((c) => c.id == categoryId);
      if (match.isNotEmpty) parts.add(match.first.name);
    }
    for (final q in quick) {
      parts.add(q.label);
    }
    parts.addAll(neighborhoods);
    if (maxPrice != null) parts.add('Under ${maxPrice!.round()}');
    if (connectionsOnly) parts.add('Connections going');
    return parts.join(' · ');
  }

  /// Apply every active narrowing to [events].
  List<Experience> apply(List<Experience> events) {
    final now = DateTime.now();
    return events.where((e) {
      if (categoryId != null && e.category?.id != categoryId) return false;

      if (quick.contains(QuickFilter.free) && e.basePrice > 0) return false;

      if (quick.contains(QuickFilter.tonight)) {
        final s = e.startDateTime;
        if (!(s.year == now.year && s.month == now.month && s.day == now.day)) {
          return false;
        }
      }

      if (quick.contains(QuickFilter.thisWeekend) && !_isThisWeekend(e.startDateTime, now)) {
        return false;
      }

      if (neighborhoods.isNotEmpty && !neighborhoods.contains(e.neighborhood)) {
        return false;
      }

      if (maxPrice != null && e.basePrice > maxPrice!) return false;

      if (connectionsOnly && e.connectionsGoingCount == 0) return false;

      return true;
    }).toList();
  }

  /// Saturday and Sunday of the current week — or the coming one if it's
  /// already past this weekend.
  static bool _isThisWeekend(DateTime when, DateTime now) {
    final daysUntilSat = (DateTime.saturday - now.weekday) % 7;
    final sat = DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilSat));
    final end = sat.add(const Duration(days: 2));
    return when.isAfter(sat.subtract(const Duration(seconds: 1))) && when.isBefore(end);
  }
}
