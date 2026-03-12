import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_radius.dart';

class ThreeDCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final Function(int index)? onCardTap;
  final Function(int index)? onPageChanged;
  final double height;

  const ThreeDCarousel({
    super.key,
    required this.imageUrls,
    this.onCardTap,
    this.onPageChanged,
    this.height = 260,
  });

  @override
  State<ThreeDCarousel> createState() => _ThreeDCarouselState();
}

class _ThreeDCarouselState extends State<ThreeDCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _autoRotateController;
  double _currentAngle = 0;
  double _dragStartX = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _autoRotateController.addListener(() {
      setState(() {
        _currentAngle = _autoRotateController.value * 2 * math.pi;
      });
    });
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _autoRotateController.stop();
    _dragStartX = details.globalPosition.dx;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition.dx - _dragStartX;
    setState(() {
      _currentAngle += delta * 0.005;
      _dragStartX = details.globalPosition.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final count = widget.imageUrls.length;
    if (count == 0) return;
    final anglePerCard = 2 * math.pi / count;
    final nearestIndex = (-_currentAngle / anglePerCard).round();
    final targetAngle = -nearestIndex * anglePerCard;
    
    setState(() {
      _selectedIndex = (nearestIndex.abs()) % count;
      _currentAngle = targetAngle.toDouble();
    });
    widget.onPageChanged?.call(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;
    if (count == 0) return const SizedBox.shrink();
    
    final anglePerCard = 2 * math.pi / count;
    const radius = 140.0;
    const cardWidth = 140.0;
    final cardHeight = widget.height - 40;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(count, (i) {
              final angle = _currentAngle + i * anglePerCard;
              final x = math.sin(angle) * radius;
              final z = math.cos(angle) * radius;
              
              final normalizedZ = (z + radius) / (2 * radius);
              final scale = 0.7 + (normalizedZ * 0.35);
              final opacity = 0.5 + (normalizedZ * 0.5);
              
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 
                      + x - cardWidth / 2,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..scale(scale),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: GestureDetector(
                      onTap: () => widget.onCardTap?.call(i),
                      child: _CarouselCard(
                        imageUrl: widget.imageUrls[i % widget.imageUrls.length],
                        isSelected: i == _selectedIndex,
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final double width;
  final double height;

  const _CarouselCard({
    required this.imageUrl,
    required this.isSelected,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
          ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
          : null,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.md,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
      .scaleXY(end: 1.05, duration: 200.ms);
  }
}
