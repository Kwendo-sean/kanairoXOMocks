import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
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
      backgroundColor: AppConstants.primaryBeige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'How are you feeling right now?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontFamily: 'Serif', // A generic serif font
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: MoodSelector(
                  moods: sampleMoods,
                  onMoodSelected: onMoodSelected,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
