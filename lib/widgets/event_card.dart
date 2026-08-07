import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import '../models/ticket_model.dart';
import 'package:kanairoxo/core/theme/app_icons.dart';

/// Small circular partner logo. Monogram fallback when no logo URL.
class _PartnerAvatar extends StatelessWidget {
  final Partner partner;
  const _PartnerAvatar({required this.partner});

  @override
  Widget build(BuildContext context) {
    const double size = 18;
    if (partner.logoUrl != null && partner.logoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: partner.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _monogram(size),
        ),
      );
    }
    return _monogram(size);
  }

  Widget _monogram(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B1E3F),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }
}

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

            // Layer 3b — display_status badge (top-center)
            if (event.statusBadgeLabel != null)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: event.statusBadgeColor ?? Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.statusBadgeLabel!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'DMSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
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
                      ? AppIcons.bookmarkFill
                      : AppIcons.bookmark,
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
                    // Partner row — logo avatar + name + verified tick.
                    // Falls back to a monogram circle when no logo is set.
                    if (event.partner != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PartnerAvatar(partner: event.partner!),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              event.partner!.name,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.partner!.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(AppIcons.verified,
                                color: Color(0xFFE0708C), size: 13),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
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
                          AppIcons.calendar,
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
                          AppIcons.location,
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
