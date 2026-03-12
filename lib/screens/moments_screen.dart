import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/widgets/three_d_carousel.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  String _selectedFilter = 'All';
  int _carouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final moments = _getSampleMoments();
    final filteredMoments = _selectedFilter == 'All'
        ? moments
        : moments.where((m) => m.type.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Moments', style: AppTypography.screenTitle),
        actions: [
          _buildCreateButton(context),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. HERO: 3D Carousel
          SliverToBoxAdapter(
            child: Column(
              children: [
                ThreeDCarousel(
                  height: 260,
                  imageUrls: moments.map((m) => m.photoUrl).toList(),
                  onPageChanged: (index) => setState(() => _carouselIndex = index),
                  onCardTap: (index) => _openMomentDetail(context, moments[index]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(moments.length, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _carouselIndex == index ? AppColors.primary : AppColors.textMuted,
                      ),
                    );
                  }),
                ),
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
                children: ['All', 'Events', 'Meetups', 'Vibes'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MomentFilterChip(
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

          // 3. MOMENTS FEED
          if (filteredMoments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MomentCard(moment: filteredMoments[index]),
                childCount: filteredMoments.length,
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
      label: Text('Create',
          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      onPressed: () => _openCreateMoment(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No moments yet', style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Text('Share your first experience', style: AppTypography.caption),
          const SizedBox(height: 16),
          LiquidGlassButton(
            size: LiquidButtonSize.md,
            onPressed: () => _openCreateMoment(context),
            child: Text('Create Moment', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  void _openCreateMoment(BuildContext context) {
    // Logic to open creation screen
  }

  void _openMomentDetail(BuildContext context, Moment moment) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _MomentDetailModal(moment: moment),
    );
  }

  List<Moment> _getSampleMoments() {
    return [
      Moment(
        id: '1',
        userName: 'Sarah M.',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=sarah',
        eventName: 'Art & Sip',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: MomentType.event,
        photoUrl: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?q=80&w=2574&auto=format&fit=crop',
        caption: 'Amazing evening painting and meeting new souls! 🎨✨',
        location: 'Westlands, Nairobi',
        likeCount: 24,
        commentCount: 5,
      ),
      Moment(
        id: '2',
        userName: 'David K.',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=david',
        eventName: 'Urban Meetup',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: MomentType.meetup,
        photoUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=2574&auto=format&fit=crop',
        caption: 'Great vibes at the weekend meetup.',
        location: 'The Alchemist',
        likeCount: 15,
        commentCount: 2,
      ),
    ];
  }
}

class _MomentFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MomentFilterChip({
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

class _MomentCard extends StatelessWidget {
  final Moment moment;

  const _MomentCard({required this.moment});

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
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(moment.userAvatarUrl)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.userName,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text(moment.timeAgo, style: AppTypography.caption),
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
                    moment.type.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 2. MOMENT IMAGE
          GestureDetector(
            onTap: () {},
            onDoubleTap: () {},
            child: CachedNetworkImage(
              imageUrl: moment.photoUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 3. LOCATION TAG
          if (moment.location != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(moment.location!, style: AppTypography.caption),
                ],
              ),
            ),

          // 4. CAPTION
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Text(
              moment.caption,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 5. ACTION BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _MomentAction(
                  icon: moment.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: moment.isLiked ? AppColors.primary : AppColors.textMuted,
                  label: '${moment.likeCount}',
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${moment.commentCount}',
                  onTap: () => _openComments(context, moment),
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.send_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
                const Spacer(),
                _MomentAction(
                  icon: moment.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: moment.isSaved ? AppColors.primary : AppColors.textMuted,
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

  void _openComments(BuildContext context, Moment moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text('Comments', style: AppTypography.displayMedium),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 0, // Placeholder
                    itemBuilder: (context, index) => const SizedBox.shrink(),
                  ),
                ),
                // Text input placeholder
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: AppRadius.full),
                          child: Text('Add a comment...', style: AppTypography.caption),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MomentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MomentAction({
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

class _MomentDetailModal extends StatelessWidget {
  final Moment moment;

  const _MomentDetailModal({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: moment.photoUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(moment.userName, style: AppTypography.displayMedium.copyWith(color: Colors.white)),
                Text('${moment.timeAgo} • ${moment.location ?? ""}', style: AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(radius: 14),
                    const SizedBox(width: -8),
                    const CircleAvatar(radius: 14),
                    const SizedBox(width: -8),
                    const CircleAvatar(radius: 14),
                    const SizedBox(width: 8),
                    Text('and others were there', style: AppTypography.caption.copyWith(color: Colors.white70)),
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
