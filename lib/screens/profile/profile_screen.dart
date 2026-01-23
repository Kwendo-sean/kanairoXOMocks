// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/profile/photo_upload_screen.dart';
import 'package:kanairoxo/widgets/profile/interests_grid.dart';
import 'package:kanairoxo/widgets/profile/profile_completion_widget.dart';
import 'package:kanairoxo/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final String? publicId;

  const ProfileScreen({super.key, this.publicId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;

        if (profileProvider.isLoading && user == null) {
          return _buildLoadingScreen();
        }

        if (profileProvider.error != null && user == null) {
          return _buildErrorScreen(context, profileProvider);
        }

        if (user == null) {
          return _buildNoProfileScreen(context, profileProvider);
        }

        return Scaffold(
          backgroundColor: AppConstants.primaryBeige,
          body: RefreshIndicator(
            onRefresh: () => profileProvider.loadMyProfile(),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, user, publicId == null, profileProvider),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (publicId == null)
                        ProfileCompletionCard(user: user),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'About Me'),
                      const SizedBox(height: 12),
                      _buildBioCard(context, user),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'My Interests'),
                      const SizedBox(height: 12),
                      InterestsGrid(interests: user.interests),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Gallery'),
                      const SizedBox(height: 12),
                      _buildGallery(context, user.profilePhotos),
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

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(BuildContext context, ProfileProvider profileProvider) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false,),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text('Error Loading Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(profileProvider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => profileProvider.loadMyProfile(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileScreen(BuildContext context, ProfileProvider profileProvider) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No profile data found.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => profileProvider.loadMyProfile(),
              child: const Text('Reload Profile'),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, User user, bool isCurrentUser, ProfileProvider profileProvider) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryBeige,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        if (isCurrentUser)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileEditorScreen()),
              );
            },
            icon: PhosphorIcon(PhosphorIcons.pencil(PhosphorIconsStyle.regular), color: AppConstants.primaryBlack),
          ),
          if (isCurrentUser)
          IconButton(
            onPressed: () async {
              await AuthService().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
            },
            icon: PhosphorIcon(PhosphorIcons.signOut(PhosphorIconsStyle.regular), color: AppConstants.primaryBlack),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: (user.mainProfilePhoto != null && user.mainProfilePhoto!.isNotEmpty
                      ? NetworkImage(user.mainProfilePhoto!)
                      : const AssetImage('assets/default_avatar.png')) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (user.headline != null && user.headline!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.headline!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.mapPin(PhosphorIconsStyle.regular), size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        user.neighborhoodDisplay,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrentUser)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.small(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PhotoUploadScreen()),
                    ).then((_) => profileProvider.loadMyProfile());
                  },
                  backgroundColor: AppConstants.primaryRed,
                  child: PhosphorIcon(PhosphorIcons.camera(PhosphorIconsStyle.regular), size: 20, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBioCard(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          user.bio ?? 'No bio available.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context, List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) {
      return const Center(child: Text('No photos yet.'));
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
          borderRadius: BorderRadius.circular(12),
          child: Image.network(photoUrl, fit: BoxFit.cover),
        );
      },
    );
  }
}
