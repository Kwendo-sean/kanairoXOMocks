import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../models/ticket_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/ticket_time_state_card.dart';

class TicketRevealScreen extends StatelessWidget {
  final TicketModel ticket;

  const TicketRevealScreen({super.key, required this.ticket});

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileProvider>().myProfile;
    final userName = profile?.fullName ?? 'Guest';
    final isDark = context.isDark;

    // The Scaffold background should respect the theme
    // but we can adjust based on ticket type for better immersion if desired.
    // However, the request is for dark theme applicability.
    final bgColor = context.bgColor;
    final iconColor = context.textColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time-aware state card — countdown / live / past
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TicketTimeStateCard(event: ticket.event),
                    ),
                    if (ticket.ticketType == 'qr') _buildQrTicket(userName, isDark),
                    if (ticket.ticketType == 'invitation') _buildInvitationTicket(userName, isDark),
                    if (ticket.ticketType == 'polaroid') _buildPolaroidTicket(isDark),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQrTicket(String userName, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // QR tickets are always dark/black tie style
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            "KXO",
            style: GoogleFonts.cormorantGaramond(
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9B111E),
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 24),
          Text(
            ticket.event.title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            ticket.event.formattedDate,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "${ticket.event.venue} · ${ticket.event.neighborhood}",
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: QrImageView(
              data: ticket.qrHash,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "TICKET ${ticket.qrHash.substring(0, 8).toUpperCase()}",
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            "KANAIROXO.ONLINE",
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: Colors.white.withOpacity(0.25),
              letterSpacing: 3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationTicket(String userName, bool isDark) {
    // If it's an invitation design, it usually looks like paper.
    // We'll keep the paper look but can dim it slightly for dark mode if it's too bright.
    final cardBg = isDark ? const Color(0xFFF0EAE4) : const Color(0xFFFAF7F4);
    
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: const Color(0xFFC4A882), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8D5B8)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "KanairoXO",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: const Color(0xFF9B111E),
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              "cordially invites",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "to attend",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              ticket.event.title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9B111E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFFE8D5B8)),
            const SizedBox(height: 20),
            Text(
              ticket.event.formattedDate,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF444444),
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              ticket.event.formattedTime,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF444444),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "${ticket.event.venue} · ${ticket.event.neighborhood}",
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF444444),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: QrImageView(
                data: ticket.qrHash,
                size: 80,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.qrHash.substring(0, 8).toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: const Color(0xFF999999),
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolaroidTicket(bool isDark) {
    return Transform.rotate(
      angle: -0.026,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFF5F5F5) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            CachedNetworkImage(
              imageUrl: ticket.event.coverImage ?? '',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                height: 220,
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEDE5D8),
                child: Icon(
                  Icons.image_outlined,
                  color: isDark ? Colors.grey[800] : const Color(0xFFBBAA99),
                  size: 48,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.event.title,
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.event.formattedDate,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.qrHash.substring(0, 8).toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: const Color(0xFFBBAA99),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Transform.rotate(
                      angle: 0.26,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF9B111E),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "KXO",
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 9,
                              color: const Color(0xFF9B111E),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  QrImageView(
                    data: ticket.qrHash,
                    size: 80,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Scan at entry",
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final textColor = context.textColor;
    final borderColor = context.borderColor;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _launchUrl(ticket.pdfUrl),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: Text(
                "Download PDF",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _launchUrl("${ApiConstants.baseUrl}/tickets/${ticket.id}/"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B111E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 0,
              ),
              child: Text(
                "View Online",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
