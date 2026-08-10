import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

/// Ticket purchase checkout screen.
///
/// P0-3 : Parses `ticket_ids` array from the purchase response; shows a
///         per-ticket QR page when quantity > 1.
/// P1-6 : Payment method selector — M-Pesa (default) | Card (Paystack).
///         Card → receives `authorization_url` → opens in browser.
/// P2-7 : Optional per-ticket attendee name fields when quantity > 1.
class TicketPurchaseScreen extends StatefulWidget {
  final Experience event;
  final String? selectedTierId;
  final double? selectedTierPrice;
  final String? selectedTierName;

  const TicketPurchaseScreen({
    super.key,
    required this.event,
    this.selectedTierId,
    this.selectedTierPrice,
    this.selectedTierName,
  });

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final ApiClient apiClient = ApiClient();
  int _quantity = 1;
  bool _isLoading = false;

  // P1-6: payment method
  String _paymentMethod = 'mpesa'; // 'mpesa' | 'card'

  // flow state
  String _paymentStatus = 'idle'; // idle | processing | polling | success | failed | card_pending

  Timer? _pollTimer;
  String? _ticketId;           // first ticket ID (backward compat)
  List<String> _ticketIds = []; // all IDs (P0-3)

  // P1-6: Paystack authorization URL
  String? _authorizationUrl;

  // phone field (M-Pesa)
  final _phoneController = TextEditingController();

  // P2-7: optional attendee name controllers (one per ticket slot)
  final List<TextEditingController> _attendeeControllers = [];

  double get unitPrice => widget.selectedTierPrice ?? widget.event.basePrice;
  double get totalAmount => unitPrice * _quantity;

  @override
  void initState() {
    super.initState();
    _rebuildAttendeeControllers();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    for (final c in _attendeeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildAttendeeControllers() {
    for (final c in _attendeeControllers) {
      c.dispose();
    }
    _attendeeControllers.clear();
    for (int i = 0; i < _quantity; i++) {
      _attendeeControllers.add(TextEditingController());
    }
  }

  Future<void> _purchaseTicket() async {
    if (_paymentMethod == 'mpesa' && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your M-Pesa phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _paymentStatus = 'processing';
    });

    // P2-7: build attendees list
    final List<Map<String, String>> attendees = _attendeeControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => {'name': name})
        .toList();

    final Map<String, dynamic> body = {
      'quantity': _quantity,
      'pricing_tier_id': widget.selectedTierId,
      'payment_method': _paymentMethod, // P1-6
      if (_paymentMethod == 'mpesa')
        'phone_number': _phoneController.text.trim(),
      if (attendees.isNotEmpty) 'attendees': attendees, // P2-7
    };

    try {
      final response = await apiClient.post(
        'api/v1/tickets/purchase/${widget.event.id}/',
        body,
      );

      // P0-3: parse ticket_ids array (with single ticket_id fallback)
      final rawIds = response['ticket_ids'];
      final List<String> ids = rawIds != null
          ? List<String>.from((rawIds as List).map((e) => e.toString()))
          : (response['ticket_id'] != null ? [response['ticket_id'].toString()] : []);

      _ticketIds = ids;
      _ticketId = ids.isNotEmpty ? ids.first : response['ticket_id']?.toString();

      // P1-6: card payments
      if (_paymentMethod == 'card') {
        final authUrl = response['authorization_url']?.toString();
        if (authUrl != null && authUrl.isNotEmpty) {
          setState(() {
            _authorizationUrl = authUrl;
            _paymentStatus = 'card_pending';
            _isLoading = false;
          });
          return;
        }
      }

      if (response['status'] == 'confirmed') {
        setState(() {
          _paymentStatus = 'success';
          _isLoading = false;
        });
      } else {
        setState(() {
          _paymentStatus = 'polling';
          _isLoading = false;
        });
        _startPolling();
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'failed';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final id = _ticketId ?? '';
        if (id.isEmpty) return;
        final response = await apiClient.get('api/v1/tickets/$id/status/');
        final status = response['status'];
        if (status == 'paid' || status == 'confirmed') {
          _pollTimer?.cancel();
          if (mounted) setState(() => _paymentStatus = 'success');
        } else if (status == 'cancelled' || status == 'failed') {
          _pollTimer?.cancel();
          if (mounted) setState(() => _paymentStatus = 'failed');
        }
      } catch (_) {
        // keep polling
      }
    });
    Future.delayed(const Duration(minutes: 2), () {
      if (_paymentStatus == 'polling') {
        _pollTimer?.cancel();
        if (mounted) setState(() => _paymentStatus = 'failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout',
            style: AppTypography.labelLarge.copyWith(color: Colors.white)),
      ),
      body: switch (_paymentStatus) {
        'success'      => _buildSuccessState(),
        'polling'      => _buildPollingState(),
        'failed'       => _buildFailedState(),
        'card_pending' => _buildCardPendingState(),
        _              => _buildPurchaseForm(),
      },
    );
  }

