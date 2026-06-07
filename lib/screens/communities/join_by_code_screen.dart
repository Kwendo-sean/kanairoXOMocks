import 'package:flutter/material.dart';
import 'package:kanairoxo/services/communities_service.dart';

/// User can paste an invite code or full URL and join the community.
class JoinByCodeScreen extends StatefulWidget {
  final String? initialCode;
  const JoinByCodeScreen({super.key, this.initialCode});

  @override
  State<JoinByCodeScreen> createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends State<JoinByCodeScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _preview;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _ctrl.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkCode());
    }
  }
  static const accent = Color(0xFF9B111E);

  String _extractCode(String raw) {
    final s = raw.trim();
    // Accept either "abc123" or "https://.../c/abc123"
    final match = RegExp(r'/c/([a-z0-9]{4,16})').firstMatch(s);
    if (match != null) return match.group(1)!;
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _checkCode() async {
    final code = _extractCode(_ctrl.text);
    if (code.length < 4) {
      setState(() => _error = 'Enter a valid code.');
      return;
    }
    setState(() { _loading = true; _error = null; _preview = null; });
    try {
      final res = await CommunitiesService().previewInvite(code);
      if (mounted) setState(() { _preview = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'No community found for that code.';
      });
    }
  }

  Future<void> _join() async {
    if (_preview == null) return;
    final code = _extractCode(_ctrl.text);
    setState(() => _loading = true);
    try {
      await CommunitiesService().joinByCode(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not join: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);
    final surface = isDark ? const Color(0xFF1C1612) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, centerTitle: true,
        title: Text('Join Community',
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Paste an invite link or code',
            style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.7),
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. ab12cd34 or kanairoxo.online/c/ab12cd34',
              hintStyle: TextStyle(fontFamily: 'DMSans',
                color: textColor.withOpacity(0.35), fontSize: 14),
              filled: true,
              fillColor: surface,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: textColor.withOpacity(0.08))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: textColor.withOpacity(0.08))),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: accent, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          if (_preview == null)
            SizedBox(height: 50, child: ElevatedButton(
              onPressed: _ctrl.text.trim().isEmpty || _loading ? null : _checkCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Check code',
                    style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                      fontWeight: FontWeight.w700))))
          else
            _previewCard(textColor, surface),
        ],
      ),
    );
  }

  Widget _previewCard(Color textColor, Color surface) {
    final c = Map<String, dynamic>.from(_preview!['community'] ?? {});
    final name = (c['name'] ?? 'Community').toString();
    final members = c['member_count'] ?? 0;
    final maxM = c['max_members'] ?? 20;
    final cover = (c['cover_url'] ?? '').toString();
    final desc = (c['description'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (cover.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: AspectRatio(aspectRatio: 2.4,
              child: Image.network(cover, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: textColor.withOpacity(0.08))))),
        const SizedBox(height: 12),
        Text(name,
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('$members of $maxM members',
          style: TextStyle(fontFamily: 'DMSans',
            color: textColor.withOpacity(0.55), fontSize: 12)),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(fontFamily: 'DMSans',
            color: textColor.withOpacity(0.7), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: _loading ? null : _join,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
          child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Join community',
                style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                  fontWeight: FontWeight.w700)))),
      ]),
    );
  }
}
