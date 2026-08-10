import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/api_client.dart';

/// Password reset, in the same shape as the email-verification screen:
/// send a 6-digit code, enter it, done.
///
///   1. POST api/v1/auth/password/reset/request/ {"identifier"}
///   2. POST api/v1/auth/password/reset/confirm/ {"identifier", "code",
///      "new_password"}
///
/// Both endpoints are the ones `ClaimAccountScreen` already uses.
class ForgotPasswordScreen extends StatefulWidget {
  /// Pre-fills the field with whatever was typed on the login screen.
  final String initialIdentifier;

  const ForgotPasswordScreen({super.key, this.initialIdentifier = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Stage { identify, code, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiClient();

  late final _identifierController =
      TextEditingController(text: widget.initialIdentifier);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeFocus = FocusNode();

  _Stage _stage = _Stage.identify;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  /// Matches the server's resend cooldown — asking sooner just earns a 429.
  static const _cooldownSeconds = 60;
  int _secondsLeft = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _codeFocus.dispose();
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

  Future<void> _sendCode({bool isResend = false}) async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = 'Enter your email or phone number');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await _api.post('api/v1/auth/password/reset/request/', {
        'identifier': identifier,
      });
      if (!mounted) return;
      setState(() {
        _stage = _Stage.code;
        _notice = 'Code sent to $identifier';
      });
      _startCooldown();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _codeFocus.requestFocus());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _readable(e));
      // A rate limit means no new code is coming for a while either way.
      if (isResend) _startCooldown();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await _api.post('api/v1/auth/password/reset/confirm/', {
        'identifier': _identifierController.text.trim(),
        'code': code,
        'new_password': password,
      });
      if (!mounted) return;
      setState(() => _stage = _Stage.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _readable(e);
        _codeController.clear();
      });
      _codeFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ApiClient throws `Exception: Error <status>: <detail>`. The server's
  /// messages here are written for users ("Incorrect code.", "This code has
  /// expired."), so pass them through rather than inventing our own.
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
    return "That didn't work. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          child: switch (_stage) {
            _Stage.identify => _buildIdentify(),
            _Stage.code => _buildCode(),
            _Stage.done => _buildDone(),
          },
        ),
      ),
    );
  }

  // ── Stage 1: who are you ──────────────────────────────────────────────────

  Widget _buildIdentify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reset your password',
            style:
                AppTypography.displaySmall.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Text(
          "Tell us the email or phone on your account and we'll send a "
          '6-digit code.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 36),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: _fieldDecoration(
            hint: 'Email or phone',
            prefix: const Icon(Icons.person_outline_rounded,
                size: 20, color: AppColors.textMuted),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _busy ? null : _sendCode(),
        ),
        _buildMessages(),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Send code',
          onPressed: _busy ? null : () => _sendCode(),
        ),
      ],
    );
  }

  // ── Stage 2: code + new password ──────────────────────────────────────────

  Widget _buildCode() {
    final canResend = _secondsLeft <= 0 && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check your inbox',
            style:
                AppTypography.displaySmall.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.6),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: _identifierController.text.trim(),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          focusNode: _codeFocus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: AppTypography.displaySmall
              .copyWith(letterSpacing: 14, color: AppColors.textPrimary),
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
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 20),
        Text('NEW PASSWORD',
            style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: _fieldDecoration(
            hint: 'At least 8 characters',
            prefix: const Icon(Icons.lock_outline_rounded,
                size: 20, color: AppColors.textMuted),
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _busy ? null : _confirm(),
        ),
        _buildMessages(),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Reset password',
          onPressed: _busy ? null : _confirm,
        ),
        const SizedBox(height: 22),
        Center(
          child: TextButton(
            onPressed: canResend ? () => _sendCode(isResend: true) : null,
            child: Text(
              canResend ? 'Resend code' : 'Resend in ${_secondsLeft}s',
              style: AppTypography.bodyMedium.copyWith(
                color: canResend ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('The code expires in 15 minutes.',
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  // ── Stage 3: done ─────────────────────────────────────────────────────────

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle_outline,
            size: 52, color: AppColors.success),
        const SizedBox(height: 20),
        Text('Password reset',
            style:
                AppTypography.displaySmall.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Text('You can now sign in with your new password.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 32),
        _primaryButton(
          label: 'Back to sign in',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ── Shared bits ───────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.error)),
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
                  style:
                      AppTypography.caption.copyWith(color: AppColors.success)),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label, style: AppTypography.labelLarge),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}
