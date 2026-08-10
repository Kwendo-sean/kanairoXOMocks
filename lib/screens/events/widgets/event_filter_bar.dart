import 'package:flutter/material.dart';
import '../../../models/data_models.dart';
import '../../../models/event_filters.dart';

const _kAccent = Color(0xFF9B111E);

/// Airbnb-style category strip plus a row of one-tap quick filters.
///
/// Categories come from whatever the feed actually contains, so there's no
/// separate categories endpoint to keep in sync.
class EventFilterBar extends StatelessWidget {
  final List<ExperienceCategory> categories;
  final EventFilters filters;
  final ValueChanged<EventFilters> onChanged;
  final VoidCallback onOpenSheet;

  const EventFilterBar({
    super.key,
    required this.categories,
    required this.filters,
    required this.onChanged,
    required this.onOpenSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final mutedColor = textColor.withOpacity(0.5);
    final divider = textColor.withOpacity(0.08);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 68,
          child: Row(children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 22),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _CategoryItem(
                      icon: Icons.apps_rounded,
                      label: 'All',
                      selected: filters.categoryId == null,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () => onChanged(filters.copyWith(clearCategory: true)),
                    );
                  }
                  final c = categories[i - 1];
                  return _CategoryItem(
                    icon: _iconFor(c.icon, c.name),
                    label: c.name,
                    selected: filters.categoryId == c.id,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    onTap: () => onChanged(filters.categoryId == c.id
                        ? filters.copyWith(clearCategory: true)
                        : filters.copyWith(categoryId: c.id)),
                  );
                },
              ),
            ),
            // Filter sheet trigger, with a count badge when narrowed.
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: _FilterButton(
                count: filters.activeCount,
                textColor: textColor,
                onTap: onOpenSheet,
              ),
            ),
          ]),
        ),
        // Quick pills
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: QuickFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final q = QuickFilter.values[i];
              final on = filters.quick.contains(q);
              return GestureDetector(
                onTap: () {
                  final next = Set<QuickFilter>.from(filters.quick);
                  on ? next.remove(q) : next.add(q);
                  onChanged(filters.copyWith(quick: next));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? _kAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: on ? _kAccent : textColor.withOpacity(0.18)),
                  ),
                  child: Text(
                    q.label,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on ? Colors.white : textColor.withOpacity(0.75),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(height: 0.5, color: divider),
      ],
    );
  }

  /// Category icons come from the backend as loose slugs; fall back to
  /// matching on the name so a new category still gets something sensible.
  static IconData _iconFor(String slug, String name) {
    final key = '$slug ${name.toLowerCase()}';
    if (key.contains('music') || key.contains('concert') || key.contains('gig')) {
      return Icons.music_note_rounded;
    }
    if (key.contains('food') || key.contains('dining') || key.contains('drink')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('art') || key.contains('culture') || key.contains('gallery')) {
      return Icons.palette_outlined;
    }
    if (key.contains('night') || key.contains('party') || key.contains('club')) {
      return Icons.nightlife_rounded;
    }
    if (key.contains('sport') || key.contains('outdoor') || key.contains('hike')) {
      return Icons.terrain_rounded;
    }
    if (key.contains('wellness') || key.contains('yoga') || key.contains('fitness')) {
      return Icons.self_improvement_rounded;
    }
    if (key.contains('market') || key.contains('shop') || key.contains('bazaar')) {
      return Icons.storefront_outlined;
    }
    if (key.contains('film') || key.contains('cinema') || key.contains('movie')) {
      return Icons.movie_outlined;
    }
    if (key.contains('tech') || key.contains('talk') || key.contains('meetup')) {
      return Icons.mic_external_on_rounded;
    }
    return Icons.local_activity_outlined;
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _kAccent : mutedColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? textColor : mutedColor,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: selected ? 28 : 0,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final Color textColor;
  final VoidCallback onTap;

  const _FilterButton({
    required this.count,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, size: 17, color: textColor),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: _kAccent, shape: BoxShape.circle),
              child: Text('$count',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}
