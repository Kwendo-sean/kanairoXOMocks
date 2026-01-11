// lib/widgets/profile/profile_stats.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/user_model.dart';

class ProfileStats extends StatelessWidget {
  final User user;
  final bool showCompletionBar;

  const ProfileStats({
    super.key,
    required this.user,
    this.showCompletionBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile completion
          if (showCompletionBar) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${user.profileCompletionPercentage}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: user.profileCompletionPercentage >= 70
                        ? AppConstants.successGreen
                        : AppConstants.warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: user.profileCompletionPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                user.profileCompletionPercentage >= 70
                    ? AppConstants.successGreen
                    : AppConstants.warningOrange,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
          ],

          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildStatCard(
                icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                title: 'Neighborhood',
                value: user.neighborhoodDisplay,
                context: context,
              ),
              _buildStatCard(
                icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                title: 'Life Stage',
                value: user.lifeStageDisplay,
                context: context,
              ),
              _buildStatCard(
                icon: PhosphorIcons.users(PhosphorIconsStyle.regular),
                title: 'Social Circle',
                value: user.socialCircleDisplay,
                context: context,
              ),
              _buildStatCard(
                icon: PhosphorIcons.heart(PhosphorIconsStyle.regular),
                title: 'Visibility',
                value: user.profileVisibility == 'public' ? 'Public' : 'Private',
                context: context,
              ),
            ],
          ),

          // Trust score if available
          if (user.trustScore != null && user.trustScore! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryBeige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.shield(PhosphorIconsStyle.fill),
                    color: AppConstants.primaryRed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trust Score',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.secondaryGray,
                          ),
                        ),
                        Text(
                          '${user.trustScore}/100',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.trustScore! >= 70
                          ? AppConstants.successGreen.withOpacity(0.2)
                          : AppConstants.warningOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.trustScore! >= 70 ? 'High' : 'Medium',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: user.trustScore! >= 70
                            ? AppConstants.successGreen
                            : AppConstants.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              icon,
              color: AppConstants.primaryRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}