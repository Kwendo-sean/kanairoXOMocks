import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

/// Renders a remote moment media — image via CachedNetworkImage, video via VideoPlayer.
/// Use `thumbnailMode: true` in lists where many previews exist; videos then show
/// a static play-icon placeholder instead of spawning a VideoPlayerController.
class NetworkMediaPreview extends StatefulWidget {
  final String url;
  final String mediaType; // 'image' | 'video'
  final BoxFit fit;
  final bool autoPlay;
  final bool loop;
  final bool muted;
  final bool thumbnailMode;
  final Widget? placeholder;

  const NetworkMediaPreview({
    super.key,
    required this.url,
    required this.mediaType,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.loop = true,
    this.muted = true,
    this.thumbnailMode = false,
    this.placeholder,
  });

  @override
  State<NetworkMediaPreview> createState() => _NetworkMediaPreviewState();
}

class _NetworkMediaPreviewState extends State<NetworkMediaPreview> {
  VideoPlayerController? _controller;

  bool get _isVideo => widget.mediaType == 'video';

  @override
  void initState() {
    super.initState();
    if (_isVideo && !widget.thumbnailMode) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      await c.setLooping(widget.loop);
      if (widget.muted) await c.setVolume(0);
      if (widget.autoPlay) await c.play();
      if (mounted) setState(() => _controller = c);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(NetworkMediaPreview old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.mediaType != widget.mediaType) {
      _controller?.dispose();
      _controller = null;
      if (_isVideo && !widget.thumbnailMode) _initVideo();
      else setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideo) {
      return CachedNetworkImage(
        imageUrl: widget.url, fit: widget.fit,
        placeholder: (_, __) => widget.placeholder ?? _shimmer(),
        errorWidget: (_, __, ___) => Container(color: const Color(0xFFEEE6DC),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32))));
    }

    if (widget.thumbnailMode) {
      return Stack(fit: StackFit.expand, children: [
        _shimmer(),
        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32)),
      ]);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return _shimmer();
    }

    return Stack(fit: StackFit.expand, children: [
      FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!))),
      if (!_controller!.value.isPlaying)
        Positioned(right: 8, bottom: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 14))),
    ]);
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E2D8),
      highlightColor: const Color(0xFFF5F0E8),
      child: Container(color: const Color(0xFFE8E2D8)));
  }
}
