import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/user_model.dart';

class ProfileEditorScreen extends StatefulWidget {
  final VoidCallback onClose;

  const ProfileEditorScreen({super.key, required this.onClose});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _bioController = TextEditingController();
  final _headlineController = TextEditingController();
  final _interestInputController = TextEditingController();

  File? _profilePhotoFile;
  String? _currentPhotoUrl;

  final List<String> _selectedInterests = [];

  String? _selectedNeighborhood;
  String? _selectedLifeStage;
  String? _selectedSocialCircle;
  String? _visibility;
  String? _gender;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSelectingGender = false;
  final ApiClient apiClient = ApiClient();

  final _neighborhoods = [
    'Westlands', 'Kilimani', 'Karen',
    'Lavington', 'Kileleshwa', 'Parklands',
    'South B', 'South C', 'Eastleigh',
    'Kasarani', 'Embakasi', 'Langata',
    'Ngong Road', 'Ruaka', 'Kitengela',
    'Thika Road', 'Rongai', 'Other',
  ];

  final _lifeStages = [
    'Student', 'Early Career', 'Established Career',
    'Entrepreneur', 'Freelancer', 'Creative',
    'Remote Worker', 'Between Chapters',
  ];

  final _socialCircles = [
    'Arts & Culture', 'Tech & Startups',
    'Finance & Business', 'Health & Wellness',
    'Food & Hospitality', 'Sports & Outdoors',
    'Music & Entertainment', 'Fashion & Lifestyle',
    'Social Impact & NGO', 'Academia & Research',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final user = await profileProvider.loadMyProfile();
      final profile = profileProvider.myProfile;

      if (user != null && profile != null) {
        _bioController.text = profile.bio;
        _headlineController.text = profile.headline;
        _selectedInterests.clear();
        _selectedInterests.addAll(profile.interests.map((i) => i.name));
        _selectedNeighborhood = profile.primaryNeighborhood;
        _selectedLifeStage = profile.lifeStage;
        _selectedSocialCircle = profile.primarySocialCircle;
        _visibility = profile.profileVisibility;
        _currentPhotoUrl = profile.profilePhotoUrl;
        _gender = user.gender;

        // Force gender selection ONLY for social logins (no phone number) missing gender
        if ((_gender == null || _gender!.isEmpty) && user.phoneNumber.isEmpty) {
          _isSelectingGender = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _headlineController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text('Take a photo', style: AppTypography.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (img != null) setState(() => _profilePhotoFile = File(img.path));
              }),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Choose from gallery', style: AppTypography.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (img != null) setState(() => _profilePhotoFile = File(img.path));
              }),
            const SizedBox(height: 8),
          ])));
  }

  Future<void> _addInterest() async {
    final name = _interestInputController.text.trim();
    if (name.isEmpty) return;
    if (_selectedInterests.any((i) => i.toLowerCase() == name.toLowerCase())) return;
    setState(() {
      _selectedInterests.add(name);
      _interestInputController.clear();
    });
  }

  void _removeInterest(String name) {
    setState(() => _selectedInterests.remove(name));
  }

  Future<void> _updateGender(String gender) async {
    setState(() => _isSaving = true);
    try {
      await apiClient.patch('api/v1/profiles/edit/', {'gender': gender});
      setState(() {
        _gender = gender;
        _isSelectingGender = false;
        _isSaving = false;
      });
    } catch (e) {
      debugPrint('Error updating gender: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update gender: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // 1. Update basic profile info via Provider
      await profileProvider.updateProfile(UserProfileUpdate(
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        primaryNeighborhood: _selectedNeighborhood,
        lifeStage: _selectedLifeStage,
        primarySocialCircle: _selectedSocialCircle,
        profileVisibility: _visibility,
        interests: _selectedInterests,
      ));
      
      // 2. Update account info (gender) - sync with profiles/edit as requested
      if (_gender != null) {
        await apiClient.patch('api/v1/profiles/edit/', {'gender': _gender});
      }
      
      // 3. Upload photo if changed - Uses specific upload endpoint with immediate UI sync
      if (_profilePhotoFile != null) {
        await profileProvider.uploadProfilePhoto(_profilePhotoFile!);
      }
      
      // 4. Refresh both providers to sync state and prevent loops
      await profileProvider.refreshMyProfile();
      await authProvider.refreshProfile();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully',
            style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2)));
      
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      
    } catch (e) {
      debugPrint('Save error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: ${e.toString()}',
            style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final mutedColor = isDark ? const Color(0xFF9A8F85) : const Color(0xFFA0A0A0);
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;
    final primaryColor = isDark ? const Color(0xFFC0394B) : const Color(0xFF8B1A1A);
    final primaryGlass = isDark ? const Color(0x26C0394B) : const Color(0x148B1A1A);
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_isSelectingGender) {
      return _buildGenderSelectionStep(bgColor, textColor, mutedColor, surfaceColor, borderColor, primaryColor, primaryGlass);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
          onPressed: widget.onClose),
        title: Text('Edit Profile', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text('Save', style: AppTypography.labelMedium.copyWith(color: primaryColor, fontWeight: FontWeight.w600))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePhoto(borderColor, primaryColor),
            const SizedBox(height: 24),
            _buildBasicInfo(textColor, mutedColor, surfaceColor, borderColor, primaryColor),
            const SizedBox(height: 20),
            _buildLocationLifestyle(textColor, mutedColor, surfaceColor, borderColor, primaryColor),
            const SizedBox(height: 20),
            _buildInterests(textColor, mutedColor, surfaceColor, borderColor, primaryColor, primaryGlass, isDark),
            const SizedBox(height: 20),
            _buildVisibility(textColor, mutedColor, surfaceColor, borderColor, primaryColor, primaryGlass),
            const SizedBox(height: 32),
            _buildSaveButton(bgColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelectionStep(Color bgColor, Color textColor, Color mutedColor, Color surfaceColor, Color borderColor, Color primaryColor, Color primaryGlass) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('One last thing', style: AppTypography.displayLarge.copyWith(color: textColor, fontSize: 32)),
              const SizedBox(height: 12),
              Text('How do you identify? This helps us curate better experiences for you.', 
                style: AppTypography.bodyLarge.copyWith(color: mutedColor)),
              const SizedBox(height: 48),
              _buildGenderCard('Man', 'male', Icons.male, primaryColor, primaryGlass, borderColor, textColor, mutedColor, surfaceColor),
              const SizedBox(height: 16),
              _buildGenderCard('Woman', 'female', Icons.female, primaryColor, primaryGlass, borderColor, textColor, mutedColor, surfaceColor),
              const Spacer(),
              if (_isSaving)
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String label, String value, IconData icon, Color primaryColor, Color primaryGlass, Color borderColor, Color textColor, Color mutedColor, Color surfaceColor) {
    bool isSelected = _gender == value;
    return GestureDetector(
      onTap: _isSaving ? null : () => _updateGender(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryGlass : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryColor : borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : borderColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : mutedColor, size: 24),
            ),
            const SizedBox(width: 16),
            Text(label, style: AppTypography.bodyLarge.copyWith(
              color: isSelected ? primaryColor : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            )),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(Color borderColor, Color primaryColor) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final imgVersion = profileProvider.imageVersion;
    final myProfile = profileProvider.myProfile;
    
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
              ]),
            child: ClipOval(
              child: _profilePhotoFile != null
                ? Image.file(_profilePhotoFile!, fit: BoxFit.cover)
                : SafeNetworkImage(
                    url: myProfile?.profilePhotoUrl ?? _currentPhotoUrl, 
                    version: imgVersion,
                    fit: BoxFit.cover, 
                    width: 100, 
                    height: 100))),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)))),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(Color textColor, Color mutedColor, Color surfaceColor, Color borderColor, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Basic Info', textColor: textColor),
        const SizedBox(height: 12),
        _StyledTextField(
          controller: _headlineController,
          hint: 'Headline',
          prefixIcon: Icons.title_outlined,
          maxLines: 1,
          maxLength: 150,
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
        const SizedBox(height: 10),
        _StyledTextField(
          controller: _bioController,
          hint: 'Tell people about yourself...',
          prefixIcon: Icons.person_outline,
          maxLines: 4,
          maxLength: 500,
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
      ],
    );
  }

  Widget _buildLocationLifestyle(Color textColor, Color mutedColor, Color surfaceColor, Color borderColor, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'About You', textColor: textColor),
        const SizedBox(height: 12),
        _StyledDropdown(
          value: _gender == 'male' ? 'Male' : (_gender == 'female' ? 'Female' : null),
          hint: 'Gender',
          prefixIcon: Icons.wc_outlined,
          items: ['Male', 'Female'],
          onChanged: (val) {
             if (val == 'Male') setState(() => _gender = 'male');
             if (val == 'Female') setState(() => _gender = 'female');
          },
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedNeighborhood,
          hint: 'Primary Neighborhood',
          prefixIcon: Icons.location_on_outlined,
          items: _neighborhoods,
          onChanged: (val) => setState(() => _selectedNeighborhood = val),
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedLifeStage,
          hint: 'Life Stage',
          prefixIcon: Icons.timeline_outlined,
          items: _lifeStages,
          onChanged: (val) => setState(() => _selectedLifeStage = val),
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedSocialCircle,
          hint: 'Primary Social Circle',
          prefixIcon: Icons.group_outlined,
          items: _socialCircles,
          onChanged: (val) => setState(() => _selectedSocialCircle = val),
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor),
      ],
    );
  }

  Widget _buildInterests(Color textColor, Color mutedColor, Color surfaceColor, Color borderColor, Color primaryColor, Color primaryGlass, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Interests', textColor: textColor),
        const SizedBox(height: 8),
        Text('Add anything you are into', style: AppTypography.caption.copyWith(color: mutedColor)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _interestInputController,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Add an interest',
                hintStyle: AppTypography.bodyMedium.copyWith(color: mutedColor),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
              ),
              onSubmitted: (_) => _addInterest(),
            )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addInterest,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white, size: 20))),
        ]),
        const SizedBox(height: 12),
        if (_selectedInterests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No interests added yet', style: AppTypography.caption.copyWith(color: mutedColor)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) =>
              _InterestChip(label: interest, onDelete: () => _removeInterest(interest), primaryColor: primaryColor, primaryGlass: primaryGlass, isDark: isDark)).toList()),
      ],
    );
  }

  Widget _buildVisibility(Color textColor, Color mutedColor, Color surfaceColor, Color borderColor, Color primaryColor, Color primaryGlass) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Profile Visibility', textColor: textColor),
        const SizedBox(height: 8),
        Text('Controls who can see your Moments', style: AppTypography.caption.copyWith(color: mutedColor)),
        const SizedBox(height: 12),
        _VisibilityOption(
          icon: Icons.public_outlined,
          title: 'Public',
          subtitle: 'Everyone on KanairoXO can see your Moments',
          isSelected: _visibility == 'public',
          onTap: () => setState(() => _visibility = 'public'),
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor,
          primaryGlass: primaryGlass),
        const SizedBox(height: 10),
        _VisibilityOption(
          icon: Icons.people_outline,
          title: 'Connections Only',
          subtitle: 'Only people you are connected with can see your Moments',
          isSelected: _visibility == 'connections',
          onTap: () => setState(() => _visibility = 'connections'),
          textColor: textColor,
          mutedColor: mutedColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          primaryColor: primaryColor,
          primaryGlass: primaryGlass),
      ],
    );
  }

  Widget _buildSaveButton(Color bgColor) {
    return Container(
      color: bgColor,
      width: double.infinity,
      child: LiquidGlassButton(
        size: LiquidButtonSize.xl,
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text('Save Changes', style: AppTypography.buttonText)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: textColor));
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final int maxLines;
  final int maxLength;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryColor;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.maxLines = 1,
    this.maxLength = 100,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: AppTypography.bodyMedium.copyWith(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: mutedColor),
        prefixIcon: Icon(prefixIcon, size: 18, color: mutedColor),
        filled: true,
        fillColor: surfaceColor,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5))));
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryColor;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      dropdownColor: surfaceColor,
      value: items.contains(value) ? value : null,
      hint: Row(children: [
        Icon(prefixIcon, size: 18, color: mutedColor),
        const SizedBox(width: 10),
        Text(hint, style: AppTypography.bodyMedium.copyWith(color: mutedColor))]),
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: mutedColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5))),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: AppTypography.bodyMedium.copyWith(color: textColor)))).toList(),
      onChanged: onChanged);
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final Color primaryColor;
  final Color primaryGlass;
  final bool isDark;
  const _InterestChip({required this.label, required this.onDelete, required this.primaryColor, required this.primaryGlass, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withOpacity(0.15) : primaryGlass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.labelMedium.copyWith(color: primaryColor, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onDelete, child: Icon(Icons.close, size: 14, color: primaryColor)),
        ]));
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryColor;
  final Color primaryGlass;

  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryColor,
    required this.primaryGlass});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primaryGlass : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : borderColor, width: isSelected ? 1.5 : 1)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isSelected ? primaryColor : (Theme.of(context).brightness == Brightness.dark ? borderColor : Colors.grey.shade100), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: isSelected ? Colors.white : mutedColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: isSelected ? primaryColor : textColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption.copyWith(color: mutedColor)),
            ])),
          if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
        ])));
  }
}
