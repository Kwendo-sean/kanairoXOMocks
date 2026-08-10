import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/widgets/skeletons.dart';
import 'package:kanairoxo/screens/events/event_detail_screen.dart';
import 'package:kanairoxo/screens/dates/plan_date_screen.dart';

/// TikTok-style vertical PageView mixing event trailers and date venues.
class EventsFeedTab extends StatefulWidget {
  const EventsFeedTab({super.key});

  @override
  State<EventsFeedTab> createState() => _EventsFeedTabState();
}

class _EventsFeedTabState extends State<EventsFeedTab> with AutomaticKeepAliveClientMixin {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const _accent = Color(0xFF9B111E);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('api/v1/events/discover-feed/');
      final List items = (res is Map ? (res['items'] ?? []) : []) as List;
      if (mounted) setState(() {
        // Trailers and bookable date venues only — event memories are not
        // part of the For You feed.
        _items = items
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => m['type'] == 'trailer' || m['type'] == 'venue')
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return Skeleton.reel(context);
    if (_items.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.movie_outlined, size: 56, color: _accent),
          SizedBox(height: 12),
          Text('Nothing in the feed yet',
            style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 16)),
          SizedBox(height: 4),
          Text('Event trailers and date spots show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DMSans', color: Colors.grey, fontSize: 12)),
        ]),
      ));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _load,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        itemBuilder: (_, i) => _itemCard(_items[i], i),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item, int index) {
    final card = Map<String, dynamic>.from(item['card'] ?? {});
    // Memories are filtered out upstream, so the feed is trailers and date
    // venues only — there is no _memoryCard branch to fall through to.
    if (item['type'] == 'venue') return _venueCard(card, index);
    return _trailerCard(card, index);
  }

  Widget _trailerCard(Map<String, dynamic> c, int index) {
    final trailer = (c['trailer_url'] ?? '').toString();
    final title = (c['title'] ?? 'Untitled event').toString();
    final venue = (c['venue_name'] ?? '').toString();
    final eventId = c['id']?.toString();

    return Stack(fit: StackFit.expand, children: [
      // Full-bleed background — trailer if any, else cover
      if (trailer.isNotEmpty)
        NetworkMediaPreview(
          url: trailer, mediaType: 'video',
          fit: BoxFit.cover, autoPlay: index < 2, muted: false)
      else if ((c['cover_url'] ?? '').toString().isNotEmpty)
        NetworkMediaPreview(
          url: c['cover_url'], mediaType: 'image', fit: BoxFit.cover)
      else
        Container(color: Colors.black),

      // Gradient overlay
      DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)]))),

      // Title + venue sit above the CTA so the thumb-zone button has space.
      Positioned(left: 20, right: 20, bottom: 205, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(4)),
            child: const Text('TRAILER',
              style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.4))),
          const SizedBox(height: 10),
          Text(title,
            style: const TextStyle(fontFamily: 'DMSans', color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 22),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if (venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(venue,
              style: const TextStyle(color: Colors.white70, fontFamily: 'DMSans', fontSize: 13)),
          ],
        ])),

      // Primary CTA: full-width pill right above the floating nav so it sits
      // squarely in the thumb-zone, easy to tap one-handed.
      Positioned(left: 20, right: 20, bottom: 135,
        child: GestureDetector(
          onTap: () {
            if (eventId != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: eventId)));
            }
          },
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(
                color: _accent.withOpacity(0.45),
                blurRadius: 24, offset: const Offset(0, 6))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Get tickets',
                style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        )),
    ]);
  }


  /// Date venues in the same feed as event trailers. The server only sends
  /// venues that have both a trailer and a bookable package, so this card
  /// never has to handle "nothing to play" or "nothing to book".
  Widget _venueCard(Map<String, dynamic> c, int index) {
    final trailer = (c['trailer_url'] ?? '').toString();
    final name = (c['name'] ?? 'A venue').toString();
    final location = (c['location'] ?? '').toString();
    final category = (c['category'] ?? '').toString();
    final fromPrice = (c['from_price'] ?? '').toString();
    final packageName = (c['package_name'] ?? '').toString();

    String money(String v) {
      final n = double.tryParse(v) ?? 0;
      return 'KSh ${n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    }

    return Stack(fit: StackFit.expand, children: [
      if (trailer.isNotEmpty)
        NetworkMediaPreview(
          url: trailer, mediaType: 'video',
          fit: BoxFit.cover, autoPlay: index < 2, muted: false)
      else if ((c['image_url'] ?? '').toString().isNotEmpty)
        NetworkMediaPreview(
          url: c['image_url'], mediaType: 'image', fit: BoxFit.cover)
      else
        Container(color: Colors.black),

      DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)]))),

      Positioned(left: 20, right: 20, bottom: 170, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accent, borderRadius: BorderRadius.circular(4)),
            child: const Text('DATE SPOT',
              style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.4))),
          const SizedBox(height: 10),
          Text(name,
            style: const TextStyle(fontFamily: 'DMSans', color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 22),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text([category, location].where((x) => x.isNotEmpty).join(' · '),
            style: const TextStyle(
              color: Colors.white70, fontFamily: 'DMSans', fontSize: 13)),
          if (packageName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('$packageName · from ${money(fromPrice)}',
              style: const TextStyle(
                color: Colors.white, fontFamily: 'DMSans', fontSize: 13,
                fontWeight: FontWeight.w600)),
          ],
        ])),

      Positioned(left: 20, right: 20, bottom: 100,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PlanDateScreen(preselectedVenue: c))),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(
                color: _accent.withOpacity(0.45),
                blurRadius: 24, offset: const Offset(0, 6))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Book this date',
                style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        )),
    ]);
  }

  Widget _memoryCard(Map<String, dynamic> c, int index) {
    final media = (c['media_url'] ?? '').toString();
    final mediaType = (c['media_type'] ?? 'image').toString();
    final caption = (c['caption'] ?? '').toString();
    final name = (c['creator_name'] ?? '').toString();
    final eventTitle = (c['event_title'] ?? '').toString();
    final eventId = c['event_id']?.toString();

    return Stack(fit: StackFit.expand, children: [
      if (media.isNotEmpty)
        NetworkMediaPreview(url: media, mediaType: mediaType,
          fit: BoxFit.cover, autoPlay: mediaType == 'video' && index < 2)
      else
        Container(color: Colors.black),

      DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),

      Positioned(left: 20, right: 20, bottom: 110, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(4)),
            child: Text('MEMORY · from $eventTitle'.toUpperCase(),
              style: const TextStyle(fontFamily: 'DMSans', color: _accent,
                fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.4),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 10),
          if (caption.isNotEmpty)
            Text(caption,
              style: const TextStyle(fontFamily: 'DMSans', color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('— $name',
            style: const TextStyle(fontFamily: 'DMSans',
              color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12)),
          if (eventId != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: eventId))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white70)),
                child: const Text('Open event',
                  style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13))),
            ),
          ],
        ])),
    ]);
  }
}
