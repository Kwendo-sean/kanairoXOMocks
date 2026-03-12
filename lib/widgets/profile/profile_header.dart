import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/profile/photo_upload_screen.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onLogoutPressed;

  const ProfileHeader({
    super.key,
    required this.user,
    this.showBackButton = false,
    this.onBackPressed,
    this.onEditPressed,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.profile;
    if (profile == null) return const SizedBox.shrink(); // or a placeholder

    // Helper to construct the full URL for a given path.
    String? getFullImageUrl(String? path) {
      if (path == null || path.isEmpty || path.startsWith('http')) {
        return path;
      }
      final baseUrl = ApiConstants.baseUrl;
      if (baseUrl.endsWith('/')) {
        return baseUrl + (path.startsWith('/') ? path.substring(1) : path);
      }
      return '$baseUrl/' + (path.startsWith('/') ? path.substring(1) : path);
    }

    final fullPhotoUrl = getFullImageUrl(profile.mainProfilePhoto);

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

                  Row(
                    children: [
                      if (onEditPressed != null)
                        IconButton(
                          onPressed: onEditPressed,
                          icon: PhosphorIcon(
                            PhosphorIcons.pencil(PhosphorIconsStyle.regular),
                            color: Colors.white,
                          ),
                        ),
                      if (onLogoutPressed != null)
                        IconButton(
                          onPressed: onLogoutPressed,
                          icon: PhosphorIcon(
                            PhosphorIcons.signOut(PhosphorIconsStyle.regular),
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile image
            Stack(
              alignment: Alignment.bottomRight,
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
                    child: fullPhotoUrl != null && fullPhotoUrl.isNotEmpty
                        ? Image.network(
                            fullPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading profile image: $error"); // Debug print
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

                // Edit/Add photo button
                if (onEditPressed != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PhotoUploadScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        fullPhotoUrl != null && fullPhotoUrl.isNotEmpty
                          ? PhosphorIcons.pencil(PhosphorIconsStyle.fill)
                          : PhosphorIcons.plus(PhosphorIconsStyle.fill),
                        color: Colors.white,
                        size: 20,
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
                  user.fullName ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                if (profile.headline != null && profile.headline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.headline!,
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
                      profile.neighborhoodDisplay,
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
                    value: '${profile.profileViewsCount}',
                    label: 'Views',
                    context: context,
                  ),
                  _buildStatItem(
                    icon: PhosphorIcons.bookmark(PhosphorIconsStyle.regular),
                    value: '${profile.profileSavesCount}',
                    label: 'Saves',
                    context: context,
                  ),
                  _buildStatItem(
                    icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                    value: '${profile.profileCompletionPercentage}%',
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
