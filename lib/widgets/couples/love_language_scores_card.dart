import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';

class LoveLanguageScoresCard extends StatelessWidget {
  const LoveLanguageScoresCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Love Languages',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            _LoveLanguageBar(language: 'Words of Affirmation', score: 0.8, color: Colors.blue),
            SizedBox(height: 8),
            _LoveLanguageBar(language: 'Acts of Service', score: 0.6, color: Colors.green),
            SizedBox(height: 8),
            _LoveLanguageBar(language: 'Receiving Gifts', score: 0.4, color: Colors.purple),
            SizedBox(height: 8),
            _LoveLanguageBar(language: 'Quality Time', score: 0.9, color: AppConstants.primaryRed),
            SizedBox(height: 8),
            _LoveLanguageBar(language: 'Physical Touch', score: 0.7, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

class _LoveLanguageBar extends StatelessWidget {
  final String language;
  final double score;
  final Color color;

  const _LoveLanguageBar({
    required this.language,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score,
                  minHeight: 8,
                  backgroundColor: AppConstants.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(score * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
