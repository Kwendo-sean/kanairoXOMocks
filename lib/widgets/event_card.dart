import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import '../models/ticket_model.dart';

class EventCard extends StatelessWidget {
  final Experience event;
  final VoidCallback? onTap;
  final Function(Experience)? onSaveToggle;
  final bool isBookmarked;
  final bool compact;
  final bool hasTicket;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onSaveToggle,
    this.isBookmarked = false,
    this.compact = false,
    this.hasTicket = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 — full bleed photo
            CachedNetworkImage(
              imageUrl: event.coverUrl ?? '',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFEDE5D8),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Color(0xFFBBAA99),
                    size: 40,
                  ),
                ),
              ),
            ),

            // Layer 2 — gradient overlay bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 3 — price chip or "Going" top-left
            Positioned(
              top: 14,
              left: 14,
              child: hasTicket
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "GOING",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'DMSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.priceDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),

            // Layer 4 — bookmark icon top-right
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
                color: Colors.white,
                iconSize: 22,
                onPressed: () => onSaveToggle?.call(event),
              ),
            ),

            // Layer 5 — event details bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white.withOpacity(0.8),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${DateFormat('EEE, d MMM').format(event.startDateTime)} · ${event.formattedTime}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontFamily: 'DMSans',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withOpacity(0.8),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${event.venueName} · ${event.neighborhood}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontFamily: 'DMSans',
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tappable InkWell overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
