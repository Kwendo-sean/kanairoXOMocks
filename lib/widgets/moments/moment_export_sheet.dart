import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/tickets_service.dart';

/// Bottom sheet that lets the user pick a format (Polaroid / Photo /
/// Story / Grid), preview it, then save to gallery or share via the
/// system share sheet.
///
/// Backed by the server-side renderers in apps/moments/exports.py.
class MomentExportSheet extends StatefulWidget {
  final String momentId;
  final String? captionForShare;
  const MomentExportSheet({super.key, required this.momentId, this.captionForShare});

  static Future<void> show(BuildContext context, {
    required String momentId,
    String? captionForShare,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MomentExportSheet(
        momentId: momentId,
        captionForShare: captionForShare,
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

  String get _previewUrl => _format == 'grid'
      ? _svc.momentsGridUrl(count: _gridCount)
      : _svc.momentExportUrl(widget.momentId, format: _format);

  @override
  void initState() {
    super.initState();
    _loadPreview();
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
      await Gal.putImage(f.path, album: 'KanairoXO');
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
        _loadPreview();
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

              // Format pills
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill('Polaroid', 'polaroid'),
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
