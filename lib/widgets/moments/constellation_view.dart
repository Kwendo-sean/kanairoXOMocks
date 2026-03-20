import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/moment.dart';

class ConstellationView extends StatefulWidget {
  final List<Moment> moments;
  final Function(Moment) onTap;

  const ConstellationView({
    super.key,
    required this.moments,
    required this.onTap,
  });

  @override
  State<ConstellationView> createState() => _ConstellationViewState();
}

class _ConstellationViewState extends State<ConstellationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkleController;
  List<_StarData> _stars = [];

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _generateStars();
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  void _generateStars() {
    final random = math.Random(42);
    _stars = widget.moments.map((moment) {
      return _StarData(
        x: random.nextDouble() * 320 + 20,
        y: random.nextDouble() * 160 + 20,
        // More likes = bigger brighter star
        brightness: math.min(1.0, 0.3 + (moment.likeCount / 20.0)),
        moment: moment,
      );
    }).toList();
  }

  @override
  void didUpdateWidget(ConstellationView old) {
    super.didUpdateWidget(old);
    if (old.moments != widget.moments) {
      _generateStars();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moments.isEmpty) {
      return Container(
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(20)),
          child: const Center(
              child: Text('Post moments to see your stars',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontFamily: 'DM Sans'))));
    }

    return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedBuilder(
                animation: _twinkleController,
                builder: (context, _) => CustomPaint(
                    painter: _StarsPainter(
                        stars: _stars, twinkle: _twinkleController.value),
                    child: Stack(
                        children: _stars
                            .map((star) => Positioned(
                                left: star.x - 20,
                                top: star.y - 20,
                                child: GestureDetector(
                                    onTap: () => widget.onTap(star.moment),
                                    child: _StarNode(
                                        star: star,
                                        twinkle: _twinkleController.value))))
                            .toList())))));
  }
}

class _StarData {
  final double x;
  final double y;
  final double brightness;
  final Moment moment;
  _StarData(
      {required this.x,
      required this.y,
      required this.brightness,
      required this.moment});
}

class _StarNode extends StatelessWidget {
  final _StarData star;
  final double twinkle;

  const _StarNode({required this.star, required this.twinkle});

  @override
  Widget build(BuildContext context) {
    final size = 6.0 + (star.brightness * 14);
    final opacity = 0.5 + (twinkle * 0.5 * star.brightness);

    return SizedBox(
        width: 40,
        height: 40,
        child: Center(
            child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.white.withOpacity(star.brightness * 0.6),
                          blurRadius: size * 2,
                          spreadRadius: size * 0.3)
                    ]))));
  }
}

class _StarsPainter extends CustomPainter {
  final List<_StarData> stars;
  final double twinkle;

  _StarsPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06 + twinkle * 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw lines between nearby stars
    for (int i = 0; i < stars.length; i++) {
      for (int j = i + 1; j < stars.length; j++) {
        final dist = math.sqrt(math.pow(stars[i].x - stars[j].x, 2) +
            math.pow(stars[i].y - stars[j].y, 2));
        if (dist < 70) {
          canvas.drawLine(
              Offset(stars[i].x, stars[i].y), Offset(stars[j].x, stars[j].y), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.twinkle != twinkle;
}
