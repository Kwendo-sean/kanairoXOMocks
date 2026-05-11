import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/moments/comments_bottom_sheet.dart';
import 'package:kanairoxo/widgets/moments/the_drop_widget.dart';
import 'package:kanairoxo/widgets/moments/polaroid_stack.dart';
import 'package:kanairoxo/widgets/moments/constellation_view.dart';
import 'package:kanairoxo/services/widget_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/screens/create_moment_screen.dart';
import 'package:kanairoxo/screens/moments/moment_detail_screen.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final MomentService _momentService = MomentService();
  
  List<Moment> _allMoments = [];
  DropModel? _dropData;
  
  bool _isLoading = true;
  String _selectedTag = 'All';
  String _carouselStyle = 'polaroid';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStylePreference();
      _loadDropData();
    });
  }

  Future<void> _loadStylePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('carousel_style');
      if (mounted) {
        setState(() {
          _carouselStyle = saved ?? 'polaroid';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carouselStyle = 'polaroid';
        });
      }
    }
  }

  Future<void> _switchStyle(String style) async {
    if (_carouselStyle == style) return;
    
    setState(() => _carouselStyle = style);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('carousel_style', style);
    } catch (e) {
      // Error
    }
  }

  Future<void> _loadMoments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final moments = await _momentService.getMoments();
      if (!mounted) return;
      setState(() {
        _allMoments = moments;
        _isLoading = false;
      });
      WidgetService.refreshAllWidgets(_allMoments, 0, 0); 
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDropData() async {
    try {
      final response = await ApiClient.instance.dio.get('/api/v1/moments/drop/');
      if (mounted) {
        setState(() {
          _dropData = DropModel.fromJson(response.data as Map<String, dynamic>);
        });
        if (_dropData != null) {
          WidgetService.updateDropWidget(
              secondsUntilDrop: _dropData!.secondsUntilDrop,
              isLive: _dropData!.status == 'live');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dropData = null);
      }
    }
  }

  List<Moment> get filteredMoments {
    if (_selectedTag == 'All') return _allMoments;
    return _allMoments
        .where((m) => m.type.name.toLowerCase() == _selectedTag.toLowerCase())
        .toList();
  }

  void openCreateMoment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateMomentScreen()),
    );
    if (result == true) {
      _loadMoments();
    }
  }

  void _openMomentViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MomentDetailScreen(
          moments: _allMoments,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: _buildBody());
  }
  
  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _safeTopSection()),

        if (_dropData?.status != 'live')
          SliverToBoxAdapter(
            child: _buildViewToggle()),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_carouselSubtitle,
              style: AppTypography.caption.copyWith(
                color: context.mutedColor,
                fontStyle: FontStyle.italic),
              textAlign: TextAlign.center))),
        
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterTabsDelegate(
            selectedTag: _selectedTag,
            onTagSelected: (tag) => setState(() =>
              _selectedTag = tag),
            backgroundColor: context.bgColor)),
        
        if (_isLoading && _allMoments.isEmpty)
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: PulsingGlassPlaceholder(width: 40, height: 40, borderRadius: 20)),
            ))
        else if (filteredMoments.isEmpty)
          SliverToBoxAdapter(
            child: _buildTagEmptyState())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _MomentCard(
                moment: filteredMoments[i],
                onImageTap: () => _openMomentViewer(_allMoments.indexOf(filteredMoments[i]))),
              childCount: filteredMoments.length)),
        
        const SliverToBoxAdapter(
          child: SizedBox(height: 80)),
      ]);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Moments', style: AppTypography.screenTitle.copyWith(color: context.textColor)),
        centerTitle: true,
        actions: [
          TextButton.icon(
              icon: Icon(Icons.add_circle_outline,
                  size: 16, color: context.primaryColor),
              label: Text('Create',
                  style: AppTypography.labelMedium.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600)),
              onPressed: openCreateMoment),
        ]);
  }

  Widget _buildViewToggle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _switchStyle('polaroid'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 'polaroid'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 14,
                      color: _carouselStyle == 'polaroid'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Polaroid',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'polaroid'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'polaroid'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
            GestureDetector(
              onTap: () => _switchStyle(
                'constellation'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 
                    'constellation'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: _carouselStyle == 
                        'constellation'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Stars',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'constellation'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'constellation'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
          ])));
  }
  
  Widget _safeTopSection() {
    try {
      return _buildTopSection();
    } catch (e) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDark ? context.surfaceColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
        child: Center(child: Icon(
          Icons.photo_library_outlined,
          size: 48, color: context.mutedColor)));
    }
  }

  Widget _buildTopSection() {
    if (_dropData != null && (_dropData!.status == 'live' || _dropData!.secondsUntilDrop > 0)) {
       return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TheDropWidget(
          dropData: _dropData!,
          onRefresh: _loadDropData));
    }

    if (_carouselStyle == 'constellation') {
      return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConstellationView(
              moments: _allMoments, 
              onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
    }

    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: PolaroidStack(
            moments: _allMoments,
            onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
  }

  Widget _buildTagEmptyState() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.photo_library_outlined,
                  size: 44, color: context.mutedColor),
              const SizedBox(height: 12),
              Text(
                  _selectedTag == 'All'
                      ? 'No moments yet'
                      : 'No $_selectedTag moments yet',
                  style:
                      AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 6),
              Text('Be the first to share one',
                  style:
                      AppTypography.caption.copyWith(color: context.mutedColor)),
              const SizedBox(height: 16),
              LiquidGlassButton(
                  size: LiquidButtonSize.md,
                  onPressed: openCreateMoment,
                  child: Text('Create Moment', style: AppTypography.buttonText)),
            ])));
  }
}

