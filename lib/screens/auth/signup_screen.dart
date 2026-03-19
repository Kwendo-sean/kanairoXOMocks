import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  final VoidCallback onLoginTap;

  const SignupScreen({
    super.key,
    required this.onSignupSuccess,
    required this.onLoginTap,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Existing controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _partnerFirstNameController = TextEditingController();
  final _partnerLastNameController = TextEditingController();
  final _partnerEmailController = TextEditingController();

  // Existing state
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _signupType = 'single';
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _partnerFirstNameController.dispose();
    _partnerLastNameController.dispose();
    _partnerEmailController.dispose();
    super.dispose();
  }

  // Existing logic preserved
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() => _errorMessage = 'Please accept the terms and privacy policy');
      return;
    }

    if (_selectedGender == null) {
      setState(() => _errorMessage = 'Please select your gender');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      String? djangoGender;
      switch (_selectedGender) {
        case 'Male': djangoGender = 'male'; break;
        case 'Female': djangoGender = 'female'; break;
      }

      final data = {
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'password': _passwordController.text,
        'password2': _confirmPasswordController.text,
        'termsAccepted': _agreeTerms,
        'privacyPolicyAccepted': _agreePrivacy,
        'accountType': _signupType,
        'gender': djangoGender,
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'partnerFirstName': _signupType == 'couple' ? _partnerFirstNameController.text.trim() : null,
        'partnerLastName': _signupType == 'couple' ? _partnerLastNameController.text.trim() : null,
        'partnerEmail': _signupType == 'couple' ? _partnerEmailController.text.trim() : null,
      };
      
      await authProvider.register(data);
      widget.onSignupSuccess();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Join the KanairoXO community',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!, 
                        style: AppTypography.caption.copyWith(color: Colors.red.shade400)),
                    ),

                  // 2. Single / Couple Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2))]),
                    child: Row(children: [
                      _ToggleOption(
                        label: 'Single',
                        icon: Icons.person_outline,
                        isSelected: _signupType == 'single',
                        onTap: () => setState(() => _signupType = 'single')),
                      _ToggleOption(
                        label: 'Couple',
                        icon: Icons.favorite_outline,
                        isSelected: _signupType == 'couple',
                        onTap: () => setState(() => _signupType = 'couple')),
                    ])),
                  const SizedBox(height: 24),

                  // 5. Your Details Section
                  const _SectionLabel(label: 'Your Details'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDecoration(),
                    child: Column(children: [
                      _SignupField(
                        controller: _firstNameController,
                        hint: 'First Name',
                        icon: Icons.person_outline),
                      const _FieldDivider(),
                      _SignupField(
                        controller: _lastNameController,
                        hint: 'Last Name',
                        icon: Icons.person_outline),
                      const _FieldDivider(),
                      _SignupField(
                        controller: _emailController,
                        hint: 'Email Address',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress),
                      const _FieldDivider(),
                      _SignupField(
                        controller: _phoneController,
                        hint: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                      const _FieldDivider(),
                      _GenderDropdown(
                        value: _selectedGender,
                        onChanged: (val) => setState(() => _selectedGender = val)),
                      const _FieldDivider(),
                      _DateOfBirthField(
                        date: _selectedDate,
                        onTap: () => _selectDate(context)),
                    ])),
                  const SizedBox(height: 16),

                  // 6. Password Section
                  const _SectionLabel(label: 'Set Password'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDecoration(),
                    child: Column(children: [
                      _SignupField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                      const _FieldDivider(),
                      _SignupField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                    ])),
                  
                  // 7. Partner Details Mode
                  if (_signupType == 'couple') ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlass,
                            borderRadius: BorderRadius.circular(999)),
                          child: Text('Partner Details',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)))),
                      Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(children: [
                        _SignupField(
                          controller: _partnerFirstNameController,
                          hint: 'Partner First Name',
                          icon: Icons.person_outline),
                        const _FieldDivider(),
                        _SignupField(
                          controller: _partnerLastNameController,
                          hint: 'Partner Last Name',
                          icon: Icons.person_outline),
                        const _FieldDivider(),
                        _SignupField(
                          controller: _partnerEmailController,
                          hint: 'Partner Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress),
                      ])),
                  ],
                  const SizedBox(height: 20),

                  // 8. Terms & Conditions
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100)),
                    child: Column(children: [
                      Row(children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: Colors.grey.shade300))),
                        const SizedBox(width: 10),
                        Expanded(child: RichText(
                          text: TextSpan(
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()..onTap = () {}),
                            ]))),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _agreePrivacy,
                            onChanged: (val) => setState(() => _agreePrivacy = val ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: Colors.grey.shade300))),
                        const SizedBox(width: 10),
                        Expanded(child: RichText(
                          text: TextSpan(
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()..onTap = () {}),
                            ]))),
                      ]),
                    ])),
                  const SizedBox(height: 20),

                  // 9. Create Account Button
                  SizedBox(
                    width: double.infinity,
                    child: LiquidGlassButton(
                      size: LiquidButtonSize.xl,
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Create Account', style: AppTypography.buttonText))),
                  const SizedBox(height: 20),

                  // 10. Social Login
                  Row(children: [
                    Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted))),
                    Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(label: 'Google', icon: Icons.g_mobiledata, onTap: () {}),
                      const SizedBox(width: 12),
                      _SocialButton(label: 'Apple', icon: Icons.apple, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 11. Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: widget.onLoginTap,
                        child: Text('Log In',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
                    ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2))]);
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            ])),
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _SignupField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1)),
      ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.grey.shade100);
  }
}

class _GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text('Gender', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.wc_outlined, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
      ],
      onChanged: onChanged);
  }
}

class _DateOfBirthField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateOfBirthField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Date of Birth',
            style: AppTypography.bodyMedium.copyWith(color: date != null ? AppColors.textPrimary : AppColors.textMuted)),
        ])),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(label,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ])),
    );
  }
}
