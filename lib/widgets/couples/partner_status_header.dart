import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/safe_network_image.dart';

class PartnerStatusHeader extends StatelessWidget {
  final String partnerName;
  final String? partnerPhoto;
  final String mood;
  final String moodEmoji;
  final String statusText;
  final bool isOnline;

  const PartnerStatusHeader({
    super.key,
    required this.partnerName,
    this.partnerPhoto,
    required this.mood,
    required this.moodEmoji,
    required this.statusText,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SafeNetworkImage(
                    url: partnerPhoto,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      partnerName,
                      style: AppTypography.displayMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            mood,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? const Color(0xFF9A8F85) : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static PartnerStatusHeader sample(BuildContext context) {
    return const PartnerStatusHeader(
      partnerName: 'Sarah',
      mood: 'Happy',
      moodEmoji: '',
      statusText: 'At GTC Mall • 20m ago',
      isOnline: true,
    );
  }

  static PartnerStatusHeader sampleOffline(BuildContext context) {
    return const PartnerStatusHeader(
      partnerName: 'Sarah',
      mood: 'Resting',
      moodEmoji: '',
      statusText: 'Last seen 2h ago',
      isOnline: false,
    );
  }
}
