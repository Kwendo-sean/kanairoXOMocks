import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/ticket_model.dart';
import '../../../services/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import 'ticket_reveal_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final response = await _apiClient.get('api/v1/tickets/');
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      if (mounted) {
        setState(() {
          _tickets = data.map((json) => TicketModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetching tickets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = context.bgColor;
    final textColor = context.textColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Tickets",
          style: AppTypography.screenTitle.copyWith(
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    return _TicketListItem(ticket: _tickets[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_num_outlined, size: 64, color: context.mutedColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No tickets yet",
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your tickets will appear here after purchase",
            style: GoogleFonts.dmSans(fontSize: 14, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}

class _TicketListItem extends StatelessWidget {
  final TicketModel ticket;

  const _TicketListItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final textColor = context.textColor;
    final mutedColor = context.mutedColor;
    final primaryColor = context.primaryColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketRevealScreen(ticket: ticket),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: ticket.event.coverImage ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: context.isDark ? Colors.grey[900] : Colors.grey[200],
                      height: 140,
                      child: Icon(Icons.image_outlined, color: mutedColor),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      ticket.event.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ticket.status == 'confirmed'
                            ? primaryColor
                            : ticket.status == 'attended'
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.status.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, Icons.calendar_today_rounded, "Date", ticket.event.formattedDate),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, Icons.location_on_outlined, "Venue", "${ticket.event.venue} · ${ticket.event.neighborhood}"),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, Icons.confirmation_num_outlined, "Type", ticket.ticketType.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 13, color: context.mutedColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 13, color: context.textColor, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
