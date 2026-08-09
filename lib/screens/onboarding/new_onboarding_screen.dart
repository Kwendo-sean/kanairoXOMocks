import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:intl/intl.dart';

// ── Brand tokens ─────────────────────────────────────────────────────────────
const _kCream  = Color(0xFFFAF7F4);
const _kRed    = Color(0xFF9B111E);
const _kText   = Color(0xFF1A1A1A);
const _kMuted  = Color(0xFF888888);
const _kBorder = Color(0xFFE8E0D0);
const _kDark   = Color(0xFF0D0D0D);

// ── Option lists ──────────────────────────────────────────────────────────────
const _energyOptions = [
  'Live music', 'Food experiences', 'Game nights', 'Art & creativity',
  'Outdoor adventures', 'Parties', 'Sports', 'Coffee dates',
  'Movies', 'Networking', 'Travel', 'Wellness',
];

const _neighbourhoodOptions = [
  'Westlands', 'Kilimani', 'Lavington', 'Karen',
  'CBD', 'Parklands', 'Ngong Road', 'Other',
];


// ── Screen ────────────────────────────────────────────────────────────────────

class NewOnboardingScreen extends StatefulWidget {
  const NewOnboardingScreen({super.key});

  @override
  State<NewOnboardingScreen> createState() => _NewOnboardingScreenState();
}

