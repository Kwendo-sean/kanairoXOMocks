import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
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
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _partnerFirstNameController = TextEditingController();
  final _partnerLastNameController = TextEditingController();
  final _partnerEmailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _signupType = 'single';
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  String? _selectedGender; // 'male', 'female', 'other'
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
        'gender': _selectedGender,
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
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final minDate = DateTime(now.year - 100, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 22, 1, 1),
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select Date of Birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.primaryColor,
            onPrimary: Colors.white,
            onSurface: context.textColor,
            surface: context.surfaceColor),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: context.primaryColor))),
        child: child!));
    
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: context.textColor)),
                        const SizedBox(height: 4),
                        Text('Join the KanairoXO community',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.mutedColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!, 
                        style: AppTypography.caption.copyWith(color: Colors.red.shade400)),
                    ),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
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

                  _SectionLabel(label: 'Your Details', color: context.textColor),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDecoration(context),
                    child: Column(children: [
                      _SignupField(
                        controller: _firstNameController,
                        hint: 'First Name',
                        icon: Icons.person_outline),
                      _FieldDivider(color: context.borderColor),
                      _SignupField(
                        controller: _lastNameController,
                        hint: 'Last Name',
                        icon: Icons.person_outline),
                      _FieldDivider(color: context.borderColor),
                      _SignupField(
                        controller: _emailController,
                        hint: 'Email Address',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress),
                      _FieldDivider(color: context.borderColor),
                      _SignupField(
                        controller: _phoneController,
                        hint: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                      _FieldDivider(color: context.borderColor),
                      _DateOfBirthField(
                        date: _selectedDate,
                        onTap: () => _selectDate(context)),
                    ])),
                  const SizedBox(height: 24),

                  _SectionLabel(label: 'Gender', color: context.textColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _GenderCard(
                        label: 'Man',
                        value: 'male',
                        icon: Icons.male,
                        isSelected: _selectedGender == 'male',
                        onTap: () => setState(() => _selectedGender = 'male'),
                      ),
                      const SizedBox(width: 8),
                      _GenderCard(
                        label: 'Woman',
                        value: 'female',
                        icon: Icons.female,
                        isSelected: _selectedGender == 'female',
                        onTap: () => setState(() => _selectedGender = 'female'),
                      ),
                      const SizedBox(width: 8),
                      _GenderCard(
                        label: 'Other',
                        value: 'other',
                        icon: Icons.person_outline,
                        isSelected: _selectedGender == 'other',
                        onTap: () => setState(() => _selectedGender = 'other'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _SectionLabel(label: 'Set Password', color: context.textColor),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDecoration(context),
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
                            color: context.mutedColor),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                      _FieldDivider(color: context.borderColor),
                      _SignupField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: context.mutedColor),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                    ])),
                  
                  if (_signupType == 'couple') ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: Container(height: 1, color: context.borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.isDark ? context.primaryColor.withOpacity(0.15) : AppColors.primaryGlass,
                            borderRadius: BorderRadius.circular(999)),
                          child: Text('Partner Details',
                            style: AppTypography.caption.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w600)))),
                      Expanded(child: Container(height: 1, color: context.borderColor)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      decoration: _cardDecoration(context),
                      child: Column(children: [
                        _SignupField(
                          controller: _partnerFirstNameController,
                          hint: 'Partner First Name',
                          icon: Icons.person_outline),
                        _FieldDivider(color: context.borderColor),
                        _SignupField(
                          controller: _partnerLastNameController,
                          hint: 'Partner Last Name',
                          icon: Icons.person_outline),
                        _FieldDivider(color: context.borderColor),
                        _SignupField(
                          controller: _partnerEmailController,
                          hint: 'Partner Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress),
                      ])),
                  ],
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor)),
                    child: Column(children: [
                      Row(children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                            activeColor: context.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: context.isDark ? context.mutedColor : Colors.grey.shade300))),
                        const SizedBox(width: 10),
                        Expanded(child: RichText(
                          text: TextSpan(
                            style: AppTypography.caption.copyWith(color: context.textColor.withOpacity(0.7)),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w600),
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
                            activeColor: context.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: context.isDark ? context.mutedColor : Colors.grey.shade300))),
                        const SizedBox(width: 10),
                        Expanded(child: RichText(
                          text: TextSpan(
                            style: AppTypography.caption.copyWith(color: context.textColor.withOpacity(0.7)),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()..onTap = () {}),
                            ]))),
                      ]),
                    ])),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: LiquidGlassButton(
                      size: LiquidButtonSize.xl,
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Create Account', style: AppTypography.buttonText))),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: Divider(color: context.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with',
                        style: AppTypography.caption.copyWith(color: context.mutedColor))),
                    Expanded(child: Divider(color: context.borderColor)),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(color: context.mutedColor)),
                      GestureDetector(
                        onTap: widget.onLoginTap,
                        child: Text('Log In',
                          style: AppTypography.bodyMedium.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600))),
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

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.borderColor),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2))]);
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    final primaryGlass = context.isDark ? primaryColor.withOpacity(0.15) : AppColors.primaryGlass;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryGlass : context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primaryColor : context.borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? primaryColor : context.mutedColor, size: 24),
              const SizedBox(height: 8),
              Text(label, style: AppTypography.caption.copyWith(
                color: isSelected ? primaryColor : context.textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
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
            color: isSelected ? context.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : context.mutedColor),
              const SizedBox(width: 6),
              Text(label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : context.mutedColor,
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
      style: AppTypography.bodyMedium.copyWith(color: context.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: context.mutedColor),
        prefixIcon: Icon(icon, size: 18, color: context.mutedColor),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: context.primaryColor.withOpacity(0.3), width: 1)),
      ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: color));
  }
}

class _FieldDivider extends StatelessWidget {
  final Color color;
  const _FieldDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: color);
  }
}

class _DateOfBirthField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateOfBirthField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(
        text: date != null ? DateFormat('dd/MM/yyyy').format(date!) : ''),
      style: AppTypography.bodyMedium.copyWith(color: context.textColor),
      decoration: InputDecoration(
        hintText: 'Date of Birth',
        hintStyle: AppTypography.bodyMedium.copyWith(color: context.mutedColor),
        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: context.mutedColor),
        suffixIcon: Icon(Icons.keyboard_arrow_down, size: 18, color: context.mutedColor),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: context.primaryColor.withOpacity(0.3), width: 1)),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ));
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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: context.textColor),
            const SizedBox(width: 8),
            Text(label,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
          ])),
    );
  }
}
