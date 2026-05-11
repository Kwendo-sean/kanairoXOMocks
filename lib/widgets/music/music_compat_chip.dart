import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MusicCompatChip extends StatelessWidget {
  final double score;
  final List<String> sharedGenres;
  
  const MusicCompatChip({
    super.key,
    required this.score,
    this.sharedGenres = const [],
  });
  
  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? const Color(0xFF1DB954)
        : score >= 40
            ? Colors.orange.shade600
            : AppColors.textMuted;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '${score.toInt()}% music match',
            style: AppTypography.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
