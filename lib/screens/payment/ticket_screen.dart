import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'dart:math';

class TicketScreen extends StatefulWidget {
  final String eventName;
  final String eventDate;
  final double amount;
  
  const TicketScreen({
    super.key,
    required this.eventName,
    required this.eventDate,
    required this.amount,
  });
  
  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String _ticketId = '';
  
  @override
  void initState() {
    super.initState();
    _generateTicketId();
  }
  
  void _generateTicketId() {
    final random = Random();
    _ticketId = 'KXO-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(10000)}';
  }
  
  Future<void> _downloadTicket() async {
    setState(() => _isDownloading = true);
    
    // Simulate download
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket downloaded successfully'),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }
  
  void _shareTicket() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorIcons.whatsappLogo(), color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  // Share via WhatsApp
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.telegramLogo(), color: Colors.blue),
                title: const Text('Telegram'),
                onTap: () {
                  Navigator.pop(context);
                  // Share via Telegram
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.envelope(), color: Colors.red),
                title: const Text('Email'),
                onTap: () {
                  Navigator.pop(context);
                  // Share via Email
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.copy(), color: AppConstants.secondaryGray),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket link copied')),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
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
          'Your Ticket',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _shareTicket,
            icon: Icon(PhosphorIcons.shareNetwork()),
            color: AppConstants.primaryRed,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ticket Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ticket background with perforation
                  CustomPaint(
                    size: Size(MediaQuery.of(context).size.width - 48, 400),
                    painter: TicketPainter(),
                  ),
                  
                  // Ticket content
                  Container(
                    width: MediaQuery.of(context).size.width - 48,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Event name
                        Text(
                          widget.eventName,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Ticket ID
                        Text(
                          'TICKET ID',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _ticketId,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Event details
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    widget.eventDate,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Venue',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    'Bluestone Lane, SoHo',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ticket Type',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    'General Admission',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Price',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    'KES ${widget.amount.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // QR Code placeholder
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.qrCode(),
                                  size: 60,
                                  color: AppConstants.primaryRed,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SCAN HERE',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppConstants.primaryRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Download button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloaded ? null : _downloadTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDownloaded 
                      ? AppConstants.successGreen 
                      : AppConstants.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                  ),
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isDownloaded ? PhosphorIcons.checkCircle() : PhosphorIcons.download(),
                      ),
                label: Text(
                  _isDownloading
                      ? 'Downloading...'
                      : _isDownloaded
                          ? 'Ticket Downloaded'
                          : 'Download Ticket',
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Instructions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.info(),
                        size: 16,
                        color: AppConstants.secondaryGray,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Present this ticket at the entrance. Digital tickets are accepted.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.clock(),
                        size: 16,
                        color: AppConstants.secondaryGray,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arrive 15 minutes before the event starts.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.user(),
                        size: 16,
                        color: AppConstants.secondaryGray,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valid for one person only. ID may be required.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class TicketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.primaryRed
      ..style = PaintingStyle.fill;
    
    // Main ticket body
    final ticketPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(ticketPath, paint);
    
    // Perforated edges
    final dashPaint = Paint()
      ..color = AppConstants.primaryBeige
      ..style = PaintingStyle.fill;
    
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double startY = 0;
    
    // Top dashes
    while (startY < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(startY, 0, dashWidth, 2),
        dashPaint,
      );
      startY += dashWidth + dashSpace;
    }
    
    startY = 0;
    // Bottom dashes
    while (startY < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(startY, size.height - 2, dashWidth, 2),
        dashPaint,
      );
      startY += dashWidth + dashSpace;
    }
    
    // Decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      40,
      circlePaint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.5),
      30,
      circlePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}