// lib/widgets/profile/profile_completion_widget.dart
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileCompletionCard extends StatelessWidget {
  final User user;

  const ProfileCompletionCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final completionPercentage = user.profileCompletionPercentage;
    final suggestions = _getCompletionSuggestions(user);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Your Profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: AppConstants.primaryRed,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completionPercentage%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Next Steps:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...suggestions.map((s) => _buildSuggestionItem(context, s)),
            ]
          ],
        ),
      ),
    );
  }

  List<String> _getCompletionSuggestions(User user) {
    final suggestions = <String>[];
    if (user.mainProfilePhoto == null || user.mainProfilePhoto!.isEmpty) {
      suggestions.add('Add a profile photo');
    }
    if (user.bio == null || user.bio!.isEmpty) {
      suggestions.add('Write a bio');
    }
    if (user.interests.isEmpty) {
      suggestions.add('Add your interests');
    }
    if (user.occupation == null || user.occupation!.isEmpty) {
      suggestions.add('Add your occupation');
    }
    if (user.voiceIntro == null || user.voiceIntro!.isEmpty) {
      suggestions.add('Record a voice intro');
    }
    return suggestions.take(2).toList(); // Only show top 2 suggestions
  }

  Widget _buildSuggestionItem(BuildContext context, String suggestion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIcons.arrowCircleRight(PhosphorIconsStyle.regular), color: AppConstants.primaryRed, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(suggestion, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
