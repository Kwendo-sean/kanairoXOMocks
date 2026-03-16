import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final _momentService = MomentService();
  final _captionController = TextEditingController();
  File? _selectedImage;
  String _selectedType = 'vibe';
  bool _isSubmitting = false;

  final List<Map<String, String>> _momentTypes = [
    {'value': 'vibe', 'label': 'Vibe'},
    {'value': 'event', 'label': 'Event'},
    {'value': 'meetup', 'label': 'Meetup'},
    {'value': 'date', 'label': 'Date'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _momentService.createMoment(
        caption: _captionController.text,
        type: _selectedType,
        photo: _selectedImage!,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment shared successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('New Moment', style: AppTypography.screenTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SELECTOR
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: AppRadius.lg,
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: AppRadius.lg,
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text('Select a Photo', style: AppTypography.bodyLarge),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. CAPTION INPUT
            _buildSectionTitle('What\'s happening?'),
            ClipRRect(
              borderRadius: AppRadius.md,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _captionController,
                  maxLines: 4,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Share the vibe...',
                    hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. MOMENT TYPE
            _buildSectionTitle('Tag the Moment'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _momentTypes.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type['value']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.7),
                          borderRadius: AppRadius.full,
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          type['label']!,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),

            // 4. SUBMIT BUTTON
            LiquidGlassButton(
              size: LiquidButtonSize.xl,
              width: double.infinity,
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Share Moment', style: AppTypography.buttonText),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: AppTypography.displayMedium.copyWith(fontSize: 16)),
    );
  }
}
