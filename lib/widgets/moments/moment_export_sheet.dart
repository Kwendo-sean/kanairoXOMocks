import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/tickets_service.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';

/// Bottom sheet that lets the user pick a format (Polaroid / Photo /
/// Story / Grid), preview it, then save to gallery or share via the
/// system share sheet.
///
/// Image moments: all formats are stills from apps/moments/exports.py.
/// Video moments: Polaroid is the ffmpeg-baked polaroid VIDEO
/// (/polaroid-video/) and the Photo pill becomes the raw Video — both
/// save and share as mp4. Story/Grid stay stills.
class MomentExportSheet extends StatefulWidget {
  final String momentId;
  final String? captionForShare;
  final String mediaType; // 'image' | 'video'
  final String? mediaUrl; // raw media URL (the mp4 for video moments)
  const MomentExportSheet({
    super.key,
    required this.momentId,
    this.captionForShare,
    this.mediaType = 'image',
    this.mediaUrl,
  });

  static Future<void> show(BuildContext context, {
    required String momentId,
    String? captionForShare,
    String mediaType = 'image',
    String? mediaUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MomentExportSheet(
        momentId: momentId,
        captionForShare: captionForShare,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
      ),
    );
  }

  @override
  State<MomentExportSheet> createState() => _MomentExportSheetState();
}

class _MomentExportSheetState extends State<MomentExportSheet> {
  String _format = 'polaroid';
  int _gridCount = 4;
  bool _busy = false;
  final _svc = TicketsService();
  // The export endpoints require auth — use the shared ApiClient Dio so the
  // Bearer token goes out with every request (a bare Dio/Image.network 401s).
  final Dio _dio = ApiClient().dio;

  Uint8List? _previewBytes;
  bool _previewLoading = true;
  bool _previewFailed = false;
  int _previewReq = 0;

  // Video-moment state: polaroid resolves to the server-baked polaroid
  // video, 'video' is the raw clip.
  String? _bakedPolaroidUrl;
  String? _videoPreviewUrl;
  bool _videoResolving = false;
  bool _videoFailed = false;

  bool get _isVideoMoment => widget.mediaType == 'video';
  bool get _isVideoFormat =>
      _isVideoMoment && (_format == 'polaroid' || _format == 'video');

  String get _previewUrl => _format == 'grid'
      ? _svc.momentsGridUrl(count: _gridCount)
      : _svc.momentExportUrl(widget.momentId, format: _format);

  @override
  void initState() {
    super.initState();
    _refreshPreview();
  }

  void _refreshPreview() {
    if (_isVideoFormat) {
      _resolveVideo();
    } else {
      _loadPreview();
    }
  }

  /// Resolve the video URL for the current format. The polaroid bake can
  /// take a while on first request (ffmpeg composites server-side); the
  /// result is cached, so a retry after a timeout usually lands instantly.
  Future<void> _resolveVideo() async {
    final req = ++_previewReq;
    setState(() {
      _videoResolving = true;
      _videoFailed = false;
      _videoPreviewUrl = null;
    });
    try {
      String url;
      if (_format == 'video') {
        url = widget.mediaUrl!;
      } else {
        _bakedPolaroidUrl ??= (await ApiClient()
            .get('api/v1/moments/${widget.momentId}/polaroid-video/'))['url']
            ?.toString();
        url = _bakedPolaroidUrl!;
      }
      if (!mounted || req != _previewReq) return;
      setState(() {
        _videoPreviewUrl = url;
        _videoResolving = false;
      });
    } catch (_) {
      if (!mounted || req != _previewReq) return;
      setState(() {
        _videoFailed = true;
        _videoResolving = false;
      });
    }
  }

