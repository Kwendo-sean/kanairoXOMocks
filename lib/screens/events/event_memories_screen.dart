import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/widgets/skeletons.dart';

class EventMemoriesScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventMemoriesScreen({
    super.key, required this.eventId, this.eventTitle = 'Moments'});

  @override
  State<EventMemoriesScreen> createState() => _EventMemoriesScreenState();
}

class _EventMemoriesScreenState extends State<EventMemoriesScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _memories = [];
  bool _loading = true;
  int _heroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('api/v1/events/${widget.eventId}/memories/');
      final List items = (res is Map ? (res['memories'] ?? []) : []) as List;
      if (mounted) {
        setState(() {
          _memories = items.map((m) => Map<String, dynamic>.from(m)).toList();
          _heroIndex = 0;
          _loading = false;
        });
        _startHeroTimer();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    if (_memories.length > 1) {
      _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) setState(() => _heroIndex = (_heroIndex + 1) % _memories.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final mutedColor = isDark ? Colors.white54 : Colors.black38;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
        ? Skeleton.grid(context, count: 9)
        : _memories.isEmpty
          ? _buildEmpty(textColor, mutedColor)
          : CustomScrollView(
              slivers: [
                // ── Hero — no AppBar, title lives inside the photo ─────────────
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => _openDetail(_heroIndex),
                    child: AspectRatio(
                      aspectRatio: 0.92,
                      child: Stack(fit: StackFit.expand, children: [

                        // Crossfading media — plays video like the trailers feed
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 900),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _heroMedia(_memories[_heroIndex], _heroIndex, isDark),
                        ),

                        // Top gradient so title text is always legible
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black87, Colors.transparent],
                              stops: [0.0, 0.45]),
                          ),
                        ),

                        // Bottom gradient for creator name + dots
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                              stops: const [0.0, 0.4]),
                          ),
                        ),

                        // Back button — top-left
                        Positioned(
                          top: top + 4,
                          left: 4,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            onPressed: () => Navigator.pop(context)),
                        ),

                        // Event title + memory count — centered at top
                        Positioned(
                          top: top + 12,
                          left: 52,
                          right: 52,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.eventTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DMSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${_memories.length} memories',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                            ],
                          ),
                        ),

                        // Creator name — bottom-left
                        if ((_memories[_heroIndex]['creator_name'] ?? '').toString().isNotEmpty)
                          Positioned(
                            left: 14, bottom: 32,
                            child: Text(
                              _memories[_heroIndex]['creator_name'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'DMSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 6)]))),

                        // Dot indicator — bottom-center
                        if (_memories.length > 1)
                          Positioned(
                            bottom: 12, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _memories.length.clamp(0, 8),
                                (d) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  width: d == _heroIndex ? 16 : 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: d == _heroIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(99)),
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),

                // ── 3-column thumbnail grid ──────────────────────────────────
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => GestureDetector(
                      onTap: () => _openDetail(i),
                      child: _gridCell(_memories[i], isDark),
                    ),
                    childCount: _memories.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                    childAspectRatio: 1.0,
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
    );
  }

  // Hero media: plays video, no thumbnail mode — same as the trailers For You feed
  Widget _heroMedia(Map<String, dynamic> m, int i, bool isDark) {
    final url  = (m['media_url'] ?? '').toString();
    final type = (m['media_type'] ?? 'image').toString();

    return url.isNotEmpty
      ? NetworkMediaPreview(
          key: ValueKey(i),
          url: url,
          mediaType: type,
          fit: BoxFit.cover,
          autoPlay: true,
          loop: true,
          muted: false)
      : Container(
          key: ValueKey(i),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100);
  }

  Widget _gridCell(Map<String, dynamic> m, bool isDark) {
    final url  = (m['media_url'] ?? '').toString();
    final type = (m['media_type'] ?? 'image').toString();

    return Stack(fit: StackFit.expand, children: [
      url.isNotEmpty
        ? NetworkMediaPreview(url: url, mediaType: type,
            fit: BoxFit.cover, thumbnailMode: true)
        : Container(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),

      if (type == 'video')
        const Positioned(
          right: 5, bottom: 5,
          child: Icon(Icons.play_circle_filled_rounded,
            color: Colors.white, size: 16,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
    ]);
  }

  Widget _buildEmpty(Color textColor, Color mutedColor) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_library_outlined, size: 52, color: mutedColor),
          const SizedBox(height: 14),
          Text('No memories yet',
            style: TextStyle(fontFamily: 'DMSans', fontSize: 17,
              fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Text('Photos and videos tagged to this event appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
              color: mutedColor, height: 1.5)),
        ]),
      ),
    );
  }

  void _openDetail(int startIndex) {
    _heroTimer?.cancel();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _MemoryDetailView(
        memories: _memories,
        initialIndex: startIndex,
        eventTitle: widget.eventTitle,
      ),
    )).then((_) => _startHeroTimer());
  }
}

// ─── Full-screen swipe viewer ───────────────────────────────────────────────

class _MemoryDetailView extends StatefulWidget {
  final List<Map<String, dynamic>> memories;
  final int initialIndex;
  final String eventTitle;
  const _MemoryDetailView({
    required this.memories,
    required this.initialIndex,
    required this.eventTitle,
  });

  @override
  State<_MemoryDetailView> createState() => _MemoryDetailViewState();
}

class _MemoryDetailViewState extends State<_MemoryDetailView> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m       = widget.memories[_current];
    final creator = (m['creator_name'] ?? '').toString();
    final caption = (m['caption'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.memories.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) {
            final item = widget.memories[i];
            final url  = (item['media_url'] ?? '').toString();
            final type = (item['media_type'] ?? 'image').toString();
            return Center(
              child: url.isNotEmpty
                ? NetworkMediaPreview(
                    url: url, mediaType: type,
                    fit: BoxFit.contain,
                    autoPlay: type == 'video',
                    loop: true)
                : const Icon(Icons.broken_image, color: Colors.white38, size: 64),
            );
          },
        ),

        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Text('${_current + 1} / ${widget.memories.length}',
                  style: const TextStyle(color: Colors.white70,
                    fontFamily: 'DMSans', fontSize: 13)),
                const SizedBox(width: 12),
              ]),
            ),
          ),
        ),

        if (creator.isNotEmpty || caption.isNotEmpty)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.75), Colors.transparent])),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (caption.isNotEmpty)
                        Text(caption,
                          style: const TextStyle(color: Colors.white,
                            fontFamily: 'DMSans', fontSize: 14,
                            fontStyle: FontStyle.italic, height: 1.4),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      if (creator.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(creator,
                          style: const TextStyle(color: Colors.white70,
                            fontFamily: 'DMSans', fontSize: 12,
                            fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
