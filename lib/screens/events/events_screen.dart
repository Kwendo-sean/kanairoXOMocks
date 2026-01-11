// lib/screens/events/events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/experience_card.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/services/events_api_service.dart';
import 'package:kanairoxo/providers/events_provider.dart';

class EventsScreen extends StatefulWidget {
  final void Function(Experience) onJoinExperience;
  final ValueChanged<Experience> onExperienceSelected;

  const EventsScreen({
    super.key,
    required this.onJoinExperience,
    required this.onExperienceSelected,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late EventsApiService _eventsApiService;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _eventsApiService = EventsApiService();
    _loadExperiences();
    _setupScrollController();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreExperiences();
      }
    });
  }

  Future<void> _loadExperiences() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      await eventsProvider.fetchExperiences();

      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    } catch (e) {
      print('Error loading experiences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load experiences'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreExperiences() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      final hasMore = await eventsProvider.loadMoreExperiences();

      setState(() {
        _hasMore = hasMore;
        _currentPage++;
      });
    } catch (e) {
      print('Error loading more experiences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load more experiences'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshExperiences() async {
    return _loadExperiences();
  }

  Future<void> _handleJoinExperience(Experience experience) async {
    try {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

      if (experience.isFull) {
        // Show waitlist dialog
        final joinWaitlist = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Event is Full'),
            content: Text('This event is currently at capacity. Would you like to join the waitlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Join Waitlist'),
              ),
            ],
          ),
        );

        if (joinWaitlist == true) {
          final result = await eventsProvider.joinWaitlist(experience.id);

          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to waitlist at position ${result['position']}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Show registration dialog
        final shouldRegister = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Join ${experience.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: ${experience.priceDisplay}'),
                SizedBox(height: 8),
                Text('Date: ${experience.formattedDate} at ${experience.formattedTime}'),
                SizedBox(height: 8),
                Text('Venue: ${experience.venueName}'),
                SizedBox(height: 8),
                Text('Spots left: ${experience.ticketsAvailable}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Register'),
              ),
            ],
          ),
        );

        if (shouldRegister == true) {
          final result = await eventsProvider.registerForExperience(
            experienceId: experience.id,
          );

          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully registered for ${experience.title}'),
                backgroundColor: Colors.green,
              ),
            );

            // Call the callback
            widget.onJoinExperience(experience);
          }
        }
      }
    } catch (e) {
      print('Error joining experience: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        final experiences = eventsProvider.experiences;
        final featuredExperiences = eventsProvider.featuredExperiences;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Experiences',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                  Navigator.pushNamed(context, '/events/search');
                },
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  // TODO: Implement filter
                  _showFilterDialog();
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _refreshExperiences,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Featured experiences section
                if (featuredExperiences.isNotEmpty) ...[
                  Text(
                    'Featured Experiences',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredExperiences.length,
                      itemBuilder: (context, index) {
                        final experience = featuredExperiences[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onExperienceSelected(experience);
                            Navigator.pushNamed(
                              context,
                              '/events/${experience.id}',
                            );
                          },
                          child: Container(
                            width: 280,
                            margin: EdgeInsets.only(right: 16),
                            child: FeaturedExperienceCard(
                              experience: experience,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // All experiences
                Text(
                  'All Experiences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Curated gatherings for meaningful connections',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF8B7355),
                  ),
                ),
                const SizedBox(height: 24),

                if (experiences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No experiences available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back soon for new gatherings',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...experiences.map((experience) {
                    return ExperienceCard(
                      experience: experience,
                      onJoin: () {
                        widget.onExperienceSelected(experience);
                        _handleJoinExperience(experience);
                      },
                      onTap: () {
                        widget.onExperienceSelected(experience);
                        Navigator.pushNamed(
                          context,
                          '/events/${experience.id}',
                        );
                      },
                    );
                  }).toList(),

                  // Load more indicator
                  if (_isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  if (!_hasMore && experiences.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No more experiences to load',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F1EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Experiences',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New experiences are added weekly. Check back often to find gatherings that match your current mood.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Filter Experiences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // TODO: Add filter options
              Expanded(
                child: ListView(
                  children: [
                    // Add filter options here
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Apply filters
                  _loadExperiences();
                },
                child: Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FeaturedExperienceCard extends StatelessWidget {
  final Experience experience;

  const FeaturedExperienceCard({
    super.key,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background image
          if (experience.coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                experience.coverImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Featured badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  experience.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        experience.venueName,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Text(
                      experience.formattedDate,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Text(
                      experience.formattedTime,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}