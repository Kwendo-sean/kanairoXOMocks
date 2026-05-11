import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/experience_card.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
import 'package:kanairoxo/screens/events/ticket_purchase_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
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
    try {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      await eventsProvider.fetchExperiences();

      setState(() {
        _hasMore = true;
      });
    } catch (e) {
      debugPrint('Error loading experiences: $e');
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
      });
    } catch (e) {
      debugPrint('Error loading more experiences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshExperiences() async {
    return _loadExperiences();
  }

  void _goToTicketScreen(Experience experience) {
    Navigator.push(context,
      MaterialPageRoute(
        builder: (_) => TicketPurchaseScreen(
          event: experience)));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleJoinExperience(Experience experience) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
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
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
              ? const Color(0xFF1C1612)
              : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                ? const Color(0xFF2E2820)
                : Colors.grey.shade100)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24))),
                child: Row(children: [
                  Expanded(child: Text(
                    experience.title,
                    style: AppTypography.displayMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: const Icon(Icons.close,
                      size: 20,
                      color: AppColors.textMuted),
                    onPressed: () =>
                      Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                ])),

              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    _DetailRow(
                      icon: Icons.confirmation_number_outlined,
                      label: experience.basePrice > 0
                        ? 'KES ${experience.basePrice.toInt()}'
                        : 'Free entry'),

                    const SizedBox(height: 10),

                    // Date
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(experience.startDateTime)),

                    const SizedBox(height: 10),

                    // Venue
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: experience.venueName),

                    const SizedBox(height: 10),

                    // Spots
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: '${experience.ticketsAvailable} spots left'),

                    const SizedBox(height: 20),

                    // Buttons
                    Row(children: [
                      // Cancel
                      Expanded(child: OutlinedButton(
                        onPressed: () =>
                          Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppColors.textMuted.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999))),
                        child: Text('Cancel',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500)))),

                      const SizedBox(width: 12),

                      // Buy Ticket / Get Ticket
                      Expanded(child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _goToTicketScreen(experience);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999))),
                        child: Text(
                          experience.basePrice > 0
                            ? 'Buy Ticket'
                            : 'Get Ticket',
                          style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)))),
                    ]),
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final mutedColor = isDark ? const Color(0xFF9A8F85) : const Color(0xFFA0A0A0);
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        final experiences = eventsProvider.experiences;
        final featuredExperiences = eventsProvider.featuredExperiences;
        final isLoading = eventsProvider.isLoading;

        final allExperiences = [...experiences];
        for (var featured in featuredExperiences) {
          if (!allExperiences.any((e) => e.id == featured.id)) {
            allExperiences.insert(0, featured);
          }
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              'Experiences',
              style: AppTypography.screenTitle.copyWith(color: textColor),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: textColor, size: 22),
                onPressed: () {
                  Navigator.pushNamed(context, '/events/host');
                },
              ),
              IconButton(
                icon: Icon(Icons.search_outlined, color: textColor, size: 22),
                onPressed: () {
                  Navigator.pushNamed(context, '/events/search');
                },
              ),
              IconButton(
                icon: Icon(Icons.tune_outlined, color: textColor, size: 22),
                onPressed: () {
                  _showFilterDialog();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshExperiences,
            color: AppColors.primary,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                LiquidGlassButton(
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
                      const Text(
                        'Host an Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                if (featuredExperiences.isNotEmpty) ...[
                  Text(
                    'Featured Experiences',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
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
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FeaturedExperienceCard(
                              experience: experience,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'All Experiences',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Curated gatherings for meaningful connections',
                  style: TextStyle(
                    color: mutedColor,
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                if (allExperiences.isEmpty && !isLoading)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: mutedColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No experiences available',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check back soon for new gatherings',
                          style: TextStyle(
                            color: mutedColor,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...allExperiences.map((experience) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
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

                  if (isLoading || _isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    ),

                  if (!_hasMore && allExperiences.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          'No more experiences to load',
                          style: TextStyle(color: mutedColor, fontFamily: 'DM Sans'),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1612) : const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3D342A) : const Color(0xFF8B1A1A).withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Experiences',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New experiences are added weekly. Check back often to find gatherings that match your current mood.',
                        style: TextStyle(
                          color: mutedColor,
                          fontFamily: 'DM Sans',
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1612) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          backgroundColor: bgColor.withOpacity(0.9),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'Filter Experiences',
                  style: AppTypography.displayMedium.copyWith(
                    color: isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: const [
                    ],
                  ),
                ),
                LiquidGlassButton(
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _DetailRow({
    required this.icon,
    required this.label});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness
      == Brightness.dark;
    return Row(children: [
      Icon(icon,
        size: 16,
        color: AppColors.primary.withOpacity(0.7)),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark
            ? const Color(0xFFF5EFE6)
            : const Color(0xFF1A1A1A),
          fontSize: 14))),
    ]);
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
    return Container(
      width: 200,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A0808),
            Color(0xFF1A0505),
          ])),
      child: Stack(children: [
        // Large faint letter in background
        Positioned(
          right: -10, top: -10,
          child: Text(
            experience.title.isNotEmpty
              ? experience.title[0].toUpperCase()
              : 'K',
            style: TextStyle(
              fontSize: 110,
              fontWeight: FontWeight.w900,
              color: AppColors.primary.withOpacity(0.08),
              height: 1))),

        // Content
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Featured badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6)),
                child: const Text('FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5))),

              // Event details at bottom
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(experience.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 4),

                  Row(children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: Colors.white.withOpacity(0.55)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(
                      experience.neighborhood.isNotEmpty
                        ? experience.neighborhood
                        : experience.venueName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
                  ]),
                ]),
            ])),
      ]));
  }
}
