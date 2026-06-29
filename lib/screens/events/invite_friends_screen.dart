import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kanairoxo/services/events_api_service.dart';
import 'package:kanairoxo/services/tickets_service.dart';

/// Combined screen for the two flavours of "bring friends":
///
///   Mode.invite     — send referral invites by email. Each recipient
///                     gets a Resend email with the event short URL.
///                     They buy their own ticket. The inviter's
///                     "Going with you" widget lights up after they do.
///
///   Mode.groupBuy   — buy N tickets in one M-Pesa STK push. Each
///                     recipient's ticket lands in their inbox via
///                     the same Resend email flow used for individual
///                     ticket confirmations.
class InviteFriendsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final InviteMode initialMode;
  final String? pricingTierId;
  final num? unitPrice;       // KSh, for the group-buy total
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

    if (cleaned.isEmpty) {
      _toast('Add at least one email');
      return;
    }
    if (_mode == InviteMode.groupBuy && cleaned.length < 2) {
      _toast('Group purchase needs 2 or more recipients. Use Invite for one friend.');
      return;
    }
    if (_mode == InviteMode.groupBuy && _phoneCtrl.text.trim().isEmpty) {
      _toast('Enter the M-Pesa phone number paying for the group');
      return;
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
          // After dismissal, offer to share the link in WhatsApp / etc.
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

  Widget _modePicker() {
    Widget chip(InviteMode m, String label, IconData icon) {
      final selected = _mode == m;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _mode = m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFC0394B) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFFC0394B) : Colors.white.withOpacity(0.10)),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ));
    }
    return Row(children: [
      chip(InviteMode.invite, 'Invite friends', Icons.send),
      const SizedBox(width: 10),
      chip(InviteMode.groupBuy, 'Buy for group', Icons.payments),
    ]);
  }

  Widget _row(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(flex: 5, child: TextField(
          controller: _recipients[i].email,
          decoration: _decoration('Email'),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
        )),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: TextField(
          controller: _recipients[i].name,
          decoration: _decoration('Name'),
          style: const TextStyle(color: Colors.white),
        )),
        IconButton(
          icon: Icon(Icons.remove_circle_outline,
              color: _recipients.length == 1 ? Colors.white24 : Colors.white70),
          onPressed: _recipients.length == 1 ? null : () => _removeRow(i),
        ),
      ]),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFC0394B)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isGroup = _mode == InviteMode.groupBuy;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bring friends', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.eventTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Georgia')),
          const SizedBox(height: 14),
          _modePicker(),
          const SizedBox(height: 8),
          Text(
            isGroup
              ? 'Pay for everyone in one M-Pesa prompt. Each person gets their own ticket emailed to them.'
              : 'Send your friends the event. They grab their own ticket — you\'ll see them in "Going with you" once they do.',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 22),
          Text('Recipients',
            style: TextStyle(color: Colors.white.withOpacity(0.5),
              fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (var i = 0; i < _recipients.length; i++) _row(i),
          TextButton.icon(
            icon: const Icon(Icons.add, color: Color(0xFFC0394B)),
            label: const Text('Add another',
                style: TextStyle(color: Color(0xFFC0394B))),
            onPressed: _addRow,
          ),

          const SizedBox(height: 18),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Message (optional) — "come thru!"'),
          ),

          if (isGroup) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Your M-Pesa phone (e.g. +254712345678)'),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFC0394B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC0394B).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.payments, color: Color(0xFFC0394B)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Total: KSh ${_total.toStringAsFixed(0)} '
                  '(${_recipients.length} × KSh ${widget.unitPrice?.toStringAsFixed(0) ?? '—'})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0394B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: _busy
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isGroup ? 'Pay KSh ${_total.toStringAsFixed(0)}' : 'Send invites'),
          ),
        ],
      )),
    );
  }
}

class _Recipient {
  final TextEditingController email = TextEditingController();
  final TextEditingController name = TextEditingController();
}
