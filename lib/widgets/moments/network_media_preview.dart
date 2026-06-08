import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Renders a remote moment media — image via CachedNetworkImage, video via VideoPlayer.
/// Use `thumbnailMode: true` in lists where many previews exist; videos then show
/// a static play-icon placeholder instead of spawning a VideoPlayerController.
///
/// Videos auto-pause when scrolled off-screen, when the user navigates to another
/// tab, and when the app is backgrounded — so trailer audio doesn't keep playing
/// after you've left the Events page.
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

class _NetworkMediaPreviewState extends State<NetworkMediaPreview>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isVisible = false;

  bool get _isVideo => widget.mediaType == 'video';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isVideo && !widget.thumbnailMode) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      await c.setLooping(widget.loop);
      if (widget.muted) await c.setVolume(0);
      // Don't auto-play here — wait for visibility callback. Otherwise the
      // very-first build before VisibilityDetector reports a fraction would
      // start audio before we know if the widget is actually on screen.
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App backgrounded -> pause. Returning to foreground -> resume only if
    // still visible (visibility callback handles re-plays for in-app nav).
    if (state != AppLifecycleState.resumed) {
      _controller?.pause();
    } else if (_isVisible) {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _controller == null) return;
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.5;

    if (_isVisible && !wasVisible) {
      if (widget.autoPlay) _controller!.play();
    } else if (!_isVisible && wasVisible) {
      _controller!.pause();
    }
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

    // Unique visibility key per URL so multiple previews on the same page
    // each track their own visibility independently.
    return VisibilityDetector(
      key: Key('vmp:${widget.url}:${hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(fit: StackFit.expand, children: [
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
      ]),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E2D8),
      highlightColor: const Color(0xFFF5F0E8),
      child: Container(color: const Color(0xFFE8E2D8)));
  }
}