class _NewOnboardingScreenState extends State<NewOnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  // Step map:
  //  0 - brand / welcome
  //  1 - energy / interests
  //  2 - neighbourhood
  //  3 - create account (signup form)
  //  4 - photos + bio
  //  5 - safety & community
  //  6 - final reward

  static const _totalProgressSteps = 5; // steps 1–5

  // ── Onboarding data ───────────────────────────────────────────────────────
  final List<String> _interests  = [];
  String? _neighbourhood;

  // ── Signup form data ──────────────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  DateTime? _dob;
  String? _gender;           // 'male' | 'female'
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _agreeTerms     = false;
  final _signupFormKey = GlobalKey<FormState>();

  // ── Profile data ──────────────────────────────────────────────────────────
  File? _photo1;
  File? _photo2;
  final _bioCtrl = TextEditingController();

  // ── Safety ────────────────────────────────────────────────────────────────
  bool _agreedGuidelines = false;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _registering = false;
  bool _submitting  = false;
  String? _signupError;

  @override
  void dispose() {
    _page.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  bool get _canAdvance {
    switch (_step) {
      case 0: return true;
      case 1: return _interests.isNotEmpty;
      case 2: return _neighbourhood != null;
      case 3: return false; // handled by register button
      case 4: return _photo1 != null && _bioCtrl.text.trim().isNotEmpty;
      case 5: return _agreedGuidelines;
      default: return false;
    }
  }

  void _advance() {
    if (_step < 6) {
      _page.animateToPage(_step + 1,
          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step > 0) {
      _page.animateToPage(_step - 1,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  // ── Register (step 3) ─────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_signupFormKey.currentState!.validate()) return;
    if (_gender == null) {
      setState(() => _signupError = 'Please select your gender');
      return;
    }
    if (_dob == null) {
      setState(() => _signupError = 'Please enter your date of birth');
      return;
    }
    if (!_agreeTerms) {
      setState(() => _signupError = 'Please accept the Terms & Privacy Policy');
      return;
    }

    setState(() { _registering = true; _signupError = null; });
    try {
      await context.read<AuthProvider>().register({
        'firstName':             _firstNameCtrl.text.trim(),
        'lastName':              _lastNameCtrl.text.trim(),
        'email':                 _emailCtrl.text.trim(),
        'phoneNumber':           _phoneCtrl.text.trim(),
        'password':              _passwordCtrl.text,
        'password2':             _confirmCtrl.text,
        'gender':                _gender,
        'dateOfBirth':           _dob!.toIso8601String(),
        'termsAccepted':         true,
        'privacyPolicyAccepted': true,
        'accountType':           'single',
      });
      _advance();
    } catch (e) {
      setState(() => _signupError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  // ── Finish (step 5 → 6) ───────────────────────────────────────────────────

  Future<void> _finish() async {
    setState(() => _submitting = true);
    try {
      // Upload primary photo
      if (_photo1 != null) {
        await context.read<ProfileProvider>().uploadProfilePhoto(_photo1!);
      }

      // PATCH confirmed fields only
      await ApiClient().patch('api/v1/profiles/me/', {
        if (_interests.isNotEmpty)
          'interests': _interests
              .map((e) => e.toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll('&', 'and'))
              .toList(),
        if (_neighbourhood != null) 'neighborhood': _neighbourhood,
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
        'onboarding_completed': true,
      });

      if (mounted) {
        _page.animateToPage(6,
            duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _kRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final max = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 22, 6, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: max,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kRed, onPrimary: Colors.white)),
        child: child!),
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showProgress = _step >= 1 && _step <= _totalProgressSteps;

    return Scaffold(
      backgroundColor: _kCream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [
          if (showProgress)
            _ProgressBar(step: _step, total: _totalProgressSteps),

          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _buildBrand(),     // 0
                _buildEnergy(),    // 1
                _buildNairobi(),   // 2
                _buildSignup(),    // 3
                _buildProfile(),   // 4
                _buildSafety(),    // 5
                _buildFinal(),     // 6
              ],
            ),
          ),

          if (_step == 0) _buildBrandCta(),

          if (_step >= 1 && _step <= 2)
            _BottomNav(
              step: _step, isLast: false,
              canAdvance: _canAdvance, submitting: false,
              onBack: _back, onAdvance: _advance),

          if (_step == 4 || _step == 5)
            _BottomNav(
              step: _step, isLast: _step == 5,
              canAdvance: _canAdvance, submitting: _step == 5 ? _submitting : false,
              onBack: _back,
              onAdvance: _step == 5 ? _finish : _advance),
        ]),
      ),
    );
  }

  // ── Step 0: Brand ─────────────────────────────────────────────────────────

  Widget _buildBrand() {
    return Container(
      color: _kDark,
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KanairoXO',
            style: TextStyle(
              fontFamily: 'DancingScript', fontSize: 26,
              color: Color(0xFFF5EFE6))),
          const Spacer(),
          const Text(
            'Nairobi is full of\npeople you haven\'t\nmet yet.',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 44, fontWeight: FontWeight.w700,
              color: Color(0xFFF5EFE6), height: 1.05, letterSpacing: -1.2)),
          const SizedBox(height: 18),
          Text(
            'Discover events, meet interesting people and build connections beyond endless swiping.',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 16, height: 1.55,
              color: const Color(0xFFF5EFE6).withValues(alpha: 0.6))),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildBrandCta() {
    return Container(
      color: _kDark,
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _advance,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _kRed, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text("Let's Go",
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 17,
                      fontWeight: FontWeight.w600, color: Colors.white)))))),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: Text('Already a member? Log in',
              style: TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                color: const Color(0xFFF5EFE6).withValues(alpha: 0.6)))),
        ],
      ),
    );
  }

  // ── Step 1: Energy / interests ────────────────────────────────────────────

  Widget _buildEnergy() {
    return _Shell(
      stepLabel: '1 of 5',
      title: 'What sounds like\nyour kind of plan?',
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: _energyOptions.map((o) {
          final sel = _interests.contains(o);
          return GestureDetector(
            onTap: () => setState(() =>
              sel ? _interests.remove(o) : _interests.add(o)),
            child: _Chip(label: o, selected: sel));
        }).toList(),
      ),
    );
  }

  // ── Step 2: Nairobi ───────────────────────────────────────────────────────

  Widget _buildNairobi() {
    return _Shell(
      stepLabel: '2 of 5',
      title: 'Where do you\nusually hang out?',
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: _neighbourhoodOptions.map((n) {
          final sel = _neighbourhood == n;
          return GestureDetector(
            onTap: () => setState(() => _neighbourhood = n),
            child: _Chip(label: n, selected: sel));
        }).toList(),
      ),
    );
  }

  // ── Step 3: Create account ────────────────────────────────────────────────

  Widget _buildSignup() {
    return _Shell(
      stepLabel: '3 of 5',
      title: 'Create\nyour account.',
      scrollable: true,
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_signupError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kRed.withValues(alpha: 0.3))),
                child: Text(_signupError!,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 13, color: _kRed))),
              const SizedBox(height: 14),
            ],

            Row(children: [
              Expanded(child: _FormField(
                ctrl: _firstNameCtrl, hint: 'First name',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: _FormField(
                ctrl: _lastNameCtrl, hint: 'Last name',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
            ]),
            const SizedBox(height: 10),

            _FormField(
              ctrl: _emailCtrl, hint: 'Email address',
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              }),
            const SizedBox(height: 10),

            _FormField(
              ctrl: _phoneCtrl, hint: 'Phone number',
              keyboard: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 10),

            // DOB
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _dob != null ? _kRed : _kBorder)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                    size: 18, color: _dob != null ? _kRed : _kMuted),
                  const SizedBox(width: 10),
                  Text(
                    _dob != null
                      ? DateFormat('d MMMM yyyy').format(_dob!)
                      : 'Date of birth',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 15,
                      color: _dob != null ? _kText : _kMuted)),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // Gender
            Row(children: ['Male', 'Female'].map((label) {
              final val = label.toLowerCase();
              final sel = _gender == val;
              final isFirst = label == 'Male';
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = val),
                  child: Container(
                    margin: EdgeInsets.only(right: isFirst ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: sel ? _kRed.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? _kRed : _kBorder, width: sel ? 1.5 : 1)),
                    child: Center(child: Text(label,
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? _kRed : _kMuted))))));
            }).toList()),
            const SizedBox(height: 10),

            _FormField(
              ctrl: _passwordCtrl, hint: 'Password',
              obscure: _obscurePass,
              suffix: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: _kMuted),
                onPressed: () => setState(() => _obscurePass = !_obscurePass)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                return null;
              }),
            const SizedBox(height: 10),

            _FormField(
              ctrl: _confirmCtrl, hint: 'Confirm password',
              obscure: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: _kMuted),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
              validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null),
            const SizedBox(height: 18),

            // Terms
            GestureDetector(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 22, height: 22,
                  child: Checkbox(
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                    activeColor: _kRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(color: _kBorder, width: 1.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
                const SizedBox(width: 10),
                Expanded(child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 13,
                      color: _kMuted, height: 1.5),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: const TextStyle(
                          color: _kRed, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()..onTap = () {}),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: _kRed, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()..onTap = () {}),
                    ]))),
              ]),
            ),
            const SizedBox(height: 24),

            // Register button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _registering ? null : _handleRegister,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kRed, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: _registering
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account',
                          style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 15,
                            fontWeight: FontWeight.w600, color: Colors.white)))))),
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: _back,
                child: const Text('← Back',
                  style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 14, color: _kMuted)))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Profile photos + bio ──────────────────────────────────────────

  Widget _buildProfile() {
    return _Shell(
      stepLabel: '4 of 5',
      title: 'Give people a\nreason to say hello.',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _PhotoSlot(
              photo: _photo1, label: 'Main photo',
              onPick: (f) => setState(() => _photo1 = f)),
            const SizedBox(width: 12),
            _PhotoSlot(
              photo: _photo2, label: 'Second photo',
              onPick: (f) => setState(() => _photo2 = f)),
          ]),
          const SizedBox(height: 24),

          const Text('A little about you',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 15,
              fontWeight: FontWeight.w600, color: _kText)),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'DMSans', fontSize: 14, color: _kText),
            decoration: InputDecoration(
              hintText: 'My ideal Nairobi weekend looks like…',
              hintStyle: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14, color: _kMuted),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              counterStyle: const TextStyle(
                fontFamily: 'DMSans', fontSize: 11, color: _kMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kRed, width: 1.5)))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Step 5: Safety ────────────────────────────────────────────────────────

  Widget _buildSafety() {
    return _Shell(
      stepLabel: '5 of 5',
      title: 'Good connections\nbegin with trust.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrustCard(
            icon: Icons.groups_outlined,
            title: 'Meet through public experiences',
            body: 'Start with events and shared moments before going private.'),
          const SizedBox(height: 10),
          _TrustCard(
            icon: Icons.tune_outlined,
            title: 'Control who can contact you',
            body: 'You decide who slides into your world.'),
          const SizedBox(height: 10),
          _TrustCard(
            icon: Icons.shield_outlined,
            title: 'Report or block anyone instantly',
            body: 'Our moderation team reviews every report within 24 hours.'),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _agreedGuidelines = !_agreedGuidelines),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 22, height: 22,
                child: Checkbox(
                  value: _agreedGuidelines,
                  onChanged: (v) => setState(() => _agreedGuidelines = v ?? false),
                  activeColor: _kRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                  side: const BorderSide(color: _kBorder, width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'I agree to treat everyone respectfully and follow the KanairoXO Community Guidelines.',
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 13,
                  color: _kMuted, height: 1.5))),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Final reward ──────────────────────────────────────────────────

  Widget _buildFinal() {
    return Container(
      color: _kCream,
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KanairoXO',
            style: TextStyle(
              fontFamily: 'DancingScript', fontSize: 24, color: _kRed)),
          const Spacer(),
          const Text(
            'Your Nairobi\nstarts here.',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 44, fontWeight: FontWeight.w700,
              color: _kText, height: 1.05, letterSpacing: -1.2)),
          const SizedBox(height: 16),
          const Text(
            "We've selected experiences and people that match your energy.",
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 16, color: _kMuted, height: 1.55)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/main_single'),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _kRed, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text('Explore Experiences',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 16,
                      fontWeight: FontWeight.w600, color: Colors.white)))))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/main_single'),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder, width: 1.5)),
                child: const Center(
                  child: Text('Complete My Profile',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 15,
                      fontWeight: FontWeight.w500, color: _kText)))))),
        ],
      ),
    );
  }
}


// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step, total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) => Stack(children: [
      Container(height: 2, width: c.maxWidth, color: _kBorder),
      AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        height: 2,
        width: c.maxWidth * step / total,
        color: _kRed),
    ]));
  }
}


// ── Step shell ────────────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  final String stepLabel, title;
  final Widget child;
  final bool scrollable;

  const _Shell({
    required this.stepLabel,
    required this.title,
    required this.child,
    this.scrollable = false,
  });

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(stepLabel,
        style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w700,
          color: _kRed, letterSpacing: 1.0)),
      const SizedBox(height: 10),
      Text(title,
        style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 32, fontWeight: FontWeight.w700,
          color: _kText, height: 1.1, letterSpacing: -0.5)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_header(), const SizedBox(height: 28), child]));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 28),
          Expanded(child: SingleChildScrollView(child: child)),
        ]));
  }
}


// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? _kRed : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? _kRed : _kBorder),
        boxShadow: selected ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(label,
        style: TextStyle(
          fontFamily: 'DMSans', fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? Colors.white : _kText)));
  }
}


// ── Trust card ────────────────────────────────────────────────────────────────

class _TrustCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _TrustCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _kRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kRed, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                fontWeight: FontWeight.w600, color: _kText)),
            const SizedBox(height: 4),
            Text(body,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 12,
                color: _kMuted, height: 1.4)),
          ])),
      ]));
  }
}


