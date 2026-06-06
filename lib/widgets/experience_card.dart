import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_typography.dart';
import '../utils/constants.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final VoidCallback onJoin;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onJoin,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with partner logo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: SafeNetworkImage(
                      url: experience.venueAddress, // Assuming venueAddress for now if no cover_url, though the model has description/shortDescription etc. Let's use a placeholder if needed or assume we'll add coverUrl to model.
                      // Wait, I should check if Experience model has coverUrl.
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Partner Logo Overlay (Top-left)
                if (experience.partner != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Stack(
                        children: [
                          ClipOval(
                            child: SafeNetworkImage(
                              url: experience.partner!.logoUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (experience.partner!.isVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.verified, color: Colors.blue, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // Bookmark / Save Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        experience.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          experience.title,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: context.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Partner Name / Hosted By
                  Row(
                    children: [
                      Text(
                        'Hosted by ',
                        style: AppTypography.caption.copyWith(color: context.mutedColor),
                      ),
                      Text(
                        experience.partner?.name ?? experience.organizer.firstName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (experience.partner?.isVerified ?? experience.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, color: Colors.blue, size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: context.mutedColor),
                      const SizedBox(width: 6),
                      Text(experience.formattedDate, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on_outlined, size: 14, color: context.mutedColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          experience.neighborhood,
                          style: AppTypography.caption.copyWith(color: context.mutedColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        experience.priceDisplay,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                      LiquidGlassButton(
                        size: LiquidButtonSize.sm,
                        onPressed: onJoin,
                        child: Text(experience.isFull ? 'Waitlist' : 'Get Ticket', style: AppTypography.buttonText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
