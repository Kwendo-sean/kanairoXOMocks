import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/rhythm/connection_exercises_card.dart';
import 'package:kanairoxo/widgets/rhythm/emotional_attunement_card.dart';
import 'package:kanairoxo/widgets/rhythm/evening_sync_card.dart';
import 'package:kanairoxo/widgets/rhythm/morning_rhythm_card.dart';

class RhythmScreen extends StatelessWidget {
  const RhythmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhythm'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            MorningRhythmCard(),
            SizedBox(height: 16),
            EveningSyncCard(),
            SizedBox(height: 16),
            EmotionalAttunementCard(),
            SizedBox(height: 16),
            ConnectionExercisesCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