// ── Photo slot ────────────────────────────────────────────────────────────────

class _PhotoSlot extends StatelessWidget {
  final File? photo;
  final String label;
  final ValueChanged<File> onPick;
  const _PhotoSlot({required this.photo, required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery, imageQuality: 85);
          if (picked != null) onPick(File(picked.path));
        },
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: photo != null ? _kRed : _kBorder,
                width: photo != null ? 1.5 : 1)),
            child: photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(photo!, fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined,
                    size: 28, color: _kRed.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 12, color: _kMuted)),
                ])))));
  }
}


// ── Form field ────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _FormField({
    required this.ctrl,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontFamily: 'DMSans', fontSize: 15, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 15, color: _kMuted),
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kRed, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
        errorStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 11)));
  }
}


// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int step;
  final bool isLast, canAdvance, submitting;
  final VoidCallback onBack, onAdvance;

  const _BottomNav({
    required this.step, required this.isLast,
    required this.canAdvance, required this.submitting,
    required this.onBack, required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCream,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 50, height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder)),
            child: const Center(
              child: Icon(Icons.arrow_back_ios_new, color: _kText, size: 15)))),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: canAdvance && !submitting ? onAdvance : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                color: canAdvance ? _kRed : _kBorder,
                borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : Text(isLast ? "I'm In" : 'Continue',
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: canAdvance ? Colors.white : _kMuted)))))),
      ]),
    );
  }
}
