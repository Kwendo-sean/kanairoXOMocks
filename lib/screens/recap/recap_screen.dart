import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/recap/annual_review_card.dart';
import 'package:kanairoxo/widgets/recap/milestone_highlights_card.dart';
import 'package:kanairoxo/widgets/recap/shareable_creations_card.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recap'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            AnnualReviewCard(),
            SizedBox(height: 24),
            MilestoneHighlightsCard(),
            SizedBox(height: 24),
            ShareableCreationsCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
