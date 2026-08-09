import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/api_client.dart';

const _kCream = Color(0xFFFAF7F4);
const _kRed = Color(0xFF9B111E);
const _kText = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF888888);
const _kBorder = Color(0xFFE8E0D0);

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
  // P1-5: accepts email or phone number
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRestoring = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '512106408043-tm9m4edr0p1qn5vdmnu1ut0m0ktoiroq.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      // P1-5: pass the identifier as-is; auth_service formats phone if needed.
      await auth.login(_phoneController.text.trim(), _passwordController.text);
      await NotificationService().registerDeviceToken();
      widget.onLoginSuccess();
    } catch (e) {
      // Error handled by provider
    }
  }

  Future<void> _handleRestore() async {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;

    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter phone and password first')));
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final apiClient = ApiClient();
      await apiClient.post('api/v1/auth/me/restore/', {
        'identifier':
            phone, // P1-5: send identifier, keep phone_number fallback
        'phone_number': phone,
        'password': pass,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account restored! You can now log in.')));
        setState(() => _isRestoring = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Restore failed: $e'), backgroundColor: Colors.red));
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _handleGoogleLogin(AuthProvider auth) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token.');
      }

      final isNew = await auth.googleLogin(idToken);
      await NotificationService().registerDeviceToken();
      if (!mounted) return;

      if (isNew) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                const Text('Welcome back',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                        height: 1.05,
                        letterSpacing: -1.0)),
                const SizedBox(height: 10),
                const Text('Sign in to keep your connections close.',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        color: _kMuted,
                        height: 1.5)),
                const SizedBox(height: 34),
                if (auth.error != null) ...[
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: _kRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _kRed.withValues(alpha: 0.3))),
                      child: Text(auth.error!,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              color: _kRed))),
                  const SizedBox(height: 12),
                ],
                if (auth.error != null &&
                    auth.error!.toLowerCase().contains('unauthorized'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: _isRestoring ? null : _handleRestore,
                      child: const Text('Account deleted? Restore it',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              color: _kRed,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                const Text('EMAIL OR PHONE',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: _kMuted)),
                const SizedBox(height: 8),
                _buildField(
                    controller: _phoneController,
                    hint: 'Email or phone',
                    prefix: const Icon(Icons.person_outline_rounded, size: 20),
                    keyboard: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter your email or phone'
                        : null),
                const SizedBox(height: 18),
                const Text('PASSWORD',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: _kMuted)),
                const SizedBox(height: 8),
                _buildField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscure: _obscurePassword,
                    prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffix: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: _kMuted),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword)),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter your password'
                        : null),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4)),
                        child: const Text('Forgot password?',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 13,
                                color: _kRed,
                                fontWeight: FontWeight.w500)))),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                        onTap: auth.isLoading ? null : () => _handleLogin(auth),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            decoration: BoxDecoration(
                                color: _kRed,
                                borderRadius: BorderRadius.circular(16)),
                            child: Center(
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Log In',
                                        style: TextStyle(
                                            fontFamily: 'DMSans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)))))),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(child: Divider(color: _kBorder)),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or continue with',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: _kMuted))),
                  Expanded(child: Divider(color: _kBorder)),
                ]),
                const SizedBox(height: 20),
                _buildGoogleButton(
                  auth.isLoading ? null : () => _handleGoogleLogin(auth),
                ),
                const SizedBox(height: 36),
                Center(
                    child: GestureDetector(
                        onTap: widget.onSignupTap,
                        child: RichText(
                            text: const TextSpan(
                                style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 14,
                                    color: _kMuted),
                                children: [
                              TextSpan(text: 'New here? '),
                              TextSpan(
                                  text: 'Create an account',
                                  style: TextStyle(
                                      color: _kRed,
                                      fontWeight: FontWeight.w600)),
                            ])))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(PhosphorIcons.googleLogo(), color: _kText, size: 21),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: _kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? prefix,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        style:
            const TextStyle(fontFamily: 'DMSans', fontSize: 15, color: _kText),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontFamily: 'DMSans', fontSize: 15, color: _kMuted),
            prefixIcon: prefix,
            prefixIconColor: _kMuted,
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
