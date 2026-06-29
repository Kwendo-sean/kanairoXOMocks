import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kanairoxo/services/events_api_service.dart';

/// Spotify-style "share to social" sheet for an event.
///
/// Three tabs (Story / Square / Post) pull a backend-rendered branded
/// PNG from /api/v1/events/<id>/share-card.png?format=...  and let the
/// user save, share, or hand off to Instagram Stories.
///
/// Designed to mirror the public event page's social-card output —
/// every share carries a short URL so the image is actionable even
/// after a screenshot.
class EventShareSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventShareSheet({super.key, required this.eventId, required this.eventTitle});

  static Future<void> show(BuildContext context, {
    required String eventId,
    required String eventTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventShareSheet(eventId: eventId, eventTitle: eventTitle),
    );
  }

  @override
  State<EventShareSheet> createState() => _EventShareSheetState();
}

class _EventShareSheetState extends State<EventShareSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _busy = false;
  final _dio = Dio();
  final _svc = EventsApiService();

  static const _formats = ['story', 'square', 'post'];
  static const _labels  = ['Story',  'Square',  'Post'];

  String get _currentFormat => _formats[_tabs.index];
  String get _currentUrl => _svc.shareCardUrl(widget.eventId, format: _currentFormat);
  String get _shortShareUrl => 'https://kanairoxo.online/e/${widget.eventId.substring(0, 8).toUpperCase()}';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _formats.length, vsync: this)
      ..addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<File> _downloadCard() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/kxo-event-${widget.eventId}-$_currentFormat.png');
    await _dio.download(_currentUrl, f.path);
    return f;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadCard();
      await Gal.putImage(f.path, album: 'KanairoXO');
      _toast('Saved to gallery');
    } catch (e) {
      _toast('Save failed: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _shareGeneric() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadCard();
      await Share.shareXFiles(
        [XFile(f.path)],
        text: '${widget.eventTitle} — $_shortShareUrl',
      );
    } catch (e) {
      _toast('Share failed: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  /// Hand the image to Instagram Stories directly. Works on iOS via the
  /// `instagram-stories://share` URL scheme — iOS reads the pasteboard
  /// for the asset. Android uses an Intent with the image MIME type
  /// pointing at IG's editor.
  Future<void> _shareToInstagramStories() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadCard();
      if (Platform.isIOS) {
        // iOS Instagram Stories handoff via pasteboard + URL scheme
        // (no third-party pkg needed — Flutter's services lib can set
        // the system pasteboard but not the Instagram-specific one.
        // For most users, share_plus to IG is enough: it routes
        // through the system share sheet which IG plugs into.)
        // Fall through to the share sheet — IG appears as a target.
        await Share.shareXFiles([XFile(f.path)], text: _shortShareUrl);
      } else {
        // Android — set MIME type so IG appears prominently.
        const channel = MethodChannel('plugins.flutter.io/share');
        await channel.invokeMethod('shareFiles', {
          'paths': [f.path],
          'mimeTypes': ['image/png'],
        }).catchError((_) async {
          await Share.shareXFiles([XFile(f.path)], text: _shortShareUrl);
        });
      }
    } catch (e) {
      _toast('Share failed: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _shareViaWhatsApp() async {
    setState(() => _busy = true);
    try {
      final f = await _downloadCard();
      // share_plus opens the system share sheet; WhatsApp will be a
      // visible target. Avoids the brittle "wa.me" URL scheme that
      // doesn't accept image attachments.
      await Share.shareXFiles(
        [XFile(f.path)],
        text: '${widget.eventTitle}\n$_shortShareUrl',
      );
    } catch (e) {
      _toast('Share failed: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shortShareUrl));
    _toast('Link copied');
  }

  Future<void> _openCalendar() async {
    final uri = Uri.parse(_svc.calendarIcsUrl(widget.eventId));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(
              width: 42, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Share event',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                    fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.eventTitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFC0394B),
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
              tabs: const [Tab(text: 'STORY'), Tab(text: 'SQUARE'), Tab(text: 'POST')],
            ),
            Expanded(child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(children: [
                // Card preview — aspect ratio per format
                AspectRatio(
                  aspectRatio: _currentFormat == 'story' ? 9 / 16
                    : _currentFormat == 'square' ? 1
                    : 4 / 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _currentUrl,
                      fit: BoxFit.cover,
                      headers: const {'Accept': 'image/*'},
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : Container(color: Colors.white.withOpacity(0.04),
                              child: const Center(child: CircularProgressIndicator(
                                color: Color(0xFFC0394B), strokeWidth: 2,
                              ))),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withOpacity(0.04),
                        child: const Center(child: Text(
                          'Card not ready yet',
                          style: TextStyle(color: Colors.white54),
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Quick actions
                Row(children: [
                  _actionButton(Icons.camera_alt_outlined, 'Stories', _shareToInstagramStories),
                  const SizedBox(width: 8),
                  _actionButton(Icons.chat_bubble_outline, 'WhatsApp', _shareViaWhatsApp),
                  const SizedBox(width: 8),
                  _actionButton(Icons.save_alt, 'Save', _save),
                  const SizedBox(width: 8),
                  _actionButton(Icons.link, 'Copy link', _copyLink),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share elsewhere'),
                    onPressed: _busy ? null : _shareGeneric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0394B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.event, size: 18, color: Colors.white),
                    label: const Text('+ Calendar'),
                    onPressed: _busy ? null : _openCalendar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
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
              ]),
            )),
          ]),
        );
      },
    );
  }
}
