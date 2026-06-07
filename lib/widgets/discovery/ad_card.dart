import 'package:flutter/material.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class AdCard extends StatelessWidget {
  final DiscoveryItem ad;
  final VoidCallback onNext;

  const AdCard({super.key, required this.ad, required this.onNext});

  Future<void> _handleCta(BuildContext context) async {
    final apiClient = ApiClient();
    try {
      final response = await apiClient.post('api/v1/ads/${ad.adId}/click/', {});
      final type = response['cta_type'];
      final url = response['cta_url'];
      final eventId = response['cta_event_id'];

      if (type == 'event' && eventId != null) {
        Navigator.pushNamed(context, '/event-detail', arguments: eventId);
      } else if (type == 'url' && url != null) {
        launchUrl(Uri.parse(url));
      } else if (type == 'subscribe') {
        Navigator.pushNamed(context, '/premium');
      } else if (type == 'partner' && url != null) {
        // Handle partner profile navigation
      }
    } catch (e) {
      debugPrint('Ad click error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(url: ad.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
            Positioned(
              top: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: const Text('Sponsored', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (ad.sponsor?.logoUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(ad.sponsor!.logoUrl!)),
                          ),
                        Text(ad.sponsoredByLabel ?? ad.sponsor?.name ?? 'Sponsored', 
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ad.title ?? '', style: AppTypography.displaySmall.copyWith(color: Colors.white, fontSize: 22)),
                    Text(ad.subtitle ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(ad.body ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: LiquidGlassButton(
                            onPressed: () => _handleCta(context),
                            child: Text(ad.ctaText ?? 'Learn More'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: onNext,
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
