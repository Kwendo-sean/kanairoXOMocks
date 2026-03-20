import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/profile_model.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/profile_api_service.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/singles/moment_viewer_screen.dart';
import 'package:kanairoxo/screens/settings/settings_screen.dart';
import 'package:kanairoxo/utils/auth_storage.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  final String? publicId;

  const ProfileScreen({super.key, this.publicId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final ProfileApiService profileApiService = ProfileApiService();
  final ApiClient _apiClient = ApiClient();
  
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _error;
  
  List<GalleryPhotoModel> _galleryPhotos = [];
  bool _galleryLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
        _loadGallery();
      }
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _apiClient.get(
        'api/v1/profiles/edit/',
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        });
      
      if (!mounted) return;
      
      final profileData = response is Map<String, dynamic>
        ? (response.containsKey('profile') ? response['profile'] as Map<String, dynamic> : response)
        : response as Map<String, dynamic>;

      final profile = ProfileModel.fromJson(profileData);
      
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      if (!mounted) return;
      setState(() => _galleryLoading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(
          onClose: () => Navigator.pop(context, true),
        ),
      ),
    );
    
    if (result == true) {
      _loadProfile();
      _loadGallery();
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle),
                child: Icon(
                  Icons.logout_outlined,
                  color: context.primaryColor,
                  size: 26)),
              
              const SizedBox(height: 16),
              
              Text('Log out?',
                style: AppTypography.displayMedium
                  .copyWith(fontSize: 20, color: context.textColor)),
              
              const SizedBox(height: 8),
              
              Text(
                'You can log back in anytime',
                style: AppTypography.bodyMedium
                  .copyWith(
                    color: context.mutedColor),
                textAlign: TextAlign.center),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: LiquidGlassButton(
                  size: LiquidButtonSize.lg,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performLogout();
                  },
                  child: Text('Log Out',
                    style: AppTypography
                      .buttonText))),
              
              const SizedBox(height: 10),
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => 
                    Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14)),
                  child: Text('Cancel',
                    style: AppTypography
                      .labelMedium.copyWith(
                        color: context.mutedColor,
                        fontWeight: 
                          FontWeight.w500)))),
            ]))));
  }
  
  Future<void> _performLogout() async {
    try {
      await AuthStorage.clearAll();
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainAppScreen()),
                (route) => false);
            },
            onSignupTap: () {},
          )),
        (route) => false);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed',
            style: AppTypography.caption.copyWith(
              color: Colors.white)),
          backgroundColor: Colors.red.shade700));
    }
  }

  Future<void> _uploadGalleryPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    
    try {
      await profileApiService.uploadGalleryPhoto(File(img.path));
      _loadGallery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e', style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteGalleryPhoto(GalleryPhotoModel photo) async {
    final originalPhotos = List<GalleryPhotoModel>.from(_galleryPhotos);
    setState(() => _galleryPhotos.remove(photo));
    try {
      await profileApiService.deleteGalleryPhoto(photo.id);
    } catch (e) {
      setState(() => _galleryPhotos = originalPhotos);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red),
      );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.labelMedium.copyWith(color: context.mutedColor)),
          ),
          LiquidGlassButton(
            size: LiquidButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              _deleteGalleryPhoto(photo);
            },
            child: Text('Remove', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  void _openGalleryViewer(int startIndex) {
    final moments = _galleryPhotos.map((p) => Moment(
      id: p.id.toString(),
      userName: _profile?.fullName ?? 'User',
      userAvatarUrl: _profile?.profilePhotoUrl,
      date: p.uploadedAt,
      type: MomentType.vibe,
      photoUrl: p.imageUrl,
      caption: p.caption,
    )).toList();

    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => MomentViewerScreen(
        moments: moments,
        initialIndex: startIndex,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: Center(child: CircularProgressIndicator(color: context.primaryColor, strokeWidth: 2)),
      );
    }
    
    if (_error != null || _profile == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          await _loadGallery();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  if (_profile!.completionPercentage < 100)
                    _buildCompletionCard(),
                  if (_profile!.completionPercentage < 100)
                    const SizedBox(height: 16),
                  _buildAboutMe(),
                  const SizedBox(height: 16),
                  _buildInterests(),
                  const SizedBox(height: 16),
                  _buildGallery(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              if (_profile!.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: SafeNetworkImage(
                      url: _profile!.profilePhotoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [context.primaryColor, context.primaryColor.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Row(
            children: [
              if (widget.publicId == null) ...[
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  onPressed: _openEditProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                  onPressed: _confirmLogout,
                ),
              ],
            ],
          ),
        ),
        
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (_profile!.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                          ? SafeNetworkImage(
                              url: _profile!.profilePhotoUrl,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 88,
                              height: 88,
                              color: context.isDark ? context.surfaceColor : Colors.grey.shade200,
                              child: Icon(Icons.person_outline, size: 40, color: context.mutedColor),
                            ),
                    ),
                  ),
                  if (widget.publicId == null && (_profile!.profilePhotoUrl == null || _profile!.profilePhotoUrl!.isEmpty))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _openEditProfile,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_profile!.fullName, style: AppTypography.displayMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              if (_profile!.location.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(_profile!.location, style: AppTypography.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              if (_profile!.headline.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 24, right: 24),
                  child: Text(
                    _profile!.headline,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(icon: Icons.visibility_outlined, value: _profile!.viewsCount.toString(), label: 'Views'),
          _buildStatDivider(),
          _StatItem(icon: Icons.bookmark_border, value: _profile!.savesCount.toString(), label: 'Saves'),
          _buildStatDivider(),
          _StatItem(icon: Icons.person_outline, value: '${_profile!.completionPercentage}%', label: 'Complete'),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(height: 30, width: 1, color: context.borderColor);

  Widget _buildCompletionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Complete Your Profile', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
              Text('${_profile!.completionPercentage}%', style: AppTypography.labelMedium.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _profile!.completionPercentage / 100,
              backgroundColor: context.isDark ? context.borderColor : Colors.grey.shade100,
              color: context.primaryColor,
              minHeight: 6,
            ),
          ),
          if (_profile!.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: context.borderColor),
            const SizedBox(height: 8),
            Text('Next Steps:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 8),
            ..._profile!.nextSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: _openEditProfile,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Text(step.label, style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutMe() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Me', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Text(
              _profile!.bio.isNotEmpty ? _profile!.bio : 'No bio yet. Tap edit to add one.',
              style: AppTypography.bodyMedium.copyWith(
                color: _profile!.bio.isNotEmpty ? context.textColor : context.mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Interests', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 8),
          if (_profile!.interests.isEmpty)
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 18, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Text('Add your interests', style: AppTypography.bodyMedium.copyWith(color: context.primaryColor)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.interests.map((interest) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.themePrimaryGlass(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.primaryColor.withOpacity(0.2)),
                ),
                child: Text(
                  interest.name,
                  style: AppTypography.labelMedium.copyWith(color: context.primaryColor, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
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
                GestureDetector(
                  onTap: _uploadGalleryPhoto,
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 16, color: context.primaryColor),
                      const SizedBox(width: 4),
                      Text('Upload', style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_galleryLoading)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor)))
          else if (_galleryPhotos.isEmpty)
            GestureDetector(
              onTap: widget.publicId == null ? _uploadGalleryPhoto : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 36, color: context.mutedColor),
                    const SizedBox(height: 8),
                    Text('Your gallery is empty', style: AppTypography.bodyMedium.copyWith(color: context.mutedColor)),
                    if (widget.publicId == null)
                      const SizedBox(height: 4),
                    if (widget.publicId == null)
                      Text('Tap to upload photos', style: AppTypography.caption.copyWith(color: context.mutedColor)),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: widget.publicId == null ? _galleryPhotos.length + 1 : _galleryPhotos.length,
              itemBuilder: (ctx, i) {
                if (widget.publicId == null && i == 0) {
                  return GestureDetector(
                    onTap: _uploadGalleryPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.themePrimaryGlass(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: context.primaryColor, size: 24),
                          const SizedBox(height: 4),
                          Text('Add', style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }
                final index = widget.publicId == null ? i - 1 : i;
                final photo = _galleryPhotos[index];
                return GestureDetector(
                  onTap: () => _openGalleryViewer(index),
                  onLongPress: widget.publicId == null ? () => _showDeleteDialog(photo) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SafeNetworkImage(url: photo.imageUrl, fit: BoxFit.cover),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error ?? 'Unknown error',
                style: AppTypography.caption.copyWith(
                  color: context.mutedColor),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: _loadProfile,
              child: Text('Retry', style: AppTypography.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.displayMedium.copyWith(fontSize: 16, color: context.textColor)),
        Text(label, style: AppTypography.caption.copyWith(color: context.mutedColor)),
      ],
    );
  }
}
