import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/services/memory_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:intl/intl.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final MemoryService _memoryService = MemoryService();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _spotifyController = TextEditingController();
  
  String _selectedType = 'Date';
  DateTime _selectedDate = DateTime.now();
  List<File> _selectedPhotos = [];
  bool _isSaving = false;

  Future<void> _pickPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removePhoto(File file) {
    setState(() => _selectedPhotos.remove(file));
  }

  Future<void> _saveMemory() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _memoryService.createMemory(
        title: _titleController.text,
        description: _captionController.text,
        memoryType: _selectedType,
        memoryDate: _selectedDate,
        photo: _selectedPhotos.isNotEmpty ? _selectedPhotos.first : null,
        locationName: _locationController.text,
        // Additional photos/spotify would need API support adjustment
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Add Memory', style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Photos", style: AppTypography.labelMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedPhotos.map((file) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.sm,
                      child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(file),
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                )),
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: UnderlineInputBorder()),
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Caption (optional)', border: UnderlineInputBorder()),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text("Tag", style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: ["Event", "Date", "Vibe", "Milestone"].map((type) {
                final isSel = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: AppTypography.caption.copyWith(
                          color: isSel ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date', style: AppTypography.bodyMedium),
              trailing: Text(
                DateFormat('MMM d, yyyy').format(_selectedDate),
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _spotifyController,
              decoration: const InputDecoration(
                labelText: 'Song from this memory (optional)',
                prefixIcon: Icon(Icons.music_note_outlined, size: 18),
                hintText: 'e.g. Melanin by Sauti Sol',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : LiquidGlassButton(
                    onPressed: _saveMemory,
                    child: Text('Save Memory', style: AppTypography.buttonText),
                  ),
          ],
        ),
      ),
    );
  }
}
