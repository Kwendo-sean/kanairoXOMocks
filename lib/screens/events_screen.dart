import 'package:flutter/material.dart';
import '../widgets/experience_card.dart';
import '../models/data_models.dart';

class EventsScreen extends StatelessWidget {
  final void Function(Experience) onJoinExperience;
  final ValueChanged<Experience> onExperienceSelected;

  const EventsScreen({
    super.key,
    required this.onJoinExperience,
    required this.onExperienceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Experiences',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(
            'Curated gatherings for meaningful connections',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 24),
          
          ...sampleExperiences.map((experience) {
            return ExperienceCard(
              experience: experience,
              onJoin: () {
                onExperienceSelected(experience);
                onJoinExperience(experience);
              },
            );
          }),
          
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Experiences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'New experiences are added weekly. Check back often to find gatherings that match your current mood.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}