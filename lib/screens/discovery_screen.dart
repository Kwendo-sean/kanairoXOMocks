import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../models/data_models.dart';

class DiscoveryScreen extends StatelessWidget {
  final int currentProfileIndex;
  final VoidCallback onConnect;
  final VoidCallback onNotNow;
  final VoidCallback onNextProfile;

  const DiscoveryScreen({
    super.key,
    this.currentProfileIndex = 0,
    required this.onConnect,
    required this.onNotNow,
    required this.onNextProfile,
  });

  @override
  Widget build(BuildContext context) {
    final profile = sampleProfiles[currentProfileIndex % sampleProfiles.length];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ProfileCard(
                profile: profile,
                onConnect: onConnect,
                onNotNow: onNotNow,
              ),
              const SizedBox(height: 40),
              
              // No swipe indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Take your time with each profile. Quality over quantity.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}