import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/services/memory_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kanairoxo/screens/couples/add_memory_screen.dart';
import 'package:kanairoxo/screens/couples/memory_detail_screen.dart';

class MemoriesEnhancedScreen extends StatefulWidget {
  const MemoriesEnhancedScreen({super.key});

  @override
  State<MemoriesEnhancedScreen> createState() => _MemoriesEnhancedScreenState();
}

class _MemoriesEnhancedScreenState extends State<MemoriesEnhancedScreen>
    with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  late TabController _tabController;

  Map<String, TimelineMonth>? _timeline;
  List<Memory>? _favorites;
  MemoryStats? _stats;
  bool _isLoading = true;
  String _viewMode = 'grid'; // 'grid' or 'timeline'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);

    try {
      final timeline = await _memoryService.getTimeline();
      final favorites = await _memoryService.getMemories(isFavorite: true);
      final stats = await _memoryService.getStats();

      setState(() {
        _timeline = timeline;
        _favorites = favorites;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: SafeArea(
        child: Column(
          children: [
            // Header with view toggle
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Our Memories',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryBlack,
                    ),
                  ),
                  Row(
                    children: [
                      // Toggle view mode
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _viewMode = _viewMode == 'grid' ? 'timeline' : 'grid';
                          });
                        },
                        icon: PhosphorIcon(
                          _viewMode == 'grid'
                              ? PhosphorIcons.list(PhosphorIconsStyle.regular)
                              : PhosphorIcons.gridFour(PhosphorIconsStyle.regular),
                          color: AppConstants.primaryBlack,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Navigate to add memory
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddMemoryScreen(),
                            ),
                          ).then((_) => _loadMemories());
                        },
                        icon: PhosphorIcon(
                          PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          color: AppConstants.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats bar
            if (_stats != null) _buildStatsBar(theme),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppConstants.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppConstants.secondaryGray,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Favorites'),
                  Tab(text: 'Photos'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildAllMemories(),
                  _buildFavorites(),
                  _buildPhotoGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, _stats!.total.toString(), 'Total'),
          _buildStatItem(theme, _stats!.favorites.toString(), 'Favorites'),
          _buildStatItem(theme, _stats!.recent30Days.toString(), 'This Month'),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryRed,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppConstants.secondaryGray,
          ),
        ),
      ],
    );
  }

  Widget _buildAllMemories() {
    if (_viewMode == 'grid') {
      // Grid view of all memories
      return _buildPhotoGrid();
    } else {
      // Timeline view
      return _buildTimelineView();
    }
  }

  Widget _buildTimelineView() {
    if (_timeline == null || _timeline!.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _timeline!.length,
      itemBuilder: (context, index) {
        final entry = _timeline!.entries.elementAt(index);
        final month = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                month.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryBlack,
                ),
              ),
            ),
            // Memories in that month
            ...month.memories.map((memory) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMemoryCard(memory),
            )),
          ],
        );
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailScreen(memory: memory),
          ),
        ).then((_) => _loadMemories());
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo thumbnail
            if (memory.photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: memory.photo!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppConstants.primaryBeige,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.image(PhosphorIconsStyle.regular),
                    size: 32,
                    color: AppConstants.primaryRed,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (memory.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      memory.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(memory.memoryDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                      const Spacer(),
                      if (memory.reactionCount > 0) ...[
                        PhosphorIcon(
                          PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          size: 14,
                          color: AppConstants.primaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          memory.reactionCount.toString(),
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.secondaryGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (memory.isFavorite)
              PhosphorIcon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                color: Colors.amber,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorites() {
    if (_favorites == null || _favorites!.isEmpty) {
      return _buildEmptyState(message: 'No favorite memories yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _favorites!.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildMemoryCard(_favorites![index]),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    // Get all memories with photos
    final List<Memory> allMemories = [];
    _timeline?.values.forEach((month) {
      allMemories.addAll(month.memories.where((m) => m.photo != null));
    });

    if (allMemories.isEmpty) {
      return _buildEmptyState(message: 'No photos yet');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allMemories.length,
      itemBuilder: (context, index) {
        final memory = allMemories[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemoryDetailScreen(memory: memory),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: memory.photo!,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.images(PhosphorIconsStyle.regular),
            size: 64,
            color: AppConstants.secondaryGray,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No memories yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.secondaryGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddMemoryScreen(),
                ),
              ).then((_) => _loadMemories());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryRed,
              foregroundColor: Colors.white,
            ),
            icon: PhosphorIcon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 18,
            ),
            label: const Text('Add First Memory'),
          ),
        ],
      ),
    );
  }
}
