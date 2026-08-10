import 'package:flutter/material.dart';
import '../../../models/event_filters.dart';

const _kAccent = Color(0xFF9B111E);

/// The heavier narrowings that don't earn a spot in the always-visible bar:
/// neighbourhood, price ceiling, and the connections-only toggle.
class EventFilterSheet extends StatefulWidget {
  final EventFilters initial;
  final List<String> neighborhoods;
  final double maxPriceInFeed;

  const EventFilterSheet({
    super.key,
    required this.initial,
    required this.neighborhoods,
    required this.maxPriceInFeed,
  });

  static Future<EventFilters?> show(
    BuildContext context, {
    required EventFilters initial,
    required List<String> neighborhoods,
    required double maxPriceInFeed,
  }) {
    return showModalBottomSheet<EventFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFilterSheet(
        initial: initial,
        neighborhoods: neighborhoods,
        maxPriceInFeed: maxPriceInFeed,
      ),
    );
  }

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late Set<String> _hoods = {...widget.initial.neighborhoods};
  late bool _connectionsOnly = widget.initial.connectionsOnly;
  late double _price =
      widget.initial.maxPrice ?? _ceiling;

  double get _ceiling => widget.maxPriceInFeed <= 0 ? 5000 : widget.maxPriceInFeed;
  bool get _priceIsSet => _price < _ceiling;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161210) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final divider = textColor.withOpacity(0.08);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: textColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Filters',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _hoods = {};
                  _connectionsOnly = false;
                  _price = _ceiling;
                }),
                child: Text('Reset',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: textColor.withOpacity(0.6),
                        fontSize: 13)),
              ),
            ]),
          ),
          Divider(color: divider, height: 20),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              shrinkWrap: true,
              children: [
                // ── Connections ────────────────────────────────────────────
                _label('WHO’S GOING', textColor),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      setState(() => _connectionsOnly = !_connectionsOnly),
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    Expanded(
                      child: Text('Only events my connections are going to',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              color: textColor)),
                    ),
                    Switch(
                      value: _connectionsOnly,
                      activeColor: _kAccent,
                      onChanged: (v) => setState(() => _connectionsOnly = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),

                // ── Price ──────────────────────────────────────────────────
                Row(children: [
                  _label('MAX PRICE', textColor),
                  const Spacer(),
                  Text(
                      _priceIsSet
                          ? 'KES ${_price.round()}'
                          : 'Any price',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _priceIsSet ? _kAccent : textColor.withOpacity(0.5))),
                ]),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _kAccent,
                    thumbColor: _kAccent,
                    inactiveTrackColor: textColor.withOpacity(0.12),
                    overlayColor: _kAccent.withOpacity(0.12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _price.clamp(0, _ceiling),
                    min: 0,
                    max: _ceiling,
                    divisions: 20,
                    onChanged: (v) => setState(() => _price = v),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Neighbourhood ──────────────────────────────────────────
                if (widget.neighborhoods.isNotEmpty) ...[
                  _label('NEIGHBOURHOOD', textColor),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.neighborhoods.map((n) {
                      final on = _hoods.contains(n);
                      return GestureDetector(
                        onTap: () => setState(() {
                          on ? _hoods.remove(n) : _hoods.add(n);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: on ? _kAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: on
                                    ? _kAccent
                                    : textColor.withOpacity(0.18)),
                          ),
                          child: Text(n,
                              style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  fontWeight:
                                      on ? FontWeight.w600 : FontWeight.w500,
                                  color: on
                                      ? Colors.white
                                      : textColor.withOpacity(0.8))),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Divider(color: divider, height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.initial.copyWith(
                    neighborhoods: _hoods,
                    connectionsOnly: _connectionsOnly,
                    maxPrice: _priceIsSet ? _price : null,
                    clearMaxPrice: !_priceIsSet,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Show results',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color textColor) => Text(text,
      style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: textColor.withOpacity(0.45)));
}
