import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/experience_card.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/services/events_api_service.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

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
        const SnackBar(
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
        const SnackBar(
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
        final joinWaitlist = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Event is Full'),
            content: const Text('This event is currently at capacity. Would you like to join the waitlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Join Waitlist'),
              ),
            ],
          ),
        );

        if (joinWaitlist == true) {
          final result = await eventsProvider.joinWaitlist(experience.id);

          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Added to waitlist at position ${result['position']}"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        final shouldRegister = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Join ${experience.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: ${experience.priceDisplay}'),
                const SizedBox(height: 8),
                Text('Date: ${experience.formattedDate} at ${experience.formattedTime}'),
                const SizedBox(height: 8),
                Text('Venue: ${experience.venueName}'),
                const SizedBox(height: 8),
                Text('Spots left: ${experience.ticketsAvailable}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Register'),
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(
              'Experiences',
              style: AppTypography.screenTitle,
            ),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              LiquidGlassButton(
                size: LiquidButtonSize.icon,
                variant: LiquidButtonVariant.ghost,
                onPressed: () {
                  Navigator.pushNamed(context, '/events/host');
                },
                child: const Icon(Icons.add, color: AppColors.textPrimary),
              ),
              LiquidGlassButton(
                size: LiquidButtonSize.icon,
                variant: LiquidButtonVariant.ghost,
                onPressed: () {
                  Navigator.pushNamed(context, '/events/search');
                },
                child: const Icon(Icons.search, color: AppColors.textPrimary),
              ),
              LiquidGlassButton(
                size: LiquidButtonSize.icon,
                variant: LiquidButtonVariant.ghost,
                onPressed: () {
                  _showFilterDialog();
                },
                child: const Icon(Icons.filter_list, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _refreshExperiences,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Host Event Section
                LiquidGlassButton(
                  variant: LiquidButtonVariant.primary,
                  size: LiquidButtonSize.lg,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pushNamed(context, '/events/host');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Host an Event', style: AppTypography.buttonText),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Featured experiences section
                if (featuredExperiences.isNotEmpty) ...[
                  Text(
                    'Featured Experiences',
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
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
                              width: 260,
                              margin: const EdgeInsets.only(right: 12),
                              child: FeaturedExperienceCard(
                                experience: experience,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // All experiences
                Text(
                  'All Experiences',
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Curated gatherings for meaningful connections',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                if (experiences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_available,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No experiences available',
                          style: AppTypography.bodyLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check back soon for new gatherings',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...experiences.map((experience) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        blurSigma: 12,
                        padding: EdgeInsets.zero,
                        child: ExperienceCard(
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
                        ),
                      ),
                    );
                  }).toList(),

                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  if (!_hasMore && experiences.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          'No more experiences to load',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 32),
                GlassCard(
                  backgroundColor: AppColors.primaryGlass,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Experiences',
                        style: AppTypography.displayMedium.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New experiences are added weekly. Check back often to find gatherings that match your current mood.',
                        style: AppTypography.bodyMedium,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'Filter Experiences',
                  style: AppTypography.displayMedium,
                ),
                Expanded(
                  child: ListView(
                    children: const [
                      // Add filter options here
                    ],
                  ),
                ),
                LiquidGlassButton(
                  size: LiquidButtonSize.lg,
                  onPressed: () {
                    Navigator.pop(context);
                    _loadExperiences();
                  },
                  child: Text('Apply Filters', style: AppTypography.buttonText),
                ),
              ],
            ),
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
        borderRadius: AppRadius.md,
      ),
      child: Stack(
        children: [
          if (experience.coverImage != null)
            ClipRRect(
              borderRadius: AppRadius.md,
              child: Image.network(
                experience.coverImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
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

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  experience.title,
                  style: AppTypography.displayMedium.copyWith(color: Colors.white, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        experience.venueName,
                        style: AppTypography.caption.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
