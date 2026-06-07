import 'package:flutter/material.dart';
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

class _MyMomentsScreenState extends State<MyMomentsScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _api.get('api/v1/moments/mine/', queryParameters: {'archived': 'false'});
      final a = await _api.get('api/v1/moments/mine/', queryParameters: {'archived': 'true'});
      final List pList = (p is Map ? (p['results'] ?? []) : (p ?? [])) as List;
      final List aList = (a is Map ? (a['results'] ?? []) : (a ?? [])) as List;
      if (mounted) {
        setState(() {
          _posted = pList.map((m) => Moment.fromJson(Map<String, dynamic>.from(m))).toList();
          _archived = aList.map((m) => Moment.fromJson(Map<String, dynamic>.from(m))).toList();
          _loading = false;
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
      title: const Text('Delete this moment?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: _accent))),
      ],
    ));
    if (ok != true) return;
    try {
      await MomentService().deleteMoment(m.id);
      await _load();
    } catch (_) {}
  }

  void _menu(Moment m, {required bool isArchived}) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Icon(isArchived ? Icons.unarchive : Icons.archive_outlined),
          title: Text(isArchived ? 'Unarchive' : 'Archive'),
          onTap: () { Navigator.pop(context); _toggleArchive(m, !isArchived); }),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: _accent),
          title: const Text('Delete', style: TextStyle(color: _accent)),
          onTap: () { Navigator.pop(context); _delete(m); }),
        const SizedBox(height: 8),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, centerTitle: true,
        title: Text('Your Moments',
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tab,
          labelColor: _accent,
          unselectedLabelColor: textColor.withOpacity(0.5),
          indicatorColor: _accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontFamily: 'DMSans',
            fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
          tabs: [
            Tab(text: 'POSTED · ${_posted.length}'),
            Tab(text: 'ARCHIVED · ${_archived.length}'),
          ]),
      ),
      body: _loading
        ? Skeleton.grid(context, count: 6)
        : TabBarView(controller: _tab, children: [
            _grid(_posted, false, textColor, isDark),
            _grid(_archived, true, textColor, isDark),
          ]),
    );
  }

  Widget _grid(List<Moment> items, bool isArchived, Color textColor, bool isDark) {
    if (items.isEmpty) {
      return Center(child: Text(isArchived ? 'No archived moments' : 'You haven\'t posted any moments yet',
        style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.5))));
    }
    return RefreshIndicator(
      color: _accent,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.78),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final m = items[i];
          return GestureDetector(
            onLongPress: () => _menu(m, isArchived: isArchived),
            onTap: () => _menu(m, isArchived: isArchived),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(fit: StackFit.expand, children: [
                NetworkMediaPreview(
                  url: m.photoUrl, mediaType: m.mediaType,
                  fit: BoxFit.cover, thumbnailMode: true),
                if (m.mediaType == 'video')
                  const Positioned(right: 6, top: 6,
                    child: Icon(Icons.videocam, color: Colors.white, size: 16)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
