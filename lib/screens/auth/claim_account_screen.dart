import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

/// Handles the `app.kanairoxo.online/?claim=<email>` deep link (P1-4).
///
/// Flow:
///   1. Show email (read-only) + "Send code" button.
///   2. POST /api/v1/auth/password/reset/request/ {"identifier": email}
///   3. Show 6-digit code + new password fields.
///   4. POST /api/v1/auth/password/reset/confirm/ {"identifier": email, "code": "...", "new_password": "..."}
///   5. On success → sign in automatically (calls the auth service) and pop to home.
class ClaimAccountScreen extends StatefulWidget {
  final String email;

  const ClaimAccountScreen({super.key, required this.email});

  @override
  State<ClaimAccountScreen> createState() => _ClaimAccountScreenState();
}

class _ClaimAccountScreenState extends State<ClaimAccountScreen> {
  final ApiClient _api = ApiClient();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _api.post('api/v1/auth/password/reset/request/', {
        'identifier': widget.email,
      });
      if (mounted) setState(() { _codeSent = true; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not send code. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code sent to your email.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await _api.post('api/v1/auth/password/reset/confirm/', {
        'identifier': widget.email,
        'code': code,
        'new_password': password,
      });
      // Auto sign-in after successful claim
      if (mounted) {
        await _signIn(password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Invalid code or password. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn(String password) async {
    try {
      await _api.post('api/v1/auth/login/', {
        'identifier': widget.email,
        'password': password,
      });
      if (mounted) {
        // Pop all screens and let auth_gate pick up the new token.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      // If auto sign-in fails, still pop — user can log in manually.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Set your password',
            style: AppTypography.labelLarge.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Claiming account for',
                  style: AppTypography.caption.copyWith(color: Colors.white60)),
              const SizedBox(height: 4),
              Text(widget.email,
                  style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),

              if (!_codeSent) ...[
                const Text(
                  'We\'ll send a 6-digit code to your email address so you can set a new password.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 16),
                ],
                LiquidGlassButton(
                  width: double.infinity,
                  onPressed: _isLoading ? null : _sendCode,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send code'),
                ),
              ] else ...[
                const Text(
                  'Enter the 6-digit code sent to your email, then choose a new password.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Code field
                _label('Verification code'),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // New password field
                _label('New password'),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 16),
                ],

                LiquidGlassButton(
                  width: double.infinity,
                  onPressed: _isLoading ? null : _confirm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm & sign in'),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: const Text("Didn't receive a code? Resend",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    );
  }
}
