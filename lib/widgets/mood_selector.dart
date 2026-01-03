import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/data_models.dart';


class MoodSelector extends StatefulWidget {
  final List<Mood> moods;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.moods,
    required this.onMoodSelected,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  late List<Mood> _moods;

  @override
  void initState() {
    super.initState();
    _moods = List.of(widget.moods);
  }

  IconData _getMoodIcon(String iconName) {
    switch (iconName) {
      case 'bolt':
        return PhosphorIcons.belt();
      case 'brain':
        return PhosphorIcons.brain();
      case 'compass':
        return PhosphorIcons.compass();
      case 'waves':
        return PhosphorIcons.waves();
      case 'eye':
        return PhosphorIcons.eye();
      case 'paint-brush':
        return PhosphorIcons.paintBrush();
      default:
        return PhosphorIcons.star();
    }
  }

  void _selectMood(int index) {
    setState(() {
      _moods = _moods.map((mood) => Mood(
        name: mood.name,
        icon: mood.icon,
        isSelected: false,
      )).toList();
      
      _moods[index] = Mood(
        name: _moods[index].name,
        icon: _moods[index].icon,
        isSelected: true,
      );
    });
    
    widget.onMoodSelected(_moods[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'How are you feeling right now?',
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Mood Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _moods.length,
          itemBuilder: (context, index) {
            final mood = _moods[index];
            return GestureDetector(
              onTap: () => _selectMood(index),
              child: Container(
                decoration: BoxDecoration(
                  color: mood.isSelected ? const Color(0xFF8B0000) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: mood.isSelected ? const Color(0xFF8B0000) : const Color(0xFFE0D7CC),
                    width: 1,
                  ),
                  boxShadow: mood.isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B0000).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMoodIcon(mood.icon),
                      size: 20,
                      color: mood.isSelected ? Colors.white : const Color(0xFF8B7355),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mood.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: mood.isSelected ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}