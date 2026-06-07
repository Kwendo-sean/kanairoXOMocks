import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kanairoxo/utils/constants.dart';
import '../core/theme/app_colors.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final String? version; // Added for cache busting
  
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.version,
  });
  
  @override
  Widget build(BuildContext context) {
    String fixedUrl = ApiConstants.fixMediaUrl(url);
    
    // Show placeholder if URL is empty or invalid
    if (fixedUrl.isEmpty || 
      (!fixedUrl.startsWith('http://') && 
       !fixedUrl.startsWith('https://'))) {
      return _buildPlaceholder();
    }

    // Append version for cache busting if provided
    if (version != null && version!.isNotEmpty) {
      final separator = fixedUrl.contains('?') ? '&' : '?';
      fixedUrl = '$fixedUrl${separator}v=$version';
    }
    
    final image = CachedNetworkImage(
      imageUrl: fixedUrl,
      fit: fit,
      width: width,
      height: height,
      // We set fade to 0 because we handle the blur-in transition in imageBuilder
      fadeInDuration: Duration.zero,
      fadeOutDuration: const Duration(milliseconds: 300),
      imageBuilder: (context, imageProvider) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 15.0, end: 0.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, blurValue, child) {
            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit,
                  ),
                ),
              ),
            );
          },
        );
      },
      errorWidget: (context, url, error) => _buildErrorWidget(),
      placeholder: (context, url) => placeholder ?? _buildShimmer(),
    );
    
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    
    return image;
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFFA0A0A0),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E2D8),
      highlightColor: const Color(0xFFF5F0E8),
      child: Container(
        width: width, height: height,
        color: const Color(0xFFE8E2D8)));
  }
  
  static Widget buildPulsingGlassPlaceholder(BuildContext context, {double? width, double? height, double? borderRadius}) {
    return PulsingGlassPlaceholder(width: width, height: height, borderRadius: borderRadius);
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFFA0A0A0),
          size: 24,
        ),
      ),
    );
  }
}

class PulsingGlassPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const PulsingGlassPlaceholder({super.key, this.width, this.height, this.borderRadius});

  @override
  State<PulsingGlassPlaceholder> createState() => _PulsingGlassPlaceholderState();
}

class _PulsingGlassPlaceholderState extends State<PulsingGlassPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassColor = AppColors.themePrimaryGlass(context);
    
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: widget.borderRadius != null ? BorderRadius.circular(widget.borderRadius!) : null,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glassColor.withOpacity(0.05),
              glassColor,
              glassColor.withOpacity(0.05),
            ],
          ),
        ),
      ),
    );
  }
}
