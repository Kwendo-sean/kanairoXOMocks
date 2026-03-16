import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/utils/url_helper.dart';
import '../core/theme/app_colors.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });
  
  @override
  Widget build(BuildContext context) {
    final fixedUrl = UrlHelper.fixMediaUrl(url);
    
    if (!UrlHelper.isValidUrl(fixedUrl)) {
      return _buildPlaceholder();
    }
    
    final image = CachedNetworkImage(
      imageUrl: fixedUrl,
      fit: fit,
      width: width,
      height: height,
      httpHeaders: const {
        'Accept': 'image/*',
      },
      errorWidget: (context, url, error) {
        debugPrint('Image failed: $url\nError: $error');
        return _buildErrorWidget();
      },
      placeholder: (context, url) =>
        placeholder ?? _buildLoadingWidget(),
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
  
  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade50,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.primary,
        ),
      ),
    );
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
