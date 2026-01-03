import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/auth/auth_input_field.dart';

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
  String? _selectedGender;
  DateTime? _selectedDate;
  
  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    widget.onSignupSuccess();
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
                  icon: Icon(PhosphorIcons.arrowLeft()),
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
                
                // First Name
                AuthInputField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hintText: 'John',
                  prefixIcon: PhosphorIcons.user(),
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
                  prefixIcon: PhosphorIcons.user(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Email
                AuthInputField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: PhosphorIcons.envelope(),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Phone Number
                AuthInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '0712 345 678',
                  prefixIcon: PhosphorIcons.phone(),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
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
                        prefixIcon: Icon(
                          PhosphorIcons.genderIntersex(),
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
                
                // Date of Birth
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
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
                            Icon(
                              PhosphorIcons.calendar(),
                              size: 20,
                              color: AppConstants.secondaryGray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select your date of birth',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: _selectedDate != null 
                                      ? AppConstants.primaryBlack 
                                      : AppConstants.lightGray,
                                ),
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
                  prefixIcon: PhosphorIcons.lock(),
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
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
                  prefixIcon: PhosphorIcons.lock(),
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    icon: Icon(
                      _obscureConfirmPassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
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
                const SizedBox(height: 32),
                
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppConstants.primaryRed,
                    ),
                    Expanded(
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
                            const TextSpan(text: ' and '),
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
                        AppStrings.hasAccount,
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