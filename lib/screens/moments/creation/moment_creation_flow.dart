import 'package:flutter/material.dart';
import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/screens/moments/creation/capture_screen.dart';
import 'package:kanairoxo/screens/moments/creation/edit_screen.dart';
import 'package:kanairoxo/screens/moments/creation/post_screen.dart';

class MomentCreationFlow extends StatefulWidget {
  const MomentCreationFlow({super.key});

  @override
  State<MomentCreationFlow> createState() => _MomentCreationFlowState();
}

class _MomentCreationFlowState extends State<MomentCreationFlow> {
  final PageController _pageController = PageController();
  List<MediaItem> _captured = [];
  String _filterId = 'none';
  double _trimStart = 0;
  double _trimDuration = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          CaptureScreen(
            onMediaCaptured: (media) {
              // Force single media — no carousels
              setState(() => _captured = media.isEmpty ? [] : [media.first]);
              _next();
            },
          ),
          EditScreen(
            mediaItems: _captured,
            onComplete: (media, filterId, trimStart, trimDuration) {
              setState(() {
                _captured = media.isEmpty ? [] : [media.first];
                _filterId = filterId;
                _trimStart = trimStart;
                _trimDuration = trimDuration;
              });
              _next();
            },
          ),
          PostScreen(
            mediaItems: _captured,
            filterId: _filterId,
            trimStart: _trimStart,
            trimDuration: _trimDuration,
            onComplete: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
