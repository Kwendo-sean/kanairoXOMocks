import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/events_api_service.dart';
import 'package:kanairoxo/services/tickets_service.dart';

/// Combined screen for the two flavours of "bring friends":
///
///   Mode.invite     — send referral invites by email.
///   Mode.groupBuy   — buy N tickets in one M-Pesa STK push.
class InviteFriendsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final InviteMode initialMode;
  final String? pricingTierId;
  final num? unitPrice;
  const InviteFriendsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.initialMode = InviteMode.invite,
    this.pricingTierId,
    this.unitPrice,
  });

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

enum InviteMode { invite, groupBuy }

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  late InviteMode _mode;
  final List<_Recipient> _recipients = [_Recipient()];
  final _msgCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  final _events = EventsApiService();
  final _tickets = TicketsService();

  static const _accent = Color(0xFF9B111E);

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _phoneCtrl.dispose();
    for (final r in _recipients) { r.email.dispose(); r.name.dispose(); }
    super.dispose();
  }

  num get _total => (widget.unitPrice ?? 0) * _recipients.length;

  void _addRow() => setState(() => _recipients.add(_Recipient()));
  void _removeRow(int i) {
    if (_recipients.length == 1) return;
    setState(() {
      _recipients[i].email.dispose();
      _recipients[i].name.dispose();
      _recipients.removeAt(i);
    });
  }

  Future<void> _submit() async {
    final cleaned = _recipients
        .map((r) => {'email': r.email.text.trim(), 'name': r.name.text.trim()})
        .where((m) => (m['email'] ?? '').isNotEmpty)
        .toList();

    if (cleaned.isEmpty) { _toast('Add at least one email'); return; }
    if (_mode == InviteMode.groupBuy && cleaned.length < 2) {
      _toast('Group purchase needs 2 or more recipients.'); return;
    }
    if (_mode == InviteMode.groupBuy && _phoneCtrl.text.trim().isEmpty) {
      _toast('Enter the M-Pesa phone number paying for the group'); return;
    }

    setState(() => _busy = true);
    try {
      if (_mode == InviteMode.invite) {
        final r = await _events.inviteFriends(
          eventId: widget.eventId,
          recipients: cleaned.map((m) => {'email': m['email']!, 'name': m['name']!}).toList(),
          message: _msgCtrl.text.trim(),
        );
        final sent = r['sent'] ?? cleaned.length;
        final shareUrl = r['invite_url']?.toString() ?? '';
        _toast('Invited $sent ${sent == 1 ? 'friend' : 'friends'}');
        if (mounted) Navigator.of(context).pop();
        if (shareUrl.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 250), () {
            Share.share('${widget.eventTitle} — $shareUrl');
          });
        }
      } else {
        final r = await _tickets.groupPurchase(
          eventId: widget.eventId,
          phoneNumber: _phoneCtrl.text.trim(),
          recipients: cleaned.map((m) => {'email': m['email']!, 'name': m['name']!}).toList(),
          pricingTierId: widget.pricingTierId,
          message: _msgCtrl.text.trim(),
        );
        _toast(r['message']?.toString() ?? 'Check your phone for the M-Pesa prompt');
        if (mounted) Navigator.of(context).pop(r);
      }
    } catch (e) {
      _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final surface = isDark ? const Color(0xFF1C1614) : Colors.white;
    final text    = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted   = isDark ? Colors.white60 : const Color(0xFF1A1A1A).withOpacity(0.50);
    final border  = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final isGroup = _mode == InviteMode.groupBuy;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Bring friends',
          style: TextStyle(fontFamily: 'DMSans', color: text,
            fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: text),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.eventTitle,
              style: TextStyle(color: text, fontSize: 16,
                fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Mode picker
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(children: [
                _modeChip(InviteMode.invite, 'Invite friends', Icons.send_outlined, text, isDark),
                _modeChip(InviteMode.groupBuy, 'Buy for group', Icons.payments_outlined, text, isDark),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              isGroup
                ? 'Pay for everyone in one M-Pesa prompt. Each person gets their own ticket.'
                : 'Send your friends the event link. They grab their own ticket.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5, fontFamily: 'DMSans'),
            ),

            const SizedBox(height: 22),
            Text('Recipients',
              style: TextStyle(color: muted, fontSize: 11,
                letterSpacing: 1.8, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
            const SizedBox(height: 10),
            for (var i = 0; i < _recipients.length; i++) _row(i, text, border, isDark),
            TextButton.icon(
              icon: const Icon(Icons.add, color: _accent),
              label: const Text('Add another',
                style: TextStyle(color: _accent, fontFamily: 'DMSans')),
              onPressed: _addRow,
            ),

            const SizedBox(height: 18),
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: text, fontFamily: 'DMSans'),
              decoration: _decoration('Message (optional)', text, border, isDark),
            ),

            if (isGroup) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: text, fontFamily: 'DMSans'),
                decoration: _decoration('Your M-Pesa phone (e.g. +254712345678)', text, border, isDark),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.payments_outlined, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Total: KSh ${_total.toStringAsFixed(0)} '
                    '(${_recipients.length} × KSh ${widget.unitPrice?.toStringAsFixed(0) ?? '—'})',
                    style: TextStyle(color: text, fontWeight: FontWeight.w600, fontFamily: 'DMSans'),
                  )),
                ]),
              ),
            ],

            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _busy
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isGroup ? 'Pay KSh ${_total.toStringAsFixed(0)}' : 'Send invites',
                    style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(InviteMode m, String label, IconData icon, Color text, bool isDark) {
    final selected = _mode == m;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _mode = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : text.withOpacity(0.55), size: 18),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(
              color: selected ? Colors.white : text.withOpacity(0.55),
              fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'DMSans')),
        ]),
      ),
    ));
  }

  Widget _row(int i, Color text, Color border, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(flex: 5, child: TextField(
          controller: _recipients[i].email,
          decoration: _decoration('Email', text, border, isDark),
          style: TextStyle(color: text, fontFamily: 'DMSans'),
          keyboardType: TextInputType.emailAddress,
        )),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: TextField(
          controller: _recipients[i].name,
          decoration: _decoration('Name', text, border, isDark),
          style: TextStyle(color: text, fontFamily: 'DMSans'),
        )),
        IconButton(
          icon: Icon(Icons.remove_circle_outline,
            color: _recipients.length == 1 ? text.withOpacity(0.2) : text.withOpacity(0.55)),
          onPressed: _recipients.length == 1 ? null : () => _removeRow(i),
        ),
      ]),
    );
  }

  InputDecoration _decoration(String hint, Color text, Color border, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: text.withOpacity(0.35), fontSize: 13, fontFamily: 'DMSans'),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true,
    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _accent),
    ),
  );
}

class _Recipient {
  final TextEditingController email = TextEditingController();
  final TextEditingController name = TextEditingController();
}
