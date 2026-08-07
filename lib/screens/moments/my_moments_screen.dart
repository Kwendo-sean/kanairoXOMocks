import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/widgets/skeletons.dart';

class MyMomentsScreen extends StatefulWidget {
  const MyMomentsScreen({super.key});

  @override
  State<MyMomentsScreen> createState() => _MyMomentsScreenState();
}

class _MyMomentsScreenState extends State<MyMomentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final ApiClient _api = ApiClient();
  List<Moment> _posted = [];
  List<Moment> _archived = [];
  bool _loading = true;

  static const Color _accent = Color(0xFF9B111E);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _api.get('api/v1/moments/mine/', queryParameters: {'archived': 'false'});
      final a = await _api.get('api/v1/moments/mine/', queryParameters: {'archived': 'true'});
      final List pList = (p is Map ? (p['results'] ?? []) : (p ?? [])) as List;
      final List aList = (a is Map ? (a['results'] ?? []) : (a ?? [])) as List;
      if (mounted) {
        setState(() {
          _posted   = pList.map((m) => Moment.fromJson(Map<String, dynamic>.from(m))).toList();
          _archived = aList.map((m) => Moment.fromJson(Map<String, dynamic>.from(m))).toList();
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleArchive(Moment m, bool archive) async {
    try {
      await _api.post('api/v1/moments/${m.id}/archive/', {'archived': archive});
      await _load();
    } catch (_) {}
  }

  Future<void> _delete(Moment m) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete this moment?',
        style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
      content: const Text("This can't be undone.",
        style: TextStyle(fontFamily: 'DMSans')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'DMSans'))),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete',
            style: TextStyle(color: _accent, fontFamily: 'DMSans'))),
      ],
    ));
    if (ok != true) return;
    try {
      await MomentService().deleteMoment(m.id);
      await _load();
    } catch (_) {}
  }

  void _menu(Moment m, {required bool isArchived}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1C1614) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                  color: textColor),
                title: Text(isArchived ? 'Unarchive' : 'Archive',
                  style: TextStyle(fontFamily: 'DMSans', color: textColor)),
                onTap: () { Navigator.pop(context); _toggleArchive(m, !isArchived); }),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _accent),
                title: const Text('Delete',
                  style: TextStyle(color: _accent, fontFamily: 'DMSans')),
                onTap: () { Navigator.pop(context); _delete(m); }),
              const SizedBox(height: 8),
            ]),
          ),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF1A1A1A).withOpacity(0.45);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textColor),
          title: Text('Your Moments',
            style: TextStyle(fontFamily: 'DMSans', color: textColor,
              fontSize: 17, fontWeight: FontWeight.w700)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: TabBar(
              controller: _tab,
              labelColor: _accent,
              unselectedLabelColor: mutedColor,
              indicatorColor: _accent,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                fontSize: 12, letterSpacing: 0.8),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w500, fontSize: 12),
              tabs: [
                Tab(text: 'POSTED · ${_posted.length}'),
                Tab(text: 'ARCHIVED · ${_archived.length}'),
              ]),
          ),
        ),
        body: _loading
          ? Skeleton.grid(context, count: 6)
          : TabBarView(controller: _tab, children: [
              _buildList(_posted, false, isDark, textColor, mutedColor),
              _buildList(_archived, true, isDark, textColor, mutedColor),
            ]),
      ),
    );
  }

  Widget _buildList(List<Moment> items, bool isArchived,
      bool isDark, Color textColor, Color mutedColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.photo_library_outlined,
              size: 32, color: _accent)),
          const SizedBox(height: 16),
          Text(
            isArchived ? 'No archived moments' : 'Nothing posted yet',
            style: TextStyle(fontFamily: 'DMSans', color: textColor,
              fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            isArchived
              ? 'Moments you archive appear here'
              : 'Moments you post will appear here',
            style: TextStyle(fontFamily: 'DMSans', color: mutedColor, fontSize: 13)),
        ]),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _polaroidCard(items[i], isArchived, isDark, textColor, mutedColor),
      ),
    );
  }

  Widget _polaroidCard(Moment m, bool isArchived, bool isDark,
      Color textColor, Color mutedColor) {
    final polaroidBg = isDark ? const Color(0xFF1C1614) : Colors.white;
    final shadowColor = isDark
      ? Colors.black.withOpacity(0.4)
      : Colors.black.withOpacity(0.10);
    final tilt = m.id.hashCode % 3 == 0 ? -0.015 : m.id.hashCode % 3 == 1 ? 0.013 : 0.0;
    final date = DateFormat('MMM d').format(m.date);

    return GestureDetector(
      onTap: () => _menu(m, isArchived: isArchived),
      onLongPress: () => _menu(m, isArchived: isArchived),
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          decoration: BoxDecoration(
            color: polaroidBg,
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media area — 4:3 ish crop
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  NetworkMediaPreview(
                    url: m.photoUrl, mediaType: m.mediaType,
                    fit: BoxFit.cover, thumbnailMode: true),
                  if (m.mediaType == 'video')
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 14))),
                  if (isArchived)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.archive_outlined,
                            color: Colors.white54, size: 28)))),
                ]),
              ),
              // Caption strip
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.caption.isNotEmpty)
                      Text(m.caption,
                        style: TextStyle(
                          fontFamily: 'DMSans', fontSize: 11,
                          color: textColor, fontStyle: FontStyle.italic,
                          height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis)
                    else
                      Text('No caption',
                        style: TextStyle(fontFamily: 'DMSans',
                          fontSize: 11, color: mutedColor,
                          fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(date,
                            style: TextStyle(fontFamily: 'DMSans',
                              fontSize: 10, color: mutedColor)),
                        Row(children: [
                          Icon(Icons.favorite_border_rounded,
                            size: 11, color: mutedColor),
                          const SizedBox(width: 3),
                          Text('${m.likesCount}',
                            style: TextStyle(fontFamily: 'DMSans',
                              fontSize: 10, color: mutedColor)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
