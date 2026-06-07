import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:intl/intl.dart';

class NewOnboardingScreen extends StatefulWidget {
  const NewOnboardingScreen({super.key});

  @override
  State<NewOnboardingScreen> createState() => _NewOnboardingScreenState();
}

class _NewOnboardingScreenState extends State<NewOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final ApiClient apiClient = ApiClient();

  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  File? _profilePhoto;
  List<String> _selectedIntents = [];
  List<String> _selectedInterests = [];
  String? _neighborhood;
  String? _lifeStage;

  final List<String> _intents = ['friendship', 'dating', 'networking', 'events', 'communities'];
  final List<String> _interests = [
    'Art', 'Music', 'Tech', 'Food', 'Travel', 'Fitness', 'Movies', 'Gaming',
    'Photography', 'Fashion', 'Sports', 'Reading', 'Dancing', 'Yoga', 'Coffee',
    'Nightlife', 'Hiking', 'Cooking', 'Startups', 'Design', 'Anime', 'Business',
    'Pets', 'Nature', 'Wellness', 'Parties', 'Concerts', 'Web3', 'AI', 'Coding'
  ];

  final List<String> _neighborhoods = ['Kilimani', 'Lavington', 'Westlands', 'Karen', 'South B', 'South C', 'Parklands', 'Kileleshwa', 'Langata', 'Ngong Road'];
  final List<String> _lifeStages = ['Student', 'Professional', 'Entrepreneur', 'New in City', 'Single Parent', 'Retired'];

  bool _isSubmitting = false;

  void _nextPage() {
    if (_currentStep < 7) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSubmitting = true);
    try {
      await apiClient.patch('api/v1/profiles/me/', {
        'full_name': _nameController.text,
        'date_of_birth': _dob?.toIso8601String(),
        'gender': _gender,
        'intents': _selectedIntents,
        'interests': _selectedInterests,
        'neighborhood': _neighborhood,
        'life_stage': _lifeStage,
        'onboarding_completed': true,
      });

      if (_profilePhoto != null) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.uploadProfilePhoto(_profilePhoto!);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main_single');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                  _buildStep7(),
                  _buildStep8(),
                  _buildStep9(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20),
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            )
          else
            const SizedBox(width: 40),
          Text('${_currentStep + 2} of 9', style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.bold)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    bool canGoNext = false;
    switch (_currentStep) {
      case 0: canGoNext = _nameController.text.isNotEmpty && _dob != null && _gender != null; break;
      case 1: canGoNext = _profilePhoto != null; break;
      case 2: canGoNext = _selectedIntents.isNotEmpty; break;
      case 3: canGoNext = _selectedInterests.length >= 5; break;
      case 4: canGoNext = _neighborhood != null; break;
      default: canGoNext = true;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: LiquidGlassButton(
        width: double.infinity,
        onPressed: (canGoNext && !_isSubmitting) ? _nextPage : null,
        child: _isSubmitting
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(_currentStep == 7 ? 'Enter KanairoXO' : 'Continue'),
      ),
    );
  }

  Widget _buildStep2() {
    return _StepLayout(
      title: "Tell us about you",
      subtitle: "The basics to help people get to know you.",
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: context.textColor, fontSize: 18),
            decoration: _inputDecoration("Full Name"),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
              );
              if (picked != null) setState(() => _dob = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: context.mutedColor, size: 20),
                  const SizedBox(width: 12),
                  Text(_dob == null ? "Date of Birth" : DateFormat('dd MMM yyyy').format(_dob!),
                    style: TextStyle(color: _dob == null ? context.mutedColor : context.textColor, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(alignment: Alignment.centerLeft, child: Text("Gender", style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          Row(
            children: ['Man', 'Woman', 'Non-binary'].map((g) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: _cardDecoration(isSelected: _gender == g),
                  child: Center(child: Text(g, style: TextStyle(color: _gender == g ? context.primaryColor : context.textColor, fontWeight: FontWeight.w600))),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _StepLayout(
      title: "Add your best photo",
      subtitle: "MANDATORY. We're keeping KanairoXO real. Profiles without photos can't proceed.",
      child: Center(
        child: GestureDetector(
          onTap: () async {
            final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) setState(() => _profilePhoto = File(picked.path));
          },
          child: Container(
            width: 260, height: 360,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: _profilePhoto != null
              ? ClipRRect(borderRadius: BorderRadius.circular(32), child: Image.file(_profilePhoto!, fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 48, color: AppConstants.primaryRed),
                    const SizedBox(height: 16),
                    Text('Upload Photo', style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.bold)),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return _StepLayout(
      title: "What are you here for?",
      subtitle: "Pick 1-3 intents so we can match you better.",
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: _intents.map((intent) {
          final isSelected = _selectedIntents.contains(intent);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) _selectedIntents.remove(intent);
                else if (_selectedIntents.length < 3) _selectedIntents.add(intent);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: _cardDecoration(isSelected: isSelected),
              child: Text(intent.replaceFirst(intent[0], intent[0].toUpperCase()),
                style: TextStyle(color: isSelected ? context.primaryColor : context.textColor, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep5() {
    return _StepLayout(
      title: "What do you love?",
      subtitle: "Pick at least 5 interests.",
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10, runSpacing: 10,
          children: _interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) _selectedInterests.remove(interest);
                  else _selectedInterests.add(interest);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryRed : context.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? AppConstants.primaryRed : context.borderColor),
                ),
                child: Text(interest, style: TextStyle(color: isSelected ? Colors.white : context.textColor, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStep6() {
    return _StepLayout(
      title: "Where do you stay?",
      subtitle: "We'll show you people and events in your area.",
      child: ListView.builder(
        itemCount: _neighborhoods.length,
        itemBuilder: (context, i) {
          final n = _neighborhoods[i];
          final isSelected = _neighborhood == n;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            title: Text(n, style: TextStyle(color: isSelected ? AppConstants.primaryRed : context.textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppConstants.primaryRed) : null,
            onTap: () => setState(() => _neighborhood = n),
          );
        },
      ),
    );
  }

  Widget _buildStep7() {
    return _StepLayout(
      title: "Life Stage",
      subtitle: "Optional: Helps us build your social circle.",
      child: Column(
        children: _lifeStages.map((stage) {
          final isSelected = _lifeStage == stage;
          return GestureDetector(
            onTap: () => setState(() => _lifeStage = stage),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(isSelected: isSelected),
              child: Text(stage, style: TextStyle(color: isSelected ? context.primaryColor : context.textColor, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep8() {
    return _StepLayout(
      title: "Voice Intro",
      subtitle: "Optional: Introduce yourself in 15s. People love hearing the person behind the profile.",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: context.surfaceColor, shape: BoxShape.circle, border: Border.all(color: context.borderColor)),
              child: const Icon(Icons.mic, color: AppConstants.primaryRed, size: 40),
            ),
            const SizedBox(height: 24),
            Text("Hold to record", style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep9() {
    return _StepLayout(
      title: "One last thing...",
      subtitle: "We need these permissions to give you the full KanairoXO experience.",
      child: Column(
        children: const [
          _PermissionRow(icon: Icons.notifications, title: "Push Notifications", desc: "For new messages and event invites."),
          SizedBox(height: 20),
          _PermissionRow(icon: Icons.location_on, title: "Location Access", desc: "To find matches and events near you."),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.mutedColor.withOpacity(0.5)),
      filled: true,
      fillColor: context.surfaceColor,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  BoxDecoration _cardDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? AppConstants.primaryRed.withOpacity(0.15) : context.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isSelected ? AppConstants.primaryRed : context.borderColor, width: 1.5),
    );
  }
}

class _StepLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepLayout({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.displayMedium.copyWith(color: context.textColor, fontSize: 26)),
          const SizedBox(height: 10),
          Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: context.mutedColor)),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _PermissionRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryRed, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(color: context.mutedColor, fontSize: 12)),
          ])),
          Switch(value: true, onChanged: (v) {}, activeColor: AppConstants.primaryRed),
        ],
      ),
    );
  }
}
