import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:kanairoxo/models/moment_creation_models.dart';

/// Renders a local MediaItem — Image for photo, looping silent video for video.
class LocalMediaPreview extends StatefulWidget {
  final MediaItem item;
  final BoxFit fit;
  final bool autoPlay;
  final bool showPlayBadge;

  /// When true, video items render as a STATIC placeholder (play icon + black bg)
  /// instead of spawning a VideoPlayerController. Use for thumbnails / lists where
  /// many previews exist at once — initializing many players crashes the app.
  final bool thumbnailMode;

  const LocalMediaPreview({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.showPlayBadge = true,
    this.thumbnailMode = false,
  });

  @override
  State<LocalMediaPreview> createState() => _LocalMediaPreviewState();
}

class _LocalMediaPreviewState extends State<LocalMediaPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == MediaType.video && !widget.thumbnailMode) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.file(widget.item.file);
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (widget.autoPlay) await c.play();
      if (mounted) setState(() => _controller = c);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(LocalMediaPreview old) {
    super.didUpdateWidget(old);
    if (old.item.file.path != widget.item.file.path) {
      _controller?.dispose();
      _controller = null;
      if (widget.item.type == MediaType.video) _initVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == MediaType.photo) {
      return Image.file(widget.item.file, fit: widget.fit,
        errorBuilder: (_, __, ___) => _broken());
    }

    // Video — thumbnail mode: static placeholder, never inits a player
    if (widget.thumbnailMode) {
      return Container(color: Colors.black,
        child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28)));
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
    }

    return Stack(fit: StackFit.expand, children: [
      FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!))),
      if (widget.showPlayBadge && !_controller!.value.isPlaying)
        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
    ]);
  }

  Widget _broken() {
    return Container(color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 28)));
  }
}
