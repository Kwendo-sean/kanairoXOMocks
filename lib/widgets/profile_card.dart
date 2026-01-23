// lib/widgets/profile_card.dart
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/discovery_models.dart';

class ProfileCard extends StatelessWidget {
  final DiscoveryProfile profile;
  final double compatibilityScore;
  final String compatibilityText;
  final String explanation;
  final VoidCallback onConnect;
  final VoidCallback onNotNow;
  final VoidCallback onSave;
  final bool isProcessing;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.compatibilityScore,
    required this.compatibilityText,
    required this.explanation,
    required this.onConnect,
    required this.onNotNow,
    required this.onSave,
    this.isProcessing = false,
  });

  // Helper to determine the correct image provider
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      return NetworkImage(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Section
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                    image: DecorationImage(
                      image: _getImageProvider(profile.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),

                      // Online indicator
                      if (profile.isOnline)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Profile info at bottom of image
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.displayName,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Compatibility badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCompatibilityColor(compatibilityScore)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${compatibilityScore.toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          compatibilityText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              if (profile.age != null || profile.gender != null)
                                Text(
                                  '${profile.age ?? ''} ${profile.gender ?? ''}'.trim(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),

                              if (profile.location != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.location!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bio
                            if (profile.bio != null && profile.bio!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  profile.bio!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                            // Intents
                            if (profile.primaryIntent != null || profile.secondaryIntent != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (profile.primaryIntent != null)
                                      _buildIntentChip(profile.primaryIntent!),
                                    if (profile.secondaryIntent != null)
                                      _buildIntentChip(profile.secondaryIntent!),
                                  ],
                                ),
                              ),

                            // Interests
                            if (profile.interests.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Interests',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final interest in profile.interests.take(8))
                                          _buildInterestChip(interest),
                                        if (profile.interests.length > 8)
                                          _buildInterestChip(
                                              '+${profile.interests.length - 8} more'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Moods
                            if (profile.currentMoods != null && profile.currentMoods!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Mood',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final mood in profile.currentMoods!.take(3))
                                          _buildMoodChip(mood),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Explanation
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.insights,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      explanation,
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Save Button
                        _buildActionButton(
                          icon: Icons.bookmark_border,
                          label: 'Save',
                          color: Colors.blue,
                          onPressed: onSave,
                        ),

                        // Connect Button
                        _buildActionButton(
                          icon: Icons.favorite,
                          label: 'Connect',
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: onConnect,
                          isPrimary: true,
                        ),

                        // Not Now Button
                        _buildActionButton(
                          icon: Icons.close,
                          label: 'Not Now',
                          color: Colors.grey,
                          onPressed: onNotNow,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (isProcessing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentChip(String intent) {
    return Chip(
      label: Text('🎯 $intent'),
      backgroundColor: Colors.orange[100],
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.orange[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Chip(
      label: Text(interest),
      backgroundColor: Colors.green[50],
      labelStyle: TextStyle(
        color: Colors.green[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildMoodChip(String mood) {
    return Chip(
      label: Text('😊 $mood'),
      backgroundColor: Colors.purple[50],
      labelStyle: TextStyle(
        color: Colors.purple[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isPrimary && !isProcessing
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            onPressed: isProcessing ? null : onPressed, // Disable when processing
            icon: isProcessing
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : color,
                    ),
                  )
                : Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
