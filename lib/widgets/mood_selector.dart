import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
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
  String? _selectedMoodName;

  @override
  void initState() {
    super.initState();
    // Find the initially selected mood, if any
    final selectedMood = widget.moods.firstWhere(
      (mood) => mood.isSelected,
      orElse: () => widget.moods.first, // Default to first if none are selected
    );
    _selectedMoodName = selectedMood.name;
  }

  void _selectMood(Mood mood) {
    setState(() {
      _selectedMoodName = mood.name;
    });
    widget.onMoodSelected(mood);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Let parent scroll
      itemCount: widget.moods.length,
      itemBuilder: (context, index) {
        final mood = widget.moods[index];
        final isSelected = mood.name == _selectedMoodName;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
            onPressed: () => _selectMood(mood),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? AppConstants.primaryRed : AppConstants.primaryBeige,
              foregroundColor: isSelected ? Colors.white : AppConstants.primaryBlack,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(
                  color: isSelected ? AppConstants.primaryRed : AppConstants.lightGray,
                  width: 1.5,
                ),
              ),
              elevation: isSelected ? 4 : 0,
              shadowColor: AppConstants.primaryRed.withOpacity(0.3),
            ),
            child: Text(
              mood.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}