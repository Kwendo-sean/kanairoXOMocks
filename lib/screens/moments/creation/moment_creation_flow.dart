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
  List<MediaItem> _capturedMedia = [];

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
              setState(() => _capturedMedia = media);
              _next();
            },
          ),
          EditScreen(
            mediaItems: _capturedMedia,
            onComplete: (media) {
              setState(() => _capturedMedia = media);
              _next();
            },
          ),
          PostScreen(
            mediaItems: _capturedMedia,
            onComplete: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
