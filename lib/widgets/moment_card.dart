import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';

class MomentCard extends StatelessWidget {
  final Moment moment;

  const MomentCard({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    // Get the image URL safely
    final imageUrl = moment.photoUrl;
    final hasValidImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 4, // Gives the card a consistent height
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        debugPrint('Moment image failed: $url | $error');
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                          ),
                        );
                      },
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade50,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppConstants.lightGray,
                      child: const Center(
                        child: Icon(Icons.photo, color: AppConstants.secondaryGray),
                      ),
                    ),
            ),
            // Top Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),
            // Bottom Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name (Top)
                    if (moment.eventName != null)
                      Text(
                        moment.eventName!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    const Spacer(),
                    // Date and Badge (Bottom)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(moment.date),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        _buildTypeBadge(),
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

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: moment.type == MomentType.event ? AppConstants.primaryRed : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        moment.type == MomentType.event ? 'Event' : 'Date',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
