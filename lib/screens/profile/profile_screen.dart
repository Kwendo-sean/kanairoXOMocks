// lib/screens/profile/profile_screen.dart - SIMPLIFIED VERSION
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? publicId;

  const ProfileScreen({super.key, this.publicId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = publicId == null
            ? profileProvider.currentUser
            : profileProvider.viewedProfile;

        final isCurrentUser = publicId == null;

        if (profileProvider.isLoading && user == null) {
          return const Scaffold(
            backgroundColor: AppConstants.primaryBeige,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return Scaffold(
            backgroundColor: AppConstants.primaryBeige,
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.user(PhosphorIconsStyle.fill),
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCurrentUser ? 'No profile found' : 'Profile not found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppConstants.primaryBeige,
          appBar: AppBar(
            title: Text(isCurrentUser ? 'My Profile' : user.fullName),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(20),
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
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
                        child: PhosphorIcon(
                          PhosphorIcons.user(PhosphorIconsStyle.fill),
                          size: 40,
                          color: AppConstants.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.headline != null && user.headline!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.headline!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                            size: 16,
                            color: AppConstants.secondaryGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.neighborhoodDisplay,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConstants.secondaryGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
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
                    child: Text(
                      user.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Interests
                if (user.interests.isNotEmpty) ...[
                  Text(
                    'Interests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Stats
                Container(
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
                      Text(
                        'Profile Stats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem(
                            icon: PhosphorIcons.eye(PhosphorIconsStyle.regular),
                            label: 'Views',
                            value: '${user.profileViewsCount}',
                            context: context,
                          ),
                          const SizedBox(width: 20),
                          _buildStatItem(
                            icon: PhosphorIcons.bookmark(PhosphorIconsStyle.regular),
                            label: 'Saves',
                            value: '${user.profileSavesCount}',
                            context: context,
                          ),
                          const SizedBox(width: 20),
                          _buildStatItem(
                            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                            label: 'Complete',
                            value: '${user.profileCompletionPercentage}%',
                            context: context,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isCurrentUser
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditorScreen(),
                ),
              );
            },
            backgroundColor: AppConstants.primaryRed,
            child: PhosphorIcon(
              PhosphorIcons.pencil(PhosphorIconsStyle.regular),
              color: Colors.white,
            ),
          )
              : null,
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                icon,
                color: AppConstants.primaryRed,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.secondaryGray,
            ),
          ),
        ],
      ),
    );
  }
}