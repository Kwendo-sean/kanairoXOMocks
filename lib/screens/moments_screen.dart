import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/widgets/three_d_carousel.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
import 'package:kanairoxo/screens/create_moment_screen.dart';
import 'package:kanairoxo/screens/singles/moment_viewer_screen.dart';
import 'package:kanairoxo/utils/constants.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final MomentService _momentService = MomentService();
  List<Moment> _allMoments = [];
  bool _isLoading = true;
  String _selectedTag = 'All';
  int _carouselIndex = 0;

  final List<String> _subtitles = [
    'Where Nairobi comes alive',
    'The city through your eyes',
    'Real moments, real connections',
    'Life in Nairobi, unfiltered',
    'Your story, your city',
    'Nairobi never sleeps',
    'Captured in the moment',
  ];
  
  late final String _carouselSubtitle;

  @override
  void initState() {
    super.initState();
    _carouselSubtitle = _subtitles[DateTime.now().millisecond % _subtitles.length];
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    setState(() => _isLoading = true);
    try {
      final moments = await _momentService.getMoments();
      setState(() {
        _allMoments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading moments: $e')),
        );
      }
    }
  }

  List<Moment> get _filteredMoments {
    if (_selectedTag == 'All') return _allMoments;
    return _allMoments.where((m) =>
      m.type.name.toLowerCase() == _selectedTag.toLowerCase()
    ).toList();
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateMomentScreen()),
    );
    if (result == true) {
      _loadMoments();
    }
  }

  void _openMomentViewer(int index) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => 
        MomentViewerScreen(
          moments: _allMoments,
          initialIndex: index),
      transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Moments', style: AppTypography.screenTitle),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
            label: Text('Create',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: _navigateToCreate,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildCarouselSection(),
                _buildFilterTabs(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMoments,
                    child: _filteredMoments.isEmpty
                        ? _buildTagEmptyState()
                        : _buildMomentsFeed(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCarouselSection() {
    final validMoments = _allMoments
        .where((m) => m.photoUrl.isNotEmpty && Uri.tryParse(m.photoUrl)?.hasAbsolutePath == true)
        .toList();

    if (validMoments.isEmpty) {
      return Container(
        height: 260,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: AppRadius.lg),
        child: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined,
              size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('Your moments will appear here',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted)),
          ])));
    }

    return Column(
      children: [
        ThreeDCarousel(
          height: 260,
          imageUrls: validMoments.take(5).map((m) => m.photoUrl).toList(),
          onPageChanged: (index) => setState(() => _carouselIndex = index),
          onCardTap: (index) => _openMomentViewer(index),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(validMoments.take(5).length, (index) {
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
        Text(_carouselSubtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['All', 'Event', 'Meetup', 'Vibe']
          .map((tag) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTag = tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedTag == tag ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _selectedTag == tag ? AppColors.primary : Colors.grey.shade200,
                    width: 1),
                ),
                child: Text(tag,
                  style: AppTypography.labelMedium.copyWith(
                    color: _selectedTag == tag ? Colors.white : AppColors.textSecondary,
                    fontWeight: _selectedTag == tag ? FontWeight.w600 : FontWeight.w400)),
              ),
            ))).toList(),
      ),
    );
  }

  Widget _buildMomentsFeed() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredMoments.length,
      itemBuilder: (context, index) => _MomentCard(
        moment: _filteredMoments[index],
        onLike: () => _toggleLike(_filteredMoments[index]),
        onComment: () => _openComments(context, _filteredMoments[index]),
      ),
    );
  }

  Widget _buildTagEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined,
              size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              _selectedTag == 'All'
                ? 'No moments yet'
                : 'No $_selectedTag moments yet',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Be the first to share one',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted)),
            const SizedBox(height: 16),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: _navigateToCreate,
              child: Text('Create Moment',
                style: AppTypography.buttonText)),
          ])));
  }

  Future<void> _toggleLike(Moment moment) async {
    try {
      await _momentService.toggleLike(moment.id);
      _loadMoments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not like moment')),
        );
      }
    }
  }

  void _openComments(BuildContext context, Moment moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MomentCommentsSheet(moment: moment),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final Moment moment;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _MomentCard({
    required this.moment,
    required this.onLike,
    required this.onComment,
  });

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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (moment.userAvatarUrl != null && moment.userAvatarUrl!.isNotEmpty) 
                      ? NetworkImage(moment.userAvatarUrl!) 
                      : null,
                  backgroundColor: AppColors.primaryGlass,
                  child: (moment.userAvatarUrl == null || moment.userAvatarUrl!.isEmpty) 
                      ? const Icon(Icons.person_outline, size: 18, color: AppColors.primary) 
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.userName,
                        style: AppTypography.labelMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(moment.timeAgo, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlass,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    moment.type.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          GestureDetector(
            onDoubleTap: onLike,
            child: CachedNetworkImage(
              imageUrl: moment.photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 240,
              errorWidget: (context, url, error) {
                debugPrint('IMG ERROR: $url | $error');
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted, 
                    size: 24)));
              },
              placeholder: (context, url) => Container(
                color: Colors.grey.shade50,
                child: const Center(child: 
                  CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary))),
            ),
          ),

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

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Text(
              moment.caption,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _MomentAction(
                  icon: moment.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: moment.isLiked ? AppColors.primary : AppColors.textMuted,
                  label: '${moment.likeCount}',
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${moment.commentCount}',
                  onTap: onComment,
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.send_outlined,
                  label: 'Share',
                  color: AppColors.textMuted,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Social sharing coming soon',
                      style: AppTypography.caption.copyWith(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  )),
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

class _MomentCommentsSheet extends StatefulWidget {
  final Moment moment;
  const _MomentCommentsSheet({required this.moment});

  @override
  State<_MomentCommentsSheet> createState() => _MomentCommentsSheetState();
}

class _MomentCommentsSheetState extends State<_MomentCommentsSheet> {
  final MomentService _momentService = MomentService();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _momentService.getComments(widget.moment.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await _momentService.addComment(widget.moment.id, _commentController.text);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      // Error
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: comment['user_avatar'] != null ? NetworkImage(comment['user_avatar']) : null,
                            child: comment['user_avatar'] == null ? const Icon(Icons.person, size: 14) : null,
                          ),
                          title: Text(comment['user_name'] ?? 'User', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(comment['text'] ?? '', style: AppTypography.bodyMedium),
                        );
                      },
                    ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: AppTypography.caption,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: AppRadius.full, borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                Text(moment.caption, style: AppTypography.bodyLarge.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
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
