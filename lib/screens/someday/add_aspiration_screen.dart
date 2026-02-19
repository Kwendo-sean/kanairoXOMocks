import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddAspirationScreen extends StatefulWidget {
  const AddAspirationScreen({super.key});

  @override
  State<AddAspirationScreen> createState() => _AddAspirationScreenState();
}

class _AddAspirationScreenState extends State<AddAspirationScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  void _saveAspiration() {
    if (_titleController.text.isNotEmpty) {
      Navigator.of(context).pop({
        'title': _titleController.text,
        'notes': _notesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Dream'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _saveAspiration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration.collapsed(
                hintText: 'What\'s the dream?',
                hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.lightGray),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration.collapsed(
                hintText: 'Add some notes or details...',
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              leading: const PhosphorIcon(PhosphorIcons.tag, color: AppConstants.secondaryGray),
              title: const Text('Category'),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Travel', style: TextStyle(color: AppConstants.secondaryGray)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
                ],
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const PhosphorIcon(PhosphorIcons.calendar, color: AppConstants.secondaryGray),
              title: const Text('Target Date'),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('This Year', style: TextStyle(color: AppConstants.secondaryGray)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
                ],
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
