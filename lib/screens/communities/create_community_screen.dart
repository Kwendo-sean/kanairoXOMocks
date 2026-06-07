import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/communities_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _max = TextEditingController(text: '20');
  File? _cover;
  bool _busy = false;

  static const accent = Color(0xFF9B111E);

  Future<void> _pickCover() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (img != null) setState(() => _cover = File(img.path));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your community a name.')));
      return;
    }
    final cap = int.tryParse(_max.text.trim()) ?? 20;
    setState(() => _busy = true);
    try {
      final c = await CommunitiesService().create(
        name: name,
        description: _desc.text.trim(),
        maxMembers: cap,
        cover: _cover);
      if (!mounted) return;
      // Show invite share sheet immediately
      await showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _InviteSheet(community: c));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: Text('New Community',
          style: TextStyle(fontFamily: 'DMSans', color: textColor,
            fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _pickCover,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: surface, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textColor.withOpacity(0.08)),
                image: _cover != null
                  ? DecorationImage(image: FileImage(_cover!), fit: BoxFit.cover)
                  : null),
              child: _cover == null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_photo_alternate_outlined, color: textColor.withOpacity(0.45)),
                    const SizedBox(height: 6),
                    Text('Tap to add a cover (optional)',
                      style: TextStyle(fontFamily: 'DMSans',
                        color: textColor.withOpacity(0.45), fontSize: 12)),
                  ]))
                : null,
            ),
          ),
          const SizedBox(height: 18),
          _label('Name', textColor),
          _input(_name, 'e.g. Westies Squad', textColor, surface),
          const SizedBox(height: 14),
          _label('Description', textColor),
          _input(_desc, "What's this group about?", textColor, surface, maxLines: 3),
          const SizedBox(height: 14),
          _label('Max members', textColor),
          _input(_max, '20', textColor, surface, keyboardType: TextInputType.number),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('You can choose between 2 and 200.',
              style: TextStyle(fontFamily: 'DMSans', color: textColor.withOpacity(0.5), fontSize: 11)),
          ),
          const SizedBox(height: 28),
          SizedBox(height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
              child: _busy
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create',
                    style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)))),
        ],
      ),
    );
  }

  Widget _label(String s, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 4),
    child: Text(s, style: TextStyle(
      fontFamily: 'DMSans', color: textColor.withOpacity(0.7),
      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)));

  Widget _input(TextEditingController c, String hint, Color textColor, Color surface,
                {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}


class _InviteSheet extends StatelessWidget {
  final Map<String, dynamic> community;
  const _InviteSheet({required this.community});

  @override
  Widget build(BuildContext context) {
    final url = (community['invite_url'] ?? '').toString();
    final code = (community['invite_code'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Invite people',
            style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
              fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Anyone with this link can join "${community['name']}".',
            style: const TextStyle(fontFamily: 'DMSans', color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Text(url.isNotEmpty ? url : code,
                style: const TextStyle(fontFamily: 'DMSans', color: Colors.white,
                  fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.copy, color: Color(0xFF9B111E)),
                onPressed: () {
                  Share.share(url.isNotEmpty ? url : 'Join my KanairoXO community with code: $code',
                    subject: 'Join ${community['name']} on KanairoXO');
                }),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Share.share(url.isNotEmpty ? url : 'Join with code: $code',
                subject: 'Join ${community['name']} on KanairoXO'),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Share invite',
                style: TextStyle(fontFamily: 'DMSans', color: Colors.white,
                  fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B111E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)))))
        ]),
    );
  }
}
