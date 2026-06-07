import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/widgets/moments/local_media_preview.dart';

class PostScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final String filterId;
  final double trimStart;
  final double trimDuration;
  final VoidCallback onComplete;

  const PostScreen({
    super.key,
    required this.mediaItems,
    required this.onComplete,
    this.filterId = 'none',
    this.trimStart = 0,
    this.trimDuration = 0,
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  String _visibility = 'Public';
  int? _selectedEventId;
  List<LinkedEvent> _linkableEvents = [];
  bool _isLoadingEvents = true;
  bool _isPosting = false;

  static const Color _accent = Color(0xFF9B111E);
  static const Color _paper = Color(0xFFFAF7F4);

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final service = MomentService();
    final events = await service.getLinkableEvents();
    if (mounted) {
      setState(() {
        _linkableEvents = events;
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _handlePost() async {
    if (widget.mediaItems.isEmpty) return;
    setState(() => _isPosting = true);
    final service = MomentService();
    try {
      final first = widget.mediaItems.first;
      await service.createMoment(
        caption: _captionController.text,
        type: 'vibe',
        photo: first.file,
        mediaType: first.type == MediaType.video ? 'video' : 'image',
        location: _locationController.text,
        linkedEventId: _selectedEventId,
        visibility: _visibility,
        filterId: widget.filterId,
        trimStart: widget.trimStart,
        trimDuration: widget.trimDuration,
      );
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : _paper;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;
    final divider = textColor.withOpacity(0.08);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text('New Moment',
          style: TextStyle(
            fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isPosting ? null : _handlePost,
              child: _isPosting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                : const Text('Share',
                    style: TextStyle(
                      color: _accent, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 14))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _sectionLabel('YOUR POLAROID'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _polaroidThumb(),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider)),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 5,
                    minLines: 4,
                    style: TextStyle(
                      fontFamily: 'DMSans', color: textColor, fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: TextStyle(
                        fontFamily: 'DMSans', color: textColor.withOpacity(0.35), fontSize: 14),
                      border: InputBorder.none,
                      isCollapsed: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _sectionLabel('DETAILS'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: surface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: divider)),
            child: Column(children: [
              _row(
                icon: Icons.location_on_outlined,
                child: TextField(
                  controller: _locationController,
                  style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search places',
                    hintStyle: TextStyle(
                      fontFamily: 'DMSans', color: textColor.withOpacity(0.35), fontSize: 14),
                    border: InputBorder.none, isCollapsed: true)),
                textColor: textColor,
              ),
              Divider(color: divider, height: 1, indent: 16, endIndent: 16),
              _row(
                icon: Icons.person_add_alt_1_outlined,
                child: Text('Tag people',
                  style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14)),
                trailing: Icon(Icons.chevron_right, color: textColor.withOpacity(0.4)),
                textColor: textColor,
              ),
              Divider(color: divider, height: 1, indent: 16, endIndent: 16),
              _row(
                icon: Icons.visibility_outlined,
                child: Text('Visibility',
                  style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14)),
                trailing: DropdownButton<String>(
                  value: _visibility,
                  underline: const SizedBox(),
                  dropdownColor: surface,
                  style: TextStyle(
                    fontFamily: 'DMSans', color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  items: ['Public', 'Connections', 'Close Friends']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setState(() => _visibility = v!)),
                textColor: textColor),
            ]),
          ),
          const SizedBox(height: 28),

          _sectionLabel('LINK TO EVENT'),
          const SizedBox(height: 12),
          if (_isLoadingEvents)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
          else if (_linkableEvents.isEmpty)
            Text('No events you can link right now.',
              style: TextStyle(
                fontFamily: 'DMSans', color: textColor.withOpacity(0.45), fontSize: 12))
          else
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _linkableEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final e = _linkableEvents[i];
                  final selected = _selectedEventId == e.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEventId = selected ? null : e.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _accent : surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? _accent : divider)),
                      child: Center(child: Text(e.title,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: selected ? Colors.white : textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 36),
          GestureDetector(
            onTap: () {}, // Save draft TODO
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _accent.withOpacity(0.6), width: 1.5)),
              child: const Center(child: Text('Save Draft',
                style: TextStyle(
                  fontFamily: 'DMSans', color: _accent,
                  fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: const TextStyle(
        fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w700,
        color: _accent, letterSpacing: 1.8)),
      const SizedBox(height: 4),
      Container(width: 24, height: 2, color: _accent),
    ]);
  }

  Widget _polaroidThumb() {
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        decoration: BoxDecoration(
          color: _paper, borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 70, height: 70,
            child: LocalMediaPreview(
              item: widget.mediaItems.first, fit: BoxFit.cover, thumbnailMode: true))),
      ),
    );
  }

  Widget _row({required IconData icon, required Widget child, Widget? trailing, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Icon(icon, color: textColor.withOpacity(0.55), size: 20),
        const SizedBox(width: 14),
        Expanded(child: child),
        if (trailing != null) trailing,
      ]),
    );
  }
}
