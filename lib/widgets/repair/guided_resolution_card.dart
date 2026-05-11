import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuidedResolutionCard extends StatelessWidget {
  const GuidedResolutionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.path(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Guided Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStep(step: 1, title: 'State the Issue', content: 'Each person shares their perspective without interruption.'),
            _buildStep(step: 2, title: 'Identify Underlying Needs', content: 'What core need is not being met for each of you?'),
            _buildStep(step: 3, title: 'Brainstorm Solutions', content: 'Come up with ideas together. No bad ideas at this stage.'),
            _buildStep(step: 4, title: 'Agree on Action Steps', content: 'Choose a solution and decide on concrete steps to take.'),
            _buildStep(step: 5, title: 'Schedule a Follow-up', content: 'Set a time to check in on how the solution is working.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required int step, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppConstants.primaryRed,
            child: Text(step.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
