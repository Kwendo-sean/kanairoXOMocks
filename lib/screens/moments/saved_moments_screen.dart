import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/moment_provider.dart';

class SavedMomentsScreen extends StatefulWidget {
  const SavedMomentsScreen({super.key});
  @override
  State<SavedMomentsScreen> createState() => _SavedMomentsScreenState();
}

class _SavedMomentsScreenState extends State<SavedMomentsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh in background if needed, but the provider likely already has data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MomentProvider>().fetchSavedMoments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final text = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A0808);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Saved Moments', style: AppTypography.screenTitle.copyWith(color: text)),
      ),
      body: Consumer<MomentProvider>(
        builder: (context, provider, child) {
          if (provider.isSavedLoading && provider.savedMoments.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }

          if (provider.savedMoments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_outline, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No saved moments', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: text)),
                  const SizedBox(height: 6),
                  Text('Save moments from your feed', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchSavedMoments(refresh: true),
            color: AppColors.primary,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: provider.savedMoments.length,
              itemBuilder: (ctx, i) {
                final m = provider.savedMoments[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: m.photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: m.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.primaryGlass),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primaryGlass,
                          child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                        ),
                      )
                    : Container(color: AppColors.primaryGlass),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
