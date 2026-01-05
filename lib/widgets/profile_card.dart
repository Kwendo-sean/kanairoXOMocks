import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import '../models/data_models.dart';


class ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onNotNow;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onConnect,
    required this.onNotNow,
  });

  IconData _getMoodIcon(String iconName) {
    switch (iconName) {
      case 'coffee':
        return PhosphorIcons.coffee();
      case 'building':
        return PhosphorIcons.buildings();
      case 'brain':
        return PhosphorIcons.brain();
      case 'waves':
        return PhosphorIcons.waves();
      case 'eye':
        return PhosphorIcons.eye();
      case 'paint-brush':
        return PhosphorIcons.paintBrush();
      default:
        return PhosphorIcons.user();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: profile.imageUrl.startsWith('http') 
            ? Image.network(
                profile.imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    width: double.infinity,
                    color: AppConstants.lightGray,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppConstants.secondaryGray,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load image',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppConstants.secondaryGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 400,
                    color: AppConstants.lightGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryRed,
                      ),
                    ),
                  );
                },
              )
            : Image.asset(
                profile.imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a placeholder if asset is missing
                  return Container(
                    height: 400,
                    width: double.infinity,
                    color: AppConstants.lightGray,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  );
                },
              ),
          ),
          
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name, Age, and Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${profile.name}, ',
                      style: theme.textTheme.displayMedium,
                    ),
                    Text(
                      '${profile.age}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bio
                Text(
                  profile.bio,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                
                // Mood Indicator
                Row(
                  children: [
                    Icon(
                      _getMoodIcon(profile.moodIcon),
                      size: 18,
                      color: AppConstants.secondaryGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.mood,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Interests (if any)
                if (profile.interests.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests
                        .map((interest) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryBeige,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        interest,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Looking For (if any)
                if (profile.lookingFor.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Looking for: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...profile.lookingFor.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppConstants.primaryRed,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Connect'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onNotNow,
                        child: Text(
                          'Not now',
                          style: theme.textTheme.labelLarge?.copyWith(
                             color: AppConstants.secondaryGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}