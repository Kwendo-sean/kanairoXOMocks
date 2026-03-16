import 'package:flutter/material.dart';
import 'package:kanairoxo/screens/someday/add_aspiration_screen.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/someday/bucket_list_card.dart';
import 'package:kanairoxo/widgets/someday/vision_board_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SomedayScreen extends StatefulWidget {
  const SomedayScreen({super.key});

  @override
  State<SomedayScreen> createState() => _SomedayScreenState();
}

class _SomedayScreenState extends State<SomedayScreen> {
  // Placeholder for aspirations data
  final List<Map<String, dynamic>> _aspirations = [
    {'title': 'Visit Japan during cherry blossom season', 'isChecked': true},
    {'title': 'Learn to make pasta from scratch', 'isChecked': true},
    {'title': 'Go on a hot air balloon ride', 'isChecked': false},
    {'title': 'Adopt a dog', 'isChecked': false},
  ];

  Future<void> _addAspiration() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddAspirationScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _aspirations.add({
          'title': result['title'],
          'isChecked': false, // New items are unchecked by default
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Someday'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VisionBoardCard(),
            const SizedBox(height: 24),
            BucketListCard(aspirations: _aspirations),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAspiration,
        backgroundColor: AppConstants.primaryRed,
        tooltip: 'Add Aspiration',
        child: const PhosphorIcon(PhosphorIcons.plus, color: Colors.white, size: 28),
      ),
    );
  }
}
