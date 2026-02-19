import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/auth/auth_input_field.dart';
import 'package:kanairoxo/services/auth_service.dart';

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
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  String _selectedAccountType = 'single';
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _errorMessage;

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _errorMessage = 'You must accept the terms and privacy policy';
      });
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() {
        _errorMessage = 'Please select your gender';
      });
      return;
    }

    String? djangoGender;
    switch (_selectedGender) {
      case 'Male': djangoGender = 'male'; break;
      case 'Female': djangoGender = 'female'; break;
      case 'Non-binary': djangoGender = 'non_binary'; break;
      case 'Prefer not to say': djangoGender = 'prefer_not_to_say'; break;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      String phoneNumber = _formatPhoneNumber(_phoneController.text.trim());

      await authService.register(
        phoneNumber: phoneNumber,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        password2: _confirmPasswordController.text,
        termsAccepted: _termsAccepted,
        privacyPolicyAccepted: _privacyAccepted,
        accountType: _selectedAccountType,
        gender: djangoGender,
        dateOfBirth: _selectedDate,
        partnerFirstName: _selectedAccountType == 'couple' ? _partnerFirstNameController.text.trim() : null,
        partnerLastName: _selectedAccountType == 'couple' ? _partnerLastNameController.text.trim() : null,
        partnerEmail: _selectedAccountType == 'couple' ? _partnerEmailController.text.trim() : null,
      );

      setState(() => _isLoading = false);
      widget.onSignupSuccess();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _extractErrorMessage(e);
      });
    }
  }

  String _formatPhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) return '+254${digits.substring(1)}';
    if (digits.startsWith('7') && digits.length == 9) return '+254$digits';
    if (digits.startsWith('254') && digits.length == 12) return '+$digits';
    return phone;
  }

  String _extractErrorMessage(dynamic error) {
    String errorStr = error.toString();
    if (errorStr.contains('Exception: ')) errorStr = errorStr.replaceAll('Exception: ', '');
    if (errorStr.contains('already exists')) return errorStr.contains('phone_number') ? 'This phone number is already registered' : 'This email is already registered';
    if (errorStr.contains('password')) return 'Password requirements not met';
    if (errorStr.contains('network')) return 'Network error. Please check your connection';
    return errorStr;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
        firstDate: DateTime(1900),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        builder: (context, child) {
          return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppConstants.primaryRed, onPrimary: Colors.white), dialogBackgroundColor: Colors.white), child: child!);
        });
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
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
      backgroundColor: AppConstants.primaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Create Account', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Join our community of meaningful connections', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppConstants.secondaryGray)),
                const SizedBox(height: 40),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Row(children: [PhosphorIcon(PhosphorIcons.warningCircle(PhosphorIconsStyle.regular), color: Colors.red, size: 20), const SizedBox(width: 12), Expanded(child: Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)))]),
                  ),

                Text('I am signing up as a...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConstants.secondaryGray, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _buildAccountTypeChip(context, label: 'Single', value: 'single', icon: PhosphorIcons.user(PhosphorIconsStyle.regular))), const SizedBox(width: 16), Expanded(child: _buildAccountTypeChip(context, label: 'Couple', value: 'couple', icon: PhosphorIcons.heart(PhosphorIconsStyle.regular)))]),
                const SizedBox(height: 30),
                
                Text('Your Details', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),

                AuthInputField(controller: _firstNameController, label: 'First Name', hintText: 'John', prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)), validator: (v) => v!.isEmpty ? 'Please enter your first name' : null),
                const SizedBox(height: 20),
                AuthInputField(controller: _lastNameController, label: 'Last Name', hintText: 'Doe', prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)), validator: (v) => v!.isEmpty ? 'Please enter your last name' : null),
                const SizedBox(height: 20),
                AuthInputField(controller: _emailController, label: 'Email', hintText: 'you@example.com', prefixIcon: PhosphorIcon(PhosphorIcons.envelope(PhosphorIconsStyle.regular)), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isNotEmpty && !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 20),
                AuthInputField(controller: _phoneController, label: 'Phone Number', hintText: '0712 345 678', prefixIcon: PhosphorIcon(PhosphorIcons.phone(PhosphorIconsStyle.regular)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Please enter your phone number' : null),
                const SizedBox(height: 20),
                _buildGenderDropdown(context),
                const SizedBox(height: 20),
                _buildDobPicker(context),
                const SizedBox(height: 20),

                if (_selectedAccountType == 'couple') _buildPartnerFields(),

                AuthInputField(controller: _passwordController, label: 'Password', hintText: '••••••••', prefixIcon: PhosphorIcon(PhosphorIcons.lock(PhosphorIconsStyle.regular)), obscureText: _obscurePassword, suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: PhosphorIcon(_obscurePassword ? PhosphorIcons.eye(PhosphorIconsStyle.regular) : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular), size: 20)), validator: (v) => v!.length < 6 ? 'Password is too short' : null),
                const SizedBox(height: 20),
                AuthInputField(controller: _confirmPasswordController, label: 'Confirm Password', hintText: '••••••••', prefixIcon: PhosphorIcon(PhosphorIcons.lock(PhosphorIconsStyle.regular)), obscureText: _obscureConfirmPassword, suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), icon: PhosphorIcon(_obscureConfirmPassword ? PhosphorIcons.eye(PhosphorIconsStyle.regular) : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular), size: 20)), validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
                const SizedBox(height: 24),

                _buildTermsAndConditions(context),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius))),
                    child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium), TextButton(onPressed: widget.onLoginTap, child: Text('Log In', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConstants.primaryRed, fontWeight: FontWeight.w600)))]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Column _buildTermsAndConditions(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Checkbox(value: _termsAccepted, onChanged: (v) => setState(() => _termsAccepted = v ?? false), activeColor: AppConstants.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          Expanded(child: GestureDetector(onTap: () => {}, child: Text.rich(TextSpan(text: 'I agree to the ', style: Theme.of(context).textTheme.bodyMedium, children: [TextSpan(text: 'Terms & Conditions', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.w600))])))),
        ]),
        Row(children: [
          Checkbox(value: _privacyAccepted, onChanged: (v) => setState(() => _privacyAccepted = v ?? false), activeColor: AppConstants.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          Expanded(child: GestureDetector(onTap: () => {}, child: Text.rich(TextSpan(text: 'I agree to the ', style: Theme.of(context).textTheme.bodyMedium, children: [TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.w600))])))),
        ]),
      ],
    );
  }

  Widget _buildPartnerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 40),
        Text('Your Partner\'s Details', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Your partner will be invited to join once you create your account.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConstants.secondaryGray)),
        const SizedBox(height: 20),
        AuthInputField(controller: _partnerFirstNameController, label: 'Partner\'s First Name', hintText: 'Jane', prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)), validator: (v) => _selectedAccountType == 'couple' && v!.isEmpty ? 'Enter partner\'s first name' : null),
        const SizedBox(height: 20),
        AuthInputField(controller: _partnerLastNameController, label: 'Partner\'s Last Name', hintText: 'Doe', prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)), validator: (v) => _selectedAccountType == 'couple' && v!.isEmpty ? 'Enter partner\'s last name' : null),
        const SizedBox(height: 20),
        AuthInputField(controller: _partnerEmailController, label: 'Partner\'s Email', hintText: 'jane@example.com', prefixIcon: PhosphorIcon(PhosphorIcons.envelope(PhosphorIconsStyle.regular)), keyboardType: TextInputType.emailAddress, validator: (v) => _selectedAccountType == 'couple' && (v!.isEmpty || !v.contains('@')) ? 'Enter a valid partner email' : null),
        const SizedBox(height: 40),
        const Divider(height: 1),
        const SizedBox(height: 40),
      ],
    );
  }

  Column _buildGenderDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConstants.secondaryGray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), borderSide: BorderSide(color: AppConstants.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), borderSide: BorderSide(color: AppConstants.lightGray)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), borderSide: BorderSide(color: AppConstants.primaryRed, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), prefixIcon: PhosphorIcon(PhosphorIcons.genderIntersex(PhosphorIconsStyle.regular), size: 20, color: AppConstants.secondaryGray)),
          items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) => value == null || value.isEmpty ? 'Please select your gender' : null,
          hint: const Text('Select gender'),
        ),
      ],
    );
  }

  GestureDetector _buildDobPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date of Birth', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConstants.secondaryGray, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            height: 56, 
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), border: Border.all(color: AppConstants.lightGray)),
            child: Row(children: [PhosphorIcon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 20, color: AppConstants.secondaryGray), const SizedBox(width: 12), Expanded(child: Text(_selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : 'Select your date of birth', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _selectedDate != null ? AppConstants.primaryBlack : AppConstants.lightGray))), if (_selectedDate != null) IconButton(onPressed: () => setState(() => _selectedDate = null), icon: PhosphorIcon(PhosphorIcons.x(PhosphorIconsStyle.regular), size: 16, color: AppConstants.secondaryGray))]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeChip(BuildContext context, {required String label, required String value, required IconData icon}) {
    final bool isSelected = _selectedAccountType == value;
    return ChoiceChip(
      label: Text(label),
      avatar: PhosphorIcon(icon, size: 18, color: isSelected ? Colors.white : AppConstants.primaryRed),
      selected: isSelected,
      onSelected: (selected) => { if (selected) setState(() => _selectedAccountType = value) },
      backgroundColor: Colors.white,
      selectedColor: AppConstants.primaryRed,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), side: BorderSide(color: isSelected ? AppConstants.primaryRed : AppConstants.lightGray, width: 1.5)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelPadding: const EdgeInsets.only(left: 8),
    );
  }
}
