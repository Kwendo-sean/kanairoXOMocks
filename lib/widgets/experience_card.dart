import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/data_models.dart';


class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final VoidCallback onJoin;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onJoin,
  });

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'energetic':
        return PhosphorIcons.belt();
      case 'reflective':
        return PhosphorIcons.brain();
      case 'adventurous':
        return PhosphorIcons.compass();
      case 'calm':
        return PhosphorIcons.waves();
      case 'curious':
        return PhosphorIcons.eye();
      case 'creative':
        return PhosphorIcons.paintBrush();
      default:
        return PhosphorIcons.star();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = _getWeekday(dateTime.weekday);
    final month = _getMonth(dateTime.month);
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    
    return '$day, $month ${dateTime.day} • $hour12:$minute $period';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.network(
              experience.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 180,
                  color: const Color(0xFFF0ECE4),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B0000),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  experience.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Date, Time & Location
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.calendar(),
                      size: 16,
                      color: const Color(0xFF8B7355),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(experience.dateTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.mapPin(),
                      size: 16,
                      color: const Color(0xFF8B7355),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        experience.location,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  experience.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Mood Tag and Join Button
                Row(
                  children: [
                    // Mood Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1EA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMoodIcon(experience.mood),
                            size: 14,
                            color: const Color(0xFF8B7355),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            experience.mood,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF8B7355),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Join Button
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: onJoin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Join Experience'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}