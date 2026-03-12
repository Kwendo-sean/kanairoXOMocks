import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/profile/photo_upload_screen.dart';
import 'package:kanairoxo/widgets/profile/interests_grid.dart';
import 'package:kanairoxo/widgets/profile/profile_completion_widget.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/widgets/profile/profile_header.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  final String? publicId;

  const ProfileScreen({super.key, this.publicId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;

        if (profileProvider.isLoading && user == null) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
        }

        if (profileProvider.error != null && user == null) {
          return _buildErrorScreen(context, profileProvider);
        }

        if (user == null || user.profile == null) {
          return _buildNoProfileScreen(context, profileProvider);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () => profileProvider.loadMyProfile(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      ProfileHeader(
                        user: user,
                        showBackButton: publicId != null,
                        onEditPressed: null,
                        onLogoutPressed: null,
                      ),
                      if (publicId == null)
                        Positioned(
                          top: 40,
                          right: 16,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileEditorScreen(onClose: () => Navigator.of(context).pop()),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                                onPressed: () async {
                                  await context.read<AuthProvider>().logout();
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (publicId == null)
                        GlassCard(child: ProfileCompletionCard(user: user)),
                      const SizedBox(height: 16),
                      _buildSectionTitle('About Me'),
                      const SizedBox(height: 8),
                      GlassCard(
                        child: Text(
                          user.profile?.bio ?? 'No bio available.',
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('My Interests'),
                      const SizedBox(height: 8),
                      InterestsGrid(interests: user.profile!.interests),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Gallery'),
                      const SizedBox(height: 8),
                      _buildGallery(context, user.profile!.profilePhotos, profileProvider),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(BuildContext context, ProfileProvider profileProvider) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              Text('Error Loading Profile', style: AppTypography.displayMedium),
              const SizedBox(height: 6),
              Text(profileProvider.error!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              LiquidGlassButton(
                size: LiquidButtonSize.md,
                onPressed: () => profileProvider.loadMyProfile(),
                child: Text('Try Again', style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileScreen(BuildContext context, ProfileProvider profileProvider) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No profile data found.', style: AppTypography.bodyLarge),
            const SizedBox(height: 12),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: () => profileProvider.loadMyProfile(),
              child: Text('Reload Profile', style: AppTypography.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.displayMedium.copyWith(fontSize: 16),
    );
  }

  Widget _buildGallery(BuildContext context, List<Map<String, dynamic>> photos, ProfileProvider profileProvider) {
    if (photos.isEmpty && publicId == null) {
      return LiquidGlassButton(
        size: LiquidButtonSize.lg,
        width: double.infinity,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PhotoUploadScreen()),
          ).then((_) => profileProvider.loadMyProfile());
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Upload Photos', style: AppTypography.buttonText),
          ],
        ),
      );
    }
    if (photos.isEmpty) {
      return Center(child: Text('No photos yet.', style: AppTypography.bodyMedium));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photoUrl = photos[index]['url'];
        return ClipRRect(
          borderRadius: AppRadius.sm,
          child: Image.network(photoUrl, fit: BoxFit.cover),
        );
      },
    );
  }
}
