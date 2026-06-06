import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/event_card.dart';
import '../../models/data_models.dart';
import '../../providers/events_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  final ValueChanged<Experience>? onExperienceSelected;
  final ValueChanged<Experience>? onJoinExperience;

  const EventsScreen({
    super.key,
    this.onExperienceSelected,
    this.onJoinExperience,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchFeed();
    });
  }

  void _openSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const EventSearchOverlay(),
        transitionsBuilder: (context, anim, secondaryAnim, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Experiences',
          style: AppTypography.screenTitle.copyWith(color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: textColor, size: 22),
            onPressed: _openSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.feed.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF9B111E)));
          }

          final feed = provider.feed;
          final trending = feed['trending'] ?? [];
          final weekend = feed['this_weekend'] ?? [];
          final week = feed['happening_this_week'] ?? [];
          final all = feed['all'] ?? [];

          return RefreshIndicator(
            onRefresh: provider.fetchFeed,
            color: const Color(0xFF9B111E),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (trending.isNotEmpty) ...[
                  _buildSectionHeader('TRENDING NOW'),
                  _buildSectionList(trending),
                ],
                if (weekend.isNotEmpty) ...[
                  _buildSectionHeader('THIS WEEKEND'),
                  _buildSectionList(weekend),
                ],
                if (week.isNotEmpty) ...[
                  _buildSectionHeader('HAPPENING THIS WEEK'),
                  _buildSectionList(week),
                ],
                if (all.isNotEmpty) ...[
                  _buildSectionHeader('ALL EVENTS'),
                  _buildSectionList(all),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9B111E),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 2,
              color: const Color(0xFF9B111E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionList(List<Experience> events) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            isBookmarked: event.isSaved,
            onTap: () => _navigateToDetail(event),
            onSaveToggle: (e) => context.read<EventsProvider>().toggleSave(e),
          );
        },
        childCount: events.length,
      ),
    );
  }

  void _navigateToDetail(Experience event) {
    widget.onExperienceSelected?.call(event);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
    );
  }
}

class EventSearchOverlay extends StatefulWidget {
  const EventSearchOverlay({super.key});

  @override
  State<EventSearchOverlay> createState() => _EventSearchOverlayState();
}

class _EventSearchOverlayState extends State<EventSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 18, fontFamily: 'DMSans'),
          decoration: const InputDecoration(
            hintText: 'Search experiences...',
            hintStyle: TextStyle(color: Colors.grey, fontFamily: 'DMSans'),
            border: InputBorder.none,
          ),
          onChanged: (val) => context.read<EventsProvider>().search(val),
        ),
      ),
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isSearching) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF9B111E)));
          }

          if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(
              child: Text(
                'No events found',
                style: TextStyle(color: Colors.grey, fontFamily: 'DMSans'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final event = provider.searchResults[index];
              return EventCard(
                event: event,
                isBookmarked: event.isSaved,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                  );
                },
                onSaveToggle: (e) => provider.toggleSave(e),
              );
            },
          );
        },
      ),
    );
  }
}
