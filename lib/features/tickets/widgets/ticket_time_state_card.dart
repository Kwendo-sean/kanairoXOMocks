import 'dart:async';
import 'package:flutter/material.dart';
// Use the root TicketEvent model — that's what ticket_reveal_screen.dart
// + the rest of the app pass around. The features/tickets/models/ copy
// is the same shape but a separate Dart type and would force callers
// to convert.
import 'package:kanairoxo/models/ticket_model.dart';
import 'package:kanairoxo/screens/events/event_memories_screen.dart';

/// Mirrors the public ticket page's three time states inside the app.
///
///   upcoming → live countdown (days/hours/min, hours/min/sec under 1h)
///   live     → "Happening now" pulse banner
///   past     → "View moments from this event" button (deep-links into
///              the EventMemoriesScreen with the event id pre-filled)
class TicketTimeStateCard extends StatefulWidget {
  final TicketEvent event;
  const TicketTimeStateCard({super.key, required this.event});

  @override
  State<TicketTimeStateCard> createState() => _TicketTimeStateCardState();
}

class _TicketTimeStateCardState extends State<TicketTimeStateCard> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  String _state = 'unknown';

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    final st = widget.event.state;
    final start = widget.event.startDateTime;
    Duration newRemaining = Duration.zero;
    if (st == 'upcoming' && start != null) {
      newRemaining = start.difference(DateTime.now());
      if (newRemaining.isNegative) newRemaining = Duration.zero;
    }
    if (!mounted) return;
    if (st != _state || newRemaining != _remaining) {
      setState(() {
        _state = st;
        _remaining = newRemaining;
      });
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildUpcoming() {
    final d = _remaining;
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final big = days > 0
        ? '${days}d  ${_two(hours)}h  ${_two(minutes)}m'
        : '${_two(hours)} : ${_two(minutes)} : ${_two(seconds)}';
    final sub = days > 0 ? 'days · hours · minutes' : 'hours : minutes : seconds';
    return _stateBox(
      labelColor: const Color(0xFFC0394B),
      label: 'STARTS IN',
      bg: const Color(0xFFC0394B).withOpacity(0.10),
      border: const Color(0xFFC0394B).withOpacity(0.30),
      child: Column(children: [
        Text(big, style: const TextStyle(
          color: Colors.white,
          fontSize: 24, letterSpacing: 1.5,
          fontFamily: 'Georgia', fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        )),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w500,
        )),
      ]),
    );
  }

  Widget _buildLive() {
    return _stateBox(
      labelColor: const Color(0xFF2ECC71),
      label: 'HAPPENING NOW',
      bg: const Color(0xFF2ECC71).withOpacity(0.10),
      border: const Color(0xFF2ECC71).withOpacity(0.30),
      labelLeading: const _PulseDot(),
      child: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'See you at the door — your QR is below.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildPast() {
    return _stateBox(
      labelColor: Colors.white60,
      label: 'IT\'S OVER',
      bg: Colors.white.withOpacity(0.04),
      border: Colors.white.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('View moments from this event'),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EventMemoriesScreen(
                eventId: widget.event.id,
                eventTitle: widget.event.title,
              ),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC0394B),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _stateBox({
    required Color labelColor,
    required String label,
    required Color bg,
    required Color border,
    required Widget child,
    Widget? labelLeading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (labelLeading != null) ...[labelLeading, const SizedBox(width: 8)],
          Text(label, style: TextStyle(
            color: labelColor, fontSize: 11, letterSpacing: 3,
            fontWeight: FontWeight.w700,
          )),
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case 'upcoming': return _buildUpcoming();
      case 'live': return _buildLive();
      case 'past': return _buildPast();
      default: return const SizedBox.shrink();
    }
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle),
      ),
    );
  }
}
