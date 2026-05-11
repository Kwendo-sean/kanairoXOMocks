import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/date_request_model.dart';
import '../../services/api_client.dart';
import '../../providers/date_plan_provider.dart';
import 'package:provider/provider.dart';

class DatePaymentScreen extends StatefulWidget {
  final DateRequestModel request;
  const DatePaymentScreen({super.key, required this.request});

  @override
  State<DatePaymentScreen> createState() => _DatePaymentScreenState();
}

class _DatePaymentScreenState extends State<DatePaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    context.read<DatePlanProvider>().fetchConfig();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your M-Pesa number')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final requestId = widget.request.id;
      String formattedPhone = phone;
      if (phone.startsWith('0')) {
        formattedPhone = '254${phone.substring(1)}';
      } else if (!phone.startsWith('254')) {
        formattedPhone = '254$phone';
      }

      await ApiClient.instance.post(
        'api/v1/date-planning/requests/$requestId/pay/',
        {'phone_number': formattedPhone},
      );

      if (!mounted) return;

      _showSuccessSheet();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 56),
            const SizedBox(height: 16),
            Text(
              "Booking Confirmed",
              style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Your date at ${widget.request.venue.name} is confirmed. Enjoy the evening.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text("Back to Messages", style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatePlanProvider>();
    final resFee = provider.config?.reservationFee ?? 500.0;
    final commissionRate = provider.config?.commissionRate ?? 0.1;
    final kxoFee = widget.request.package.price * commissionRate;
    
    final venuePhoto = widget.request.venue.coverImage;
    final hasVenuePhoto = venuePhoto != null && venuePhoto.isNotEmpty;
    final senderPhoto = widget.request.sender.photo;
    final hasSenderPhoto = senderPhoto != null && senderPhoto.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.warmBeige,
      appBar: AppBar(
        backgroundColor: AppColors.warmBeige,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.nearBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Complete Booking",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.nearBlack,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        hasVenuePhoto
                          ? CachedNetworkImage(
                              imageUrl: venuePhoto,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: const Color(0xFFF0E8E0), height: 140),
                            )
                          : Container(color: const Color(0xFFF0E8E0), height: 140),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 16,
                          child: Text(
                            widget.request.venue.name,
                            style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFF0E8E0),
                              backgroundImage: hasSenderPhoto ? NetworkImage(senderPhoto) : null,
                              child: !hasSenderPhoto 
                                ? Text(widget.request.sender.name[0], style: GoogleFonts.cormorantGaramond(fontSize: 18, color: AppColors.primary))
                                : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date with ${widget.request.sender.name}", style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.nearBlack)),
                                Text(widget.request.vibe, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.primary)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE8E0D0)),
                        const SizedBox(height: 16),
                        _buildPayRow("Package", widget.request.package.name, "KES ${widget.request.package.price}"),
                        const SizedBox(height: 10),
                        _buildPayRow("KXO Fee", "Platform service fee", "KES ${kxoFee.toInt()}"),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFFE8E0D0)),
                        const SizedBox(height: 10),
                        _buildPayRow("Reservation Deposit", "Due now to confirm", "KES ${resFee.toInt()}", bold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text("Pay with M-Pesa", style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.nearBlack)),
            const SizedBox(height: 4),
            const Text("Enter your M-Pesa registered phone number", style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Color(0xFF999999))),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E0D0)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text("+254", style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.nearBlack)),
                  ),
                  const SizedBox(height: 24, child: VerticalDivider(color: Color(0xFFE8E0D0), width: 24)),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "7XX XXX XXX",
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isProcessing 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text("Pay KES 500", style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
              ),
            ),
            
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Your booking is confirmed once payment is received",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayRow(String label, String subtitle, String amount, {bool bold = false}) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.nearBlack)),
            Text(subtitle, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Color(0xFF999999))),
          ],
        ),
        const Spacer(),
        Text(amount, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColors.primary)),
      ],
    );
  }
}
