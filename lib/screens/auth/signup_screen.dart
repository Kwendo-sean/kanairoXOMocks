import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  bool _obscureConfirmPassword = true;
  String _selectedAccountType = 'single';
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _errorMessage;

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_termsAccepted || !_privacyAccepted) {
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
        case 'Non-binary': djangoGender = 'non_binary'; break;
        case 'Prefer not to say': djangoGender = 'prefer_not_to_say'; break;
      }

      final data = {
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'password': _passwordController.text,
        'password2': _confirmPasswordController.text,
        'termsAccepted': _termsAccepted,
        'privacyPolicyAccepted': _privacyAccepted,
        'accountType': _selectedAccountType,
        'gender': djangoGender,
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'partnerFirstName': _selectedAccountType == 'couple' ? _partnerFirstNameController.text.trim() : null,
        'partnerLastName': _selectedAccountType == 'couple' ? _partnerLastNameController.text.trim() : null,
        'partnerEmail': _selectedAccountType == 'couple' ? _partnerEmailController.text.trim() : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Create Account', style: AppTypography.displayLarge),
                const SizedBox(height: 8),
                Text('Join our community', style: AppTypography.bodyLarge),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: AppRadius.md,
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(_errorMessage!, style: AppTypography.bodyMedium.copyWith(color: Colors.red)),
                  ),

                Text('I am signing up as a...', style: AppTypography.labelMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildAccountTypeChip('Single', 'single', PhosphorIcons.user())),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAccountTypeChip('Couple', 'couple', PhosphorIcons.heart())),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Your Details', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
                const SizedBox(height: 16),

                _buildGlassTextField(controller: _firstNameController, hintText: 'First Name', prefixIcon: const Icon(Icons.person_outline, size: 20)),
                const SizedBox(height: 12),
                _buildGlassTextField(controller: _lastNameController, hintText: 'Last Name', prefixIcon: const Icon(Icons.person_outline, size: 20)),
                const SizedBox(height: 12),
                _buildGlassTextField(controller: _emailController, hintText: 'Email', keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.email_outlined, size: 20)),
                const SizedBox(height: 12),
                _buildGlassTextField(controller: _phoneController, hintText: 'Phone Number', keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
                const SizedBox(height: 12),
                
                _buildGenderDropdown(),
                const SizedBox(height: 12),
                _buildDobPicker(),
                const SizedBox(height: 12),

                if (_selectedAccountType == 'couple') ...[
                  const Divider(height: 32),
                  Text('Partner Details', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildGlassTextField(controller: _partnerFirstNameController, hintText: 'Partner First Name', prefixIcon: const Icon(Icons.person_outline, size: 20)),
                  const SizedBox(height: 12),
                  _buildGlassTextField(controller: _partnerLastNameController, hintText: 'Partner Last Name', prefixIcon: const Icon(Icons.person_outline, size: 20)),
                  const SizedBox(height: 12),
                  _buildGlassTextField(controller: _partnerEmailController, hintText: 'Partner Email', keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.email_outlined, size: 20)),
                  const SizedBox(height: 12),
                ],

                _buildGlassTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGlassTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                _buildCheckbox('I agree to the Terms & Conditions', _termsAccepted, (v) => setState(() => _termsAccepted = v!)),
                _buildCheckbox('I agree to the Privacy Policy', _privacyAccepted, (v) => setState(() => _privacyAccepted = v!)),
                
                const SizedBox(height: 24),

                LiquidGlassButton(
                  size: LiquidButtonSize.lg,
                  width: double.infinity,
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text('Create Account', style: AppTypography.buttonText),
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or sign up with', style: AppTypography.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(PhosphorIcons.googleLogo(), () {}),
                    const SizedBox(width: 12),
                    _buildSocialButton(PhosphorIcons.appleLogo(), () {}),
                  ],
                ),

                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTypography.bodyMedium),
                      TextButton(
                        onPressed: widget.onLoginTap,
                        child: Text('Log In', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Select Gender',
            hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.transgender, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.4))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) => value == null || value.isEmpty ? 'Please select your gender' : null,
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Date of Birth',
                    style: AppTypography.bodyLarge.copyWith(color: _selectedDate != null ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeChip(String label, String value, IconData icon) {
    final bool isSelected = _selectedAccountType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.labelMedium.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24, width: 24,
          child: Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.4))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ),
    );
  }
}
