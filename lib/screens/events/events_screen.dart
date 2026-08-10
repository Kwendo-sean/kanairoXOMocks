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
import 'package:kanairoxo/models/event_filters.dart';
import 'package:kanairoxo/screens/events/widgets/event_filter_bar.dart';
import 'package:kanairoxo/screens/events/widgets/event_filter_sheet.dart';
import 'package:kanairoxo/screens/events/widgets/event_poster_card.dart';
import 'package:kanairoxo/screens/events/widgets/past_event_row.dart';

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
          child: Stack(alignment: Alignment.topCenter, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(width: 16),
              Expanded(child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  // Kill the default underline — clean Reels-style labels only
                  indicator: const BoxDecoration(),
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  labelColor: isFeedActive ? Colors.white : textColor,
                  unselectedLabelColor: isFeedActive
                    ? Colors.white.withOpacity(0.55)
                    : textColor.withOpacity(0.5),
                  labelStyle: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    shadows: isFeedActive ? const [
                      Shadow(blurRadius: 12, color: Colors.black54)] : null),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    shadows: isFeedActive ? const [
                      Shadow(blurRadius: 12, color: Colors.black54)] : null),
                  tabs: const [Tab(text: 'For you'), Tab(text: 'Events')]),
              )),
              // Search only makes sense on the Events tab — the For you feed
              // is Reels-style and doesn't take a query.
              if (!isFeedActive)
                IconButton(
                  icon: Icon(Icons.search_rounded, color: textColor, size: 22),
                  onPressed: _openSearch)
              else
                const SizedBox(width: 12),
              const SizedBox(width: 8),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Filter state ──────────────────────────────────────────────────────────

  EventFilters _filters = const EventFilters();

  /// Categories are derived from whatever the feed actually contains, so a new
  /// backend category shows up without any client change.
  List<ExperienceCategory> _categoriesIn(List<Experience> events) {
    final seen = <String, ExperienceCategory>{};
    for (final e in events) {
      final c = e.category;
      if (c != null && c.id.isNotEmpty) seen.putIfAbsent(c.id, () => c);
    }
    final list = seen.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<String> _neighborhoodsIn(List<Experience> events) {
    final set = events
        .map((e) => e.neighborhood)
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  double _maxPriceIn(List<Experience> events) {
    double max = 0;
    for (final e in events) {
      if (e.basePrice > max) max = e.basePrice;
    }
    return max;
  }

  Future<void> _openFilterSheet(List<Experience> pool) async {
    final result = await EventFilterSheet.show(
      context,
      initial: _filters,
      neighborhoods: _neighborhoodsIn(pool),
      maxPriceInFeed: _maxPriceIn(pool),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  Widget _buildEventsTab(Color textColor) {
    return Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.feed.isEmpty) {
            return Skeleton.feed(context, count: 3);
          }

          final feed = provider.feed;
          final trending = feed['trending'] ?? <Experience>[];
          final weekend = feed['this_weekend'] ?? <Experience>[];
          final week = feed['happening_this_week'] ?? <Experience>[];
          final all = feed['all'] ?? <Experience>[];

          // Everything we know about, de-duplicated — the pool that filters
          // run against and that categories/neighbourhoods are derived from.
          final pool = <String, Experience>{};
          for (final e in [...all, ...trending, ...weekend, ...week]) {
            pool[e.id] = e;
          }
          final poolList = pool.values.toList();

          final attendedPast = (_pastData?['attended'] as List?) ?? [];
          final otherPast = (_pastData?['others'] as List?) ?? [];
          final liveEmpty = poolList.isEmpty;
          final pastEmpty = attendedPast.isEmpty && otherPast.isEmpty;

          final categories = _categoriesIn(poolList);

          return RefreshIndicator(
            onRefresh: () async { await provider.fetchFeed(); await _loadPast(); },
            color: const Color(0xFF9B111E),
            child: Column(children: [
              EventFilterBar(
                categories: categories,
                filters: _filters,
                onChanged: (f) => setState(() => _filters = f),
                onOpenSheet: () => _openFilterSheet(poolList),
              ),
              Expanded(
                child: liveEmpty && pastEmpty
                  ? _buildEmpty(textColor)
                  : _filters.isActive
                    ? _buildResults(poolList, categories, textColor)
                    : _buildBrowse(
                        trending: trending,
                        weekend: weekend,
                        week: week,
                        all: all,
                        attendedPast: attendedPast,
                        otherPast: otherPast,
                        textColor: textColor),
              ),
            ]),
          );
        },
      );
  }

  /// Filters active — curation steps aside for a flat, countable result list.
  Widget _buildResults(List<Experience> pool,
      List<ExperienceCategory> categories, Color textColor) {
    final results = _filters.apply(pool);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${results.length} ${results.length == 1 ? 'event' : 'events'}'
                  '${_filters.summary(categories).isEmpty ? '' : ' · ${_filters.summary(categories)}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.75),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _filters = const EventFilters()),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Text('Clear',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9B111E))),
                  SizedBox(width: 3),
                  Icon(Icons.close_rounded, size: 15, color: Color(0xFF9B111E)),
                ]),
              ),
            ]),
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(child: _buildNoResults(textColor))
        else
          _buildSectionList(results),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildNoResults(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 60),
      child: Column(children: [
        Icon(Icons.search_off_rounded, size: 46, color: textColor.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('Nothing matches those filters',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor)),
        const SizedBox(height: 6),
        Text('Try widening your search — or clear the filters to see everything.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                height: 1.4,
                color: textColor.withOpacity(0.55))),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => _filters = const EventFilters()),
          child: const Text('Clear filters',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9B111E))),
        ),
      ]),
    );
  }

  /// Nothing filtered — curated rails on top, then the full list, then past.
  Widget _buildBrowse({
    required List<Experience> trending,
    required List<Experience> weekend,
    required List<Experience> week,
    required List<Experience> all,
    required List attendedPast,
    required List otherPast,
    required Color textColor,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (trending.isNotEmpty) ...[
          _buildSectionHeader('TRENDING NOW'),
          _buildRail(trending),
        ],
        if (weekend.isNotEmpty) ...[
          _buildSectionHeader('THIS WEEKEND'),
          _buildRail(weekend),
        ],
        if (week.isNotEmpty) ...[
          _buildSectionHeader('HAPPENING THIS WEEK'),
          _buildRail(week),
        ],
        if (all.isNotEmpty) ...[
          _buildSectionHeader('ALL EVENTS'),
          _buildSectionList(all),
        ],
        if (attendedPast.isNotEmpty) ...[
          _buildSectionHeader('YOU ATTENDED'),
          _buildPastSectionList(attendedPast, attended: true),
        ],
        if (otherPast.isNotEmpty) ...[
          _buildSectionHeader('PAST EVENTS'),
          _buildPastSectionList(otherPast),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Horizontal rail of poster cards. Curated rows preview breadth instead of
  /// burying the next section under a long vertical stack.
  Widget _buildRail(List<Experience> events) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 356,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final e = events[i];
            return EventPosterCard(
              event: e,
              onTap: () => _navigateToDetail(e),
              onSaveToggle: () => context.read<EventsProvider>().toggleSave(e),
            );
          },
        ),
      ),
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

  Widget _buildPastSectionList(List events, {bool attended = false}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final m = Map<String, dynamic>.from(events[index] as Map);
          return PastEventRow(
            event: m,
            attended: attended,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                eventId: (m['id'] ?? '').toString()))),
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
            return Skeleton.list(context, count: 4);
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
