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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _errorMessage;

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _errorMessage = 'You must accept terms and privacy policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();

      // Format phone number for Kenya
      String phoneNumber = _phoneController.text.trim();
      phoneNumber = _formatPhoneNumber(phoneNumber);

      // Map gender to Django model values
      String? djangoGender;
      switch (_selectedGender) {
        case 'Male':
          djangoGender = 'male';
          break;
        case 'Female':
          djangoGender = 'female';
          break;
        case 'Non-binary':
          djangoGender = 'non_binary';
          break;
        case 'Prefer not to say':
          djangoGender = 'prefer_not_to_say';
          break;
      }

      final response = await authService.register(
        phoneNumber: phoneNumber,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        password2: _confirmPasswordController.text,
        termsAccepted: _termsAccepted,
        privacyPolicyAccepted: _privacyAccepted,
        // Additional profile fields
        gender: djangoGender,
        dateOfBirth: _selectedDate,
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
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Format for Kenya
    if (digits.startsWith('0')) {
      return '+254${digits.substring(1)}';
    } else if (digits.startsWith('7') && digits.length == 9) {
      return '+254$digits';
    } else if (digits.startsWith('254') && digits.length == 12) {
      return '+$digits';
    }

    return phone; // Return as-is if already formatted
  }

  String _extractErrorMessage(dynamic error) {
    String errorStr = error.toString();

    // Extract meaningful error message
    if (errorStr.contains('Exception: ')) {
      errorStr = errorStr.replaceAll('Exception: ', '');
    }

    // Common error mappings
    if (errorStr.contains('already exists')) {
      if (errorStr.contains('phone_number')) {
        return 'This phone number is already registered';
      } else if (errorStr.contains('email')) {
        return 'This email is already registered';
      }
    }

    if (errorStr.contains('password')) {
      return 'Password requirements not met';
    }

    if (errorStr.contains('network')) {
      return 'Network error. Please check your connection';
    }

    return errorStr;
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
              primary: AppConstants.primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppConstants.primaryBlack,
            ),
            dialogBackgroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: PhosphorIcon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular)),
                  color: AppConstants.primaryBlack,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join our community of meaningful connections',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 40),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 20),

                // First Name
                AuthInputField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hintText: 'John',
                  prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Last Name
                AuthInputField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hintText: 'Doe',
                  prefixIcon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.regular)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email (optional but recommended)
                AuthInputField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  hintText: 'you@example.com',
                  prefixIcon: PhosphorIcon(PhosphorIcons.envelope(PhosphorIconsStyle.regular)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number
                AuthInputField(
                  controller: _phoneController,
                  label: 'Phone Number*',
                  hintText: '0712 345 678 or +254712345678',
                  prefixIcon: PhosphorIcon(PhosphorIcons.phone(PhosphorIconsStyle.regular)),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }

                    // Basic validation
                    String digits = value.replaceAll(RegExp(r'[^\d]'), '');

                    // Check length
                    if (digits.length < 9 || digits.length > 15) {
                      return 'Please enter a valid phone number';
                    }

                    // Check if it's a Kenyan number pattern
                    if (!digits.startsWith('0') &&
                        !digits.startsWith('7') &&
                        !digits.startsWith('254') &&
                        !value.startsWith('+')) {
                      return 'Please enter a valid Kenyan phone number';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Gender
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          borderSide: BorderSide(color: AppConstants.lightGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          borderSide: BorderSide(color: AppConstants.lightGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          borderSide: BorderSide(color: AppConstants.primaryRed, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: PhosphorIcon(
                          PhosphorIcons.genderIntersex(PhosphorIconsStyle.regular),
                          size: 20,
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                      items: _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                      hint: const Text('Select gender'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth (Optional)
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth (Optional)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.secondaryGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(color: AppConstants.lightGray),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                              size: 20,
                              color: AppConstants.secondaryGray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select your date of birth (optional)',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: _selectedDate != null
                                      ? AppConstants.primaryBlack
                                      : AppConstants.lightGray,
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              IconButton(
                                onPressed: () {
                                  setState(() => _selectedDate = null);
                                },
                                icon: PhosphorIcon(
                                  PhosphorIcons.x(PhosphorIconsStyle.regular),
                                  size: 16,
                                  color: AppConstants.secondaryGray,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                AuthInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: '••••••••',
                  prefixIcon: PhosphorIcon(PhosphorIcons.lock(PhosphorIconsStyle.regular)),
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: PhosphorIcon(
                      _obscurePassword ? PhosphorIcons.eye(PhosphorIconsStyle.regular) : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password
                AuthInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: '••••••••',
                  prefixIcon: PhosphorIcon(PhosphorIcons.lock(PhosphorIconsStyle.regular)),
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    icon: PhosphorIcon(
                      _obscureConfirmPassword ? PhosphorIcons.eye(PhosphorIconsStyle.regular) : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() => _termsAccepted = value ?? false);
                          },
                          activeColor: AppConstants.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Show terms dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Terms & Conditions'),
                                  content: const SingleChildScrollView(
                                    child: Text(
                                      'Please read and accept our Terms & Conditions to continue.',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppConstants.primaryRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _privacyAccepted,
                          onChanged: (value) {
                            setState(() => _privacyAccepted = value ?? false);
                          },
                          activeColor: AppConstants.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Show privacy policy dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Privacy Policy'),
                                  content: const SingleChildScrollView(
                                    child: Text(
                                      'Please read and accept our Privacy Policy to continue.',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppConstants.primaryRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Signup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.buttonBorderRadius,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: widget.onLoginTap,
                        child: Text(
                          'Log In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}
