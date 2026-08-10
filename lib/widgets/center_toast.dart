import 'package:flutter/material.dart';

/// Centered toast in the app's burgundy styling.
///
/// Replaces bottom SnackBars for status feedback ("Saved to gallery", errors)
/// so the message lands where the user is already looking.
class CenterToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, String message, {bool isError = false}) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => _ToastBody(message: message, isError: isError),
    );
    _current = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 1900), () {
      if (_current == entry) {
        entry.remove();
        _current = null;
      }
    });
  }
}

class _ToastBody extends StatefulWidget {
  final String message;
  final bool isError;
  const _ToastBody({required this.message, required this.isError});

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _c,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: widget.isError
                      ? const Color(0xFF7A0D17)
                      : const Color(0xFF9B111E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
