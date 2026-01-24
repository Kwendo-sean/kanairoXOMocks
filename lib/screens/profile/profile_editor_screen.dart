// lib/screens/profile/profile_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/widgets/loading_indicator.dart';
import 'package:kanairoxo/models/user_model.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late TextEditingController _bioController;
  late TextEditingController _headlineController;
  final _interestController = TextEditingController();

  final List<String> _selectedInterests = [];

  String? _selectedNeighborhood;
  String? _selectedLifeStage;
  String? _selectedSocialCircle;
  String? _selectedConnectionFrequency;
  String? _selectedVisibility;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final user = profileProvider.currentUser;

    if (user != null) {
      _bioController = TextEditingController(text: user.bio);
      _headlineController = TextEditingController(text: user.headline);
      _selectedInterests.addAll(user.interests);
      _selectedNeighborhood = user.primaryNeighborhood;
      _selectedLifeStage = user.lifeStage;
      _selectedSocialCircle = user.primarySocialCircle;
      _selectedConnectionFrequency = user.connectionFrequency;
      _selectedVisibility = user.profileVisibility;
    } else {
      _bioController = TextEditingController();
      _headlineController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _headlineController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      final update = UserProfileUpdate(
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        headline: _headlineController.text.isNotEmpty ? _headlineController.text : null,
        primaryNeighborhood: _selectedNeighborhood,
        lifeStage: _selectedLifeStage,
        primarySocialCircle: _selectedSocialCircle,
        interests: _selectedInterests,
        connectionFrequency: _selectedConnectionFrequency,
        profileVisibility: _selectedVisibility,
      );

      await profileProvider.updateProfile(update);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppConstants.successGreen,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label'),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

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
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppConstants.primaryBlack),
        ),
      ),
      body: _isSaving
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline
            TextField(
              controller: _headlineController,
              decoration: const InputDecoration(
                labelText: 'Headline',
                hintText: 'Brief tagline about yourself',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Bio
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            // Neighborhood
            _buildDropdown(
              label: 'Primary Neighborhood',
              value: _selectedNeighborhood,
              options: profileProvider.neighborhoods,
              onChanged: (value) {
                setState(() {
                  _selectedNeighborhood = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Life Stage
            _buildDropdown(
              label: 'Life Stage',
              value: _selectedLifeStage,
              options: profileProvider.lifeStages,
              onChanged: (value) {
                setState(() {
                  _selectedLifeStage = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Social Circle
            _buildDropdown(
              label: 'Primary Social Circle',
              value: _selectedSocialCircle,
              options: profileProvider.socialCircles,
              onChanged: (value) {
                setState(() {
                  _selectedSocialCircle = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Interests
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      onDeleted: () {
                        setState(() {
                          _selectedInterests.remove(interest);
                        });
                      },
                    );
                  }).toList(),
                ),

                // Add interest
                const SizedBox(height: 16),
                TextField(
                  controller: _interestController,
                  decoration: InputDecoration(
                    hintText: 'Add an interest...',
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (_interestController.text.isNotEmpty) {
                          setState(() {
                            _selectedInterests.add(_interestController.text.trim());
                            _interestController.clear();
                          });
                        }
                      },
                      icon: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.regular)),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _selectedInterests.add(value.trim());
                        _interestController.clear();
                      });
                    }
                  },
                ),

                // Suggested interests
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profileProvider.commonInterests
                      .where((interest) => !_selectedInterests.contains(interest))
                      .take(10)
                      .map((interest) {
                    return ActionChip(
                      label: Text(interest),
                      onPressed: () {
                        setState(() {
                          _selectedInterests.add(interest);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Connection Frequency
            _buildDropdown(
              label: 'Connection Frequency',
              value: _selectedConnectionFrequency,
              options: profileProvider.connectionFrequencies,
              onChanged: (value) {
                setState(() {
                  _selectedConnectionFrequency = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Visibility
            _buildDropdown(
              label: 'Profile Visibility',
              value: _selectedVisibility,
              options: profileProvider.visibilityOptions,
              onChanged: (value) {
                setState(() {
                  _selectedVisibility = value;
                });
              },
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