class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  final String selectedTag;
  final Function(String) onTagSelected;
  final Color backgroundColor;

  _FilterTabsDelegate({
    required this.selectedTag,
    required this.onTagSelected,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;
  
  @override
  bool shouldRebuild(_FilterTabsDelegate old) =>
    old.selectedTag != selectedTag ||
    old.backgroundColor != backgroundColor;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: backgroundColor,
          child: OverflowBox(
            minHeight: 52,
            maxHeight: 52,
            alignment: Alignment.topCenter,
            child: _buildTabs(context),
          ),
        );
      }
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['All', 'Event', 'Meetup', 'Vibe']
            .map((tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onTagSelected(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selectedTag == tag ? context.primaryColor : context.surfaceColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selectedTag == tag ? context.primaryColor : context.borderColor,
                            width: 1),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: selectedTag == tag ? Colors.white : context.mutedColor,
                            fontWeight: selectedTag == tag ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MomentCard extends StatefulWidget {
  final Moment moment;
  final VoidCallback onImageTap;

  const _MomentCard({
    required this.moment,
    required this.onImageTap,
  });

  @override
  State<_MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<_MomentCard> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.moment.isLiked;
    _likeCount = widget.moment.likeCount;
    _isSaved = widget.moment.isSaved;
  }

  Future<void> _toggleLike() async {
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/${widget.moment.id}/like/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/${widget.moment.id}/save/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = wasSaved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
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
                  backgroundImage: (widget.moment.userAvatarUrl != null && widget.moment.userAvatarUrl!.isNotEmpty) 
                      ? NetworkImage(widget.moment.userAvatarUrl!) 
                      : null,
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: (widget.moment.userAvatarUrl == null || widget.moment.userAvatarUrl!.isEmpty) 
                      ? Icon(Icons.person_outline, size: 18, color: context.primaryColor) 
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.moment.userName,
                          style: AppTypography.labelMedium
                              .copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
                      if (widget.moment.trackName != null && widget.moment.trackName!.isNotEmpty)
                        Row(children: [
                          const Icon(Icons.music_note, size: 10, color: Color(0xFF1DB954)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(
                            '${widget.moment.trackName} — ${widget.moment.trackArtist ?? ''}',
                            style: AppTypography.caption.copyWith(color: const Color(0xFF1DB954), fontSize: 10),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.moment.type.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onDoubleTap: _toggleLike,
            onTap: widget.onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Hero(
                tag: 'moment_${widget.moment.id}',
                child: SafeNetworkImage(
                  url: widget.moment.photoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                ),
              ),
            ),
          ),

          if (widget.moment.location != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: context.mutedColor),
                  const SizedBox(width: 3),
                  Text(widget.moment.location!, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Text(
              widget.moment.caption,
              style: AppTypography.bodyMedium.copyWith(color: context.textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _MomentAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? context.primaryColor : context.mutedColor,
                  label: '$_likeCount',
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${widget.moment.commentCount}',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsBottomSheet(momentId: widget.moment.id)),
                ),
                const Spacer(),
                _MomentAction(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? context.primaryColor : context.mutedColor,
                  label: '',
                  onTap: _toggleSave,
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
      icon: Icon(icon, size: 16, color: color ?? context.mutedColor),
      label: label.isNotEmpty ? Text(label, style: AppTypography.caption.copyWith(color: context.mutedColor)) : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