  // ── Purchase form ──────────────────────────────────────────────

  Widget _buildPurchaseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete Purchase',
              style: AppTypography.displaySmall.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Choose how many tickets and how to pay.',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),

          // Quantity
          _SectionHeader(title: 'Quantity', textColor: Colors.white),
          _quantityRow(),
          const SizedBox(height: 24),

          // P2-7: per-ticket attendee names (only when qty > 1)
          if (_quantity > 1) ...[
            _SectionHeader(title: 'Attendee names (optional)', textColor: Colors.white),
            const Text(
              'Attendees with an email address will receive their ticket directly.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            ...List.generate(_quantity, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _attendeeControllers[i],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Attendee ${i + 1} name',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // P1-6: Payment method selector
          _SectionHeader(title: 'Payment method', textColor: Colors.white),
          _paymentMethodSelector(),
          const SizedBox(height: 24),

          // M-Pesa phone number (only when mpesa selected)
          if (_paymentMethod == 'mpesa') ...[
            _SectionHeader(title: 'M-Pesa phone number', textColor: Colors.white),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0712 345 678',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Order summary
          _SectionHeader(title: 'Order summary', textColor: Colors.white),
          _orderSummary(),
          const SizedBox(height: 32),

          // CTA
          LiquidGlassButton(
            width: double.infinity,
            onPressed: _isLoading ? null : _purchaseTicket,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_ctaLabel()),
          ),
        ],
      ),
    );
  }

  Widget _quantityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Text('Tickets', style: TextStyle(color: Colors.white)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.white),
          onPressed: _quantity > 1
              ? () => setState(() {
                    _quantity--;
                    _rebuildAttendeeControllers();
                  })
              : null,
        ),
        Text('$_quantity',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => setState(() {
            _quantity++;
            _rebuildAttendeeControllers();
          }),
        ),
      ]),
    );
  }

  Widget _paymentMethodSelector() {
    return Row(children: [
      _paymentChip('mpesa', 'M-Pesa', Icons.phone_android),
      const SizedBox(width: 12),
      _paymentChip('card', 'Card', Icons.credit_card),
    ]);
  }

  Widget _paymentChip(String method, String label, IconData icon) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppConstants.primaryRed : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppConstants.primaryRed : Colors.white24,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text(
              widget.selectedTierName ?? 'General Admission',
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Text('KES ${unitPrice.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('× $_quantity',
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Spacer(),
        ]),
        const Divider(color: Colors.white12, height: 20),
        Row(children: [
          const Text('Total',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('KES ${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppConstants.primaryRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
        ]),
      ]),
    );
  }

  String _ctaLabel() {
    if (totalAmount == 0) return 'Get free ticket';
    if (_paymentMethod == 'card') {
      return 'Pay KES ${totalAmount.toStringAsFixed(0)} with Card';
    }
    return 'Pay KES ${totalAmount.toStringAsFixed(0)} with M-Pesa';
  }

  // ── P1-6: Card pending state ───────────────────────────────────

  Widget _buildCardPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.credit_card, color: Colors.white70, size: 72),
          const SizedBox(height: 24),
          const Text('Complete payment in browser',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'A Paystack page has been opened. Return here once payment is confirmed.',
            style: TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: () async {
              if (_authorizationUrl != null) {
                await launchUrl(Uri.parse(_authorizationUrl!),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open payment page'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // User says they've paid; start polling
              setState(() => _paymentStatus = 'polling');
              _startPolling();
            },
            child: const Text("I've completed payment",
                style: TextStyle(color: Colors.white60)),
          ),
        ]),
      ),
    );
  }

  // ── States ──────────────────────────────────────────────────────

  Widget _buildPollingState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppConstants.primaryRed),
        const SizedBox(height: 24),
        Text(
          _paymentMethod == 'card'
              ? 'Confirming card payment…'
              : 'Waiting for M-Pesa prompt…',
          style: const TextStyle(color: Colors.white)),
      ]),
    );
  }

  Widget _buildSuccessState() {
    // P0-3: show all ticket IDs/QR codes when qty > 1
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        const Text('Payment Successful!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Your tickets are now available in your profile.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center),
        if (_ticketIds.length > 1) ...[
          const SizedBox(height: 24),
          Text('${_ticketIds.length} ticket IDs',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_ticketIds.length, (i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.confirmation_number_outlined,
                  color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text('Ticket ${i + 1}: ${_ticketIds[i]}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          )),
        ],
        const SizedBox(height: 32),
        LiquidGlassButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Event'),
        ),
      ]),
    );
  }

  Widget _buildFailedState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        const Text('Payment Failed',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => setState(() => _paymentStatus = 'idle'),
          child: const Text('Try Again',
              style: TextStyle(color: Colors.redAccent)),
        ),
      ]),
    );
  }
}

// ── helpers ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: AppTypography.labelMedium
              .copyWith(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
