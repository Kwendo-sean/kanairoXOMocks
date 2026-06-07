import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/widgets/moments/local_media_preview.dart';

class CaptureScreen extends StatefulWidget {
  final Function(List<MediaItem>) onMediaCaptured;
  const CaptureScreen({super.key, required this.onMediaCaptured});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _videoMode = false; // false = photo, true = video
  Timer? _recordTimer;
  int _recordMs = 0;

  static const int _maxVideoMs = 3000; // Locket-style cap

  final List<MediaItem> _captured = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _accent = Color(0xFF9B111E);
  static const Color _paper = Color(0xFFFAF7F4);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    final c = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );
    await c.initialize();
    if (mounted) setState(() => _controller = c);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    setState(() => _controller = null);
    await _initCamera();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final img = await _controller!.takePicture();
      setState(() {
        _captured
          ..clear()
          ..add(MediaItem(file: File(img.path), type: MediaType.photo, position: 0));
      });
    } catch (_) {}
  }

  Future<void> _startVideo() async {
    if (_controller == null || _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordMs = 0;
      });
      _recordTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _recordMs += 50);
        if (_recordMs >= _maxVideoMs) _stopVideo();
      });
    } catch (_) {}
  }

  Future<void> _stopVideo() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    try {
      final f = await _controller!.stopVideoRecording();
      setState(() {
        _captured
          ..clear()
          ..add(MediaItem(file: File(f.path), type: MediaType.video, position: 0));
        _isRecording = false;
        _recordMs = 0;
      });
    } catch (_) {
      setState(() { _isRecording = false; _recordMs = 0; });
    }
  }

  Future<void> _pickFromGallery() async {
    // Release the camera before launching the system picker — otherwise the
    // camera + picker hardware contention crashes the app on return.
    final wasInitialized = _controller != null && _controller!.value.isInitialized;
    final wasVideoMode = _videoMode;
    if (wasInitialized) {
      await _controller!.dispose();
      if (mounted) setState(() => _controller = null);
    }

    try {
      if (wasVideoMode) {
        final XFile? vid = await _picker.pickVideo(source: ImageSource.gallery);
        if (vid != null) {
          if (mounted) {
            setState(() {
              _captured
                ..clear()
                ..add(MediaItem(file: File(vid.path), type: MediaType.video, position: 0));
            });
          }
          // User picked — fire-and-forget straight to Next so we never re-init the camera.
          if (mounted) widget.onMediaCaptured(_captured);
          return;
        }
      } else {
        final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
        if (img != null) {
          if (mounted) {
            setState(() {
              _captured
                ..clear()
                ..add(MediaItem(file: File(img.path), type: MediaType.photo, position: 0));
            });
          }
          if (mounted) widget.onMediaCaptured(_captured);
          return;
        }
      }
    } finally {
      // User cancelled — re-initialize the camera so the live preview comes back.
      if (mounted && _controller == null) await _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : _paper;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                _topBar(textColor),
                const SizedBox(height: 8),
                Expanded(child: Center(child: _polaroidPreview(textColor))),
                _modeToggle(textColor, isDark),
                _shutterRow(textColor, isDark),
                const SizedBox(height: 8),
              ],
            ),
      ),
    );
  }

  Widget _topBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: textColor, size: 26),
            onPressed: () => Navigator.pop(context)),
          Text('Capture a Moment',
            style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
          IconButton(
            icon: Icon(Icons.flip_camera_ios_rounded, color: textColor, size: 24),
            onPressed: _flipCamera),
        ],
      ),
    );
  }

  Widget _polaroidPreview(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Transform.rotate(
        angle: -0.015,
        child: Container(
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 0, offset: const Offset(-1, -1)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(fit: StackFit.expand, children: [
                    // Center-crop the camera feed to fit the square without stretching
                    LayoutBuilder(builder: (ctx, box) {
                      final previewAspect = _controller!.value.previewSize == null
                        ? 1.0
                        : _controller!.value.previewSize!.height / _controller!.value.previewSize!.width;
                      return ClipRect(
                        child: OverflowBox(
                          maxWidth: double.infinity, maxHeight: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: box.maxWidth,
                              height: box.maxWidth / previewAspect,
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_isRecording)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent, borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text('${(_recordMs / 1000).toStringAsFixed(1)}s',
                              style: const TextStyle(color: Colors.white,
                                fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w700)),
                          ]),
                        )),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Nairobi · ${DateTime.now().day}/${DateTime.now().month}',
                  style: GoogleFonts.caveat(fontSize: 16, color: const Color(0xFF555555)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeToggle(Color textColor, bool isDark) {
    Widget _pill(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: TextStyle(
            fontFamily: 'DMSans', fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 1.2,
            color: selected ? Colors.white : textColor.withOpacity(0.55))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1612) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: textColor.withOpacity(0.08))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _pill('PHOTO', !_videoMode, () => setState(() => _videoMode = false)),
          _pill('VIDEO 3s', _videoMode, () => setState(() => _videoMode = true)),
        ]),
      ),
    );
  }

  Widget _shutterRow(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.photo_library_outlined, color: textColor, size: 26),
            onPressed: _pickFromGallery),
          GestureDetector(
            onTap: _videoMode ? null : _takePhoto,
            onLongPressStart: _videoMode ? (_) => _startVideo() : null,
            onLongPressEnd: _videoMode ? (_) => _stopVideo() : null,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _isRecording ? _accent : textColor, width: 3))),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? _accent : (_videoMode ? _accent.withOpacity(0.85) : textColor))),
              if (_isRecording)
                SizedBox(width: 76, height: 76,
                  child: CircularProgressIndicator(
                    value: _recordMs / _maxVideoMs,
                    strokeWidth: 3, color: Colors.white, backgroundColor: Colors.transparent)),
            ]),
          ),
          _captured.isNotEmpty
            ? GestureDetector(
                onTap: () => widget.onMediaCaptured(_captured),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(999)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Next', style: TextStyle(
                      color: Colors.white, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                  ])))
            : SizedBox(width: 48, height: 48,
                child: Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _gallerySheet(Color textColor, bool isDark) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _captured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = _captured[i];
          return Transform.rotate(
            angle: i.isEven ? 0.04 : -0.04,
            child: Stack(children: [
              Container(
                width: 56, height: 70,
                decoration: BoxDecoration(
                  color: _paper, borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6, offset: const Offset(0, 3))]),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: SizedBox(
                    width: 50, height: 50,
                    child: LocalMediaPreview(
                      item: m, fit: BoxFit.cover, thumbnailMode: true))),
              ),
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _captured.removeAt(i)),
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 12)))),
            ]),
          );
        },
      ),
    );
  }
}
