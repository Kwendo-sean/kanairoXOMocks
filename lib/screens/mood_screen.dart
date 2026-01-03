import 'package:flutter/material.dart';
import '../widgets/mood_selector.dart';
import '../models/data_models.dart';

class MoodScreen extends StatelessWidget {
  final ValueChanged<Mood> onMoodSelected;
  final VoidCallback onContinue;

  const MoodScreen({
    super.key,
    required this.onMoodSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MoodSelector(
              moods: sampleMoods,
              onMoodSelected: onMoodSelected,
            ),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why track your mood?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'KanairoXO matches you with people and experiences based on your current emotional state. Sharing authentic moments starts with being true to how you feel.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: const Text('Continue with this mood'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Skip for now',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}