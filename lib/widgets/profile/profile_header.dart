import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    required this.user,
    this.showBackButton = false,
    this.onBackPressed,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.primaryRed.withOpacity(0.8),
            AppConstants.primaryBeige,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with back button and edit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    IconButton(
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                      icon: PhosphorIcon(
                        PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                        color: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(width: 48),

                  if (onEditPressed != null)
                    IconButton(
                      onPressed: onEditPressed,
                      icon: PhosphorIcon(
                        PhosphorIcons.pencil(PhosphorIconsStyle.regular),
                        color: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Profile content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile image
                  Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.mainProfilePhoto != null && user.mainProfilePhoto!.isNotEmpty
                              ? Image.network(
                                  user.mainProfilePhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: PhosphorIcon(
                                          PhosphorIcons.user(PhosphorIconsStyle.fill),
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: PhosphorIcon(
                                      PhosphorIcons.user(PhosphorIconsStyle.fill),
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Verification badge
                      if (user.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppConstants.primaryRed, width: 2),
                            ),
                            child: PhosphorIcon(
                              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                              color: AppConstants.successGreen,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Name and headline
                  Column(
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      if (user.headline != null && user.headline!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.headline!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Location and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.neighborhoodDisplay,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick stats row
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          icon: PhosphorIcons.eye(PhosphorIconsStyle.regular),
                          value: '${user.profileViewsCount}',
                          label: 'Views',
                          context: context,
                        ),
                        _buildStatItem(
                          icon: PhosphorIcons.bookmark(PhosphorIconsStyle.regular),
                          value: '${user.profileSavesCount}',
                          label: 'Saves',
                          context: context,
                        ),
                        _buildStatItem(
                          icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                          value: '${user.profileCompletionPercentage}%',
                          label: 'Complete',
                          context: context,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Row(
          children: [
            PhosphorIcon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}
