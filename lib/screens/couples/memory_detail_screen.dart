import 'package:flutter/material.dart';
import 'package:kanairoxo/models/memory_model.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemoryDetailScreen extends StatelessWidget {
  final Memory memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.textColor),
        title: Text('Memory', style: AppTypography.screenTitle),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory.photo != null)
              CachedNetworkImage(
                imageUrl: memory.photo!,
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memory.title, style: AppTypography.displayLarge.copyWith(fontSize: 32)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${memory.memoryDate.day}/${memory.memoryDate.month}/${memory.memoryDate.year}',
                        style: AppTypography.caption,
                      ),
                      if (memory.locationName != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(memory.locationName!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (memory.description != null)
                    Text(memory.description!, style: AppTypography.bodyLarge),
                  const SizedBox(height: 40),
                  // Add more details like who added it, spotify track etc if available in the model
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
