import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final Experience event;
  final String? selectedTierId;

  const TicketPurchaseScreen({super.key, required this.event, this.selectedTierId});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final ApiClient apiClient = ApiClient();
  int _quantity = 1;
  bool _isLoading = false;
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
    if (_phoneController.text.isEmpty) {
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
          'pricing_tier_id': widget.selectedTierId,
        });
      
      if (response['status'] == 'confirmed') {
        setState(() {
          _ticketId = response['ticket_id']?.toString();
          _paymentStatus = 'success';
          _isLoading = false;
        });
      } else {
        setState(() {
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
          } else if (status == 'cancelled' || status == 'failed') {
            _pollTimer?.cancel();
            setState(() => _paymentStatus = 'failed');
          }
        } catch (e) {
          // Continue polling
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
    final textColor = Colors.white;
    final bgColor = Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text('Checkout', style: AppTypography.labelLarge.copyWith(color: textColor))),
      
      body: _paymentStatus == 'success'
        ? _buildSuccessState(textColor)
        : _paymentStatus == 'polling'
          ? _buildPollingState(textColor)
          : _paymentStatus == 'failed'
            ? _buildFailedState(textColor)
            : _buildPurchaseForm(textColor, bgColor));
  }
  
  Widget _buildPurchaseForm(Color textColor, Color bgColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete Purchase', style: AppTypography.displaySmall.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Enter your M-Pesa number to receive a payment prompt.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          
          _SectionHeader(title: 'Quantity', textColor: textColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Text('Tickets', style: TextStyle(color: Colors.white)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                Text('$_quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => setState(() => _quantity++)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader(title: 'Phone Number', textColor: textColor),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0712345678',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 48),
          
          LiquidGlassButton(
            width: double.infinity,
            onPressed: _isLoading ? null : _purchaseTicket,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Pay with M-Pesa'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPollingState(Color textColor) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppConstants.primaryRed),
        const SizedBox(height: 24),
        Text('Waiting for M-Pesa prompt...', style: TextStyle(color: textColor)),
      ],
    ));
  }
  
  Widget _buildSuccessState(Color textColor) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Your tickets are now available in your profile.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 32),
        LiquidGlassButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Event')),
      ],
    ));
  }
  
  Widget _buildFailedState(Color textColor) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        const Text('Payment Failed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        TextButton(onPressed: () => setState(() => _paymentStatus = 'idle'), child: const Text('Try Again', style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.labelMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
