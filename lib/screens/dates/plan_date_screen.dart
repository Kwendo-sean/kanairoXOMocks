import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/dates/date_categories.dart';
import 'package:kanairoxo/widgets/dates/date_idea_generator_card.dart';
import 'package:kanairoxo/widgets/dates/date_templates.dart';

class PlanDateScreen extends StatelessWidget {
  /// The venue card the user tapped, when they arrived from a "Book this
  /// date" CTA. Without it the screen opened generic, giving no sign the
  /// chosen venue had been carried across at all.
  final Map<String, dynamic>? preselectedVenue;

  const PlanDateScreen({super.key, this.preselectedVenue});

  @override
  Widget build(BuildContext context) {
    final venue = preselectedVenue;

    return Scaffold(
      appBar: AppBar(
        title: Text(venue == null ? 'Plan a Date' : 'Book this date'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            if (venue != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SelectedVenueCard(venue: venue),
              ),
              const SizedBox(height: 20),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DateIdeaGeneratorCard(),
            ),
            const SizedBox(height: 16),
            const DateCategories(),
            const DateTemplates(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Confirms which venue the user came in from, with its package and price.
class _SelectedVenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  const _SelectedVenueCard({required this.venue});

  static const _accent = Color(0xFF9B111E);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = textColor.withOpacity(0.55);

    final name = (venue['name'] ?? 'A venue').toString();
    final location = (venue['location'] ?? '').toString();
    final category = (venue['category'] ?? '').toString();
    final packageName = (venue['package_name'] ?? '').toString();
    final fromPrice = (venue['from_price'] ?? '').toString();
    final image = (venue['image_url'] ?? '').toString();

    final subtitle =
        [category, location].where((x) => x.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Row(children: [
        if (image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(width: 56, height: 56, color: const Color(0xFFEDE5D8)),
            ),
          )
        else
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: _accent, size: 24),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 12, color: muted)),
              ],
              if (packageName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                    fromPrice.isEmpty
                        ? packageName
                        : '$packageName · from ${_money(fromPrice)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _accent)),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  static String _money(String v) {
    final n = double.tryParse(v) ?? 0;
    return 'KSh ${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }
}
