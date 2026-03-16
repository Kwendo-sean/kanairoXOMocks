import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';

class MomentViewerScreen extends StatefulWidget {
  final List<Moment> moments;
  final int initialIndex;
  
  const MomentViewerScreen({
    super.key,
    required this.moments,
    required this.initialIndex,
  });
  
  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable pages
          PageView.builder(
            controller: _pageController,
            itemCount: widget.moments.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => setState(() => _showInfo = !_showInfo),
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy > 200) {
                  Navigator.pop(context);
                }
              },
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: widget.moments[i].photoUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Counter pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_currentIndex + 1} of ${widget.moments.length}',
                          style: AppTypography.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: (widget.moments[_currentIndex].userAvatarUrl != null &&
                                      widget.moments[_currentIndex].userAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(widget.moments[_currentIndex].userAvatarUrl!)
                                  : null,
                              backgroundColor: AppColors.primaryGlass,
                              child: (widget.moments[_currentIndex].userAvatarUrl == null ||
                                      widget.moments[_currentIndex].userAvatarUrl!.isEmpty)
                                  ? const Icon(Icons.person_outline, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.moments[_currentIndex].userName,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.moments[_currentIndex].type.name.toUpperCase(),
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              widget.moments[_currentIndex].timeAgo,
                              style: AppTypography.caption.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                        if (widget.moments[_currentIndex].caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              widget.moments[_currentIndex].caption,
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Action row
                        Row(
                          children: [
                            _ViewerAction(
                              icon: widget.moments[_currentIndex].isLiked ? Icons.favorite : Icons.favorite_border,
                              label: '${widget.moments[_currentIndex].likeCount}',
                              color: widget.moments[_currentIndex].isLiked ? AppColors.primary : Colors.white,
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            _ViewerAction(
                              icon: Icons.chat_bubble_outline,
                              label: '${widget.moments[_currentIndex].commentCount}',
                              color: Colors.white,
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            _ViewerAction(
                              icon: widget.moments[_currentIndex].isSaved ? Icons.bookmark : Icons.bookmark_border,
                              label: '',
                              color: widget.moments[_currentIndex].isSaved ? AppColors.primary : Colors.white,
                              onTap: () {},
                            ),
                            const Spacer(),
                            // Share placeholder
                            GestureDetector(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Social sharing coming soon',
                                    style: AppTypography.caption.copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              child: const Icon(Icons.send_outlined, color: Colors.white60, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Swipe hint dots (bottom center)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.moments.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _currentIndex ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _currentIndex ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
