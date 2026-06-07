import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/widgets/skeletons.dart';

class EventMemoriesScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventMemoriesScreen({
    super.key, required this.eventId, required this.eventTitle});

  @override
  State<EventMemoriesScreen> createState() => _EventMemoriesScreenState();
}

class _EventMemoriesScreenState extends State<EventMemoriesScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _memories = [];
  bool _loading = true;
  static const _accent = Color(0xFF9B111E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('api/v1/events/${widget.eventId}/memories/');
      final List items = (res is Map ? (res['memories'] ?? []) : []) as List;
      if (mounted) setState(() {
        _memories = items.map((m) => Map<String, dynamic>.from(m)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text(widget.eventTitle,
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _accent, onRefresh: _load,
        child: _loading
          ? Skeleton.grid(context, count: 9)
          : _memories.isEmpty
            ? Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_library_outlined, size: 56, color: _accent),
                  const SizedBox(height: 12),
                  Text('No memories yet',
                    style: TextStyle(fontFamily: 'DMSans', fontSize: 16,
                      fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  Text('Once people post moments tagged to this event, they show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                      color: textColor.withOpacity(0.55), height: 1.4)),
                ])))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.78),
                itemCount: _memories.length,
                itemBuilder: (_, i) {
                  final m = _memories[i];
                  final url = (m['media_url'] ?? '').toString();
                  final type = (m['media_type'] ?? 'image').toString();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(fit: StackFit.expand, children: [
                      if (url.isNotEmpty)
                        NetworkMediaPreview(url: url, mediaType: type,
                          fit: BoxFit.cover, thumbnailMode: true)
                      else
                        Container(color: textColor.withOpacity(0.08)),
                      if (type == 'video')
                        const Positioned(top: 6, right: 6,
                          child: Icon(Icons.videocam, color: Colors.white, size: 16)),
                      Positioned(left: 0, right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                          child: Text(m['creator_name']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 10,
                              fontFamily: 'DMSans'),
                            maxLines: 1, overflow: TextOverflow.ellipsis))),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
