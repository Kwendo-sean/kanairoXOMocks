import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

enum LiquidButtonSize { sm, md, lg, xl, icon }
enum LiquidButtonVariant { primary, ghost, outline }

class LiquidGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final LiquidButtonSize size;
  final LiquidButtonVariant variant;
  final Color? color;
  final double? width;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = LiquidButtonSize.lg,
    this.variant = LiquidButtonVariant.primary,
    this.color,
    this.width,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  EdgeInsets get _padding {
    switch (widget.size) {
      case LiquidButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case LiquidButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case LiquidButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case LiquidButtonSize.xl:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
      case LiquidButtonSize.icon:
        return const EdgeInsets.all(10);
    }
  }

  double get _minHeight {
    switch (widget.size) {
      case LiquidButtonSize.sm: return 32;
      case LiquidButtonSize.md: return 40;
      case LiquidButtonSize.lg: return 44;
      case LiquidButtonSize.xl: return 50;
      case LiquidButtonSize.icon: return 40;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color baseColor = widget.color ?? AppColors.themePrimary(context);
    final bool isEnabled = widget.onPressed != null;
    
    final backgroundColor = switch (widget.variant) {
      LiquidButtonVariant.primary => isEnabled ? baseColor.withOpacity(0.9) : baseColor.withOpacity(0.4),
      LiquidButtonVariant.ghost => Colors.transparent,
      LiquidButtonVariant.outline => isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15),
    };

    final borderColor = switch (widget.variant) {
      LiquidButtonVariant.primary => isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.25),
      LiquidButtonVariant.ghost => Colors.transparent,
      LiquidButtonVariant.outline => isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.4),
    };

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: isEnabled && _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: SizedBox(
            width: widget.width,
            child: ClipRRect(
              borderRadius: AppRadius.xl,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: BoxConstraints(minHeight: _minHeight),
                  padding: _padding,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: AppRadius.xl,
                    border: Border.all(
                      color: borderColor,
                      width: 1.0,
                    ),
                    boxShadow: isEnabled ? [
                      BoxShadow(
                        color: baseColor.withOpacity(_isPressed ? 0.1 : 0.25),
                        blurRadius: _isPressed ? 8 : 20,
                        offset: Offset(0, _isPressed ? 2 : 6),
                      ),
                    ] : [],
                    gradient: widget.variant == LiquidButtonVariant.primary && isEnabled
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            baseColor.withOpacity(0.95),
                            baseColor.withOpacity(0.80),
                          ],
                        )
                      : null,
                  ),
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
