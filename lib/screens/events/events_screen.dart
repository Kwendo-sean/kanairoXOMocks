import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/event_card.dart';
import '../../models/data_models.dart';
import '../../providers/events_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'event_detail_screen.dart';
import 'package:kanairoxo/widgets/skeletons.dart';
import 'package:kanairoxo/screens/events/events_feed_tab.dart';
import 'package:kanairoxo/services/api_client.dart';

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

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _pastData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Rebuild so the AppBar overlay restyles (white-on-video vs dark-on-bg)
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchFeed();
      _loadPast();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPast() async {
    try {
      final res = await ApiClient.instance.dio.get('/api/v1/events/past/');
      if (mounted) setState(() => _pastData = Map<String, dynamic>.from(res.data as Map));
    } catch (_) {}
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

    // For the FEED tab we want full-bleed video like Instagram Reels:
    // no AppBar, transparent overlaid tab bar on top of the video.
    final isFeedActive = _tabController.index == 0;
    final scaffoldBg = isFeedActive ? Colors.black : bgColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        // The actual tabbed content fills the entire screen
        Positioned.fill(
          child: TabBarView(
            controller: _tabController,
            children: [
              const EventsFeedTab(),
              SafeArea(
                top: true, bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: _buildEventsTab(textColor))),
            ],
          ),
        ),
        // Overlaid tab bar + search at the very top (matches Reels)
        Positioned(
          left: 0, right: 0,
          top: MediaQuery.of(context).padding.top,
          child: Stack(alignment: Alignment.center, children: [
            // Subtle dark gradient only when feed is active so text stays legible
            if (isFeedActive)
              IgnorePointer(
                child: Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent])))),
            Column(children: [
              SizedBox(height: 4,
                child: Row(children: [
                  const SizedBox(width: 8),
                  if (!isFeedActive)
                    Expanded(child: Text('Experiences',
                      textAlign: TextAlign.center,
                      style: AppTypography.screenTitle.copyWith(color: textColor)))
                  else
                    const Spacer(),
                  IconButton(
                    icon: Icon(Icons.search_rounded,
                      color: isFeedActive ? Colors.white : textColor, size: 22),
                    onPressed: _openSearch),
                  const SizedBox(width: 8),
                ])),
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isFeedActive ? Colors.white : const Color(0xFF9B111E),
                  unselectedLabelColor: isFeedActive
                    ? Colors.white.withOpacity(0.55)
                    : textColor.withOpacity(0.5),
                  indicatorColor: isFeedActive ? Colors.white : const Color(0xFF9B111E),
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.8),
                  tabs: const [Tab(text: 'FOR YOU'), Tab(text: 'EVENTS')]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEventsTab(Color textColor) {
    return Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.feed.isEmpty) {
            return Skeleton.feed(context, count: 3);
          }

          final feed = provider.feed;
          final trending = feed['trending'] ?? [];
          final weekend = feed['this_weekend'] ?? [];
          final week = feed['happening_this_week'] ?? [];
          final all = feed['all'] ?? [];

          final attendedPast = (_pastData?['attended'] as List?) ?? [];
          final otherPast = (_pastData?['others'] as List?) ?? [];
          final liveEmpty = trending.isEmpty && weekend.isEmpty && week.isEmpty && all.isEmpty;
          final pastEmpty = attendedPast.isEmpty && otherPast.isEmpty;

          return RefreshIndicator(
            onRefresh: () async { await provider.fetchFeed(); await _loadPast(); },
            color: const Color(0xFF9B111E),
            child: liveEmpty && pastEmpty
              ? _buildEmpty(textColor)
              : CustomScrollView(
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
                    if (attendedPast.isNotEmpty) ...[
                      _buildSectionHeader('YOU ATTENDED'),
                      _buildPastSectionList(attendedPast),
                    ],
                    if (otherPast.isNotEmpty) ...[
                      _buildSectionHeader('PAST EVENTS'),
                      _buildPastSectionList(otherPast),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
          );
        },
      );
  }

  Widget _buildEmpty(Color textColor) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.event_outlined, size: 64, color: Color(0xFF9B111E)),
        const SizedBox(height: 20),
        Center(
          child: Text('No experiences live right now',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 18, fontWeight: FontWeight.w600, color: textColor))),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Our partners are cooking up something new. Pull to refresh, or check Moments for the latest from the city.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans', fontSize: 13,
                color: textColor.withOpacity(0.55), height: 1.4)))),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () => context.read<EventsProvider>().fetchFeed(),
            icon: const Icon(Icons.refresh, color: Color(0xFF9B111E)),
            label: const Text('Refresh',
              style: TextStyle(color: Color(0xFF9B111E), fontWeight: FontWeight.w600)))),
      ],
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

  Widget _buildPastSectionList(List events) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final m = Map<String, dynamic>.from(events[index] as Map);
          final id = (m['id'] ?? '').toString();
          final title = (m['title'] ?? 'Untitled').toString();
          final venue = (m['venue_name'] ?? m['neighborhood'] ?? '').toString();
          final cover = (m['cover_url'] ?? m['cover_image'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: id))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(children: [
                  if (cover.isNotEmpty)
                    Image.network(cover, height: 120, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey.shade300))
                  else
                    Container(height: 120, color: Colors.grey.shade300),
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)])))),
                  Positioned(left: 12, right: 12, bottom: 12, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: const TextStyle(fontFamily: 'DMSans', color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (venue.isNotEmpty)
                        Text(venue, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                ]),
              ),
            ),
          );
        },
        childCount: events.length,
      ),
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