  Future<void> _loadPreview() async {
    final req = ++_previewReq;
    setState(() {
      _previewLoading = true;
      _previewFailed = false;
      _previewBytes = null;
    });
    try {
      final resp = await _dio.get<List<int>>(
        _previewUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'image/*'},
        ),
      );
      if (!mounted || req != _previewReq) return;
      setState(() {
        _previewBytes = Uint8List.fromList(resp.data ?? const []);
        _previewLoading = false;
      });
    } catch (_) {
      if (!mounted || req != _previewReq) return;
      setState(() {
        _previewFailed = true;
        _previewLoading = false;
      });
    }
  }

  Future<File> _downloadToTemp() async {
    final dir = await getTemporaryDirectory();
    if (_isVideoFormat) {
      if (_videoPreviewUrl == null) {
        await _resolveVideo();
        if (_videoPreviewUrl == null) throw Exception('video not ready');
      }
      final file = File('${dir.path}/kxo-${widget.momentId}-$_format.mp4');
      await _dio.download(_videoPreviewUrl!, file.path);
      return file;
    }
    final file = File('${dir.path}/kxo-${widget.momentId}-$_format.jpg');
    // Reuse the preview bytes when they're already in hand.
    final bytes = _previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      await file.writeAsBytes(bytes, flush: true);
    } else {
      await _dio.download(_previewUrl, file.path);
    }
    return file;
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadToTemp();
      if (_isVideoFormat) {
        await Gal.putVideo(f.path, album: 'KanairoXO');
      } else {
        await Gal.putImage(f.path, album: 'KanairoXO');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadToTemp();
      await Share.shareXFiles(
        [XFile(f.path)],
        text: widget.captionForShare ?? 'My KanairoXO moment',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildPreview() {
    if (_isVideoFormat) {
      if (_videoResolving) {
        return Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(
              color: Color(0xFFC0394B), strokeWidth: 2),
            const SizedBox(height: 14),
            Text(
              _format == 'polaroid'
                  ? 'Preparing polaroid video…'
                  : 'Loading video…',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ]),
        );
      }
      if (_videoFailed || _videoPreviewUrl == null) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Preview unavailable',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _resolveVideo,
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFC0394B))),
            ),
          ]),
        );
      }
      return SizedBox(
        height: 440,
        width: double.infinity,
        child: NetworkMediaPreview(
          key: ValueKey(_videoPreviewUrl),
          url: _videoPreviewUrl!,
          mediaType: 'video',
          fit: BoxFit.contain,
          autoPlay: true,
          loop: true,
        ),
      );
    }
    if (_previewLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: Color(0xFFC0394B),
          strokeWidth: 2,
        ),
      );
    }
    if (_previewFailed || _previewBytes == null || _previewBytes!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Preview unavailable',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadPreview,
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFFC0394B)),
              ),
            ),
          ],
        ),
      );
    }
    return Image.memory(
      _previewBytes!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }

  Widget _pill(String label, String value) {
    final selected = _format == value;
    return GestureDetector(
      onTap: () {
        if (_format == value) return;
        setState(() => _format = value);
        _refreshPreview();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC0394B) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected ? const Color(0xFFC0394B) : Colors.white.withOpacity(0.12),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Grab handle
              Center(child: Container(
                width: 42, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 16),

              const Text(
                'Save & share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a format. Saves to your gallery or shares via WhatsApp / Stories.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              // Format pills — video moments swap Photo for the raw Video
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill('Polaroid', 'polaroid'),
                if (_isVideoMoment && (widget.mediaUrl ?? '').isNotEmpty)
                  _pill('Video', 'video')
                else if (!_isVideoMoment)
                  _pill('Photo', 'photo'),
                _pill('Story', 'story'),
                _pill('Grid (my week)', 'grid'),
              ]),

              if (_format == 'grid') ...[
                const SizedBox(height: 12),
                Row(children: [
                  Text('Layout: ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('2×2'),
                    selected: _gridCount == 4,
                    onSelected: (_) {
                      if (_gridCount == 4) return;
                      setState(() => _gridCount = 4);
                      _loadPreview();
                    },
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFFC0394B),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('3×3'),
                    selected: _gridCount == 9,
                    onSelected: (_) {
                      if (_gridCount == 9) return;
                      setState(() => _gridCount = 9);
                      _loadPreview();
                    },
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFFC0394B),
                  ),
                ]),
              ],

              const SizedBox(height: 18),
              // Preview
              Container(
                constraints: const BoxConstraints(minHeight: 280, maxHeight: 460),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Center(child: _buildPreview()),
              ),

              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt, color: Colors.white, size: 18),
                  label: const Text('Save'),
                  onPressed: _busy ? null : _saveToGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share'),
                  onPressed: _busy ? null : _share,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0394B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
              ]),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(
                    color: Color(0xFFC0394B),
                    backgroundColor: Color(0x22FFFFFF),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
