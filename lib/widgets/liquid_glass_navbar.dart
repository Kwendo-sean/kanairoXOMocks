import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

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

  // Per-icon spring scale bounce
  late List<AnimationController> _scaleCtrl;
  late List<Animation<double>> _scaleAnim;

  static const double _navHeight = 50.0;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _scaleCtrl = List.generate(
      widget.items.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 380)),
    );
    _scaleAnim = _scaleCtrl.map(_buildScaleAnim).toList();

    // Start active tab in bounced state
    _scaleCtrl[widget.currentIndex].forward();
  }

  Animation<double> _buildScaleAnim(AnimationController c) =>
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.24).chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.24, end: 0.94).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(c);

  @override
  void didUpdateWidget(LiquidGlassNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _scaleCtrl[old.currentIndex].reset();
      _scaleCtrl[widget.currentIndex]
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
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
                  child: CustomPaint(
                    painter: _GlassBarPainter(
                      activeIndex: widget.currentIndex,
                      itemCount: widget.items.length,
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

class _GlassBarPainter extends CustomPainter {
  final int activeIndex;
  final int itemCount;
  final bool isDark;

  const _GlassBarPainter({
    required this.activeIndex,
    required this.itemCount,
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

    // 4 ─ Red glow at active icon position
    final itemW  = size.width / itemCount;
    final cx     = (activeIndex + 0.5) * itemW;
    final cy     = size.height / 2;
    final glowR  = itemW * 0.55;

    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9B111E).withOpacity(isDark ? 0.32 : 0.20),
            const Color(0xFF9B111E).withOpacity(isDark ? 0.10 : 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );
  }

  @override
  bool shouldRepaint(_GlassBarPainter old) =>
    old.activeIndex != activeIndex || old.isDark != isDark;
}
