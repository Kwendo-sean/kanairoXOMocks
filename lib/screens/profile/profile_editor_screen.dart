import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class ProfileEditorScreen extends StatefulWidget {
  final VoidCallback onClose;

  const ProfileEditorScreen({super.key, required this.onClose});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late TextEditingController _bioController;
  late TextEditingController _headlineController;
  final _interestInputController = TextEditingController();

  File? _profilePhotoFile;
  String? _currentPhotoUrl;

  final List<String> _selectedInterests = [];

  String? _selectedNeighborhood;
  String? _selectedLifeStage;
  String? _selectedSocialCircle;
  String? _visibility;

  bool _isLoading = false;

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
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final user = profileProvider.currentUser;
    final profile = user?.profile;

    if (user != null && profile != null) {
      _bioController = TextEditingController(text: profile.bio);
      _headlineController = TextEditingController(text: profile.headline);
      _selectedInterests.addAll(profile.interests);
      _selectedNeighborhood = profile.neighborhoodDisplay;
      _selectedLifeStage = profile.lifeStage;
      _selectedSocialCircle = profile.primarySocialCircle;
      _visibility = profile.profileVisibility ?? 'public';
      _currentPhotoUrl = profile.mainProfilePhoto;
    } else {
      _bioController = TextEditingController();
      _headlineController = TextEditingController();
      _visibility = 'public';
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

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (_profilePhotoFile != null) {
        await profileProvider.uploadProfilePhotos([XFile(_profilePhotoFile!.path)]);
      }

      final update = UserProfileUpdate(
        bio: _bioController.text.trim(),
        headline: _headlineController.text.trim(),
        primaryNeighborhood: _selectedNeighborhood,
        lifeStage: _selectedLifeStage,
        primarySocialCircle: _selectedSocialCircle,
        interests: _selectedInterests,
        profileVisibility: _visibility,
      );

      await profileProvider.updateProfile(update);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated', style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save profile', style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 22),
          onPressed: widget.onClose),
        title: Text('Edit Profile', style: AppTypography.screenTitle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text('Save', style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePhoto(),
            const SizedBox(height: 24),
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildLocationLifestyle(),
            const SizedBox(height: 20),
            _buildInterests(),
            const SizedBox(height: 20),
            _buildVisibility(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
              ]),
            child: ClipOval(
              child: _profilePhotoFile != null
                ? Image.file(_profilePhotoFile!, fit: BoxFit.cover)
                : SafeNetworkImage(url: _currentPhotoUrl, fit: BoxFit.cover, width: 96, height: 96))),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 15)))),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Basic Info'),
        const SizedBox(height: 12),
        _StyledTextField(
          controller: _headlineController,
          hint: 'Headline',
          prefixIcon: Icons.title_outlined,
          maxLines: 1,
          maxLength: 150),
        const SizedBox(height: 10),
        _StyledTextField(
          controller: _bioController,
          hint: 'Tell people about yourself...',
          prefixIcon: Icons.person_outline,
          maxLines: 4,
          maxLength: 500),
      ],
    );
  }

  Widget _buildLocationLifestyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'About You'),
        const SizedBox(height: 12),
        _StyledDropdown(
          value: _selectedNeighborhood,
          hint: 'Primary Neighborhood',
          prefixIcon: Icons.location_on_outlined,
          items: _neighborhoods,
          onChanged: (val) => setState(() => _selectedNeighborhood = val)),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedLifeStage,
          hint: 'Life Stage',
          prefixIcon: Icons.timeline_outlined,
          items: _lifeStages,
          onChanged: (val) => setState(() => _selectedLifeStage = val)),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedSocialCircle,
          hint: 'Primary Social Circle',
          prefixIcon: Icons.group_outlined,
          items: _socialCircles,
          onChanged: (val) => setState(() => _selectedSocialCircle = val)),
      ],
    );
  }

  Widget _buildInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Interests'),
        const SizedBox(height: 8),
        Text('Add anything you are into', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _interestInputController,
              style: AppTypography.bodyMedium,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Add an interest',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              onSubmitted: (_) => _addInterest(),
            )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addInterest,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white, size: 20))),
        ]),
        const SizedBox(height: 12),
        if (_selectedInterests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No interests added yet', style: AppTypography.caption.copyWith(color: AppColors.textMuted)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) =>
              _InterestChip(label: interest, onDelete: () => _removeInterest(interest))).toList()),
      ],
    );
  }

  Widget _buildVisibility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Profile Visibility'),
        const SizedBox(height: 8),
        Text('Controls who can see your Moments', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        _VisibilityOption(
          icon: Icons.public_outlined,
          title: 'Public',
          subtitle: 'Everyone on KanairoXO can see your Moments',
          isSelected: _visibility == 'public',
          onTap: () => setState(() => _visibility = 'public')),
        const SizedBox(height: 10),
        _VisibilityOption(
          icon: Icons.people_outline,
          title: 'Connections Only',
          subtitle: 'Only people you are connected with can see your Moments',
          isSelected: _visibility == 'connections',
          onTap: () => setState(() => _visibility = 'connections')),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: LiquidGlassButton(
        size: LiquidButtonSize.xl,
        onPressed: _isLoading ? null : _saveProfile,
        child: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text('Save Changes', style: AppTypography.buttonText)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final int maxLines;
  final int maxLength;

  const _StyledTextField({required this.controller, required this.hint, required this.prefixIcon, this.maxLines = 1, this.maxLength = 100});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))));
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({required this.value, required this.hint, required this.prefixIcon, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      hint: Row(children: [
        Icon(prefixIcon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(hint, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted))]),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: AppTypography.bodyMedium))).toList(),
      onChanged: onChanged);
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  const _InterestChip({required this.label, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primaryGlass, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onDelete, child: const Icon(Icons.close, size: 14, color: AppColors.primary)),
        ]));
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _VisibilityOption({required this.icon, required this.title, required this.subtitle, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGlass : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 1.5 : 1)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: isSelected ? Colors.white : AppColors.textMuted, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ])),
          if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ])));
  }
}
