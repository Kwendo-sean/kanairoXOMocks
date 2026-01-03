import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/auth/auth_input_field.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Welcome Back',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email field
                AuthInputField(
                  controller: _emailController,
                  label: AppStrings.email,
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
                
                // Password field
                AuthInputField(
                  controller: _passwordController,
                  label: AppStrings.password,
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
                      AppStrings.forgotPassword,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
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
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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
                      icon: Icon(
                        PhosphorIcons.googleLogo(),
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
                      icon: Icon(
                        PhosphorIcons.appleLogo(),
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
                        AppStrings.noAccount,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppConstants.primaryBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onSignupTap,
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
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