import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/services/memory_service.dart';
import 'package:kanairoxo/widgets/three_d_carousel.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
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
  int _carouselIndex = 0;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMemories = _getAllMemories();
    final filteredMemories = _selectedFilter == 'All'
        ? allMemories
        : allMemories.where((m) => m.memoryType.toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, // REMOVED BACK BUTTON
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Our Memories', style: AppTypography.screenTitle),
        actions: [
          _buildCreateButton(context),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 1. HERO: 3D Carousel (Favorites or Recent)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (allMemories.isNotEmpty)
                        ThreeDCarousel(
                          height: 260,
                          imageUrls: allMemories.take(5).map((m) => m.photo ?? '').where((url) => url.isNotEmpty).toList(),
                          onPageChanged: (index) => setState(() => _carouselIndex = index),
                          onCardTap: (index) {
                            final memoriesWithPhotos = allMemories.where((m) => m.photo != null && m.photo!.isNotEmpty).toList();
                            if (index < memoriesWithPhotos.length) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memoriesWithPhotos[index])),
                              );
                            }
                          },
                        ),
                      if (allMemories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            allMemories.take(5).where((m) => m.photo != null && m.photo!.isNotEmpty).length,
                            (index) => Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _carouselIndex == index ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text('Your social story', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // 2. FILTER TABS
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ['All', 'Event', 'Date', 'Vibe'].map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _MemoryFilterChip(
                            label: filter,
                            isSelected: _selectedFilter == filter,
                            onTap: () => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. MEMORIES FEED
                if (filteredMemories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _MemoryCard(
                        memory: filteredMemories[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: filteredMemories[index])),
                        ).then((_) => _loadMemories()),
                      ),
                      childCount: filteredMemories.length,
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  List<Memory> _getAllMemories() {
    final List<Memory> all = [];
    _timeline?.values.forEach((month) {
      all.addAll(month.memories);
    });
    return all;
  }

  Widget _buildCreateButton(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
      label: Text('Create',
          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
        ).then((_) => _loadMemories());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No memories yet', style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Text('Share your first experience together', style: AppTypography.caption),
          const SizedBox(height: 16),
          LiquidGlassButton(
            size: LiquidButtonSize.md,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
              ).then((_) => _loadMemories());
            },
            child: Text('Add Memory', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }
}

class _MemoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: AppRadius.full,
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const _MemoryCard({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CARD HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, child: Icon(Icons.favorite, size: 16, color: AppColors.primary)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memory.title,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text(_formatDate(memory.memoryDate), style: AppTypography.caption),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlass,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    memory.memoryType.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                if (memory.isFavorite)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.star, color: Colors.amber, size: 18),
                  ),
              ],
            ),
          ),

          // 2. MOMENT IMAGE
          if (memory.photo != null && memory.photo!.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: CachedNetworkImage(
                imageUrl: memory.photo!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[100]),
                errorWidget: (context, url, error) => Container(
                  height: 240,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          // 3. LOCATION TAG
          if (memory.locationName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(memory.locationName!, style: AppTypography.caption),
                ],
              ),
            ),

          // 4. CAPTION/DESCRIPTION
          if (memory.description != null && memory.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Text(
                memory.description!,
                style: AppTypography.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 5. ACTION BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _MemoryAction(
                  icon: memory.userReaction != null ? Icons.favorite : Icons.favorite_border,
                  color: memory.userReaction != null ? AppColors.primary : AppColors.textMuted,
                  label: '${memory.reactionCount}',
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _MemoryAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${memory.commentCount}',
                  onTap: () {},
                ),
                const Spacer(),
                _MemoryAction(
                  icon: Icons.share_outlined,
                  label: '',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MemoryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MemoryAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color ?? AppColors.textMuted),
      label: label.isNotEmpty ? Text(label, style: AppTypography.caption) : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
