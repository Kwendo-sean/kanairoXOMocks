import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/models/moment_filter.dart';
import 'package:kanairoxo/widgets/moments/local_media_preview.dart';

class EditScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  /// Receives: list of media items (always size 1 now), the chosen filter id,
  /// trim start seconds (for video), and trim duration seconds (for video).
  final Function(List<MediaItem> items, String filterId,
      double trimStart, double trimDuration) onComplete;

  const EditScreen({super.key, required this.mediaItems, required this.onComplete});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'none';
  final TextEditingController _overlayText = TextEditingController();

  // Video trim state
  VideoPlayerController? _trimController;
  double _trimStart = 0;        // seconds
  double _trimDuration = 0;     // seconds (0 = no trim)
  static const double _maxTrim = 5.0;

  static const Color _accent = Color(0xFF9B111E);
  static const Color _paper = Color(0xFFFAF7F4);

  MediaItem get _item => widget.mediaItems.first;
  bool get _isVideo => _item.type == MediaType.video;

  List<Tab> get _tabs => [
    const Tab(icon: Icon(Icons.filter_b_and_w, size: 18), text: 'FILTERS'),
    if (_isVideo) const Tab(icon: Icon(Icons.content_cut, size: 18), text: 'TRIM'),
    const Tab(icon: Icon(Icons.crop_rotate, size: 18), text: 'CROP'),
    const Tab(icon: Icon(Icons.text_fields, size: 18), text: 'TEXT'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Lazy-init trim controller only when the user actually opens the Trim tab,
    // so we don't have two VideoPlayerControllers fighting over the same file.
    _tabController.addListener(_maybeInitTrimController);
  }

  void _maybeInitTrimController() {
    if (!_isVideo || _trimController != null) return;
    // Trim tab is index 1 for videos, otherwise nothing to do
    if (_tabController.index != 1) return;
    _initTrimController();
  }

  Future<void> _initTrimController() async {
    final c = VideoPlayerController.file(_item.file);
    try {
      await c.initialize();
      await c.setLooping(false);
      await c.setVolume(0);
      final total = c.value.duration.inMilliseconds / 1000.0;
      _trimDuration = total <= _maxTrim ? total : _maxTrim;
      if (mounted) setState(() => _trimController = c);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_maybeInitTrimController);
    _trimController?.dispose();
    _tabController.dispose();
    _overlayText.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onComplete(widget.mediaItems, _selectedFilter, _trimStart, _trimDuration);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : _paper;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text('Edit',
          style: TextStyle(
            fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _submit,
              child: const Text('Next',
                style: TextStyle(
                  color: _accent, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _polaroidPreview())),
          _tabBar(textColor, surface),
          SizedBox(
            height: 150,
            child: TabBarView(
              controller: _tabController,
              children: [
                _filterStrip(textColor, isDark),
                if (_isVideo) _trimPanel(textColor),
                _placeholder('Crop coming soon', textColor),
                _textPanel(textColor),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _polaroidPreview() {
    final filter = MomentFilter.byId(_selectedFilter).colorFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(fit: StackFit.expand, children: [
                    filter == null
                      ? LocalMediaPreview(item: _item, fit: BoxFit.cover,
                          autoPlay: false, showPlayBadge: false)
                      : ColorFiltered(
                          colorFilter: filter,
                          child: LocalMediaPreview(item: _item, fit: BoxFit.cover,
                            autoPlay: false, showPlayBadge: false)),
                    if (_overlayText.text.isNotEmpty)
                      Positioned(
                        left: 10, right: 10, bottom: 14,
                        child: Text(_overlayText.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pacifico(
                            color: Colors.white, fontSize: 22,
                            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)]))),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_selectedFilter == 'none' ? 'A moment in Nairobi' : '${MomentFilter.byId(_selectedFilter).label} · Nairobi',
                  style: GoogleFonts.caveat(fontSize: 16, color: const Color(0xFF555555)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar(Color textColor, Color surface) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.06))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: _accent,
        indicatorWeight: 2,
        labelColor: _accent,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'DMSans', fontWeight: FontWeight.w500, fontSize: 11),
        tabs: _tabs,
      ),
    );
  }

  Widget _filterStrip(Color textColor, bool isDark) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: MomentFilter.presets.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final f = MomentFilter.presets[i];
        final selected = _selectedFilter == f.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = f.id),
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _accent : textColor.withOpacity(0.1),
                    width: selected ? 2 : 1)),
                clipBehavior: Clip.antiAlias,
                child: f.colorFilter == null
                  ? LocalMediaPreview(item: _item, fit: BoxFit.cover, thumbnailMode: true)
                  : ColorFiltered(
                      colorFilter: f.colorFilter!,
                      child: LocalMediaPreview(item: _item, fit: BoxFit.cover, thumbnailMode: true)),
              ),
              const SizedBox(height: 6),
              Text(f.label, style: TextStyle(
                fontFamily: 'DMSans', fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _accent : textColor.withOpacity(0.65))),
            ],
          ),
        );
      },
    );
  }

  Widget _trimPanel(Color textColor) {
    if (_trimController == null || !_trimController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
    }
    final total = _trimController!.value.duration.inMilliseconds / 1000.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a 5-second window',
            style: TextStyle(
              fontFamily: 'DMSans', color: textColor,
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          RangeSlider(
            values: RangeValues(_trimStart, _trimStart + _trimDuration),
            min: 0, max: total,
            activeColor: _accent,
            inactiveColor: textColor.withOpacity(0.15),
            divisions: (total * 10).toInt().clamp(1, 600),
            labels: RangeLabels(
              '${_trimStart.toStringAsFixed(1)}s',
              '${(_trimStart + _trimDuration).toStringAsFixed(1)}s'),
            onChanged: (v) {
              double s = v.start, e = v.end;
              if (e - s > _maxTrim) {
                // Clamp the moving handle so the window stays ≤ 5s
                if ((s - _trimStart).abs() > (e - (_trimStart + _trimDuration)).abs()) {
                  s = e - _maxTrim;
                } else {
                  e = s + _maxTrim;
                }
              }
              setState(() {
                _trimStart = s.clamp(0, total);
                _trimDuration = (e - s).clamp(0.1, _maxTrim);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_trimStart.toStringAsFixed(1)}s',
                style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.7), fontSize: 11)),
              Text('window: ${_trimDuration.toStringAsFixed(1)}s',
                style: const TextStyle(fontFamily: 'DMSans', color: _accent,
                  fontSize: 11, fontWeight: FontWeight.w700)),
              Text('${(_trimStart + _trimDuration).toStringAsFixed(1)}s',
                style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textPanel(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: TextField(
        controller: _overlayText,
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontFamily: 'DMSans', color: textColor),
        decoration: InputDecoration(
          hintText: 'Type to overlay on the photo…',
          hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
          filled: true,
          fillColor: textColor.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _placeholder(String label, Color textColor) {
    return Center(child: Text(label,
      style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.45), fontSize: 13)));
  }
}
