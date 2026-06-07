import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/communities_service.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/screens/communities/create_community_screen.dart';
import 'package:kanairoxo/screens/communities/community_detail_screen.dart';
import 'package:kanairoxo/screens/communities/join_by_code_screen.dart';
import 'package:kanairoxo/widgets/skeletons.dart';

/// "My People" — tabs for Connections (dating) and Communities (group hangouts).
class MyConnectionsScreen extends StatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final ApiClient _api = ApiClient();
  final CommunitiesService _communities = CommunitiesService();

  List<Map<String, dynamic>> _connections = [];
  List<Map<String, dynamic>> _communitiesList = [];
  bool _loading = true;
  String _query = '';

  static const accent = Color(0xFF9B111E);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final connRes = await _api.get('api/v1/connections/');
      final List connData = connRes is List ? connRes : (connRes['results'] ?? []) as List;
      final cs = await _communities.mine();
      if (mounted) setState(() {
        _connections = connData
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _communitiesList = cs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _otherOf(Map<String, dynamic> c) {
    final raw = c['other_user'] ?? c['user'] ?? <String, dynamic>{};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  bool _match(String name) =>
      _query.isEmpty || name.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text('My People',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
        bottom: TabBar(
          controller: _tab,
          labelColor: accent,
          unselectedLabelColor: textColor.withOpacity(0.5),
          indicatorColor: accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontFamily: 'DMSans',
            fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
          tabs: [
            Tab(text: 'CONNECTIONS · ${_connections.length}'),
            Tab(text: 'COMMUNITIES · ${_communitiesList.length}'),
          ]),
      ),
      body: _loading
        ? Skeleton.list(context, count: 8)
        : Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5), size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1C1612) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: textColor.withOpacity(0.08))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: textColor.withOpacity(0.08))),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _connectionsList(textColor, isDark),
                  _communitiesView(textColor, isDark),
                ],
              )),
          ]),
    );
  }

  Widget _connectionsList(Color textColor, bool isDark) {
    final items = _connections.where((c) {
      final o = _otherOf(c);
      final name = (o['display_name'] ?? o['name'] ?? o['full_name'] ?? '').toString();
      return _match(name);
    }).toList();
    if (items.isEmpty) return _empty('No connections yet', 'People you connect with on Discover land here.', textColor);
    return RefreshIndicator(color: accent, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _userRow(_otherOf(items[i]), textColor, isDark),
      ));
  }

  Widget _communitiesView(Color textColor, bool isDark) {
    final items = _communitiesList.where((c) =>
      _match((c['name'] ?? '').toString())).toList();

    return RefreshIndicator(color: accent, onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Action buttons at the top
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () async {
                  final created = await Navigator.push<bool>(context, MaterialPageRoute(
                    builder: (_) => const CreateCommunityScreen()));
                  if (created == true) _load();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: accent,
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(children: const [
                    Icon(Icons.group_add, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('Create community',
                      style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 13))),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final joined = await Navigator.push<bool>(context, MaterialPageRoute(
                    builder: (_) => const JoinByCodeScreen()));
                  if (joined == true) _load();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent, width: 1.5)),
                  child: const Icon(Icons.qr_code_2, color: accent))),
            ]),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _empty('No communities yet', 'Create one or join with an invite code.', textColor),
            )
          else
            ...items.map((c) => _communityRow(c, textColor, isDark)),
        ],
      ));
  }

  Widget _communityRow(Map<String, dynamic> c, Color textColor, bool isDark) {
    final id = (c['id'] ?? '').toString();
    final name = (c['name'] ?? 'Community').toString();
    final memberCount = c['member_count'] ?? 0;
    final maxMembers = c['max_members'] ?? 20;
    final cover = (c['cover_url'] ?? '').toString();
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(communityId: id)));
            _load();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 52, height: 52,
                  child: cover.isNotEmpty
                    ? Image.network(cover, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: textColor.withOpacity(0.08),
                          child: Icon(Icons.group, color: textColor.withOpacity(0.4))))
                    : Container(color: textColor.withOpacity(0.08),
                        child: Icon(Icons.group, color: textColor.withOpacity(0.4)))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: TextStyle(fontFamily: 'DMSans', color: textColor,
                      fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$memberCount of $maxMembers members',
                    style: TextStyle(fontFamily: 'DMSans',
                      color: textColor.withOpacity(0.55), fontSize: 12)),
                ])),
              Icon(Icons.chevron_right, color: textColor.withOpacity(0.35)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _userRow(Map<String, dynamic> o, Color textColor, bool isDark) {
    final id = (o['id'] ?? o['public_id'])?.toString();
    final name = (o['display_name'] ?? o['name'] ?? o['full_name'] ?? 'User').toString();
    final headline = (o['headline'] ?? o['neighborhood'] ?? '').toString();
    final photo = ApiConstants.fixMediaUrl(o['photo_url'] ?? o['profile_photo'] ?? o['avatar']);
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (id != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfilePreviewScreen(userId: id)));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              ClipOval(
                child: SizedBox(width: 52, height: 52,
                  child: photo.isNotEmpty
                    ? Image.network(photo, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: textColor.withOpacity(0.08),
                          child: Icon(Icons.person, color: textColor.withOpacity(0.4))))
                    : Container(color: textColor.withOpacity(0.08),
                        child: Icon(Icons.person, color: textColor.withOpacity(0.4)))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: TextStyle(fontFamily: 'DMSans', color: textColor,
                      fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (headline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(headline,
                      style: TextStyle(fontFamily: 'DMSans',
                        color: textColor.withOpacity(0.55), fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ])),
              Icon(Icons.chevron_right, color: textColor.withOpacity(0.35)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _empty(String title, String body, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.group_outlined, size: 56, color: accent),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontFamily: 'DMSans',
          fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
            color: textColor.withOpacity(0.55), height: 1.4)),
      ]),
    );
  }
}
