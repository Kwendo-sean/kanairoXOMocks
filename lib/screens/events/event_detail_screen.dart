import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import '../../models/data_models.dart';
import '../../models/ticket_model.dart';
import '../../providers/events_provider.dart';
import '../../services/api_client.dart';
import 'ticket_purchase_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Experience? _experience;
  bool _isLoading = true;
  bool _hasTicket = false;

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
    _checkTicketStatus();
  }

  Future<void> _loadEventDetail() async {
    try {
      final experience = await Provider.of<EventsProvider>(context, listen: false)
          .fetchExperienceDetail(widget.eventId);

      if (!mounted) return;

      setState(() {
        _experience = experience;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading event detail: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load event details'),
          backgroundColor: Color(0xFF9B111E),
        ),
      );
    }
  }

  Future<void> _checkTicketStatus() async {
    try {
      final response = await ApiClient.instance.get('api/v1/tickets/');
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      final tickets = data.map((json) => TicketModel.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _hasTicket = tickets.any((t) => t.event.id.toString() == widget.eventId && t.status == 'confirmed');
        });
      }
    } catch (e) {
      debugPrint('Error checking ticket status: $e');
    }
  }

  void _navigateToPurchase() {
    if (_experience == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketPurchaseScreen(event: _experience!),
      ),
    ).then((_) => _checkTicketStatus());
  }

  Future<void> _handleSaveEvent() async {
    if (_experience == null) return;
    try {
      await Provider.of<EventsProvider>(context, listen: false).toggleSave(_experience!);
      setState(() {
        _experience = _experience!.copyWith(isSaved: !(_experience!.isSaved));
      });
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF9B111E);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final mutedTextColor = isDark ? const Color(0xFF999999) : const Color(0xFF444444);
    final borderColor = isDark ? const Color(0xFF2E2820) : const Color(0xFFE8E0D0);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_experience == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: Text('Event not found')),
      );
    }

    final formattedDate = DateFormat('EEE, d MMM').format(_experience!.startDateTime);
    final formattedTime = _experience!.formattedTime;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero image — SliverAppBar
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.48,
            pinned: false,
            stretch: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _experience!.coverUrl ?? _experience!.venueAddress,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEDE5D8),
                      child: Icon(Icons.image_outlined, color: isDark ? Colors.grey[800] : const Color(0xFFBBAA99), size: 56),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.4, 1.0],
                          colors: [
                            Colors.transparent,
                            bgColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.35),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                    iconSize: 16,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Content sheet — SliverToBoxAdapter
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row — title + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _experience!.title,
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _experience!.basePrice == 0
                              ? Colors.green.withOpacity(0.1)
                              : primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _experience!.basePrice == 0
                                ? Colors.green.withOpacity(0.3)
                                : primaryColor.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          _experience!.priceDisplay,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _experience!.basePrice == 0
                                ? Colors.green
                                : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Organiser row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? const Color(0xFF2E2820) : const Color(0xFFF0E8E0),
                        backgroundImage: _experience!.organizer.profilePicture != null
                            ? NetworkImage(_experience!.organizer.profilePicture!)
                            : null,
                        child: _experience!.organizer.profilePicture == null
                            ? Text(
                                _experience!.organizer.firstName.isNotEmpty
                                    ? _experience!.organizer.firstName[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hosted by",
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                          Text(
                            _experience!.organizer.firstName,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  // Info rows
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    "Date & Time",
                    "$formattedDate · $formattedTime",
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    "Location",
                    "${_experience!.venueName} · ${_experience!.neighborhood}",
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    context,
                    Icons.confirmation_number_outlined,
                    "Availability",
                    "${_experience!.ticketsAvailable} tickets left",
                  ),

                  const SizedBox(height: 24),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 24),

                  // Description section
                  Text(
                    "About this Experience",
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _experience!.description,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: mutedTextColor,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Ticket action section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _experience!.priceDisplay,
                                  style: TextStyle(
                                    fontFamily: 'CormorantGaramond',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "${_experience!.ticketsAvailable} tickets left",
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (_experience!.ticketsAvailable < 20)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text(
                                  "Limited",
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _hasTicket
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, color: Colors.green[600], size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "You're Going",
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontFamily: 'DMSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _navigateToPurchase,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Get Tickets",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'DMSans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final primaryColor = const Color(0xFF9B111E);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
