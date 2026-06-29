import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/event_tier_model.dart';
import '../../models/data_models.dart';
import '../../models/ticket_model.dart';
import '../../providers/events_provider.dart';
import '../../services/api_client.dart';
import 'ticket_purchase_screen.dart';
import 'event_memories_screen.dart';
import 'invite_friends_screen.dart';
import 'package:kanairoxo/widgets/events/event_share_sheet.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/utils/constants.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiClient apiClient = ApiClient();
  Experience? _experience;
  List<EventTier> _tiers = [];
  EventTier? _selectedTier;
  bool _isLoading = true;
  bool _loadingTiers = false;
  bool _hasTicket = false;

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
    _loadTiers();
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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTiers() async {
    setState(() => _loadingTiers = true);
    try {
      final response = await apiClient.get('api/v1/events/${widget.eventId}/tiers/');
      if (mounted) {
        setState(() {
          _tiers = (response['tiers'] as List).map((t) => EventTier.fromJson(t)).toList();
          if (_tiers.isNotEmpty) {
            _selectedTier = _tiers.firstWhere((t) => t.isAvailableNow, orElse: () => _tiers.first);
          }
          _loadingTiers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTiers = false);
    }
  }

  Future<void> _checkTicketStatus() async {
    try {
      final response = await apiClient.get('api/v1/tickets/');
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
        builder: (context) => TicketPurchaseScreen(
          event: _experience!,
          selectedTierId: _selectedTier?.id,
        ),
      ),
    ).then((_) => _checkTicketStatus());
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConstants.primaryRed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Colors.black;
    final surfaceColor = Colors.grey[900]!;
    final textColor = Colors.white;
    final mutedTextColor = Colors.white70;
    final borderColor = Colors.white10;

    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    if (_experience == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Event not found', style: TextStyle(color: Colors.white))));
    }

    final formattedDate = DateFormat('EEE, d MMM').format(_experience!.startDateTime);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_experience!.trailerUrl != null && _experience!.trailerUrl!.isNotEmpty)
                    NetworkMediaPreview(
                      url: _experience!.trailerUrl!,
                      mediaType: 'video',
                      fit: BoxFit.cover,
                      autoPlay: true,
                      loop: true,
                      muted: false)
                  else if (_experience!.coverUrl != null && _experience!.coverUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _experience!.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade900))
                  else
                    Container(color: Colors.grey.shade900),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white),
                tooltip: 'Share event',
                onPressed: () => EventShareSheet.show(
                  context,
                  eventId: _experience!.id,
                  eventTitle: _experience!.title,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.group_add_outlined, color: Colors.white),
                tooltip: 'Invite friends',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InviteFriendsScreen(
                    eventId: _experience!.id,
                    eventTitle: _experience!.title,
                    initialMode: InviteMode.invite,
                  ),
                )),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_experience!.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('$formattedDate · ${_experience!.formattedTime}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('${_experience!.venueName}, ${_experience!.neighborhood}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('About this Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(_experience!.description, style: const TextStyle(color: Colors.white70, height: 1.5)),
                  const SizedBox(height: 32),
                  
                  if (_tiers.isNotEmpty) ...[
                    const Text('Select Ticket Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    ..._tiers.map((tier) => _buildTierCard(tier)),
                    const SizedBox(height: 24),
                  ],

                  _buildPurchaseAction(primaryColor, surfaceColor, borderColor),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(EventTier tier) {
    final isSelected = _selectedTier?.id == tier.id;
    return GestureDetector(
      onTap: tier.isAvailableNow ? () => setState(() => _selectedTier = tier) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryRed.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppConstants.primaryRed : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tier.name, style: TextStyle(color: tier.isAvailableNow ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('KES ${tier.price}', style: TextStyle(color: tier.isAvailableNow ? AppConstants.primaryRed : Colors.white24, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            if (tier.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(tier.description, style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            if (tier.benefits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: tier.benefits.map((b) => Text('• $b', style: const TextStyle(color: Colors.white70, fontSize: 11))).toList(),
                ),
              ),
            if (tier.remaining > 0 && tier.remaining < 20)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${tier.remaining} left!', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            if (!tier.isAvailableNow)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Not Available', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseAction(Color primaryColor, Color surfaceColor, Color borderColor) {
    final bool isPast = _experience != null
      && _experience!.endDateTime.isBefore(DateTime.now());

    // For past events: show "View memories" instead of "Get tickets".
    if (isPast) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: [
          const Text('This experience has ended.',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventMemoriesScreen(eventId: widget.eventId,
                  eventTitle: _experience?.title ?? 'Memories'))),
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
              label: const Text('View memories',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedTier != null ? 'KES ${_selectedTier!.price}' : _experience!.priceDisplay,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                  const Text('Price per ticket', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
              if (_hasTicket)
                const Icon(Icons.check_circle, color: Colors.green, size: 32)
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_hasTicket || (_tiers.isNotEmpty && _selectedTier == null)) ? null : _navigateToPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: Text(_hasTicket ? "You're Going" : "Get Tickets", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
