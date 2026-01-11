// lib/widgets/experience_card.dart
import 'package:flutter/material.dart';
import '../models/data_models.dart';

class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final VoidCallback onJoin;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onJoin,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(experience.category?.color),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(experience.category?.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and organizer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experience.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hosted by ${experience.organizer.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Save button
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_border,
                      size: 20,
                    ),
                    onPressed: onSave,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                experience.shortDescription,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Details row
              Row(
                children: [
                  // Date
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    text: experience.formattedDate,
                    context: context,
                  ),
                  const SizedBox(width: 16),

                  // Time
                  _buildDetailItem(
                    icon: Icons.access_time,
                    text: experience.formattedTime,
                    context: context,
                  ),
                  const SizedBox(width: 16),

                  // Location
                  _buildDetailItem(
                    icon: Icons.location_on,
                    text: experience.neighborhood.replaceAll('_', ' '),
                    context: context,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Footer row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price and capacity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experience.priceDisplay,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${experience.ticketsAvailable} spots left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: experience.ticketsAvailable < 10
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Join button
                  ElevatedButton(
                    onPressed: experience.isFull ? null : onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      experience.isFull ? 'Full' : 'Join',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Mood tags
              if (experience.secondaryMoods.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: experience.secondaryMoods
                      .map((mood) => Chip(
                    label: Text(
                      mood.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[100],
                    visualDensity: VisualDensity.compact,
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
    required BuildContext context,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? colorHex) {
    if (colorHex == null) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    const iconMap = {
      'users': Icons.people,
      'paint-brush': Icons.brush,
      'briefcase': Icons.business_center,
      'globe-africa': Icons.public,
      'mountain': Icons.landscape,
      'utensils': Icons.restaurant,
      'music': Icons.music_note,
      'laptop-code': Icons.computer,
      'dumbbell': Icons.fitness_center,
      'palette': Icons.palette,
    };
    return iconMap[iconName] ?? Icons.event;
  }
}