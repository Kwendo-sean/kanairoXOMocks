import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final Experience event;

  const TicketPurchaseScreen({super.key, required this.event});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final ApiClient apiClient = ApiClient();
  int _quantity = 1;
  bool _isLoading = false;
  String? _checkoutId;
  String? _ticketId;
  String _paymentStatus = 'idle'; // idle, processing, polling, success, failed
  
  Timer? _pollTimer;
  final _phoneController = TextEditingController();
  
  double get totalAmount => (widget.event.basePrice) * _quantity;
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _purchaseTicket() async {
    if (widget.event.basePrice > 0 && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _paymentStatus = 'processing';
    });
    
    try {
      final response = await apiClient.post(
        'api/v1/tickets/purchase/${widget.event.id}/',
        {
          'quantity': _quantity,
          'phone_number': _phoneController.text.trim(),
        });
      
      if (response['status'] == 'confirmed') {
        // Free ticket or already confirmed
        setState(() {
          _ticketId = response['ticket_id']?.toString();
          _paymentStatus = 'success';
          _isLoading = false;
        });
        _downloadTicket();
      } else {
        // Paid — start polling
        setState(() {
          _checkoutId = response['checkout_request_id']?.toString();
          _ticketId = response['ticket_id']?.toString();
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
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3), (_) async {
        try {
          final response = await apiClient.get(
            'api/v1/tickets/$_ticketId/status/');
          final status = response['status'];
          
          if (status == 'paid') {
            _pollTimer?.cancel();
            setState(() => _paymentStatus = 'success');
            _downloadTicket();
          } else if (status == 'cancelled' || status == 'failed') {
            _pollTimer?.cancel();
            setState(() => _paymentStatus = 'failed');
          }
        } catch (e) {
          // Continue polling
        }
      });
    
    // Stop polling after 2 minutes
    Future.delayed(const Duration(minutes: 2), () {
      if (_paymentStatus == 'polling') {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() => _paymentStatus = 'failed');
        }
      }
    });
  }
  
  Future<void> _downloadTicket() async {
    if (_ticketId == null) return;
    try {
      final url = '${ApiConstants.baseUrl}/api/v1/tickets/$_ticketId/download/';
      debugPrint('Download URL: $url');
      // In a real app, use url_launcher to open this URL
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text('Get Tickets', style: AppTypography.screenTitle)),
      
      body: _paymentStatus == 'success'
        ? _buildSuccessState()
        : _paymentStatus == 'polling'
          ? _buildPollingState()
          : _paymentStatus == 'failed'
            ? _buildFailedState()
            : _buildPurchaseForm());
  }
  
  Widget _buildPurchaseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        
        // Event summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.event.title,
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${widget.event.venueName} · ${widget.event.neighborhood}',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                Text(
                  widget.event.formattedDate,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ])),
            Text(
              widget.event.basePrice == 0
                ? 'FREE'
                : 'KES ${widget.event.basePrice.toInt()}',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
          ])),
        
        const SizedBox(height: 20),
        
        // Quantity selector
        const _SectionHeader(title: 'Number of Tickets'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Text('Tickets', style: AppTypography.bodyMedium),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                color: _quantity > 1 ? AppColors.primary : AppColors.textMuted),
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
            Text('$_quantity',
              style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () => setState(() => _quantity++)),
          ])),
        
        const SizedBox(height: 20),
        
        // Phone number for M-Pesa
        if (widget.event.basePrice > 0) ...[
          const _SectionHeader(title: 'M-Pesa Payment'),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '07XXXXXXXX',
              prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
              helperText: 'You will receive an M-Pesa prompt',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)))),
          const SizedBox(height: 20),
        ],
        
        // Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGlass,
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text('Total', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              totalAmount == 0 ? 'FREE' : 'KES ${totalAmount.toInt()}',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
          ])),
        
        const SizedBox(height: 24),
        
        // Purchase button
        SizedBox(
          width: double.infinity,
          child: LiquidGlassButton(
            size: LiquidButtonSize.xl,
            onPressed: _isLoading ? null : _purchaseTicket,
            child: _isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  totalAmount == 0
                    ? 'Get Free Ticket'
                    : 'Pay KES ${totalAmount.toInt()} via M-Pesa',
                  style: AppTypography.buttonText))),
      ]));
  }
  
  Widget _buildPollingState() {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        const SizedBox(height: 24),
        Text('Waiting for payment...',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Check your phone for the M-Pesa prompt\nand complete the payment',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center),
      ]));
  }
  
  Widget _buildSuccessState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 44)),
          const SizedBox(height: 20),
          Text('Ticket Confirmed',
            style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Your ticket has been sent to your email and is ready to download',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: LiquidGlassButton(
              size: LiquidButtonSize.lg,
              onPressed: _downloadTicket,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Download Ticket', style: AppTypography.buttonText),
                ]))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back to Event',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted))),
        ])));
  }
  
  Widget _buildFailedState() {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text('Payment Failed',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'The payment was not completed.\nPlease try again.',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        LiquidGlassButton(
          size: LiquidButtonSize.md,
          onPressed: () => setState(() => _paymentStatus = 'idle'),
          child: const Text('Try Again', style: AppTypography.buttonText)),
      ]));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
