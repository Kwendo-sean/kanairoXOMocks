import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/communities_service.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> with SingleTickerProviderStateMixin {
  final _svc = CommunitiesService();
  late TabController _tab;
  Map<String, dynamic>? _community;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _messages = [];
  final _msgCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
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
      final c = await _svc.detail(widget.communityId);
      final m = await _svc.members(widget.communityId);
      final msgs = await _svc.messages(widget.communityId);
      if (mounted) setState(() {
        _community = c;
        _members = m;
        _messages = msgs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final m = await _svc.send(widget.communityId, text);
      if (mounted) setState(() {
        _messages.add(m);
        _msgCtrl.clear();
        _sending = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _shareInvite() {
    final url = (_community?['invite_url'] ?? '').toString();
    final code = (_community?['invite_code'] ?? '').toString();
    Share.share(url.isNotEmpty ? url : 'Join with code: $code',
      subject: 'Join ${_community?['name']} on KanairoXO');
  }

  Future<void> _leaveOrDelete() async {
    final isOwner = _community?['is_owner'] == true;
    final label = isOwner ? 'Delete community' : 'Leave community';
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(label),
      content: Text(isOwner
        ? "This can't be undone."
        : 'You can rejoin if someone shares the invite again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: Text(label, style: const TextStyle(color: accent))),
      ],
    ));
    if (ok != true) return;
    try {
      if (isOwner) {
        await _svc.deleteCommunity(widget.communityId);
      } else {
        await _svc.leave(widget.communityId);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;
    final name = (_community?['name'] ?? '').toString();
    final cover = (_community?['cover_url'] ?? '').toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, centerTitle: true,
        title: Text(name.isEmpty ? 'Community' : name,
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: accent),
            onPressed: _shareInvite),
          IconButton(icon: Icon(Icons.more_vert, color: textColor),
            onPressed: _leaveOrDelete),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: accent,
          unselectedLabelColor: textColor.withOpacity(0.5),
          indicatorColor: accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontFamily: 'DMSans',
            fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
          tabs: [
            Tab(text: 'CHAT · ${_messages.length}'),
            Tab(text: 'MEMBERS · ${_members.length}'),
          ]),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: accent))
        : Column(children: [
            if (cover.isNotEmpty)
              SizedBox(height: 140, width: double.infinity,
                child: Image.network(cover, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: textColor.withOpacity(0.08)))),
            Expanded(child: TabBarView(controller: _tab, children: [
              _chatTab(textColor, isDark, surface),
              _membersTab(textColor, isDark, surface),
            ])),
          ]),
    );
  }

  Widget _chatTab(Color textColor, bool isDark, Color surface) {
    return Column(children: [
      Expanded(
        child: _messages.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No messages yet. Say hi 👋',
                style: TextStyle(fontFamily: 'DMSans',
                  color: textColor.withOpacity(0.5), fontSize: 13))))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final sender = Map<String, dynamic>.from(m['sender'] ?? {});
                final name = (sender['name'] ?? '').toString();
                final photo = (sender['photo_url'] ?? '').toString();
                final body = (m['body'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipOval(child: SizedBox(width: 36, height: 36,
                      child: photo.isNotEmpty
                        ? Image.network(photo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: textColor.withOpacity(0.08),
                              child: Icon(Icons.person, color: textColor.withOpacity(0.4), size: 20)))
                        : Container(color: textColor.withOpacity(0.08),
                            child: Icon(Icons.person, color: textColor.withOpacity(0.4), size: 20)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(fontFamily: 'DMSans',
                        color: textColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: surface,
                          borderRadius: BorderRadius.circular(14)),
                        child: Text(body, style: TextStyle(fontFamily: 'DMSans',
                          color: textColor, fontSize: 14, height: 1.4))),
                    ])),
                  ]),
                );
              })),
      Container(
        color: surface,
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _msgCtrl,
            style: TextStyle(fontFamily: 'DMSans', color: textColor),
            decoration: InputDecoration(
              hintText: 'Message…',
              hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
              filled: true,
              fillColor: textColor.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
            ))),
          const SizedBox(width: 8),
          IconButton(
            icon: _sending
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent))
              : const Icon(Icons.send, color: accent),
            onPressed: _sending ? null : _send),
        ]),
      ),
    ]);
  }

  Widget _membersTab(Color textColor, bool isDark, Color surface) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final m = _members[i];
        final user = Map<String, dynamic>.from(m['user'] ?? {});
        final id = (user['id'] ?? '').toString();
        final name = (user['name'] ?? 'User').toString();
        final photo = (user['photo_url'] ?? '').toString();
        final role = (m['role'] ?? 'member').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(color: surface, borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                if (id.isNotEmpty) Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfilePreviewScreen(userId: id)));
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                ClipOval(child: SizedBox(width: 48, height: 48,
                  child: photo.isNotEmpty
                    ? Image.network(photo, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: textColor.withOpacity(0.08),
                          child: Icon(Icons.person, color: textColor.withOpacity(0.4))))
                    : Container(color: textColor.withOpacity(0.08),
                        child: Icon(Icons.person, color: textColor.withOpacity(0.4))))),
                const SizedBox(width: 14),
                Expanded(child: Text(name,
                  style: TextStyle(fontFamily: 'DMSans', color: textColor,
                    fontSize: 15, fontWeight: FontWeight.w600))),
                if (role != 'member')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999)),
                    child: Text(role.toUpperCase(),
                      style: const TextStyle(fontFamily: 'DMSans', color: accent,
                        fontSize: 10, fontWeight: FontWeight.w700))),
              ])))),
        );
      },
    );
  }
}
