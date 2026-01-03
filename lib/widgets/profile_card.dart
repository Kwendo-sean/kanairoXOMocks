import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
            child: Image.network(
              profile.imageUrl,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 400,
                  color: const Color(0xFFF0ECE4),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B0000),
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
                        color: const Color(0xFF8B7355),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8B7355),
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
                      color: const Color(0xFF8B7355),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.mood,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8B7355),
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
                        color: const Color(0xFFF5F1EA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        interest,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8B7355),
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
                              color: const Color(0xFF8B0000),
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
                          style: theme.textTheme.labelLarge,
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