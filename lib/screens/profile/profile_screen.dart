import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/profile_model.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/models/music/spotify_models.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/services/profile_api_service.dart';
import 'package:kanairoxo/services/spotify_service.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/singles/moment_viewer_screen.dart';
import 'package:kanairoxo/screens/settings/settings_screen.dart';
import 'package:kanairoxo/screens/music/spotify_connect_screen.dart';
import 'package:kanairoxo/utils/auth_storage.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/profile/profile_stats.dart';
import 'package:kanairoxo/screens/moments/saved_moments_screen.dart';
import 'package:dio/dio.dart';

class ProfileScreen extends StatefulWidget {
  final String? publicId;

  const ProfileScreen({super.key, this.publicId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final ProfileApiService profileApiService = ProfileApiService();
  
  List<GalleryPhotoModel> _galleryPhotos = [];
  bool _galleryLoading = false;
  SpotifyStatus? _spotifyStatus;

  int _connectionsCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    await Future.wait([
      profileProvider.refreshMyProfile(),
      _loadGallery(),
      _loadSpotifyStatus(),
      _loadConnectionsCount(),
    ]);
  }

  Future<void> _loadConnectionsCount() async {
    try {
      final response = await ApiClient.instance.dio.get('/api/v1/connections/', queryParameters: {'status': 'active'});
      int connCount = 0;
      final data = response.data;
      if (data is List) {
        connCount = data.length;
      } else if (data is Map) {
        connCount = data['count'] ?? (data['results'] as List?)?.length ?? 0;
      }
      if (mounted) setState(() => _connectionsCount = connCount);
    } catch (e) {
      debugPrint('Connections count error: $e');
    }
  }

  Future<void> _loadGallery() async {
    if (!mounted) return;
    setState(() => _galleryLoading = true);
    try {
      final photos = await profileApiService.getGallery(userId: widget.publicId);
      if (!mounted) return;
      setState(() {
        _galleryPhotos = photos;
        _galleryLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _galleryLoading = false);
    }
  }

  Future<void> _loadSpotifyStatus() async {
    if (widget.publicId != null) return;
    try {
      final status = await SpotifyService().getStatus();
      if (mounted) setState(() => _spotifyStatus = status);
    } catch (e) {}
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
    _loadGallery();
    _loadConnectionsCount();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: context.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.logout_outlined, color: context.primaryColor, size: 26)),
              const SizedBox(height: 16),
              Text('Log out?', style: AppTypography.displayMedium.copyWith(fontSize: 20, color: context.textColor)),
              const SizedBox(height: 8),
              Text('You can log back in anytime', style: AppTypography.bodyMedium.copyWith(color: context.mutedColor), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: LiquidGlassButton(
                  size: LiquidButtonSize.lg,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performLogout();
                  },
                  child: Text('Log Out', style: AppTypography.buttonText))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Cancel', style: AppTypography.labelMedium.copyWith(color: context.mutedColor, fontWeight: FontWeight.w500)))),
            ]))));
  }
  
  Future<void> _performLogout() async {
    try {
      await AuthStorage.clearAll();
      Provider.of<ProfileProvider>(context, listen: false).handleLogout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainAppScreen()), (route) => false),
            onSignupTap: () {},
          )),
        (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed'), backgroundColor: Colors.red.shade700));
    }
  }

  Future<void> _uploadPhoto(File file) async {
    try {
      await profileApiService.uploadGalleryPhoto(file);
      await _loadGallery();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'), 
            backgroundColor: AppColors.primary, 
            behavior: SnackBarBehavior.floating
          )
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'), 
            backgroundColor: Colors.red.shade700, 
            behavior: SnackBarBehavior.floating
          )
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) await _uploadPhoto(File(picked.path));
  }

  Future<void> _deleteGalleryPhoto(GalleryPhotoModel photo) async {
    try {
      await profileApiService.deleteGalleryPhoto(photo.id);
      _loadGallery();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red));
    }
  }

  void _showDeleteDialog(GalleryPhotoModel photo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove photo?', style: AppTypography.displayMedium.copyWith(fontSize: 18, color: context.textColor)),
        content: Text('This photo will be permanently removed from your gallery.', style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: AppTypography.labelMedium.copyWith(color: context.mutedColor))),
          LiquidGlassButton(size: LiquidButtonSize.sm, onPressed: () { Navigator.pop(ctx); _deleteGalleryPhoto(photo); }, child: Text('Remove', style: AppTypography.buttonText)),
        ],
      ),
    );
  }

  void _openGalleryViewer(int startIndex, ProfileModel? profile) {
    final List<Moment> moments = _galleryPhotos.map((p) => Moment(
      id: p.id.toString(),
      userName: profile?.fullName ?? 'User',
      userAvatarUrl: profile?.profilePhotoUrl,
      date: p.uploadedAt,
      type: MomentType.vibe,
      photoUrl: p.imageUrl,
      caption: p.caption,
      likesCount: 0,
      commentsCount: 0,
      isLikedByMe: false,
      isSavedByMe: false,
    )).toList();

    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => MomentViewerScreen(moments: moments, initialIndex: startIndex),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.myProfile;
    final isLoading = profileProvider.isLoading && profile == null;
    final error = profileProvider.error;
    final imgVersion = profileProvider.imageVersion;

    if (isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: PulsingGlassPlaceholder(width: 200, height: 200, borderRadius: 24)),
      );
    }
    
    if (error != null && profile == null) {
      return _buildErrorState(error);
    }

    if (profile == null) {
      return _buildErrorState("Profile not found");
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(profile, imgVersion),
                  ProfileStats(
                    viewsCount: profile.viewsCount,
                    connectionsCount: _connectionsCount,
                    profileComplete: profile.completionPercentage,
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedMomentsScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                        child: Row(
                          children: [
                            const Icon(Icons.bookmark_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Saved Moments', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (profile.completionPercentage < 100)
                    _buildCompletionCard(profile),
                  if (profile.completionPercentage < 100)
                    const SizedBox(height: 16),
                  _buildAboutMe(profile),
                  const SizedBox(height: 16),
                  _buildMusicSection(),
                  const SizedBox(height: 16),
                  _buildInterests(profile),
                  const SizedBox(height: 16),
                  _buildGallery(profile, imgVersion),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileModel profile, String imgVersion) {
    final photoUrl = profile.profilePhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              if (hasPhoto)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: SafeNetworkImage(
                      url: photoUrl,
                      version: imgVersion,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                    ),
                  ),
                )
              else
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [context.primaryColor, context.primaryColor.withOpacity(0.0)])))),
              Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.25), Colors.black.withOpacity(0.55), Colors.transparent], stops: const [0.0, 0.5, 1.0])))),
            ],
          ),
        ),
        
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Row(
            children: [
              if (widget.publicId == null) ...[
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20), onPressed: _openEditProfile),
                IconButton(icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 20), onPressed: _confirmLogout),
              ],
            ],
          ),
        ),
        
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))]),
                    child: ClipOval(
                      child: hasPhoto
                          ? SafeNetworkImage(url: photoUrl, version: imgVersion, width: 88, height: 88, fit: BoxFit.cover)
                          : Container(width: 88, height: 88, color: context.isDark ? context.surfaceColor : Colors.grey.shade200, child: Icon(Icons.person_outline, size: 40, color: context.mutedColor)),
                    ),
                  ),
                  if (widget.publicId == null && !hasPhoto)
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _openEditProfile,
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: context.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.add, color: Colors.white, size: 14)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(profile.fullName, style: AppTypography.displayMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              if (profile.location.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70), const SizedBox(width: 3), Text(profile.location, style: AppTypography.caption.copyWith(color: Colors.white70))]),
              if (profile.headline.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4, left: 24, right: 24), child: Text(profile.headline, style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontStyle: FontStyle.italic), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard(ProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Complete Your Profile', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)), Text('${profile.completionPercentage}%', style: AppTypography.labelMedium.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: profile.completionPercentage / 100, backgroundColor: context.isDark ? context.borderColor : Colors.grey.shade100, color: context.primaryColor, minHeight: 6)),
          if (profile.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: context.borderColor),
            const SizedBox(height: 8),
            Text('Next Steps:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 8),
            ...profile.nextSteps.map((step) => Padding(padding: const EdgeInsets.only(bottom: 6), child: GestureDetector(onTap: _openEditProfile, child: Row(children: [Icon(Icons.add_circle_outline, size: 16, color: context.primaryColor), const SizedBox(width: 8), Text(step.label, style: AppTypography.bodyMedium.copyWith(color: context.textColor))])))),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutMe(ProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Me', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 8),
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.borderColor)), child: Text(profile.bio.isNotEmpty ? profile.bio : 'No bio yet. Tap edit to add one.', style: AppTypography.bodyMedium.copyWith(color: profile.bio.isNotEmpty ? context.textColor : context.mutedColor))),
        ],
      ),
    );
  }

  Widget _buildMusicSection() {
    if (widget.publicId != null) return const SizedBox.shrink();
    final isConnected = _spotifyStatus?.connected ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Music', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.borderColor)),
            child: ListTile(
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF1DB954).withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.music_note_outlined, color: Color(0xFF1DB954), size: 18)),
              title: Text('Music', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(isConnected ? 'Taste synced' : 'Connect to show your music taste', style: AppTypography.caption.copyWith(color: isConnected ? const Color(0xFF1DB954) : AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotifyConnectScreen())); _loadSpotifyStatus(); }),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests(ProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Interests', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 8),
          if (profile.interests.isEmpty)
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.borderColor)), child: Row(children: [Icon(Icons.add_circle_outline, size: 18, color: context.primaryColor), const SizedBox(width: 8), Text('Add your interests', style: AppTypography.bodyMedium.copyWith(color: context.primaryColor))])),
            )
          else
            Wrap(spacing: 8, runSpacing: 8, children: profile.interests.map((interest) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.themePrimaryGlass(context), borderRadius: BorderRadius.circular(999), border: Border.all(color: context.primaryColor.withOpacity(0.2))), child: Text(interest.name, style: AppTypography.labelMedium.copyWith(color: context.primaryColor, fontWeight: FontWeight.w500, fontSize: 12)))).toList()),
        ],
      ),
    );
  }

  Widget _buildGallery(ProfileModel profile, String imgVersion) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gallery', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
              if (widget.publicId == null)
                GestureDetector(onTap: _pickPhoto, child: Row(children: [Icon(Icons.add_photo_alternate_outlined, size: 16, color: context.primaryColor), const SizedBox(width: 4), Text('Upload', style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600))])),
            ],
          ),
          const SizedBox(height: 10),
          if (_galleryLoading && _galleryPhotos.isEmpty)
            _buildGallerySkeleton()
          else if (_galleryPhotos.isEmpty)
            GestureDetector(
              onTap: widget.publicId == null ? _pickPhoto : null,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)), child: Column(children: [Icon(Icons.photo_library_outlined, size: 36, color: context.mutedColor), const SizedBox(height: 8), Text('Your gallery is empty', style: AppTypography.bodyMedium.copyWith(color: context.mutedColor)), if (widget.publicId == null) const SizedBox(height: 4), if (widget.publicId == null) Text('Tap to upload photos', style: AppTypography.caption.copyWith(color: context.mutedColor))])),
            )
          else
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1),
              itemCount: widget.publicId == null ? _galleryPhotos.length + 1 : _galleryPhotos.length,
              itemBuilder: (ctx, i) {
                if (widget.publicId == null && i == 0) {
                  return GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(decoration: BoxDecoration(color: AppColors.themePrimaryGlass(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.primaryColor.withOpacity(0.2))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: context.primaryColor, size: 24), const SizedBox(height: 4), Text('Add', style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600))])),
                  );
                }
                final index = widget.publicId == null ? i - 1 : i;
                final photo = _galleryPhotos[index];
                final photoUrl = photo.imageUrl;
                final hasPhoto = photoUrl.isNotEmpty && (photoUrl.startsWith('http') || photoUrl.startsWith('https'));

                return GestureDetector(
                  onTap: () => _openGalleryViewer(index, profile),
                  onLongPress: widget.publicId == null ? () => _showDeleteDialog(photo) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), 
                    child: hasPhoto 
                      ? SafeNetworkImage(url: photoUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGallerySkeleton() {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1),
      itemCount: 6,
      itemBuilder: (_, __) => const PulsingGlassPlaceholder(borderRadius: 10),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.primaryColor),
            const SizedBox(height: 12),
            Text('Could not load profile', style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(error, style: AppTypography.caption.copyWith(color: context.mutedColor), textAlign: TextAlign.center)),
            const SizedBox(height: 16),
            LiquidGlassButton(size: LiquidButtonSize.md, onPressed: _refreshData, child: Text('Retry', style: AppTypography.buttonText)),
          ],
        ),
      ),
    );
  }
}
