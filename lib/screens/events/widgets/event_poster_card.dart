import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/data_models.dart';

const _kAccent = Color(0xFF9B111E);

/// Tall poster card used inside the curated horizontal rails.
///
/// Deliberately narrower and taller than the wide list card so a rail reads
/// as a different kind of content, not just the same list turned sideways.
class EventPosterCard extends StatelessWidget {
  final Experience event;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  const EventPosterCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = textColor.withOpacity(0.55);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 208,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 244,
                  width: 208,
                  child: (event.coverUrl?.isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: event.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: const Color(0xFFEDE5D8)),
                          errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFEDE5D8),
                              child: const Icon(Icons.image_outlined,
                                  color: Color(0xFFBBAA99))),
                        )
                      : Container(
                          color: const Color(0xFFEDE5D8),
                          child: const Icon(Icons.image_outlined,
                              color: Color(0xFFBBAA99))),
                ),
              ),
              // Save
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onSaveToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        event.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 21,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 5)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Urgency ribbon, only when genuinely scarce
              if (_urgency != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_urgency!,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ]),
            const SizedBox(height: 9),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: textColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${DateFormat('EEE, d MMM').format(event.startDateTime)} · ${event.neighborhood}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 11.5, color: muted),
            ),
            const SizedBox(height: 5),
            Row(children: [
              Text(
                event.basePrice <= 0 ? 'Free' : event.priceDisplay,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _kAccent),
              ),
              if (event.connectionsGoingCount > 0) ...[
                const Spacer(),
                ConnectionsGoing(
                  count: event.connectionsGoingCount,
                  avatars: event.connectionsGoingAvatars,
                  compact: true,
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  /// Only surface scarcity when it's real — a half-empty room shouldn't
  /// pretend otherwise.
  String? get _urgency {
    if (event.maxCapacity > 0) {
      final left = event.maxCapacity - event.currentAttendees;
      if (left > 0 && left <= 10) return '$left left';
    }
    final until = event.startDateTime.difference(DateTime.now());
    if (!until.isNegative && until.inHours < 24) {
      return until.inHours <= 1 ? 'Starting soon' : 'In ${until.inHours}h';
    }
    return null;
  }
}

/// Avatar stack + count. This is the thing a generic events list can't do —
/// it only means something because the app knows who you're connected to.
class ConnectionsGoing extends StatelessWidget {
  final int count;
  final List<String> avatars;
  final bool compact;

  const ConnectionsGoing({
    super.key,
    required this.count,
    required this.avatars,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? const Color(0xFF121212) : Colors.white;
    final shown = avatars.take(3).toList();
    final size = compact ? 17.0 : 20.0;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (shown.isNotEmpty)
        SizedBox(
          width: size + (shown.length - 1) * (size * 0.62),
          height: size,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (size * 0.62),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 1.5),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: shown[i],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: const Color(0xFFEDE5D8)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (shown.isNotEmpty) const SizedBox(width: 5),
      Text(
        compact ? '$count' : '$count going',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF6A6A6A),
        ),
      ),
    ]);
  }
}
