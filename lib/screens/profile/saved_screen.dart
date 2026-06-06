import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/moment_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/event_card.dart';
import '../../models/data_models.dart';
import 'package:kanairoxo/screens/events/event_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<EventsProvider>().fetchSavedEvents();
      }
    });
  }

  void _loadData() {
    context.read<MomentProvider>().fetchSavedMoments();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved', 
          style: AppTypography.screenTitle.copyWith(color: text)
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9B111E),
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF9B111E),
          unselectedLabelColor: const Color(0xFF999999),
          labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Moments'),
            Tab(text: 'Experiences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedMoments(text),
          _buildSavedEvents(),
        ],
      ),
    );
  }

  Widget _buildSavedMoments(Color text) {
    return Consumer<MomentProvider>(
      builder: (context, provider, child) {
        if (provider.isSavedLoading && provider.savedMoments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF9B111E), strokeWidth: 2));
        }

        if (provider.savedMoments.isEmpty) {
          return _buildEmptyState('No saved moments', Icons.photo_library_outlined);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSavedMoments(refresh: true),
          color: const Color(0xFF9B111E),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: provider.savedMoments.length,
            itemBuilder: (ctx, i) {
              final m = provider.savedMoments[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: m.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedEvents() {
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        if (provider.isSavedLoading && provider.savedEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF9B111E)));
        }

        if (provider.savedEvents.isEmpty) {
          return _buildEmptyState('No saved experiences', Icons.event_available_outlined);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSavedEvents(),
          color: const Color(0xFF9B111E),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.savedEvents.length,
            itemBuilder: (context, index) {
              final event = provider.savedEvents[index];
              return EventCard(
                event: event,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                  );
                },
                onSaveToggle: (e) => provider.toggleSave(e),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
      ),
    );
  }
}
