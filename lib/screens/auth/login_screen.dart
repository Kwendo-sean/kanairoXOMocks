import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/auth/auth_input_field.dart';
import 'package:kanairoxo/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSignupTap;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSignupTap,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();

      // Format phone number (ensure it starts with +254)
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+254${phoneNumber.substring(1)}';
        } else if (phoneNumber.startsWith('7')) {
          phoneNumber = '+254$phoneNumber';
        }
      }

      final response = await authService.login(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
      );

      // Store user data if needed
      // await _storeUserData(response.user);

      setState(() => _isLoading = false);
      widget.onLoginSuccess();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                const SizedBox(height: 40),

                // Title
                Text(
                  'Welcome Back',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 48),

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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 20),

                // Phone field
                AuthInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '+254700123456',
                  prefixIcon: PhosphorIcon(PhosphorIcons.phone(PhosphorIconsStyle.regular)),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Basic phone validation
                    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password field
                AuthInputField(
                  controller: _passwordController,
                  label: AppStrings.password,
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
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                        : Text(
                      'Log In',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppConstants.lightGray),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppConstants.lightGray),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppConstants.lightGray),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: PhosphorIcon(
                        PhosphorIcons.googleLogo(PhosphorIconsStyle.regular),
                        color: AppConstants.primaryBlack,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppConstants.lightGray),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: PhosphorIcon(
                        PhosphorIcons.appleLogo(PhosphorIconsStyle.regular),
                        color: AppConstants.primaryBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppConstants.primaryBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onSignupTap,
                        child: Text(
                          'Sign Up',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
