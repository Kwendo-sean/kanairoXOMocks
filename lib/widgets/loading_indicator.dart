import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double? borderRadius;

  const LoadingIndicator({
    super.key, 
    this.size = 40.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PulsingGlassPlaceholder(
        width: size,
        height: size,
        borderRadius: borderRadius ?? 12,
      ),
    );
  }
}
