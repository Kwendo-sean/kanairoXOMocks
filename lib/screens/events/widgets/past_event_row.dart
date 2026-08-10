import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Compact row for events that have already happened.
///
/// Past events used to render as full 120px hero cards, which gave them the
/// same visual weight as things you can still buy a ticket for. A thumbnail
/// row keeps them reachable without competing.
class PastEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool attended;
  final VoidCallback onTap;

  const PastEventRow({
    super.key,
    required this.event,
    required this.onTap,
    this.attended = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = textColor.withOpacity(0.5);

    final title = (event['title'] ?? 'Untitled').toString();
    final venue =
        (event['venue_name'] ?? event['neighborhood'] ?? '').toString();
    final cover = (event['cover_url'] ?? event['cover_image'] ?? '').toString();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 62,
              height: 62,
              child: cover.isNotEmpty
                  ? ColorFiltered(
                      // Desaturate slightly so past events read as past.
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.45, 0.45, 0.10, 0, 0,
                        0.45, 0.45, 0.10, 0, 0,
                        0.45, 0.45, 0.10, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: const Color(0xFFEDE5D8)),
                      ),
                    )
                  : Container(color: const Color(0xFFEDE5D8)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 3),
                Row(children: [
                  if (attended) ...[
                    const Icon(Icons.check_circle,
                        size: 12, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    const Text('You went',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50))),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11.5,
                            color: muted)),
                  ),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: muted),
        ]),
      ),
    );
  }
}
