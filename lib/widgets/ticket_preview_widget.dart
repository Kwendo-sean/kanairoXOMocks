// lib/widgets/ticket_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

class TicketPreviewWidget extends StatelessWidget {
  final String designType;
  final String eventTitle;
  final String organizerName;
  final String date;
  final String time;
  final String venue;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  const TicketPreviewWidget({
    super.key,
    required this.designType,
    required this.eventTitle,
    required this.organizerName,
    required this.date,
    required this.time,
    required this.venue,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (designType) {
      case 'letter':
        return _buildLetterDesign(context);
      case 'qr_code':
        return _buildQRCodeDesign(context);
      case 'digital':
        return _buildDigitalDesign(context);
      case 'minimal':
        return _buildMinimalDesign(context);
      default:
        return _buildQRCodeDesign(context);
    }
  }

  Widget _buildLetterDesign(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final txtColor = textColor ?? Colors.black;
    final accColor = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // KanairoXO Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.event,
              size: 40,
              color: accColor,
            ),
          ),

          const SizedBox(height: 24),

          // Invitation Text
          Text(
            'You\'re Invited!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: txtColor,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Event Title
          Text(
            eventTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: txtColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Divider(color: accColor.withOpacity(0.3), thickness: 1),

          const SizedBox(height: 24),

          // Personal Invitation
          Text(
            '$organizerName invites you to',
            style: TextStyle(
              fontSize: 16,
              color: txtColor.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            eventTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Event Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, 'Date', date),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.access_time, 'Time', time),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on, 'Venue', venue),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          Text(
            'kanairoxo.com',
            style: TextStyle(
              fontSize: 14,
              color: txtColor.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeDesign(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final txtColor = textColor ?? Colors.black;
    final accColor = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with logo and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kanairoxo',
                      style: TextStyle(
                        fontSize: 12,
                        color: txtColor.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      eventTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: txtColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: accColor.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: 'KANAIROXO-TICKET-${DateTime.now().millisecondsSinceEpoch}',
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: accColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: txtColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SCAN FOR CHECK-IN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Event Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, date, time),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, venue, ''),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person, 'Host', organizerName),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barcode
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: 'KX-${DateTime.now().millisecondsSinceEpoch}',
            width: double.infinity,
            height: 60,
            color: txtColor,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalDesign(BuildContext context) {
    final bgColor = backgroundColor ?? Color(0xFF1A1A2E);
    final txtColor = textColor ?? Colors.white;
    final accColor = accentColor ?? Color(0xFF00D4FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accColor, accColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGITAL PASS',
                      style: TextStyle(
                        fontSize: 12,
                        color: accColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      eventTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: txtColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Glowing QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: 'DIGITAL-PASS-${DateTime.now().millisecondsSinceEpoch}',
                version: QrVersions.auto,
                size: 120,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: accColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Event info in cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoCard(
                Icons.calendar_today,
                'DATE & TIME',
                '$date\n$time',
                accColor,
                txtColor,
              ),
              _buildInfoCard(
                Icons.location_on,
                'VENUE',
                venue,
                accColor,
                txtColor,
              ),
              _buildInfoCard(
                Icons.person,
                'HOST',
                organizerName,
                accColor,
                txtColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalDesign(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final txtColor = textColor ?? Colors.black;
    final accColor = accentColor ?? Colors.grey[800]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple header
          Text(
            'TICKET',
            style: TextStyle(
              fontSize: 12,
              color: txtColor.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          Divider(color: Colors.grey[300]!),

          const SizedBox(height: 16),

          // Event title
          Text(
            eventTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: txtColor,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 24),

          // Simple details grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE',
                      style: TextStyle(
                        fontSize: 11,
                        color: txtColor.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        color: txtColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIME',
                      style: TextStyle(
                        fontSize: 11,
                        color: txtColor.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        color: txtColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Venue
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VENUE',
                style: TextStyle(
                  fontSize: 11,
                  color: txtColor.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                venue,
                style: TextStyle(
                  fontSize: 14,
                  color: txtColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Simple QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: 'MINIMAL-TICKET',
                version: QrVersions.auto,
                size: 100,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: accColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: accColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Simple footer
          Center(
            child: Text(
              'kanairoxo.com',
              style: TextStyle(
                fontSize: 12,
                color: txtColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor?.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor?.withOpacity(0.6),
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content, Color accentColor, Color textColor) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: accentColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}