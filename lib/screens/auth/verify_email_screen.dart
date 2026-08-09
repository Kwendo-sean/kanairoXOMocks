import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/api_client.dart';

/// Six-digit email verification, shown immediately after signup.
///
/// There was no screen for this at all — the backend issued a code on
/// registration and nothing in the app ever asked for it, so every new account
/// walked straight into the app unverified.
///
/// Deliberately not dismissible: no back button, and PopScope blocks the
/// system gesture. Signup returns real tokens (this screen needs them to call
/// the verify endpoint), so an escape route here is an escape route into the
/// whole app.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _apiClient = ApiClient();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  String? _notice;

  /// Matches EMAIL_OTP_RESEND_COOLDOWN_SECONDS on the server. Asking sooner
  /// just earns a 429, so the button stays disabled until it can succeed.
  static const _cooldownSeconds = 60;
  int _secondsLeft = _cooldownSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
      _notice = null;
    });

    try {
      await _apiClient.post('api/v1/auth/email/verify/', {'code': code});
      if (!mounted) return;
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _readable(e);
        _controller.clear();
      });
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _error = null;
      _notice = null;
    });

    try {
      await _apiClient.post('api/v1/auth/email/send-verification/', {});
      if (!mounted) return;
      setState(() => _notice = 'New code sent to ${widget.email}');
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _readable(e));
      // A rate limit still means no new code will arrive for a while, so
      // restart the wait rather than inviting another rejected tap.
      _startCooldown();
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// ApiClient throws `Exception: Error <status>: <detail>`, having already
  /// pulled `detail` out of the body. Show that sentence — the server's
  /// messages here are written for users ("Incorrect code.", "This code has
  /// expired."), so passing them through beats inventing our own.
  String _readable(Object e) {
    final m = RegExp(r'Error \d{3}:\s*(.+)$').firstMatch(e.toString().trim());
    if (m != null) {
      final detail = m.group(1)!.trim();
      if (detail.isNotEmpty && detail != 'An unknown error occurred') {
        return detail;
      }
    }
    if (e.toString().contains('429')) {
      return 'Too many attempts. Try again shortly.';
    }
    return 'That didn\'t work. Check the code and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0 && !_isResending;

    return PopScope(
      canPop: false, // verification is not optional
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check your email',
                    style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary, height: 1.6),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: AppTypography.displaySmall.copyWith(
                      letterSpacing: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: AppTypography.displaySmall
                        .copyWith(letterSpacing: 14, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.6),
                    ),
                  ),
                  // Submit as soon as the sixth digit lands.
                  onChanged: (v) {
                    if (_error != null) setState(() => _error = null);
                    if (v.length == 6 && !_isVerifying) _verify();
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.error)),
                    ),
                  ]),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_notice!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.success)),
                    ),
                  ]),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Verify', style: AppTypography.labelLarge),
                  ),
                ),

                const SizedBox(height: 22),
                Center(
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: canResend ? _resend : null,
                          child: Text(
                            canResend
                                ? 'Resend code'
                                : 'Resend in ${_secondsLeft}s',
                            style: AppTypography.bodyMedium.copyWith(
                              color: canResend
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'The code expires in 15 minutes.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted),
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
