import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/auth/auth_input_field.dart';
import 'package:kanairoxo/models/user_model.dart';

class ProfileEditorScreen extends StatefulWidget {
  final User user;

  const ProfileEditorScreen({super.key, required this.user});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _interestsController;
  final List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Coffee', 'Art', 'Music', 'Travel', 'Photography',
    'Food', 'Wine', 'Hiking', 'Reading', 'Yoga',
    'Meditation', 'Technology', 'Fashion', 'Sports',
    'Movies', 'Writing', 'Dancing', 'Cooking'
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.user.bio);
    _locationController = TextEditingController(text: widget.user.location);
    _interestsController = TextEditingController();
    _selectedInterests.addAll(widget.user.interests);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Save profile logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppConstants.successGreen,
      ),
    );
    Navigator.pop(context);
  }

  void _addInterest(String interest) {
    if (!_selectedInterests.contains(interest)) {
      setState(() {
        _selectedInterests.add(interest);
      });
      _interestsController.clear();
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _selectedInterests.remove(interest);
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.camera(PhosphorIconsStyle.regular), color: AppConstants.primaryRed),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera
                },
              ),
              ListTile(
                leading:  PhosphorIcon(PhosphorIcons.image(PhosphorIconsStyle.regular), color: AppConstants.primaryRed),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle gallery
                },
              ),
              ListTile(
                leading:  PhosphorIcon(PhosphorIcons.trash(PhosphorIconsStyle.regular), color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle remove photo
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _getProfileImage(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage('assets/images/kanairoxo_logo.png');
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular)),
          color: AppConstants.primaryBlack,
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppConstants.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            GestureDetector(
              onTap: _showImagePicker,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.lightGray,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _getProfileImage(widget.user.profileImageUrl),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child:  PhosphorIcon(
                        PhosphorIcons.camera(PhosphorIconsStyle.regular),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.secondaryGray,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),

            // Name and Age
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First Name',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.firstName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Name',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.lastName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Age',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.user.age}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bio
            AuthInputField(
              controller: _bioController,
              label: 'Bio',
              hintText: 'Tell people about yourself...',
              prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),

            // Location
            AuthInputField(
              controller: _locationController,
              label: 'Location',
              hintText: 'Where are you based?',
              prefixIcon: PhosphorIcon(PhosphorIcons.mapPin(PhosphorIconsStyle.regular)),
            ),
            const SizedBox(height: 20),

            // Interests
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Selected interests
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedInterests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
                      deleteIcon: PhosphorIcon(
                        PhosphorIcons.x(PhosphorIconsStyle.regular),
                        size: 14,
                      ),
                      onDeleted: () => _removeInterest(interest),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Add interest
                TextField(
                  controller: _interestsController,
                  decoration: InputDecoration(
                    hintText: 'Add an interest...',
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (_interestsController.text.isNotEmpty) {
                          _addInterest(_interestsController.text);
                        }
                      },
                      icon: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.regular)),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _addInterest(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Suggested interests
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.where(
                    (interest) => !_selectedInterests.contains(interest)
                  ).map((interest) {
                    return ActionChip(
                      label: Text(interest),
                      onPressed: () => _addInterest(interest),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Preferences section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.users(PhosphorIconsStyle.regular), size: 20, color: AppConstants.secondaryGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Interested in',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      DropdownButton<String>(
                        value: widget.user.interestedIn ?? 'Everyone',
                        items: const ['Everyone', 'Male', 'Female', 'Non-binary']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.eye(PhosphorIconsStyle.regular), size: 20, color: AppConstants.secondaryGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show my age',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: AppConstants.primaryRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.mapPin(PhosphorIconsStyle.regular), size: 20, color: AppConstants.secondaryGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show distance',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: AppConstants.primaryRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
