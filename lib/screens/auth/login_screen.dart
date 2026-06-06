import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/api_client.dart';

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
  bool _obscurePassword = true;
  bool _isRestoring = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '512106408043-tm9m4edr0p1qn5vdmnu1ut0m0ktoiroq.apps.googleusercontent.com',
  );

  Future<void> _handleLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+254${phoneNumber.substring(1)}';
        } else if (phoneNumber.startsWith('7')) {
          phoneNumber = '+254$phoneNumber';
        }
      }
      await auth.login(phoneNumber, _passwordController.text);
      await NotificationService().registerDeviceToken();
      widget.onLoginSuccess();
    } catch (e) {
      if (e.toString().contains('401')) {
        // Potential deleted user
      }
    }
  }

  Future<void> _handleRestore() async {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    
    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter phone and password first')));
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final apiClient = ApiClient();
      await apiClient.post('api/v1/auth/me/restore/', {
        'phone_number': phone,
        'password': pass,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account restored! You can now log in.')));
        setState(() => _isRestoring = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text('Welcome Back', style: AppTypography.displayLarge.copyWith(color: context.textColor)),
                const SizedBox(height: 8),
                Text('Sign in to continue your journey', style: AppTypography.bodyLarge.copyWith(color: context.mutedColor)),
                const SizedBox(height: 48),

                if (auth.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: AppRadius.md,
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(auth.error!, style: AppTypography.bodyMedium.copyWith(color: Colors.red)),
                  ),
                
                if (auth.error != null && auth.error!.toLowerCase().contains('unauthorized'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TextButton(
                      onPressed: _isRestoring ? null : _handleRestore,
                      child: Text('Account deleted? Restore it', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),

                _buildGlassTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined, color: context.mutedColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildGlassTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(Icons.lock_outline, color: context.mutedColor),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.mutedColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot Password?', style: AppTypography.labelMedium.copyWith(color: context.primaryColor)),
                  ),
                ),
                const SizedBox(height: 32),

                LiquidGlassButton(
                  size: LiquidButtonSize.xl,
                  width: double.infinity,
                  onPressed: auth.isLoading ? null : () => _handleLogin(auth),
                  child: auth.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Log In', style: AppTypography.buttonText),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with', style: AppTypography.caption.copyWith(color: context.mutedColor)),
                    ),
                    Expanded(child: Divider(color: context.borderColor)),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(PhosphorIcons.googleLogo(), () async {
                       try {
                        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
                        if (googleUser == null) return;
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        if (googleAuth.idToken != null) {
                          final bool isNew = await auth.googleLogin(googleAuth.idToken!);
                          await NotificationService().registerDeviceToken();
                          if (isNew) Navigator.pushReplacementNamed(context, '/onboarding');
                          else widget.onLoginSuccess();
                        }
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Login Error: $e')));
                      }
                    }),
                    const SizedBox(width: 16),
                    _buildSocialButton(PhosphorIcons.appleLogo(), () {}),
                  ],
                ),

                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account? ', style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
                      TextButton(
                        onPressed: widget.onSignupTap,
                        child: Text('Sign Up', style: AppTypography.labelMedium.copyWith(color: context.primaryColor)),
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

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Icon(icon, color: context.textColor),
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
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTypography.bodyLarge.copyWith(color: context.textColor),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyLarge.copyWith(color: context.mutedColor),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: context.isDark ? context.surfaceColor.withOpacity(0.7) : Colors.white.withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.all(color: context.primaryColor, width: 1.5)),
          ),
        ),
      ),
    );
  }
}
