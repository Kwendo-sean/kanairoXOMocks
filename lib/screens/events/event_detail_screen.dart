import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/data_models.dart';
import '../../providers/events_provider.dart';
import '../../widgets/loading_indicator.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPurchase() {
    if (_experience == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketPurchaseScreen(event: _experience!),
      ),
    );
  }

  Future<void> _handleSaveEvent() async {
    if (_experience == null) return;

    try {
      final result = await Provider.of<EventsProvider>(context, listen: false)
          .saveExperience(_experience!.id);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  Widget _buildInfoSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _experience == null
              ? const Center(child: Text('Event not found'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      floating: false,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _experience!.coverImage != null
                            ? Image.network(
                                _experience!.coverImage!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(context).primaryColor,
                              ),
                        title: Text(_experience!.title),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // TODO: Implement share
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          onPressed: _handleSaveEvent,
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Organizer section
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: _experience!.organizer.profilePicture != null
                                      ? NetworkImage(_experience!.organizer.profilePicture!)
                                      : null,
                                  child: _experience!.organizer.profilePicture == null
                                      ? Text(_experience!.organizer.firstName.isNotEmpty ? _experience!.organizer.firstName[0] : '')
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hosted by ${_experience!.organizer.firstName}',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                      if (_experience!.organizer.trustScore > 0)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.verified,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Trust Score: ${_experience!.organizer.trustScore}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Date and time
                            _buildInfoSection(
                              'Date & Time',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20),
                                      const SizedBox(width: 8),
                                      Text(_experience!.formattedDate),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 8),
                                      Text(_experience!.formattedTime),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Location
                            _buildInfoSection(
                              'Location',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 20),
                                      const SizedBox(width: 8),
                                      Text(_experience!.venueName),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _experience!.venueAddress,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            // Description
                            _buildInfoSection(
                              'About this Experience',
                              Text(
                                _experience!.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),

                            // Schedule
                            if (_experience!.schedule.isNotEmpty)
                              _buildInfoSection(
                                'Schedule',
                                Column(
                                  children: _experience!.schedule.map<Widget>((item) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 4,
                                        color: item.isBreak ? Colors.orange : Theme.of(context).primaryColor,
                                      ),
                                      title: Text(item.title),
                                      subtitle: Text(item.description),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Pricing
                            if (_experience!.pricingTiers.isNotEmpty)
                              _buildInfoSection(
                                'Pricing',
                                Column(
                                  children: _experience!.pricingTiers.map<Widget>((tier) {
                                    return Card(
                                      child: ListTile(
                                        title: Text(tier.name),
                                        subtitle: Text(tier.description),
                                        trailing: Text(
                                          '${tier.currency} ${tier.price.toStringAsFixed(0)}',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Capacity
                            _buildInfoSection(
                              'Capacity',
                              LinearProgressIndicator(
                                value: _experience!.capacityPercentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _experience!.capacityPercentage > 80
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _experience == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _experience!.priceDisplay,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_experience!.ticketsAvailable} spots left',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Join button
                  ElevatedButton(
                    onPressed: _experience!.isFull ? null : _navigateToPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _experience!.isFull ? 'FULL' : 'JOIN NOW',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
