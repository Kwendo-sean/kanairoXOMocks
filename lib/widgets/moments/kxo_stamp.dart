import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KXOStamp extends StatelessWidget {
  final String userName;
  final Color? color;
  final double size;
  final double rotateAngle;

  const KXOStamp({
    super.key,
    required this.userName,
    this.color,
    this.size = 62,
    this.rotateAngle = -0.10,
  });

  @override
  Widget build(BuildContext context) {
    final stampColor = color ?? const Color(0xFF8B1A1A).withOpacity(0.82);
    final firstName = userName.split(' ').first;
    
    return Transform.rotate(
      angle: rotateAngle,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: KXOStampPainter(color: stampColor),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KanairoXO',
                  style: GoogleFonts.dancingScript(
                    fontSize: size * 0.177, // 11 for size 62
                    fontWeight: FontWeight.w700,
                    color: stampColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Moments',
                  style: GoogleFonts.dancingScript(
                    fontSize: size * 0.129, // 8 for size 62
                    fontWeight: FontWeight.w600,
                    color: stampColor,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                Container(
                  width: size * 0.45, // 28 for size 62
                  height: 0.7,
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                  color: stampColor.withOpacity(0.4),
                ),
                Text(
                  firstName.length > 7 ? firstName.substring(0, 7) : firstName,
                  style: GoogleFonts.dancingScript(
                    fontSize: size * 0.129, // 8 for size 62
                    fontWeight: FontWeight.w600,
                    color: stampColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KXOStampPainter extends CustomPainter {
  final Color color;
  KXOStampPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashCount = 32;
    final angleStep = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      final sweepAngle = i % 2 == 0 ? angleStep * 0.55 : angleStep * 0.35;
      final r = radius + (i % 3 == 0 ? 0.4 : -0.2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweepAngle,
        false,
        paint..color = color.withOpacity(i % 4 == 0 ? 0.5 : 0.82),
      );
    }

    final starR = radius - 7;
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 90) * pi / 180;
      final sx = center.dx + starR * cos(a);
      final sy = center.dy + starR * sin(a);
      _drawStar(
        canvas,
        Offset(sx, sy),
        2.0,
        Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2 - pi / 4;
      final ia = a + pi / 4;
      if (i == 0) {
        path.moveTo(c.dx + s * cos(a), c.dy + s * sin(a));
      } else {
        path.lineTo(c.dx + s * cos(a), c.dy + s * sin(a));
      }
      path.lineTo(c.dx + s * 0.4 * cos(ia), c.dy + s * 0.4 * sin(ia));
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(KXOStampPainter oldDelegate) => oldDelegate.color != color;
}
