import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/screens/payment/ticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String eventName;
  final String eventDate;
  
  const PaymentScreen({
    super.key,
    required this.amount,
    required this.eventName,
    required this.eventDate,
  });
  
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'mpesa';
  TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _paymentSuccessful = false;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'mpesa', 'name': 'M-Pesa', 'icon': PhosphorIcons.phone(), 'color': Colors.green},
    {'id': 'card', 'name': 'Card', 'icon': PhosphorIcons.creditCard(), 'color': Colors.blue},
    {'id': 'paypal', 'name': 'PayPal', 'icon': PhosphorIcons.paypalLogo(), 'color': Colors.blueAccent},
  ];
  
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'mpesa' && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your M-Pesa phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isProcessing = true);
    
    // Simulate M-Pesa API call
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _isProcessing = false;
      _paymentSuccessful = true;
    });
    
    // Show success and navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            eventName: widget.eventName,
            eventDate: widget.eventDate,
            amount: widget.amount,
          ),
        ),
      );
    });
  }
  
  void _showMpesaInstructions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('M-Pesa Payment Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Enter your M-Pesa registered phone number',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '2. Click "Pay with M-Pesa"',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '3. Check your phone for STK Push prompt',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '4. Enter your M-Pesa PIN to complete payment',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(PhosphorIcons.arrowLeft()),
          color: AppConstants.primaryBlack,
        ),
        title: Text(
          'Payment',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _paymentSuccessful
          ? _buildSuccessScreen()
          : _buildPaymentForm(),
    );
  }
  
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(color: AppConstants.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryBeige,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  Icon(
                        PhosphorIcons.ticket(),
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.eventName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.eventDate,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConstants.secondaryGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ticket Price',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'KES ${widget.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Fee',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'KES 50',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'KES ${(widget.amount * 0.16).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'KES ${(widget.amount + 50 + (widget.amount * 0.16)).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 20,
                        color: AppConstants.primaryRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Payment methods
          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Column(
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPaymentMethod = method['id']);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryRed : AppConstants.lightGray,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: method['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method['icon'],
                          color: method['color'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          method['name'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          PhosphorIcons.checkCircle(),
                          color: AppConstants.primaryRed,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // M-Pesa phone number input
          if (_selectedPaymentMethod == 'mpesa')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'M-Pesa Phone Number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '0712 345 678',
                    prefixIcon: Icon(PhosphorIcons.phone()),
                    suffixIcon: IconButton(
                      onPressed: _showMpesaInstructions,
                      icon: Icon(PhosphorIcons.info()),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      borderSide: BorderSide(color: AppConstants.lightGray),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the phone number registered with M-Pesa',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppConstants.secondaryGray,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          
          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedPaymentMethod == 'mpesa'
                              ? PhosphorIcons.phone()
                              : PhosphorIcons.creditCard(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedPaymentMethod == 'mpesa'
                              ? 'Pay with M-Pesa'
                              : 'Complete Payment',
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Security notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(color: AppConstants.lightGray),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.shieldCheck(),
                  color: AppConstants.successGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment is secure and encrypted. We never store your card details.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppConstants.secondaryGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppConstants.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.checkCircle(),
              size: 60,
              color: AppConstants.successGreen,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Payment Successful!',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'KES ${widget.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppConstants.successGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'has been deducted from your account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConstants.secondaryGray,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your ticket is being generated. You will be redirected to download it shortly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                // Already navigating automatically
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
              ),
              child: const Text('Download Ticket'),
            ),
          ),
        ],
      ),
    );
  }
}