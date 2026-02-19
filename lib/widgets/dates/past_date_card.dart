import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PastDateCard extends StatelessWidget {
  const PastDateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildDetails(),
          _buildMemories(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Dinner at The Carnivore',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Text('June 15, 2024', style: TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, size: 20)),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildRating(icon: PhosphorIcons.star(PhosphorIconsStyle.fill), color: Colors.amber, label: '4/5'),
          const SizedBox(width: 16),
          _buildRating(icon: PhosphorIcons.heart(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, label: 'High'),
          const SizedBox(width: 16),
          _buildRating(icon: PhosphorIcons.smiley(PhosphorIconsStyle.fill), color: Colors.green, label: 'Fun'),
        ],
      ),
    );
  }

   Widget _buildRating({required IconData icon, required Color color, required String label}) {
    return Row(
      children: [
        PhosphorIcon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMemories() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Memories & Notes', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2),
            ),
            child: const Text(
              'Highlight: Trying the ostrich meat! We should be more adventurous with food more often. Also, the live music was a great touch.',
              style: TextStyle(fontSize: 13, color: AppConstants.secondaryGray, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
