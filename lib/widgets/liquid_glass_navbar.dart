import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// ─── Data ──────────────────────────────────────────────────────────────────────

class LiquidNavItem {
  final IconData icon;
  final String label;
  const LiquidNavItem({required this.icon, required this.label});
}

// ─── Widget ────────────────────────────────────────────────────────────────────

class LiquidGlassNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;
  final VoidCallback? onLongPressLastItem;

  const LiquidGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onLongPressLastItem,
  });

  @override
  State<LiquidGlassNavbar> createState() => _LiquidGlassNavbarState();
}

class _LiquidGlassNavbarState extends State<LiquidGlassNavbar>
    with TickerProviderStateMixin {

  // Spring-driven blob center (normalized 0..1 across the bar)
  late AnimationController _posCtrl;

  // Liquid stretch — blob fattens as it travels, snaps back on arrival
  late AnimationController _stretchCtrl;
  late Animation<double> _stretchAnim;

  // Iridescent shimmer sweep fired once per tap
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Per-icon spring scale
  late List<AnimationController> _scaleCtrl;
  late List<Animation<double>> _scaleAnim;

  bool _goingRight = true;

  static const double _blobRestW  = 46.0;
  static const double _navHeight  = 64.0;

  // ─── Helpers ───────────────────────────────────────────────────────────────

  double _norm(int index) => (index + 0.5) / widget.items.length;

  // Returns a TweenSequence for the stretch: pull → snap → elastic settle
  Animation<double> _buildStretchAnim(double distance) =>
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: _blobRestW,
          end: _blobRestW + _blobRestW * 2.6 * distance * widget.items.length,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _blobRestW + _blobRestW * 2.6 * distance * widget.items.length,
          end: _blobRestW * 0.82,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _blobRestW * 0.82, end: _blobRestW)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_stretchCtrl);

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Position: value IS the normalized blob center (spring simulation drives it)
    _posCtrl = AnimationController(
      vsync: this,
      value: _norm(widget.currentIndex),
    );

    // Stretch
    _stretchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _stretchAnim = AlwaysStoppedAnimation(_blobRestW); // resting until first tap

    // Shimmer
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _shimmerAnim = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeOut),
    );

    // Icon scales
    _scaleCtrl = List.generate(
      widget.items.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 430)),
    );
    _scaleAnim = _scaleCtrl.map(_buildScaleAnim).toList();

    // Animate the initial tab icon so it starts in the "active" state
    _scaleCtrl[widget.currentIndex].forward();
  }

  Animation<double> _buildScaleAnim(AnimationController c) =>
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 0.93)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(c);

  @override
  void didUpdateWidget(LiquidGlassNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _animateTo(old.currentIndex, widget.currentIndex);
    }
  }

  void _animateTo(int from, int to) {
    _goingRight = to > from;

    final fromNorm = _norm(from);
    final toNorm   = _norm(to);
    final distance = (toNorm - fromNorm).abs();

    // 1 ─ Spring blob position
    _posCtrl.animateWith(SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 210, damping: 21),
      fromNorm, toNorm, 0.0,
    ));

    // 2 ─ Liquid stretch
    _stretchAnim = _buildStretchAnim(distance);
    _stretchCtrl
      ..reset()
      ..forward();

    // 3 ─ Shimmer sweep
    _shimmerCtrl
      ..reset()
      ..forward();

    // 4 ─ Icon bounces
    _scaleCtrl[from].reset();
    _scaleCtrl[to]
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _posCtrl.dispose();
    _stretchCtrl.dispose();
    _shimmerCtrl.dispose();
    for (final c in _scaleCtrl) c.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() < 100) return;
                if (v < 0 && widget.currentIndex < widget.items.length - 1) {
                  widget.onTap(widget.currentIndex + 1);
                } else if (v > 0 && widget.currentIndex > 0) {
                  widget.onTap(widget.currentIndex - 1);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18, tileMode: TileMode.mirror),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_posCtrl, _stretchCtrl]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _LiquidGlassPainter(
                          blobNormX: _posCtrl.value,
                          blobWidth: _stretchCtrl.isAnimating
                              ? _stretchAnim.value
                              : _blobRestW,
                          totalWidth: totalW,
                          goingRight: _goingRight,
                          isDark: isDark,
                        ),
                        child: SizedBox(
                          height: _navHeight,
                          child: Row(
                            children: List.generate(
                              widget.items.length,
                              (i) => _buildItem(i, totalW, isDark),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(int i, double totalW, bool isDark) {
    final isActive = i == widget.currentIndex;
    final isLast   = i == widget.items.length - 1;
    final item     = widget.items[i];

    final activeColor   = isDark ? const Color(0xFFC0394B) : const Color(0xFF9B111E);
    final inactiveColor = isDark
        ? const Color(0xFF7A6E66)
        : const Color(0xFF1A1A1A).withOpacity(0.35);

    return GestureDetector(
      onTap: () => widget.onTap(i),
      onLongPress: isLast ? widget.onLongPressLastItem : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: totalW / widget.items.length,
        height: _navHeight,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnim[i],
            builder: (_, child) => Transform.scale(
              scale: _scaleAnim[i].value,
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 24, color: isActive ? activeColor : inactiveColor),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                    letterSpacing: 0.2,
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

// ─── Painter ───────────────────────────────────────────────────────────────────

class _LiquidGlassPainter extends CustomPainter {
  final double blobNormX;
  final double blobWidth;
  final double totalWidth;
  final bool goingRight;
  final bool isDark;

  const _LiquidGlassPainter({
    required this.blobNormX,
    required this.blobWidth,
    required this.totalWidth,
    required this.goingRight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = const Radius.circular(44);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), r);

    // 1 ─ Frosted glass background
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.26),
    );

    // 2 ─ Glass border
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.white.withOpacity(isDark ? 0.14 : 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // 3 ─ Top-edge specular highlight
    canvas.drawRect(
      Rect.fromLTWH(12, 0.5, size.width - 24, 1.2),
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(isDark ? 0.30 : 0.55),
          Colors.white.withOpacity(0.0),
        ]).createShader(Rect.fromLTWH(0, 0, size.width, 2)),
    );

    // 4 ─ Liquid blob
    final cx      = blobNormX * size.width;
    final halfRest = 23.0; // half of _blobRestW
    final blobH   = 34.0;
    final blobTop = (size.height - blobH) / 2;
    final blobR   = Radius.circular(blobH / 2);

    // Leading edge stretches ahead of the center; trailing edge lags behind.
    double blobLeft, blobRight;
    if (goingRight) {
      blobLeft  = cx - halfRest;
      blobRight = cx - halfRest + blobWidth;
    } else {
      blobRight = cx + halfRest;
      blobLeft  = cx + halfRest - blobWidth;
    }

    // Clamp so blob never escapes the bar
    blobLeft  = blobLeft.clamp(4.0, size.width - 8);
    blobRight = blobRight.clamp(8.0, size.width - 4);

    final blobRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(blobLeft, blobTop, blobRight, blobTop + blobH), blobR);

    // Blob fill — slightly more opaque than bar so it reads as a distinct surface
    canvas.drawRRect(
      blobRect,
      Paint()
        ..color = isDark
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.50),
    );

    // Red glow behind the active icon — soft radial bloom, clipped to the
    // pill so it never bleeds past the blob edges into the rest of the bar.
    canvas.save();
    canvas.clipRRect(blobRect);
    final glowCenter = Offset(cx, size.height / 2);
    final glowRadius = blobH * 0.62;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9B111E).withOpacity(isDark ? 0.30 : 0.22),
            const Color(0xFF9B111E).withOpacity(isDark ? 0.08 : 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );
    canvas.restore();

    // Blob inner border
    canvas.drawRRect(
      blobRect,
      Paint()
        ..color = Colors.white.withOpacity(isDark ? 0.22 : 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Blob top highlight — the "glass lens" micro-specular
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(blobLeft + 4, blobTop + 1, blobRight - 4, blobTop + blobH * 0.45),
      blobR,
    );
    canvas.drawRRect(
      highlightRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(isDark ? 0.18 : 0.35),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(blobLeft, blobTop, blobRight, blobTop + blobH)),
    );
  }

  @override
  bool shouldRepaint(_LiquidGlassPainter old) =>
    old.blobNormX != blobNormX ||
    old.blobWidth != blobWidth ||
    old.isDark    != isDark;
}
